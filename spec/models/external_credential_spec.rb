# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
end
