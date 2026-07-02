# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    context 'when long data is present' do
      subject(:http_log) do
        create(:http_log, request: { content: "{\"images\":[\"iVBORw0KGgoAAAANSUhEUgAABEkAAAECCAYAAAACQolFAAABY2lDQ1BrQ0dDb2xvclNwYWNlRGlzcGxheVAzAAAok\nX2QsUvDUBDGv1aloHUQHRwcMolDlJIKuji0FURxCFXB6pS+pqmQxkeSIgU3/4GC/4EKzm4Whzo6OAiik+jm5KTgouV5L4mkInqP435877vjOCA5bn\nBu9wOoO75bXMorm6UtJfWMBL0gDObxnK6vSv6uP+P9PvTeTstZv///jcGK6TGqn5QZxl0fSKjE+p7PJe8Tj7m0FHFLshXyieRyyOeBZ71YIL4mVlj\nNqBC/EKvlHt3q4brdYNEOcvu06WysyTmUE1jEDjxw2DDQhAId2T/8s4G/gF1yN\nFSn4UafOrJkSI\"]}" }, response: { body: "data:image/png;base64,iVBORw0KGgoAAAAAACWZVhJZk1NACoAAAAIAAUBEgADAAAAAQABAAABGgAFAAAAAQAAAEoBGwAFAAAAAQAAAFIBKAADAAAAAQACAACHaQAEAAAAAQ
AAAFoAAAAAAAAAkAAAAAEAAACQAAAAAQADk=" })
      end

      it 'truncated long data in request/response before saving', :aggregate_failures do
        expect(http_log.request['content']).to eq('{"images":["iVBORw0KGgoAAAANSUhEUgAABEkAA...[TRUNCATED]"]}')
        expect(http_log.response['body']).to eq('data:image/png;base64,iVBORw0...[TRUNCATED]')
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
      let(:dot_separated_bearer_token) do
        %w[
          eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9
          eyJzdWIiOiJ1c2VyQGV4YW1wbGUuY29tIiwicm9sZSI6ImFwcCJ9
          c2lnbmF0dXJl
        ].join('.')
      end

      it 'masks Bearer authorization headers' do
        bearer = 'Authorization: Bearer supersecrettoken'
        expect(described_class.mask_sensitive_data(bearer)).to eq('Authorization: Bearer [FILTERED]')
      end

      it 'masks dot-separated Bearer authorization headers completely' do
        bearer = "authorization: Bearer #{dot_separated_bearer_token}"

        expect(described_class.mask_sensitive_data(bearer)).to eq('Authorization: Bearer [FILTERED]')
      end

      it 'masks previously partially filtered dot-separated Bearer authorization headers completely' do
        bearer = [
          'Authorization: Bearer [FILTERED]',
          'eyJzdWIiOiJ1c2VyQGV4YW1wbGUuY29tIn0',
          'c2lnbmF0dXJl',
        ].join('.')

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

  describe '#related_object_label' do
    it 'returns the name of the related object' do
      http_log.related_object = create(:webhook, name: 'Order system')

      expect(http_log.related_object_label).to eq('Order system')
    end

    it 'returns nil without a related object' do
      expect(http_log.related_object_label).to be_nil
    end

    it 'returns nil for a related object that no longer exists' do
      webhook = create(:webhook)
      persisted = create(:http_log, related_object: webhook)
      webhook.destroy!

      expect(persisted.reload.related_object_label).to be_nil
    end

    # A removed addon or a renamed class leaves rows behind whose type cannot be resolved anymore.
    it 'returns nil for a type that cannot be resolved' do
      http_log.related_object_type = 'SomeRemovedAddon::Thing'
      http_log.related_object_id   = 1

      expect { http_log.related_object_label }.not_to raise_error
      expect(http_log.related_object_label).to be_nil
    end

    # 'AI::Provider' resolves, but is a plain class - the association lookup would raise on it.
    it 'returns nil for a type that resolves to something other than a model' do
      http_log.related_object_id = 1

      ['AI::Provider', 'String', 'Kernel'].each do |type|
        http_log.related_object_type = type

        expect { http_log.related_object_label }.not_to raise_error
        expect(http_log.related_object_label).to be_nil
      end
    end
  end

  describe '.related_object_labels' do
    let(:webhook)      { create(:webhook, name: 'Order system') }
    let(:connection)   { create(:ai_provider_connection, name: 'Main OpenAI') }
    let(:referencing)  { [create(:http_log, related_object: webhook), create(:http_log, related_object: connection)] }
    let(:unreferenced) { create(:http_log) }
    let(:stale)        { create(:http_log, related_object_type: 'SomeRemovedAddon::Thing', related_object_id: 1) }

    it 'labels every row that has a usable reference' do
      expect(described_class.related_object_labels(referencing))
        .to eq(referencing.first.id => 'Order system', referencing.second.id => 'Main OpenAI')
    end

    it 'omits rows without a reference and rows whose type does not resolve' do
      expect(described_class.related_object_labels([unreferenced, stale])).to be_empty
    end

    it 'agrees with the per row lookup' do
      logs   = referencing + [unreferenced, stale]
      labels = described_class.related_object_labels(logs)

      expect(logs.map { |log| labels[log.id] }).to eq(logs.map(&:related_object_label))
    end

    it 'needs one query per referenced model, not one per row' do
      logs = referencing + [create(:http_log, related_object: webhook), unreferenced, stale]

      loads    = 0
      callback = ->(*, payload) { loads += 1 if payload[:name]&.end_with?(' Load') }

      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        described_class.related_object_labels(logs)
      end

      # Two referenced models (Webhook, AI::ProviderConnection) across five rows.
      expect(loads).to eq(2)
    end
  end

  describe '.facility_to_permission' do
    it 'returns correct permission for known facility' do
      expect(described_class.facility_to_permission('GitHub')).to eq('admin.integration')
      expect(described_class.facility_to_permission('webhook')).to eq('admin.webhook')
      expect(described_class.facility_to_permission('cti')).to eq('admin.integration')
      expect(described_class.facility_to_permission('AI::Provider')).to eq('admin.ai_feedback_logs')
      expect(described_class.facility_to_permission('MicrosoftGraph')).to eq('admin.channel_microsoft_graph')
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
        'admin.ai_feedback_logs'        => include('AI::Provider'),
        'admin.integration'             => include('GitHub'),
        'admin.security'                => include('SAML'),
        'admin.webhook'                 => include('webhook'),
        'admin.channel_microsoft_graph' => include('MicrosoftGraph'),
        'admin.channel_whatsapp'        => include('WhatsApp::Business')
      )
    end
  end

  describe '.truncate_long_data' do
    let(:input) { 'R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==' }

    context 'when the input includes long base64 data' do
      it 'truncates long data' do
        expect(described_class.truncate_long_data(input)).to eq('R0lGODlhAQABAAAAACH5BAEKAAEAL...[TRUNCATED]')
      end
    end

    context 'when the input includes base64 data URL prefix' do
      let(:input) { 'data:image/gif;base64,R0lGfODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==' }

      it 'truncates long data but preserves the prefix' do
        expect(described_class.truncate_long_data(input)).to eq('data:image/gif;base64,R0lGfOD...[TRUNCATED]')
      end
    end

    context 'when input is not longer than 32 chars' do
      let(:input) { 'R0lGODlhAQABAAAAACH5BAEKAAEALAA=' }

      it 'returns the input unchanged' do
        expect(described_class.truncate_long_data(input)).to eq(input)
      end
    end
  end
end
