# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HttpLog, :aggregate_failures do
  subject(:http_log) { build(:http_log) }

  describe 'callbacks' do
    # See https://github.com/zammad/zammad/issues/2100
    it 'converts request/response message data to UTF-8 before saving' do
      http_log.request[:content]  = 'foo'.dup.force_encoding('ascii-8bit')
      http_log.response[:content] = 'bar'.dup.force_encoding('ascii-8bit')

      expect { http_log.save }
        .to change { http_log.request[:content].encoding.name }.from('ASCII-8BIT').to('UTF-8')
        .and change { http_log.response[:content].encoding.name }.from('ASCII-8BIT').to('UTF-8')
    end

    context 'when sensitive data is present' do
      subject(:http_log) { create(:http_log, request: { headers: "Authorization: Bearer supersecrettoken\nCookie: session_id=12345; user_id=67890", url: 'https://example.com/api?access_token=query_secret_token&other=param' }, response: { body: 'access_token="anothersecret" api_key: "key-value" secret = "my_secret"' }) }

      it 'masks sensitive data in request/response before saving', :aggregate_failures do
        expect(http_log.request['headers']).to eq("Authorization: Bearer [FILTERED]\nCookie: session_id=[FILTERED]; user_id=[FILTERED]")
        expect(http_log.request['url']).to eq('https://example.com/api?access_token=[FILTERED]&other=param')
        expect(http_log.response['body']).to eq('access_token="[FILTERED]" api_key: "[FILTERED]" secret = "[FILTERED]"')
      end
    end
  end

  describe '.mask_sensitive_data' do
    let(:input) { 'Authorization: Basic dXNlcjpwYXNzd29yZA==' }

    context 'when the input includes authorization basic part' do
      it 'masks Basic authorization headers' do
        expect(described_class.mask_sensitive_data(input)).to eq('Authorization: Basic [FILTERED]')
      end
    end

    context 'when input has no sensitive parts' do
      it 'returns the input unchanged' do
        plain = 'no secrets here'
        expect(described_class.mask_sensitive_data(plain)).to eq('no secrets here')
      end
    end

    context 'when the input includes authorization bearer part' do
      it 'masks Bearer authorization headers' do
        bearer = 'Authorization: Bearer supersecrettoken'
        expect(described_class.mask_sensitive_data(bearer)).to eq('Authorization: Bearer [FILTERED]')
      end
    end

    context 'when the input includes sensitive query parameters' do
      it 'masks only the sensitive query parameter values' do
        url = 'https://example.com/api?api_key=abc123&other=param'
        expect(described_class.mask_sensitive_data(url)).to eq('https://example.com/api?api_key=[FILTERED]&other=param')
      end
    end

    context 'when the input includes cookies' do
      it 'masks cookie values but keeps names' do
        cookies = 'Cookie: session_id=12345; user_id=67890'
        expect(described_class.mask_sensitive_data(cookies)).to eq('Cookie: session_id=[FILTERED]; user_id=[FILTERED]')
      end
    end

    context 'when the input includes inline tokens or secrets' do
      it 'masks inline token-like values' do
        text = 'api_key: 12345 secret="s3cr3t" foo=bar'
        expect(described_class.mask_sensitive_data(text)).to eq('api_key: [FILTERED] secret="[FILTERED]" foo=bar')
      end
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(http_log).to be_valid
    end

    it 'is invalid with unknown facility' do
      http_log.facility = 'unknown'
      expect(http_log).not_to be_valid
      expect(http_log.errors[:facility]).to include('is not included in the list')
    end
  end

  describe '.facility_to_permission' do
    it 'returns correct permission for known facility' do
      expect(described_class.facility_to_permission('GitHub')).to eq('admin.integration')
      expect(described_class.facility_to_permission('webhook')).to eq('admin.webhook')
      expect(described_class.facility_to_permission('cti')).to eq('admin.integration')
      expect(described_class.facility_to_permission('AI::Provider')).to eq('admin.ai_provider')
      expect(described_class.facility_to_permission('WhatsApp::Business')).to eq('admin.channel_whatsapp')
    end

    it 'returns admin.* for blank facility' do
      expect(described_class.facility_to_permission(nil)).to eq('admin.*')
      expect(described_class.facility_to_permission('')).to eq('admin.*')
    end

    it 'returns nil for unknown facility' do
      expect(described_class.facility_to_permission('unknown')).to be_nil
    end
  end

  describe '.facilities_by_permission' do
    it 'returns a hash grouped by permissions with facilities' do
      expect(described_class.facilities_by_permission).to include(
        'admin.ai_provider'      => include('AI::Provider'),
        'admin.integration'      => include('GitHub'),
        'admin.security'         => include('SAML'),
        'admin.webhook'          => include('webhook'),
        'admin.channel_whatsapp' => include('WhatsApp::Business')
      )
    end
  end
end
