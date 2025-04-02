# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ExternalCredential::Exchange do
  describe '.refresh_token' do
    # https://github.com/zammad/zammad/issues/4454
    context 'when Exchange integration is not configured at all' do
      before do
        Setting.set('exchange_oauth', {})
        Setting.set('exchange_integration', true)
      end

      it 'does always return a value' do
        expect(described_class.refresh_token).to be_truthy
      end
    end

    # https://github.com/zammad/zammad/issues/4961
    context 'when Exchange integration is not enabled' do
      before do
        Setting.set('exchange_integration', false)
      end

      it 'does always return a value' do
        expect(described_class.refresh_token).to be_truthy
      end
    end
  end

  describe '.update_client_secret' do
    let(:external_credential) { create(:external_credential, name: 'exchange', credentials:) }
    let(:credentials)         { { client_id: 'id1337', client_secret: 'dummy' } }

    context 'when Exchange integration is not completely configured' do
      before do
        Setting.set('exchange_oauth', { client_id: 'id1337' })
      end

      it 'does not update the setting' do
        external_credential.update!(credentials: credentials)

        expect(Setting.get('exchange_oauth')).to eq({ 'client_id' => 'id1337' })
      end
    end

    context 'when Exchange integration is completely configured' do
      before do
        Setting.set('exchange_oauth', { client_id: 'id1337', client_secret: 'dummy' })
      end

      context 'when client_secret is different' do
        let(:credentials)         { { client_id: 'id1337', client_secret: 'dummy-other' } }

        it 'does not update the setting' do
          external_credential.update!(credentials: credentials.merge(client_secret: 'new-dummy'))

          expect(Setting.get('exchange_oauth')).to eq({ 'client_id' => 'id1337', 'client_secret' => 'dummy' })
        end
      end

      context 'when client_secret is the same' do
        it 'does update the setting' do
          external_credential.update!(credentials: credentials.merge(client_secret: 'new-dummy'))

          expect(Setting.get('exchange_oauth')).to eq({ 'client_id' => 'id1337', 'client_secret' => 'new-dummy' })
        end
      end
    end
  end
end
