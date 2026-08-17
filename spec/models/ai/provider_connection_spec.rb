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

    # The embedding model used to be resolved from the adapter at request time, so the connection
    # serving embeddings could carry none: Setting::Validation::VectorDB kept passing and the
    # failure only surfaced when indexing ran.
    describe 'embedding model of the connection serving embeddings' do
      it 'accepts a connection that names its embedding model' do
        connection = build(:ai_provider_connection, :default_embedding, provider: 'open_ai',
                                                                        config:   { token: 'a', embedding_model: 'text-embedding-3-small' })

        expect(connection).to be_valid
      end

      it 'rejects one that does not' do
        connection = build(:ai_provider_connection, :default_embedding, provider: 'open_ai', config: { token: 'a' })

        expect(connection).not_to be_valid
      end

      it 'rejects one whose embedding model was cleared' do
        connection = build(:ai_provider_connection, :default_embedding, provider: 'open_ai',
                                                                        config:   { token: 'a', embedding_model: '' })

        expect(connection).not_to be_valid
      end

      # The dialog clears the field, the API replaces the whole config - either way semantic search
      # must not switch itself off behind a "successfully updated".
      context 'with a stored connection' do
        let(:connection) { create(:ai_provider_connection, provider: 'open_ai', config: { token: 'a' }).reload }

        it 'rejects clearing its embedding model', :aggregate_failures do
          expect(connection.update(config: { 'token' => 'a', 'embedding_model' => '' })).to be(false)
          expect(connection.reload.default_embedding?).to be true
        end

        it 'rejects a config that no longer names it', :aggregate_failures do
          expect(connection.update(config: { 'token' => 'a' })).to be(false)
          expect(connection.reload.default_embedding?).to be true
        end

        # What the stale flag fix-up is for: a save that does not touch the config at all.
        it 'drops a flag it cannot back with a model on an unrelated save', :aggregate_failures do
          connection.update_column(:config, { 'token' => 'a' })

          expect(connection.reload.update(name: 'renamed')).to be(true)
          expect(connection.reload.default_embedding?).to be false
        end
      end

      it 'does not ask it of a connection that serves something else' do
        expect(build(:ai_provider_connection, provider: 'open_ai', config: { token: 'a' })).to be_valid
      end

      # remove_unsupported_embedding_default drops the flag for such a provider, so rejecting the
      # record instead would make a provider change fail rather than turn the purpose off.
      it 'does not ask it of a provider that cannot embed at all' do
        connection = build(:ai_provider_connection, :default_embedding, provider: 'anthropic', config: { token: 'a' })

        expect(connection).to be_valid
      end

      # Zammad AI serves a fixed model, so there is none for an admin to name.
      it 'does not ask it of a provider whose model is not configurable' do
        connection = build(:ai_provider_connection, :default_embedding, provider: 'zammad_ai', config: { token: 'a' })

        expect(connection).to be_valid
      end
    end

    # A dimension of zero cannot be built into a vector table, and a token budget of zero or less
    # makes the chunker raise - both only once indexing runs, naming anything but the connection
    # that holds the value. The dialog constrains its fields; this covers everything else.
    describe 'embedding metadata of the connection' do
      def connection_with(config)
        build(:ai_provider_connection, provider: 'open_ai', config: { token: 'a', embedding_model: 'text-embedding-3-small' }.merge(config))
      end

      it 'accepts positive numbers' do
        expect(connection_with(embedding_size: 1536, embedding_input_limit: 8191)).to be_valid
      end

      # jsonb keeps what an API write put there, and the consumers parse the number back out of it.
      it 'accepts a number that arrived as a string' do
        expect(connection_with(embedding_size: '1536', embedding_input_limit: '8191')).to be_valid
      end

      # A model no source could size is stored without them, and the consumers fall back.
      it 'accepts a connection that carries neither' do
        expect(connection_with({})).to be_valid
      end

      it 'accepts fields the dialog submitted as cleared' do
        expect(connection_with(embedding_size: '', embedding_input_limit: '')).to be_valid
      end

      it 'rejects a negative input limit', :aggregate_failures do
        connection = connection_with(embedding_input_limit: -1)

        expect(connection).not_to be_valid
        expect(connection.errors.full_messages).to include(a_string_matching(%r{context window size must be a positive number}i))
      end

      it 'rejects a zero input limit' do
        expect(connection_with(embedding_input_limit: 0)).not_to be_valid
      end

      it 'rejects a negative dimension', :aggregate_failures do
        connection = connection_with(embedding_size: -1)

        expect(connection).not_to be_valid
        expect(connection.errors.full_messages).to include(a_string_matching(%r{embedding dimensions must be a positive number}i))
      end

      it 'rejects a zero dimension' do
        expect(connection_with(embedding_size: 0)).not_to be_valid
      end

      it 'rejects a value that is no number at all' do
        expect(connection_with(embedding_size: 'large')).not_to be_valid
      end

      it 'rejects a fractional dimension' do
        expect(connection_with(embedding_size: 1536.5)).not_to be_valid
      end

      it 'reports both fields at once', :aggregate_failures do
        connection = connection_with(embedding_size: 0, embedding_input_limit: -1)

        expect(connection).not_to be_valid
        expect(connection.errors.full_messages.count { |m| m.include?('positive number') }).to eq(2)
      end

      it 'rejects an update that writes one, leaving the stored config untouched', :aggregate_failures do
        connection = create(:ai_provider_connection, provider: 'open_ai',
                                                     config:   { token: 'a', embedding_model: 'text-embedding-3-small', embedding_size: 1536 })

        expect(connection.update(config: connection.config.merge('embedding_size' => -1))).to be(false)
        expect(connection.reload.config['embedding_size']).to eq(1536)
      end

      # A value the API allowed in before this validation existed. Rejecting the record over it would
      # make every later save of it fail, down to the default flag maintenance of its siblings - and
      # both consumers fall back where the config holds no usable number.
      it 'does not reject a save that leaves a stored one where it is' do
        connection = create(:ai_provider_connection, provider: 'open_ai',
                                                     config:   { token: 'a', embedding_model: 'text-embedding-3-small' })
        connection.update_column(:config, connection.config.merge('embedding_size' => -1))

        expect(connection.reload.update(name: 'renamed')).to be(true)
      end
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
      first  = create(:ai_provider_connection, :default_embedding, config: { token: 'a', embedding_model: 'text-embedding-3-small' })
      second = create(:ai_provider_connection, config: { token: 'b', embedding_model: 'text-embedding-3-small' })

      second.update!(default_embedding: true)

      expect(first.reload.default_embedding?).to be false
      expect(second.reload.default_embedding?).to be true
    end

    it 'exposes the flagged connections via .embedding_connection', :aggregate_failures do
      embedding = create(:ai_provider_connection, :default_embedding, config: { token: 'b', embedding_model: 'text-embedding-3-small' })

      expect(described_class.embedding_connection).to eq(embedding)
    end

    it 'strips blank config values so they cannot override provider defaults', :aggregate_failures do
      connection = create(:ai_provider_connection, config: { token: 'a', embedding_model: '', ocr_model: '' })

      # The blank embedding model is stripped like any other; what is left is the recommendation
      # the embedding seeding writes for the first connection, not the cleared value.
      expect(connection.reload.config)
        .to eq('token' => 'a', 'embedding_model' => AI::Provider::OpenAI.recommended_embedding_model)
    end

    it 'drops the default embedding flag when the provider changes to one without embedding support' do
      create(:ai_provider_connection, :default_chat)
      connection = create(:ai_provider_connection, :default_embedding, provider: 'open_ai',
                                                                       config:   { token: 'a', embedding_model: 'text-embedding-3-small' })

      connection.update!(provider: 'anthropic')

      expect(connection.reload.default_embedding?).to be false
    end

    it 'keeps the default embedding flag when the provider changes to another embedding-capable one' do
      create(:ai_provider_connection, :default_chat)
      connection = create(:ai_provider_connection, :default_embedding, provider: 'open_ai',
                                                                       config:   { token: 'a', embedding_model: 'text-embedding-3-small' })

      connection.update!(provider: 'ollama')

      expect(connection.reload.default_embedding?).to be true
    end
  end

  # The very first connection is seeded as the embedding one, and serving embeddings requires a
  # named model - so the seeding names the provider's recommendation, which is the value the former
  # silent fallback resolved to. Only now it is visible in the dialog and recorded with the vectors.
  describe 'embedding default seeding' do
    # What the dialog's listing answered travels to the seeding through the very cache it reads
    # (Service::AI::ProviderConnection::ListModels).
    def cache_listing(provider_name, models, config:)
      allow(AI::Provider.by_name(provider_name)).to receive(:models).and_return(models)

      Service::AI::ProviderConnection::ListModels.execute(provider: provider_name, incoming_config: config)
    end

    # The same listing, cached for 90 seconds (Ollama, custom endpoints) to five minutes (hosted
    # providers) - less than an admin may spend on the dialog, so the save has to arrive at the same
    # answer without the catalogue. Simulated by a catalogue that expires the moment it is cached,
    # while the verdict on the recommendation keeps its own lifetime.
    def cache_expired_listing(provider_name, models, config:)
      stub_const('Service::AI::ProviderConnection::ListModels::CACHE_TTL', 0)

      cache_listing(provider_name, models, config:)
    end

    it 'names the recommended model where the admin named none', :aggregate_failures do
      connection = create(:ai_provider_connection, provider: 'open_ai', config: { token: 'a' })

      expect(connection.reload.default_embedding?).to be true
      expect(connection.config['embedding_model']).to eq('text-embedding-3-small')
    end

    # The wizard deliberately leaves the field empty when the listing carries models but no fit -
    # the seeding must not overrule that with a model the provider was seen not to serve.
    it 'preserves the empty choice when the listing does not offer the recommendation', :aggregate_failures do
      cache_listing('open_ai', [{ id: 'gpt-4.1', capabilities: [:chat] }], config: { 'token' => 'a' })

      connection = create(:ai_provider_connection, provider: 'open_ai', config: { token: 'a' })

      expect(connection.reload.default_embedding?).to be false
      expect(connection.config).not_to have_key('embedding_model')
    end

    # The dialog's listing answered the question, and its cache running out is no permission to seed
    # a model the endpoint was seen not to serve - the admin who leaves the empty option selected
    # takes longer over the dialog than the catalogue lives.
    it 'preserves the empty choice once the cached listing expired', :aggregate_failures do
      cache_expired_listing('open_ai', [{ id: 'bge-m3', capabilities: [:embedding] }], config: { 'token' => 'a' })

      connection = create(:ai_provider_connection, provider: 'open_ai', config: { token: 'a' })

      expect(connection.reload.default_embedding?).to be false
      expect(connection.config).not_to have_key('embedding_model')
    end

    it 'seeds the recommendation the listing offers', :aggregate_failures do
      cache_listing('open_ai', [{ id: 'text-embedding-3-small', capabilities: [:embedding] }], config: { 'token' => 'a' })

      connection = create(:ai_provider_connection, provider: 'open_ai', config: { token: 'a' })

      expect(connection.reload.default_embedding?).to be true
      expect(connection.config['embedding_model']).to eq('text-embedding-3-small')
    end

    # Ollama lists a model by name and tag, while the recommendation names it alone.
    it 'resolves the listed recommendation behind a tag', :aggregate_failures do
      cache_listing('ollama', [{ id: 'bge-m3:latest', capabilities: [:embedding] }], config: { 'url' => 'http://localhost:11434' })

      connection = create(:ai_provider_connection, provider: 'ollama', config: { url: 'http://localhost:11434' })

      expect(connection.reload.default_embedding?).to be true
      expect(connection.config['embedding_model']).to eq('bge-m3')
    end

    # An Ollama with nothing pulled answers an empty listing: it serves nothing, the
    # recommendation included - which is also why the dialog offers it no model there, and asks
    # the admin to name one for the connection that is to serve embeddings.
    it 'preserves the empty choice for a listing that carried nothing at all', :aggregate_failures do
      cache_listing('ollama', [], config: { 'url' => 'http://localhost:11434' })

      connection = create(:ai_provider_connection, provider: 'ollama', config: { url: 'http://localhost:11434' })

      expect(connection.reload.default_embedding?).to be false
      expect(connection.config).not_to have_key('embedding_model')
    end

    it 'keeps the model the admin named', :aggregate_failures do
      connection = create(:ai_provider_connection, provider: 'open_ai',
                                                   config:   { token: 'a', embedding_model: 'text-embedding-3-large' })

      expect(connection.reload.default_embedding?).to be true
      expect(connection.config['embedding_model']).to eq('text-embedding-3-large')
    end

    # Flagging it would produce a record its own validation rejects.
    it 'leaves a provider without a recommendation unflagged', :aggregate_failures do
      connection = create(:ai_provider_connection, provider: 'custom_open_ai',
                                                   config:   { url: 'https://example.com/v1', model: 'gpt-4o' })

      expect(connection.reload.default_embedding?).to be false
      expect(connection.config).not_to have_key('embedding_model')
    end

    it 'leaves a provider that cannot embed unflagged' do
      connection = create(:ai_provider_connection, provider: 'anthropic', config: { token: 'a' })

      expect(connection.reload.default_embedding?).to be false
    end

    # Zammad AI serves a fixed model, so the config stays free of one.
    it 'flags a provider whose model is not configurable without naming one', :aggregate_failures do
      connection = create(:ai_provider_connection, provider: 'zammad_ai', config: { token: 'a' })

      expect(connection.reload.default_embedding?).to be true
      expect(connection.config).not_to have_key('embedding_model')
    end

    # The dialog submits none for it, but an API caller could - and it would then decide what the
    # vectors are built with for a model the admin cannot see.
    it 'drops a submitted model where the provider serves a fixed one', :aggregate_failures do
      connection = create(:ai_provider_connection, provider: 'zammad_ai',
                                                   config:   { token: 'a', embedding_model: 'nomic-embed-text' })

      expect(connection.reload.config).not_to have_key('embedding_model')
      expect(connection.provider_instance.embedding_model).to eq(AI::Provider::ZammadAI::EMBEDDING_MODEL_FALLBACK)
    end

    # The upgrade path of an install whose first connection was a custom endpoint: it was flagged
    # for embeddings by the former seeding, and no model can be named for it. Keeping the flag would
    # persist a record that the validation rejects - which then takes the next save of any sibling
    # connection down with it, and aborted the migration that created the connection to begin with.
    it 'clears a flag it cannot back with a model', :aggregate_failures do
      connection = build(:ai_provider_connection, provider: 'custom_open_ai', default_embedding: true,
                         config: { url: 'https://example.com/v1', model: 'gpt-4o' })

      expect { connection.save!(validate: false) }.not_to raise_error

      expect(connection.reload.default_embedding?).to be false
    end
  end

  # The dialog leaves the model field empty where the admin accepts the recommendation its label
  # names ('Default (text-embedding-3-small)'), while submitting the numbers that describe that very
  # model - so the name has to be recorded along with them, on every connection rather than on the
  # first one of the install alone, which only got it as a side effect of the embedding seeding.
  describe 'recommended embedding model' do
    # What the dialog's listing answered travels to the resolution through the very cache it reads
    # (Service::AI::ProviderConnection::ListModels).
    def cache_listing(provider_name, models, config:)
      allow(AI::Provider.by_name(provider_name)).to receive(:models).and_return(models)

      Service::AI::ProviderConnection::ListModels.execute(provider: provider_name, incoming_config: config)
    end

    # See the seeding above: the catalogue outlives neither a long dialog nor one left open, so it is
    # cached as expired here.
    def cache_expired_listing(provider_name, models, config:)
      stub_const('Service::AI::ProviderConnection::ListModels::CACHE_TTL', 0)

      cache_listing(provider_name, models, config:)
    end

    context 'with a connection already serving embeddings' do
      before { create(:ai_provider_connection, :default_chat, :default_embedding, config: { token: 'a', embedding_model: 'text-embedding-3-small' }) }

      it 'names it on a connection that serves something else', :aggregate_failures do
        connection = create(:ai_provider_connection, provider: 'open_ai',
                                                     config:   { token: 'b', embedding_size: 1536, embedding_input_limit: 8191 })

        # The metadata the dialog filled for the recommendation describes the model it named, which
        # is of no use to its consumers without the model itself.
        expect(connection.reload.config).to include(
          'embedding_model'       => AI::Provider::OpenAI.recommended_embedding_model,
          'embedding_size'        => 1536,
          'embedding_input_limit' => 8191,
        )

        # Naming it is not flagging it: the purposes of the connections stay where they were.
        expect(connection.default_embedding?).to be false
      end

      it 'keeps the model the admin named' do
        connection = create(:ai_provider_connection, provider: 'open_ai',
                                                     config:   { token: 'b', embedding_model: 'text-embedding-3-large' })

        expect(connection.reload.config['embedding_model']).to eq('text-embedding-3-large')
      end

      # The wizard deliberately leaves the field empty where the listing carries models but no fit,
      # and offers no numbers for a model the endpoint was seen not to serve.
      it 'preserves the empty choice when the listing does not offer the recommendation' do
        cache_listing('open_ai', [{ id: 'gpt-4.1', capabilities: [:chat] }], config: { 'token' => 'b' })

        connection = create(:ai_provider_connection, provider: 'open_ai', config: { token: 'b' })

        expect(connection.reload.config).not_to have_key('embedding_model')
      end

      # The listing decision carries through the save, however long after it the save arrives.
      it 'preserves the empty choice once the cached listing expired' do
        cache_expired_listing('open_ai', [{ id: 'bge-m3', capabilities: [:embedding] }], config: { 'token' => 'b' })

        connection = create(:ai_provider_connection, provider: 'open_ai', config: { token: 'b' })

        expect(connection.reload.config).not_to have_key('embedding_model')
      end

      it 'leaves a provider without a recommendation unnamed' do
        connection = create(:ai_provider_connection, provider: 'custom_open_ai',
                                                     config:   { url: 'https://example.com/v1', model: 'gpt-4o' })

        expect(connection.reload.config).not_to have_key('embedding_model')
      end

      # The edit dialog submits the same empty option, so it resolves there as well - for a
      # connection created through the API without one, or one that predates the explicit field.
      it 'names it on an update that rewrites the config' do
        connection = create(:ai_provider_connection, provider: 'open_ai', config: { token: 'b' })
        # Behind the create, which names it already: a connection whose stored config never did.
        connection.update_column(:config, { 'token' => 'b' })

        connection.reload.update!(config: { 'token' => 'c' })

        expect(connection.reload.config['embedding_model']).to eq(AI::Provider::OpenAI.recommended_embedding_model)
      end

      # A save that does not write the config must not start writing one: it is what the stale flag
      # fix-up and the default flag maintenance of a sibling connection run on, over legacy data
      # neither of them is there to complete.
      it 'leaves the config of a save that does not touch it alone' do
        connection = create(:ai_provider_connection, provider: 'open_ai', config: { token: 'b' })
        connection.update_column(:config, { 'token' => 'b' })

        connection.reload.update!(name: 'renamed')

        expect(connection.reload.config).to eq('token' => 'b')
      end
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
      default_conn   = create(:ai_provider_connection, :default_embedding, provider: 'open_ai',
                                                                           config:   { token: 'a', embedding_model: 'text-embedding-3-small' })
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
          create(:ai_provider_connection, :default_embedding, provider: 'ollama',
                                                              config:   { url: 'http://localhost:11434', embedding_model: 'bge-m3' })
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
      AI::Provider::OpenAI       => { 'data' => [{ 'embedding' => [0.1] }] },
      AI::Provider::Mistral      => { 'data' => [{ 'embedding' => [0.1] }] },
      AI::Provider::Ollama       => { 'embeddings' => [[0.1]] },
      AI::Provider::ZammadAI     => [{ 'model' => 'embed-model', 'embeddings' => [[0.1]] }],
      AI::Provider::CustomOpenAI => { 'data' => [{ 'embedding' => [0.1] }] },
    }

    # Fails for a newly added embedding capable provider, which then has to be added to
    # response_bodies above as well, so its logging gets asserted too.
    it 'covers every embedding capable provider' do
      supported = AI::Provider.constants
        .map { |const| AI::Provider.const_get(const) }
        .select { |klass| klass.respond_to?(:supports_embeddings?) && klass.supports_embeddings? }

      expect(supported).to contain_exactly(AI::Provider::CustomOpenAI, AI::Provider::Mistral,
                                           AI::Provider::Ollama, AI::Provider::OpenAI,
                                           AI::Provider::ZammadAI)
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

  # The vectors in the index belong to the configuration that produced them, so the model is where
  # the change is noticed - the console writes these records just like the admin dialog does. What
  # actually decides a rebuild is state, not the event: the index holds whatever
  # Configuration.indexed records, and a save is only interesting where it leaves that stale.
  describe 'vector index rebuild on an embedding configuration change', performs_jobs: true do
    let(:connection) do
      create(:ai_provider_connection, :default_embedding, provider: 'open_ai',
                                                          config:   { token: 'secret-token', embedding_model: 'text-embedding-3-small' })
    end

    before do
      connection
      Setting.set('ai_provider', true)
      Setting.set('vectordb_enabled', true)

      # The index is assumed to already hold what `connection` is configured with, so only a save
      # that actually changes something makes the examples below see a rebuild.
      Service::AI::VectorDB::Embedding::Configuration.record_indexed(Service::AI::VectorDB::Embedding::Configuration.current)

      # The setting saves above reconcile as well (Setting#schedule_vector_index_reconcile) - cleared,
      # so their enqueue does not answer for the assertions, and the lock they leave does not have
      # the enqueue under test dismissed onto it.
      clear_jobs
    end

    # A plain `update!` on the record, which is exactly what a change made from `rails console` is -
    # no controller anywhere in sight.
    it 'rebuilds when the embedding model of the connection serving semantic search changes' do
      expect { connection.update!(config: connection.config.merge('embedding_model' => 'text-embedding-3-large')) }
        .to have_enqueued_job(VectorIndexRebuildJob)
    end

    # The default maintenance saves the new record again through a freshly loaded instance, and
    # Rails runs the commit callbacks of one of those - which does not matter anymore: whichever one
    # runs, it compares the same state (what is configured now) against the same state (what the
    # index holds), and arrives at the same answer either way.
    it 'rebuilds when a connection is created as the one serving semantic search' do
      expect do
        create(:ai_provider_connection, :default_embedding, provider: 'open_ai',
                                                            config:   { token: 'other-token', embedding_model: 'text-embedding-3-large' })
      end.to have_enqueued_job(VectorIndexRebuildJob)
    end

    it 'does not rebuild when the created connection serves nothing' do
      expect { create(:ai_provider_connection, config: { token: 'other-token', embedding_model: 'text-embedding-3-large' }) }
        .not_to have_enqueued_job(VectorIndexRebuildJob)
    end

    # after_commit runs after the last save of the transaction, so the state it reads is whatever the
    # database holds once the whole transaction is done - not an intermediate value from a save
    # earlier in it. Kept as a regression test: the state-based compare makes this safe by
    # construction, with nothing here needing to track which save came first.
    it 'rebuilds when a later save in the same transaction touches something else' do
      expect do
        described_class.transaction do
          connection.update!(config: connection.config.merge('embedding_model' => 'text-embedding-3-large'))
          connection.update!(name: 'renamed')
        end
      end.to have_enqueued_job(VectorIndexRebuildJob)
    end

    # Kept as a regression test: a rolled back transaction leaves no database change behind, so the
    # next save compares against the same state as if it had never happened - nothing has to track
    # that a rollback occurred.
    it 'rebuilds for a change made after a rolled back one' do
      described_class.transaction do
        connection.update!(config: connection.config.merge('embedding_model' => 'text-embedding-3-large'))
        raise ActiveRecord::Rollback
      end

      expect { connection.update!(config: connection.config.merge('embedding_model' => 'text-embedding-ada-002')) }
        .to have_enqueued_job(VectorIndexRebuildJob)
    end

    it 'rebuilds when only the dimensions of the index change' do
      expect { connection.update!(config: connection.config.merge('embedding_size' => 512)) }
        .to have_enqueued_job(VectorIndexRebuildJob)
    end

    it 'rebuilds when a provider change brings another model with it' do
      expect { connection.update!(provider: 'mistral', config: { token: 'secret-token', embedding_model: 'mistral-embed' }) }
        .to have_enqueued_job(VectorIndexRebuildJob)
    end

    it 'rebuilds when semantic search moves to a connection on another model' do
      other = create(:ai_provider_connection, config: { token: 'other-token', embedding_model: 'text-embedding-3-large' })

      expect { other.update!(default_embedding: true) }
        .to have_enqueued_job(VectorIndexRebuildJob)
    end

    it 'does not rebuild when semantic search moves to a connection on the same model' do
      other = create(:ai_provider_connection, config: { token: 'other-token', embedding_model: 'text-embedding-3-small' })

      expect { other.update!(default_embedding: true) }
        .not_to have_enqueued_job(VectorIndexRebuildJob)
    end

    # "Do not use for semantic search" leaves the index standing, so whichever connection takes over
    # afterwards inherits vectors it did not produce.
    context 'when semantic search was switched off and is restored' do
      before { connection.update!(default_embedding: false) }

      # What the index holds was never touched by switching the flag off, so restoring the very
      # configuration it was built with leaves nothing to reconcile.
      it 'does not rebuild when restored on the same model' do
        expect { connection.update!(default_embedding: true) }
          .not_to have_enqueued_job(VectorIndexRebuildJob)
      end

      it 'rebuilds when restored on another model' do
        other = create(:ai_provider_connection, config: { token: 'other-token', embedding_model: 'text-embedding-3-large' })

        expect { other.update!(default_embedding: true) }
          .to have_enqueued_job(VectorIndexRebuildJob)
      end
    end

    # The model is what identifies the vectors, so moving it elsewhere is no reason to embed the
    # whole knowledge base again.
    it 'does not rebuild when the same model moves to another provider' do
      connection.update!(provider: 'ollama', config: { url: 'http://localhost:11434', embedding_model: 'bge-m3' })
      Service::AI::VectorDB::Embedding::Configuration.record_indexed(Service::AI::VectorDB::Embedding::Configuration.current)

      expect { connection.update!(provider: 'zammad_ai', config: { token: 'secret-token' }) }
        .not_to have_enqueued_job(VectorIndexRebuildJob)
    end

    it 'does not rebuild for a rename' do
      expect { connection.update!(name: 'renamed') }
        .not_to have_enqueued_job(VectorIndexRebuildJob)
    end

    it 'does not rebuild for a rotated token' do
      expect { connection.update!(config: connection.config.merge('token' => 'rotated')) }
        .not_to have_enqueued_job(VectorIndexRebuildJob)
    end

    it 'does not rebuild for another chat model' do
      expect { connection.update!(config: connection.config.merge('model' => 'gpt-4.1')) }
        .not_to have_enqueued_job(VectorIndexRebuildJob)
    end

    it 'does not rebuild for a change to a connection that serves nothing' do
      other = create(:ai_provider_connection, config: { token: 'other-token', embedding_model: 'text-embedding-3-large' })

      expect { other.update!(config: other.config.merge('embedding_model' => 'text-embedding-ada-002')) }
        .not_to have_enqueued_job(VectorIndexRebuildJob)
    end

    # Nothing is left to embed with, so there is nothing to rebuild from either - the index is left
    # standing rather than thrown away.
    it 'does not rebuild when the semantic search default is cleared entirely' do
      expect { connection.update!(default_embedding: false) }
        .not_to have_enqueued_job(VectorIndexRebuildJob)
    end

    # Switching it back on reconciles the same way (VectorIndexSyncJob delegates to this very job),
    # so there is nothing this hook has to do while it is off.
    it 'does not rebuild while the vector database is switched off' do
      Setting.set('vectordb_enabled', false)

      expect { connection.update!(config: connection.config.merge('embedding_model' => 'text-embedding-3-large')) }
        .not_to have_enqueued_job(VectorIndexRebuildJob)
    end

    # The hook only ever compares local state (what is configured vs. what the setting says the index
    # holds) - it never talks to Elasticsearch, on any save. An outage there is entirely the job's
    # concern, once a rebuild is actually enqueued.
    it 'never talks to Elasticsearch' do
      allow(AI::VectorDB).to receive(:new)

      connection.update!(config: connection.config.merge('embedding_model' => 'text-embedding-3-large'))

      expect(AI::VectorDB).not_to have_received(:new)
    end

    # Nothing is promoted in its place, so this leaves the index standing just like clearing the flag.
    it 'does not rebuild when the connection serving semantic search is deleted' do
      expect { connection.destroy! }
        .not_to have_enqueued_job(VectorIndexRebuildJob)
    end

    it 'does not rebuild when a connection that serves nothing is deleted' do
      other = create(:ai_provider_connection, config: { token: 'other-token', embedding_model: 'text-embedding-3-large' })

      expect { other.destroy! }
        .not_to have_enqueued_job(VectorIndexRebuildJob)
    end
  end
end
