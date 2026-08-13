# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative 'shared_examples/no_model_listing'

# The per provider specs are tagged `integration` and need real credentials, hence they do not run
# in a regular pipeline - the normalization, capability mapping and error mapping of the model
# listing is covered here without network access instead.
RSpec.describe AI::Provider, '.models' do
  def stub_get(response)
    allow(UserAgent).to receive(:get).and_return(response)
  end

  def success_response(data)
    UserAgent::Result.new(success: true, code: 200, data:)
  end

  def failed_response(code, body = nil)
    UserAgent::Result.new(success: false, code:, body:)
  end

  # An entry of a normalized descriptor list, with everything the provider does not report unknown.
  def descriptor(id, capabilities: [:chat], embedding_input_limit: nil, embedding_size: nil)
    {
      id:,
      capabilities:,
      embedding_input_limit:,
      embedding_size:,
    }
  end

  shared_examples 'a provider mapping listing failures' do
    it 'maps a rejected token to the provider message' do
      stub_get(failed_response(401, { error: { message: 'Incorrect API key provided' } }.to_json))

      expect { provider.models(config) }
        .to raise_error(AI::Provider::ResponseError, 'Invalid API key - please check your configuration')
    end

    it 'maps a missing endpoint to the provider message' do
      stub_get(failed_response(404))

      expect { provider.models(config) }
        .to raise_error(AI::Provider::ResponseError, 'Not found - resource not found')
    end

    it 'maps a server error to the provider message' do
      stub_get(failed_response(500))

      expect { provider.models(config) }
        .to raise_error(AI::Provider::ResponseError, 'API server error - please try again')
    end

    # UserAgent answers transport failures with code 0 and no body at all.
    it 'maps an unreachable endpoint to the provider message' do
      stub_get(UserAgent::Result.new(success: false, code: 0, error: '#<Errno::ECONNREFUSED>'))

      expect { provider.models(config) }
        .to raise_error(AI::Provider::ResponseError, 'An unknown error occurred')
    end

    # A non-JSON body of an otherwise successful response fails to parse inside UserAgent, which
    # answers it like a transport failure.
    it 'maps a non-JSON body to the provider message' do
      stub_get(UserAgent::Result.new(success: false, code: 0, error: '#<JSON::ParserError>'))

      expect { provider.models(config) }
        .to raise_error(AI::Provider::ResponseError, 'An unknown error occurred')
    end

    it 'reports a payload that is not a model list' do
      stub_get(success_response({ 'object' => 'list' }))

      expect { provider.models(config) }
        .to raise_error(AI::Provider::ResponseError, 'The response could not be processed.')
    end
  end

  # An id that is not a usable string is no model to offer: it would travel through the capability
  # heuristics - raising there, which the dialog would see as an internal error - and end up in the
  # dropdown as if it were a model name.
  shared_examples 'a provider skipping unusable model entries' do
    it 'skips an entry without a usable id' do
      stub_get(success_response({
                                  list_key => [
                                    { id_key => 123 },
                                    { id_key => { 'nested' => true } },
                                    { id_key => '' },
                                    { 'other' => 'key' },
                                    'not an entry at all',
                                  ],
                                }))

      expect(provider.models(config)).to eq([])
    end
  end

  describe 'with OpenAI' do
    let(:provider) { AI::Provider::OpenAI }
    let(:config)   { { token: 'sk-123' } }
    let(:list_key) { 'data' }
    let(:id_key)   { 'id' }

    include_examples 'a provider mapping listing failures'
    include_examples 'a provider skipping unusable model entries'

    it 'supports model listing' do
      expect(provider.supports_model_listing?).to be(true)
    end

    # OpenAI reports nothing but the ids, so the capabilities are the ones derived from them.
    it 'normalizes the listed ids', :aggregate_failures do
      stub_get(success_response({
                                  'object' => 'list',
                                  'data'   => [
                                    { 'id' => 'gpt-4.1' },
                                    { 'id' => 'text-embedding-3-small' },
                                    { 'id' => 'dall-e-3' },
                                    { 'id' => '' },
                                  ],
                                }))

      models = provider.models(config)

      # What OpenAI does not report about an embedding model comes from the provider's table of
      # known defaults.
      embedding_model = descriptor(
        'text-embedding-3-small',
        capabilities:          [:embedding],
        embedding_input_limit: AI::Provider::OpenAI::EMBEDDING_INPUT_LIMITS['text-embedding-3-small'],
        embedding_size:        AI::Provider::OpenAI::EMBEDDING_SIZES['text-embedding-3-small'],
      )

      expect(models).to eq([
                             descriptor('dall-e-3', capabilities: []),
                             descriptor('gpt-4.1', capabilities: %i[chat vision]),
                             embedding_model,
                           ])

      # An entry without an id would end up as a nameless dropdown option.
      expect(models.pluck(:id)).not_to include('')
    end

    it 'attributes the request to the connection' do
      connection = create(:ai_provider_connection)
      stub_get(success_response({ 'data' => [] }))

      provider.models(config, related_object: connection)

      expect(UserAgent).to have_received(:get).with(
        %r{/models\z}, {}, hash_including(log: hash_including(related_object: connection))
      )
    end
  end

  describe 'with Anthropic' do
    let(:provider) { AI::Provider::Anthropic }
    let(:config)   { { token: 'sk-123' } }
    let(:list_key) { 'data' }
    let(:id_key)   { 'id' }

    include_examples 'a provider mapping listing failures'
    include_examples 'a provider skipping unusable model entries'

    it 'requests the whole catalogue with the API key of the config' do
      stub_get(success_response({ 'data' => [] }))

      provider.models(config)

      expect(UserAgent).to have_received(:get).with(
        %r{/models\z},
        { limit: AI::Provider::Anthropic::MODEL_LIST_PAGE_SIZE },
        hash_including(headers: hash_including('X-Api-Key' => 'sk-123')),
      )
    end

    it 'normalizes the listed models by their id, ignoring the reported display name' do
      stub_get(success_response({
                                  'data' => [
                                    { 'type' => 'model', 'id' => 'claude-sonnet-4-6', 'display_name' => 'Claude Sonnet 4.6' },
                                    { 'type' => 'model', 'id' => 'claude-2.1' },
                                  ],
                                }))

      expect(provider.models(config)).to eq([
                                              descriptor('claude-2.1'),
                                              descriptor('claude-sonnet-4-6', capabilities: %i[chat vision]),
                                            ])
    end
  end

  describe 'with Mistral' do
    let(:provider) { AI::Provider::Mistral }
    let(:config)   { { token: 'sk-123' } }
    let(:list_key) { 'data' }
    let(:id_key)   { 'id' }

    include_examples 'a provider mapping listing failures'
    include_examples 'a provider skipping unusable model entries'

    # Mistral lists every alias of a model as a full entry of its own - up to eight ids for one
    # model. One per alias group survives, with the shortest id: the plain name an admin knows,
    # and the one the embedding recommendation points at.
    it 'lists one entry per alias group', :aggregate_failures do
      stub_get(success_response({
                                  'data' => [
                                    { 'id' => 'mistral-embed', 'name' => 'mistral-embed-2312', 'aliases' => ['mistral-embed-2312'] },
                                    { 'id' => 'mistral-embed-2312', 'name' => 'mistral-embed-2312', 'aliases' => ['mistral-embed'] },
                                    { 'id' => 'mistral-medium-latest', 'aliases' => %w[mistral-medium mistral-medium-3] },
                                    { 'id' => 'mistral-medium', 'aliases' => %w[mistral-medium-latest mistral-medium-3] },
                                    { 'id' => 'mistral-medium-3', 'aliases' => %w[mistral-medium mistral-medium-latest] },
                                    # No aliases at all is its own group of one.
                                    { 'id' => 'mistral-ocr-2505' },
                                  ],
                                }))

      models = provider.models(config)

      expect(models.pluck(:id)).to eq(%w[mistral-embed mistral-medium mistral-ocr-2505])
    end

    it 'normalizes the reported capabilities' do
      stub_get(success_response({
                                  'data' => [
                                    { 'id' => 'mistral-large-2512', 'name' => 'Mistral Large', 'max_context_length' => 131_072,
                                      'capabilities' => { 'completion_chat' => true, 'vision' => false } },
                                    { 'id' => 'pixtral-12b', 'max_context_length' => 128_000,
                                      'capabilities' => { 'completion_chat' => true, 'vision' => true } },
                                    # Mistral has no flag for embedding models, so this one has to
                                    # come from the id heuristics.
                                    { 'id'           => 'mistral-embed',
                                      'capabilities' => { 'completion_chat' => false, 'vision' => false } },
                                  ],
                                }))

      embedding_model = descriptor(
        'mistral-embed',
        capabilities:          [:embedding],
        embedding_input_limit: AI::Provider::Mistral::EMBEDDING_INPUT_LIMITS['mistral-embed'],
        embedding_size:        AI::Provider::Mistral::EMBEDDING_SIZES['mistral-embed'],
      )

      expect(provider.models(config)).to eq([
                                              embedding_model,
                                              # The context window Mistral reports for a chat model
                                              # is not embedding metadata, so it is not passed on.
                                              descriptor('mistral-large-2512'),
                                              descriptor('pixtral-12b', capabilities: %i[chat vision]),
                                            ])
    end

    # The table of known defaults only stands in for what the provider does not report.
    it 'prefers the reported input limit over the known default' do
      stub_get(success_response({ 'data' => [{ 'id' => 'mistral-embed', 'max_context_length' => 4096 }] }))

      expect(provider.models(config).first)
        .to include(embedding_input_limit: 4096, embedding_size: AI::Provider::Mistral::EMBEDDING_SIZES['mistral-embed'])
    end

    # The descriptor promises a string name and an integer size; passing something else on would
    # only move the failure to the consumer.
    it 'ignores metadata that is not of the promised type' do
      stub_get(success_response({ 'data' => [{ 'id' => 'mistral-large-2512', 'name' => 42, 'max_context_length' => '131072' }] }))

      expect(provider.models(config)).to eq([descriptor('mistral-large-2512')])
    end
  end

  describe 'with Ollama' do
    let(:provider) { AI::Provider::Ollama }
    let(:config)   { { url: 'http://localhost:11434' } }
    let(:list_key) { 'models' }
    let(:id_key)   { 'model' }

    # /api/tags carries the capabilities and sizes of every pulled model, so no model needs a
    # detail request of its own.
    let(:entries) do
      [
        {
          'name'         => 'llama3.2:latest',
          'model'        => 'llama3.2:latest',
          'capabilities' => %w[completion tools],
          'details'      => { 'context_length' => 131_072, 'embedding_length' => 3072 },
        },
        {
          # Older versions report the name only.
          'name'         => 'bge-m3:latest',
          'capabilities' => %w[embedding],
          'details'      => { 'context_length' => 8192, 'embedding_length' => 1024 },
        },
      ]
    end

    before do
      stub_get(success_response({ 'models' => entries }))
    end

    include_examples 'a provider mapping listing failures'
    include_examples 'a provider skipping unusable model entries'

    it 'normalizes every listed model' do
      expect(provider.models(config)).to eq([
                                              descriptor('bge-m3:latest', capabilities: [:embedding], embedding_input_limit: 8192, embedding_size: 1024),
                                              # A chat model reports neither size: the embedding
                                              # length Ollama gives for it is only its hidden size,
                                              # and its context window is not embedding metadata.
                                              descriptor('llama3.2:latest'),
                                            ])
    end

    it 'talks to the endpoint once, with the request attributed to the connection', :aggregate_failures do
      connection = create(:ai_provider_connection)
      allow(UserAgent).to receive(:post)

      provider.models(config, related_object: connection)

      expect(UserAgent).to have_received(:get).with(
        %r{/api/tags\z}, {}, hash_including(log: hash_including(related_object: connection, log_only_on_error: true))
      ).once

      # Details used to be fetched per model, which no longer happens.
      expect(UserAgent).not_to have_received(:post)
    end

    # The capability can also come from the heuristics, in which case the reported embedding length
    # is still the size of that model's vectors.
    it 'keeps the embedding size of a model derived as one' do
      entries.last.merge!('capabilities' => %w[tools], 'details' => { 'embedding_length' => 1024 })

      expect(provider.models(config)).to include(
        descriptor('bge-m3:latest', capabilities: [:embedding], embedding_size: 1024,
                                    embedding_input_limit: AI::Provider::Ollama::EMBEDDING_INPUT_LIMITS['bge-m3'])
      )
    end

    # Ollama identifies a model by name and tag, while the tables of known defaults are keyed by
    # name alone - matching them verbatim would never fill anything in here.
    it 'fills a tagged model in from the known defaults' do
      entries.last.delete('details')

      embedding_model = descriptor(
        'bge-m3:latest',
        capabilities:          [:embedding],
        embedding_input_limit: AI::Provider::Ollama::EMBEDDING_INPUT_LIMITS['bge-m3'],
        embedding_size:        AI::Provider::Ollama::EMBEDDING_SIZES['bge-m3'],
      )

      expect(provider.models(config)).to include(embedding_model)
    end

    # An endpoint too old to report capabilities and sizes answers with something else entirely,
    # which must not take the whole list down with it.
    it 'ignores capabilities and details that are not of the promised type' do
      entries.first.merge!('capabilities' => 'completion', 'details' => 'llama')

      expect(provider.models(config)).to include(descriptor('llama3.2:latest'))
    end

    it 'ignores a size that is not a whole number' do
      entries.last['details'] = { 'context_length' => 'many', 'embedding_length' => '1024' }

      embedding_model = descriptor(
        'bge-m3:latest',
        capabilities:          [:embedding],
        embedding_input_limit: AI::Provider::Ollama::EMBEDDING_INPUT_LIMITS['bge-m3'],
        embedding_size:        AI::Provider::Ollama::EMBEDDING_SIZES['bge-m3'],
      )

      expect(provider.models(config)).to include(embedding_model)
    end

    # Neither is a size, and offering one would have the dialog fill in a value its own validation
    # rejects - so it counts as nothing reported and the known defaults stand in.
    it 'ignores a size of zero or less' do
      entries.last['details'] = { 'context_length' => -1, 'embedding_length' => 0 }

      embedding_model = descriptor(
        'bge-m3:latest',
        capabilities:          [:embedding],
        embedding_input_limit: AI::Provider::Ollama::EMBEDDING_INPUT_LIMITS['bge-m3'],
        embedding_size:        AI::Provider::Ollama::EMBEDDING_SIZES['bge-m3'],
      )

      expect(provider.models(config)).to include(embedding_model)
    end
  end

  describe 'with a custom OpenAI compatible provider' do
    let(:provider) { AI::Provider::CustomOpenAI }
    let(:config)   { { url: 'https://example.com/v1' } }
    let(:list_key) { 'data' }
    let(:id_key)   { 'id' }

    include_examples 'a provider skipping unusable model entries'

    it 'supports model listing' do
      expect(provider.supports_model_listing?).to be(true)
    end

    it 'normalizes the listed ids' do
      stub_get(success_response({ 'data' => [{ 'id' => 'gpt-4o' }, { 'id' => 'text-embedding-3-small' }] }))

      expect(provider.models(config)).to eq([
                                              descriptor('gpt-4o', capabilities: %i[chat vision]),
                                              # A custom endpoint embeds too, so an embedding model
                                              # is offered - it reports no sizes to go with it, but
                                              # the shared known defaults resolve a common model
                                              # here just like behind any other provider.
                                              descriptor('text-embedding-3-small',
                                                         capabilities:          [:embedding],
                                                         embedding_size:        1536,
                                                         embedding_input_limit: 8191),
                                            ])
    end

    it 'sends no token when none is configured' do
      stub_get(success_response({ 'data' => [] }))

      provider.models(config)

      expect(UserAgent).to have_received(:get).with(anything, {}, hash_excluding(:bearer_token))
    end

    it 'sends the configured token' do
      stub_get(success_response({ 'data' => [] }))

      provider.models(config.merge(token: 'sk-123'))

      expect(UserAgent).to have_received(:get).with(anything, {}, hash_including(bearer_token: 'sk-123'))
    end

    # A compatible endpoint does not have to implement /models at all - that is a missing list, not
    # a broken configuration, and the dialog falls back to the plain model text field.
    it 'tolerates an endpoint without a model list', :aggregate_failures do
      AI::Provider::CustomOpenAI::MODEL_LIST_UNSUPPORTED_CODES.each do |code|
        stub_get(failed_response(code))

        expect(provider.models(config)).to eq([])
      end
    end

    it 'tolerates a payload that is not a model list' do
      stub_get(success_response({ 'models' => %w[gpt-4o] }))

      expect(provider.models(config)).to eq([])
    end

    it 'still maps a broken configuration to the provider message' do
      stub_get(failed_response(401))

      expect { provider.models(config) }
        .to raise_error(AI::Provider::ResponseError, 'Invalid API key - please check your configuration')
    end
  end

  describe 'with Azure' do
    let(:provider) { AI::Provider::Azure }
    let(:config)   { { token: 'sk-123', url_completions: 'https://example.com/openai/deployments/test/chat/completions' } }

    include_examples 'provider/without model listing'
  end

  describe 'with Zammad AI' do
    let(:provider) { AI::Provider::ZammadAI }
    let(:config)   { { token: 'sk-123' } }

    include_examples 'provider/without model listing'
  end

  describe 'with the base provider' do
    let(:provider) { described_class }
    let(:config)   { {} }

    include_examples 'provider/without model listing'
  end
end
