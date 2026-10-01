# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ExternalCredential, :aggregate_failures, current_user_id: 1, type: :model do
  describe '#update_client_secret' do
    let(:external_credential) { create(:external_credential, name: 'google', credentials:) }

    let(:credentials) do
      {
        'client_secret' => 'dummy-1337',
        'code'          => 'code123',
        'grant_type'    => 'authorization_code',
        'client_id'     => 'dummy123',
        'redirect_uri'  => described_class.callback_url('google'),
      }
    end

    before do
      allow(ExternalCredential::Google).to receive(:update_client_secret).and_call_original
    end

    context 'when credentials are not changed' do
      it 'does not call update_client_secret on the backend module' do
        external_credential.update!(created_at: Time.zone.now)

        expect(ExternalCredential::Google).not_to have_received(:update_client_secret)
      end
    end

    context 'when credentials are changed' do
      context 'when client_secret is blank' do
        it 'does not call update_client_secret on the backend module' do
          external_credential.update!(credentials: credentials.merge('client_secret' => ''))

          expect(ExternalCredential::Google).not_to have_received(:update_client_secret)
        end
      end

      context 'when client_secret is not changed' do
        it 'does not call update_client_secret on the backend module' do
          external_credential.update!(credentials: credentials)

          expect(ExternalCredential::Google).not_to have_received(:update_client_secret)
        end
      end

      context 'when client_id is changed' do
        it 'does not call update_client_secret on the backend module' do
          external_credential.update!(credentials: credentials.merge('client_id' => 'dummy456'))

          expect(ExternalCredential::Google).not_to have_received(:update_client_secret)
        end
      end

      context 'when client_secret is changed' do
        it 'calls update_client_secret on the backend module' do
          external_credential.update!(credentials: credentials.merge('client_secret' => 'new-dummy-1337'))

          expect(ExternalCredential::Google).to have_received(:update_client_secret).with('dummy-1337', 'new-dummy-1337')
        end
      end
    end
  end

  shared_examples 'Microsoft app secret rotation' do |provider|
    let(:app_differences) { [{ client_id: 'other' }, { client_tenant: 'other' }, { cloud: 'us_gov' }] }
    let(:credentials) { { client_id: 'app', client_tenant: 'tenant', client_secret: 'old', cloud: 'global' } }
    let(:credential)  { create(:external_credential, name: provider, credentials:) }
    let(:area)        { provider == 'microsoft_graph' ? 'MicrosoftGraph::Account' : 'Microsoft365::Account' }
    let!(:channel)    { create(:channel, area:, options: { auth: credentials }) }

    it 'rotates the secret only for the same app, tenant and cloud' do
      other_channels = app_differences.map do |difference|
        create(:channel, area:, options: { auth: credentials.merge(difference) })
      end

      credential.update!(credentials: credentials.merge(client_secret: 'new'))

      expect(channel.reload.options[:auth][:client_secret]).to eq('new')
      other_channels.each { |other| expect(other.reload.options[:auth][:client_secret]).to eq('old') }
    end

    %i[client_id client_tenant cloud].each do |attribute|
      it "leaves linked credentials unchanged when switching #{attribute}" do
        difference = { attribute => attribute == :cloud ? 'us_gov' : 'other' }
        credential.update!(credentials: credentials.merge(difference).merge(client_secret: 'new'))

        expect(channel.reload.options[:auth]).to eq(credentials.with_indifferent_access)
      end
    end

    it 'can refresh an existing commercial channel after switching the app configuration to GCC High' do
      auth = credentials.merge(provider: provider, type: 'XOAUTH2', created_at: 1.hour.ago, expires_in: 3600, refresh_token: 'refresh', access_token: 'expired')
      channel.update!(options: { auth: auth, inbound: { options: {} }, outbound: { options: {} } })
      credential.update!(credentials: { client_id: 'government-app', client_secret: 'government-secret', client_tenant: 'government-tenant', cloud: 'us_gov' })
      request = stub_request(:post, 'https://login.microsoftonline.com/tenant/oauth2/v2.0/token')
        .with(body: hash_including('client_id' => 'app', 'client_secret' => 'old', 'refresh_token' => 'refresh'))
        .to_return(body: { access_token: 'renewed', expires_in: 3600 }.to_json)

      channel.reload.refresh_xoauth2!(force: true)

      expect(request).to have_been_requested.once
      expect(channel.reload.options[:auth]).to include(client_id: 'app', client_secret: 'old', cloud: 'global', access_token: 'renewed')
    end

    it 'treats missing cloud metadata as Global during secret rotation' do
      channel.update!(options: { auth: credentials.except(:cloud) })

      credential.update!(credentials: credentials.except(:cloud).merge(client_secret: 'new'))

      expect(channel.reload.options[:auth][:client_secret]).to eq('new')
    end
  end

  %w[microsoft_graph microsoft365].each do |provider|
    context "with a #{provider} app" do
      include_examples 'Microsoft app secret rotation', provider
    end
  end
end
