# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::ProviderConnection, type: :model do
  subject(:provider_connection) { create(:ai_provider_connection) }

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }

    it 'accepts a supported provider' do
      expect(build(:ai_provider_connection, provider: 'open_ai')).to be_valid
    end

    it 'rejects an unknown provider' do
      expect(build(:ai_provider_connection, provider: 'does_not_exist')).not_to be_valid
    end
  end

  describe '#provider_klass' do
    it 'resolves the adapter class from the provider key' do
      expect(create(:ai_provider_connection, provider: 'open_ai').provider_klass).to eq(AI::Provider::OpenAI)
    end

    it 'returns nil for a connection left with an unknown provider (e.g. legacy data)' do
      connection = build(:ai_provider_connection, provider: 'does_not_exist')
      connection.save(validate: false)

      expect(connection.provider_klass).to be_nil
    end
  end

  describe 'secret masking', aggregate_failures: true do
    subject(:provider_connection) do
      create(:ai_provider_connection, config: {
               token:         'tok',
               api_key:       'ak',
               client_secret: 'cs',
               url:           'https://example.com',
               model:         'gpt-4o',
             })
    end

    let(:masked_config) { provider_connection.self_assets['config'].with_indifferent_access }

    it 'masks secret-ish keys on serialization' do
      expect(masked_config).to include(
        token:         SensitiveParamsHelper::SENSITIVE_MASK,
        api_key:       SensitiveParamsHelper::SENSITIVE_MASK,
        client_secret: SensitiveParamsHelper::SENSITIVE_MASK,
      )
    end

    it 'leaves non-secret keys untouched' do
      expect(masked_config).to include(url: 'https://example.com', model: 'gpt-4o')
    end

    it 'does not mutate the stored config' do
      provider_connection.self_assets
      expect(provider_connection.reload.config['token']).to eq('tok')
    end

    # The search index gets the raw attributes, with no masking hook to apply the above.
    it 'keeps the config out of the search index' do
      expect(provider_connection.search_index_attribute_lookup.keys)
        .to include('name', 'provider').and(not_include('config', 'status'))
    end
  end

  describe 'default flag exclusivity' do
    it 'clears the default embedding flag on other connections when enabling it', :aggregate_failures do
      create(:ai_provider_connection, :default_chat)
      first  = create(:ai_provider_connection, :default_embedding, config: { token: 'a' })
      second = create(:ai_provider_connection, config: { token: 'b' })

      second.update!(default_embedding: true)

      expect(first.reload.default_embedding?).to be false
      expect(second.reload.default_embedding?).to be true
    end

    it 'exposes the flagged connections via .embedding_connection', :aggregate_failures do
      embedding = create(:ai_provider_connection, :default_embedding, config: { token: 'b' })

      expect(described_class.embedding_connection).to eq(embedding)
    end

    it 'strips blank config values so they cannot override provider defaults', :aggregate_failures do
      connection = create(:ai_provider_connection, config: { token: 'a', embedding_model: '', ocr_model: '' })

      expect(connection.reload.config).to eq('token' => 'a')
    end

    it 'drops the default embedding flag when the provider changes to one without embedding support' do
      create(:ai_provider_connection, :default_chat)
      connection = create(:ai_provider_connection, :default_embedding, provider: 'open_ai', config: { token: 'a' })

      connection.update!(provider: 'anthropic')

      expect(connection.reload.default_embedding?).to be false
    end

    it 'keeps the default embedding flag when the provider changes to another embedding-capable one' do
      create(:ai_provider_connection, :default_chat)
      connection = create(:ai_provider_connection, :default_embedding, provider: 'open_ai', config: { token: 'a' })

      connection.update!(provider: 'ollama')

      expect(connection.reload.default_embedding?).to be true
    end
  end

  describe 'online service protection' do
    # The platform provisions the Zammad AI connection outside this validated admin model —
    # simulated via a validation-bypassing save.
    def provisioned_zammad_ai_connection
      build(:ai_provider_connection, provider: 'zammad_ai').tap { |c| c.save(validate: false) }
    end

    it 'blocks deleting the Zammad AI connection on SaaS', :aggregate_failures do
      Setting.set('system_online_service', true)
      conn = provisioned_zammad_ai_connection

      expect { conn.destroy }.to raise_error(Exceptions::UnprocessableContent)
      expect(described_class.exists?(conn.id)).to be true
    end

    it 'allows deleting the Zammad AI connection on self-hosted systems' do
      conn = create(:ai_provider_connection, provider: 'zammad_ai')

      expect { conn.destroy }.to change(described_class, :count).by(-1)
    end

    it 'allows deleting other connections on SaaS' do
      Setting.set('system_online_service', true)
      conn = create(:ai_provider_connection, provider: 'open_ai')

      expect { conn.destroy }.to change(described_class, :count).by(-1)
    end
  end

  describe 'provider changes on SaaS' do
    it 'blocks creating a new Zammad AI connection on SaaS' do
      Setting.set('system_online_service', true)

      expect(build(:ai_provider_connection, provider: 'zammad_ai')).not_to be_valid
    end

    it 'allows creating a Zammad AI connection on self-hosted systems' do
      expect(build(:ai_provider_connection, provider: 'zammad_ai')).to be_valid
    end

    it 'blocks switching an existing connection to Zammad AI on SaaS' do
      Setting.set('system_online_service', true)
      conn = create(:ai_provider_connection, provider: 'open_ai')

      conn.provider = 'zammad_ai'

      expect(conn).not_to be_valid
    end

    it 'blocks switching the provisioned Zammad AI connection away from it on SaaS' do
      Setting.set('system_online_service', true)
      conn = build(:ai_provider_connection, provider: 'zammad_ai').tap { |c| c.save(validate: false) }

      conn.provider = 'open_ai'

      expect(conn).not_to be_valid
    end

    it 'allows switching a Zammad AI connection to another provider on self-hosted systems' do
      conn = create(:ai_provider_connection, provider: 'zammad_ai')

      conn.provider = 'open_ai'

      expect(conn).to be_valid
    end
  end

  describe 'dependent associations' do
    it 'destroys its feature providers when deleted' do
      feature = create(:ai_feature_provider)

      expect { feature.provider_connection.destroy }
        .to change(AI::FeatureProvider, :count).by(-1)
    end

    it 'promotes the next connection to default when the current default is deleted' do
      default_conn = create(:ai_provider_connection, :default_chat)
      next_conn    = create(:ai_provider_connection)

      default_conn.destroy

      expect(next_conn.reload.default_chat).to be true
    end

    it 'allows deleting the last connection even when it is the default' do
      conn = create(:ai_provider_connection, :default_chat)

      expect { conn.destroy }.to change(described_class, :count).by(-1)
    end

    it 'does not promote a replacement when the default embedding connection is deleted', :aggregate_failures do
      default_conn   = create(:ai_provider_connection, :default_embedding, provider: 'open_ai', config: { token: 'a' })
      other_conn     = create(:ai_provider_connection, provider: 'zammad_ai', config: { token: 'b' })

      default_conn.destroy

      expect(other_conn.reload.default_embedding?).to be false
      expect(described_class.where(default_embedding: true)).to be_none
    end
  end

  describe 'stored health status' do
    subject(:provider_connection) { create(:ai_provider_connection) }

    it 'has no status when never used', :aggregate_failures do
      expect(provider_connection.status).to eq({})
      expect(provider_connection).not_to be_status_error
    end

    describe '#record_status_ok!' do
      it 'stores an ok state with a timestamp', :aggregate_failures do
        provider_connection.record_status_ok!

        expect(provider_connection.reload.status).to include('state' => 'ok', 'at' => be_present)
        expect(provider_connection).not_to be_status_error
      end

      it 'clears a previously stored error', :aggregate_failures do
        provider_connection.record_status_error!('boom')
        provider_connection.record_status_ok!

        expect(provider_connection.reload.status).to include('state' => 'ok')
        expect(provider_connection.status).not_to have_key('message')
      end

      it 'does not rewrite the row when the state is already ok' do
        provider_connection.record_status_ok!

        expect { provider_connection.record_status_ok! }
          .not_to change { provider_connection.reload.status['at'] }
      end
    end

    describe '#record_status_error!' do
      it 'stores an error state with the message and a timestamp' do
        provider_connection.record_status_error!('quota exceeded')

        expect(provider_connection.reload.status)
          .to include('state' => 'error', 'message' => 'quota exceeded', 'at' => be_present)
      end

      it 'flags the connection as errored' do
        provider_connection.record_status_error!('boom')

        expect(provider_connection).to be_status_error
      end

      it 'does not rewrite the row when the same error repeats' do
        provider_connection.record_status_error!('boom')

        expect { provider_connection.record_status_error!('boom') }
          .not_to change { provider_connection.reload.status['at'] }
      end

      it 'refreshes the status when the error message changes' do
        provider_connection.record_status_error!('first')
        provider_connection.record_status_error!('second')

        expect(provider_connection.reload.status).to include('message' => 'second')
      end
    end

    describe 'reset on edit' do
      before { provider_connection.record_status_error!('boom') }

      it 'clears the status when the config changes' do
        provider_connection.update!(config: provider_connection.config.merge('model' => 'new-model'))

        expect(provider_connection.reload.status).to eq({})
      end

      it 'clears the status when the provider changes' do
        provider_connection.update!(provider: 'anthropic')

        expect(provider_connection.reload.status).to eq({})
      end

      it 'keeps the status on an edit that touches neither config nor provider' do
        provider_connection.update!(name: 'renamed-connection')

        expect(provider_connection.reload).to be_status_error
      end
    end
  end

  describe '#record_call' do
    subject(:provider_connection) { create(:ai_provider_connection) }

    it 'returns the block result and records an ok status', :aggregate_failures do
      expect(provider_connection.record_call { 'result' }).to eq('result')
      expect(provider_connection.reload.status).to include('state' => 'ok')
    end

    it 'records a provider response error and re-raises', :aggregate_failures do
      expect { provider_connection.record_call { raise AI::Provider::ResponseError, 'quota exceeded' } }
        .to raise_error(AI::Provider::ResponseError)

      expect(provider_connection.reload.status).to include('state' => 'error', 'message' => 'quota exceeded')
    end

    it 'records a provider request error as well', :aggregate_failures do
      expect { provider_connection.record_call { raise AI::Provider::RequestError, 'timeout' } }
        .to raise_error(AI::Provider::RequestError)

      expect(provider_connection.reload.status).to include('state' => 'error', 'message' => 'timeout')
    end

    it 'lets non-provider errors pass without touching the status', :aggregate_failures do
      expect { provider_connection.record_call { raise ArgumentError, 'Zammad-side bug' } }
        .to raise_error(ArgumentError)

      expect(provider_connection.reload.status).to eq({})
    end

    it 'lets an unusable reply pass without reporting the connection as inaccessible', :aggregate_failures do
      expect { provider_connection.record_call { raise AI::Provider::OutputFormatError, 'unparseable JSON' } }
        .to raise_error(AI::Provider::OutputFormatError)

      expect(provider_connection.reload.status).to eq({})
    end

    it 'keeps a previously stored error untouched when a reply is unusable', :aggregate_failures do
      provider_connection.record_status_error!('quota exceeded')

      expect { provider_connection.record_call { raise AI::Provider::OutputFormatError, 'unparseable JSON' } }
        .to raise_error(AI::Provider::OutputFormatError)

      expect(provider_connection.reload.status).to include('state' => 'error', 'message' => 'quota exceeded')
    end

    it 'clears a previous error on the next successful call' do
      provider_connection.record_status_error!('boom')
      provider_connection.record_call { 'ok' }

      expect(provider_connection.reload.status).to include('state' => 'ok')
    end
  end

  describe 'provider resolution' do
    let(:connection) do
      create(:ai_provider_connection, :default_chat, provider: 'open_ai', config: { token: 'sk-test', model: 'base-model' })
    end

    before do
      Setting.set('ai_provider', true, validate: false)
    end

    describe '.for_chat' do
      context 'with a feature routed to a connection' do
        let(:routed) { create(:ai_provider_connection, provider: 'anthropic', config: { token: 'sk-other' }) }

        before do
          connection
          create(:ai_feature_provider, identifier: 'ticket_summarize', provider_connection: routed)
        end

        it 'returns the routed connection' do
          expect(described_class.for_chat(:ticket_summarize)).to eq(routed)
        end

        it 'accepts a string feature key' do
          expect(described_class.for_chat('ticket_summarize')).to eq(routed)
        end
      end

      context 'when the feature has no routing row' do
        before { connection }

        it 'falls back to the default chat connection' do
          expect(described_class.for_chat(:text_tool)).to eq(connection)
        end
      end

      context 'when no connection exists at all' do
        it 'returns nil' do
          expect(described_class.for_chat(:text_tool)).to be_nil
        end
      end

      context 'when the AI provider is disabled' do
        before do
          connection
          Setting.set('ai_provider', false)
        end

        it 'returns nil despite a configured connection — a queued job must not call out after a disable' do
          expect(described_class.for_chat(:text_tool)).to be_nil
        end
      end
    end

    describe '.for_embeddings' do
      it 'does not fall back to the default chat connection' do
        expect(described_class.for_embeddings).to be_nil
      end

      context 'with a connection is flagged for embedding' do
        let(:flagged) do
          create(:ai_provider_connection, :default_embedding, provider: 'ollama', config: { url: 'http://localhost:11434' })
        end

        before do
          connection
          flagged
        end

        it 'resolves the flagged connection, not the default chat' do
          expect(described_class.for_embeddings).to eq(flagged)
        end
      end

      context 'when the AI provider is disabled' do
        before do
          create(:ai_provider_connection, :default_embedding)
          Setting.set('ai_provider', false)
        end

        it 'returns nil despite a configured connection' do
          expect(described_class.for_embeddings).to be_nil
        end
      end

      context 'when no connection is configured at all' do
        it 'returns nil' do
          expect(described_class.for_embeddings).to be_nil
        end
      end
    end

    describe '.for_ocr' do
      context 'with a default OCR connection' do
        let(:flagged) { create(:ai_provider_connection, :default_ocr, provider: 'anthropic', config: { token: 'sk-other' }) }

        before do
          connection
          flagged
        end

        it 'resolves the default OCR connection, not the default chat' do
          expect(described_class.for_ocr).to eq(flagged)
        end
      end

      context 'when no connection is flagged for OCR' do
        it 'does not fall back to the default chat connection' do
          expect(described_class.for_ocr).to be_nil
        end
      end

      context 'when the AI provider is disabled' do
        before do
          create(:ai_provider_connection, :default_ocr)
          Setting.set('ai_provider', false)
        end

        it 'returns nil despite a flagged connection' do
          expect(described_class.for_ocr).to be_nil
        end
      end
    end

    describe '#provider_instance' do
      it 'builds the configured adapter instance' do
        expect(connection.provider_instance).to be_an_instance_of(AI::Provider::OpenAI)
      end

      it 'passes the connection config through' do
        expect(connection.provider_instance.config).to include(token: 'sk-test')
      end

      it 'uses the connection model' do
        expect(connection.provider_instance.options).to include(model: 'base-model')
      end

      it 'lets caller options win over the connection model' do
        expect(connection.provider_instance(options: { model: 'gpt-4o-mini' }).options).to include(model: 'gpt-4o-mini')
      end

      it 'keeps the connection model when the caller passes a nil model' do
        expect(connection.provider_instance(options: { model: nil }).options).to include(model: 'base-model')
      end

      it 'attributes the provider HTTP logs to the connection' do
        expect(connection.provider_instance.related_object).to eq(connection)
      end

      it 'returns nil for an unknown provider (e.g. legacy data)' do
        legacy = build(:ai_provider_connection, provider: 'does_not_exist')
        legacy.save(validate: false)

        expect(legacy.provider_instance).to be_nil
      end
    end
  end

  describe 'global switch consistency' do
    it 'disables the AI provider when the last connection is deleted' do
      conn = create(:ai_provider_connection, :default_chat)
      Setting.set('ai_provider', true)

      expect { conn.destroy }
        .to change { Setting.get('ai_provider') }
        .from(true).to(false)
    end

    it 'keeps the AI provider enabled while other connections remain' do
      create(:ai_provider_connection, :default_chat)
      conn = create(:ai_provider_connection)
      Setting.set('ai_provider', true)

      expect { conn.destroy }.not_to change { Setting.get('ai_provider') }
    end

    it 'leaves the switch untouched when it was already off' do
      conn = create(:ai_provider_connection, :default_chat)

      expect { conn.destroy }.not_to change { Setting.get('ai_provider') }
    end
  end

  # Embedding requests are as interesting as chat ones in the admin log, and they only show up there
  # when the provider passes log options - open_ai, mistral and ollama silently did not. Covered for
  # every embedding capable provider, so a new one cannot quietly omit them either.
  describe 'embedding request logging' do
    # Each provider parses its own response shape, so the stubbed body has to be realistic enough
    # not to raise before the request is made. The assertion itself is only about the log options.
    response_bodies = {
      AI::Provider::OpenAI   => { 'data' => [{ 'embedding' => [0.1] }] },
      AI::Provider::Mistral  => { 'data' => [{ 'embedding' => [0.1] }] },
      AI::Provider::Ollama   => { 'embeddings' => [[0.1]] },
      AI::Provider::ZammadAI => [{ 'model' => 'embed-model', 'embeddings' => [[0.1]] }],
    }

    # Fails for a newly added embedding capable provider, which then has to be added to
    # response_bodies above as well, so its logging gets asserted too.
    it 'covers every embedding capable provider' do
      supported = AI::Provider.constants
        .map { |const| AI::Provider.const_get(const) }
        .select { |klass| klass.respond_to?(:supports_embeddings?) && klass.supports_embeddings? }

      expect(supported).to contain_exactly(AI::Provider::Mistral, AI::Provider::Ollama,
                                           AI::Provider::OpenAI, AI::Provider::ZammadAI)
    end

    response_bodies.each do |klass, body|
      context "with #{klass.name.demodulize.underscore}" do
        let(:connection) do
          create(:ai_provider_connection,
                 provider: klass.name.demodulize.underscore,
                 config:   { token: 'sk-test', url: 'https://example.com', embedding_model: 'embed-model' })
        end

        before do
          allow(UserAgent).to receive(:post).and_return(UserAgent::Result.new(success: true, code: 200, data: body))
        end

        it 'attributes the embedding request to the connection' do
          connection.provider_instance.bulk_embed(input: ['text'])

          expect(UserAgent).to have_received(:post)
            .with(anything, anything, hash_including(log: hash_including(related_object: connection)))
        end
      end
    end
  end
end
