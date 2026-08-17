# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Provider do
  subject(:ai_provider) do
    described_class.new(
      config: {
        provider: 'open_ai',
        token:    '123',
      },
    )
  end

  describe '#ask' do
    let(:prompt_system) { 'system' }
    let(:prompt_user)   { 'user' }

    it 'raises an error when chat is not implemented' do
      expect do
        ai_provider.ask(prompt_system:, prompt_user:)
      end.to raise_error(RuntimeError, 'not implemented')
    end

    context 'when json_response option is false' do
      subject(:ai_provider) { described_class.new(options: { json_response: false }) }

      it 'returns the raw result' do
        allow(ai_provider).to receive(:chat).and_return('raw result')
        expect(ai_provider.ask(prompt_system:, prompt_user:)).to eq('raw result')
      end
    end

    context 'when json_response option is true' do
      subject(:ai_provider) { described_class.new(options: { json_response: true }) }

      it 'returns parsed JSON for correct format' do
        allow(ai_provider).to receive(:chat).and_return('{"key": "value"}')
        expect(ai_provider.ask(prompt_system:, prompt_user:)).to eq({ 'key' => 'value' })
      end

      it 'removes json code markers and parses JSON' do
        allow(ai_provider).to receive(:chat).and_return("```json\n{\"key\": \"value\"}\n```")
        expect(ai_provider.ask(prompt_system:, prompt_user:)).to eq({ 'key' => 'value' })
      end

      it 'removes generic code markers and parses JSON' do
        allow(ai_provider).to receive(:chat).and_return("```\n{\"key\": \"value\"}\n```")
        expect(ai_provider.ask(prompt_system:, prompt_user:)).to eq({ 'key' => 'value' })
      end

      it 'removes single backtick markers and parses JSON' do
        allow(ai_provider).to receive(:chat).and_return('`{"key": "value"}`')
        expect(ai_provider.ask(prompt_system:, prompt_user:)).to eq({ 'key' => 'value' })
      end

      it 'handles extra whitespace and newlines around markers' do
        allow(ai_provider).to receive(:chat).and_return("  \n```json\n  {\"key\": \"value\"}  \n```  \n")
        expect(ai_provider.ask(prompt_system:, prompt_user:)).to eq({ 'key' => 'value' })
      end

      it 'handles literal newlines inside JSON string values' do
        allow(ai_provider).to receive(:chat).and_return("{\"title\": \"test\", \"body\": \"<p>Hello</p>\n<h3>World</h3>\"}")
        expect(ai_provider.ask(prompt_system:, prompt_user:)).to eq({ 'title' => 'test', 'body' => "<p>Hello</p>\n<h3>World</h3>" })
      end

      it 'handles carriage return and tab inside JSON string values' do
        allow(ai_provider).to receive(:chat).and_return("{\"body\": \"line1\r\nline2\tindented\"}")
        expect(ai_provider.ask(prompt_system:, prompt_user:)).to eq({ 'body' => "line1\nline2\tindented" })
      end

      it 'does not break already escaped sequences' do
        allow(ai_provider).to receive(:chat).and_return('{"body": "line1\\nline2"}')
        expect(ai_provider.ask(prompt_system:, prompt_user:)).to eq({ 'body' => "line1\nline2" })
      end

      it 'raises OutputFormatError for invalid JSON' do
        allow(ai_provider).to receive(:chat).and_return('invalid json')
        expect { ai_provider.ask(prompt_system:, prompt_user:) }
          .to raise_error(AI::Provider::OutputFormatError, 'The response could not be processed.')
      end
    end
  end

  describe '#embed' do
    it 'raises an error' do
      expect do
        ai_provider.embed(
          input: Faker::Lorem.sentence,
        )
      end.to raise_error(RuntimeError, 'not implemented')
    end
  end

  describe '#embedding_input_limit' do
    context 'when the embedding input limit option is present' do
      subject(:ai_provider) do
        described_class.new(
          config: { provider: 'open_ai', token: '123', embedding_input_limit: 1024 },
        )
      end

      it 'returns the configured input limit' do
        expect(ai_provider.embedding_input_limit).to eq(1024)
      end
    end

    # AI::ProviderConnection rejects both on save, but the config is jsonb and one written before
    # that validation existed is still out there - as is a string, which the chunk budget cannot be
    # compared against at all.
    context 'when the configured input limit is unusable' do
      def provider_with(limit)
        AI::Provider::OpenAI.new(
          config: { provider: 'open_ai', token: '123', embedding_model: 'text-embedding-3-small', embedding_input_limit: limit },
        )
      end

      it 'ignores a negative limit' do
        expect(provider_with(-1).embedding_input_limit).to eq(8191)
      end

      it 'ignores a zero limit' do
        expect(provider_with(0).embedding_input_limit).to eq(8191)
      end

      it 'ignores a value that is no number at all' do
        expect(provider_with('unlimited').embedding_input_limit).to eq(8191)
      end

      it 'reads a limit that arrived as a string' do
        expect(provider_with('1024').embedding_input_limit).to eq(1024)
      end
    end

    context 'when the embedding model has a known input limit' do
      subject(:ai_provider) do
        AI::Provider::OpenAI.new(
          config: { provider: 'open_ai', token: '123', embedding_model: 'text-embedding-3-small' },
        )
      end

      it 'returns the input limit of the embedding model' do
        expect(ai_provider.embedding_input_limit).to eq(8191)
      end
    end

    context 'when the embedding model has no known input limit' do
      subject(:ai_provider) do
        described_class.new(
          config: { provider: 'open_ai', token: '123', embedding_model: 'unknown-embedding-model' },
        )
      end

      it 'returns the default input limit' do
        expect(ai_provider.embedding_input_limit).to eq(described_class::DEFAULT_EMBEDDING_INPUT_LIMIT)
      end
    end

    # The model dropdown offers the id an endpoint reports, and Ollama reports name and tag. A
    # verbatim lookup would miss and quietly size the chunks against the conservative default,
    # feeding an 8192 token model in 512 token pieces.
    context 'when the embedding model carries a tag' do
      subject(:ai_provider) do
        AI::Provider::Ollama.new(
          config: { provider: 'ollama', url: 'http://localhost:11434', embedding_model: 'bge-m3:latest' },
        )
      end

      it 'returns the input limit of the model behind the tag' do
        expect(ai_provider.embedding_input_limit).to eq(8192)
      end
    end
  end

  describe '#embedding_size' do
    def provider_with(config)
      AI::Provider::OpenAI.new(config: { provider: 'open_ai', token: '123' }.merge(config))
    end

    it 'returns the configured dimensions' do
      expect(provider_with(embedding_model: 'text-embedding-3-small', embedding_size: 512).embedding_size).to eq(512)
    end

    it 'falls back to what is known about the model' do
      expect(provider_with(embedding_model: 'text-embedding-3-small').embedding_size).to eq(1536)
    end

    # The config is jsonb and keeps whatever an API update wrote into it, down to a string or a
    # number that is no dimension at all - neither of which an index mapping can be built from.
    it 'ignores a configured value that is no dimension' do
      expect(provider_with(embedding_model: 'text-embedding-3-small', embedding_size: 0).embedding_size).to eq(1536)
    end

    it 'reads dimensions that arrived as a string' do
      expect(provider_with(embedding_model: 'text-embedding-3-small', embedding_size: '512').embedding_size).to eq(512)
    end

    it 'is nothing for a model no source could size' do
      expect(provider_with(embedding_model: 'unknown-embedding-model').embedding_size).to be_nil
    end
  end

  describe '.known_embedding_default' do
    it 'returns the value for a model that matches a key' do
      expect(AI::Provider::Ollama.known_embedding_default(:EMBEDDING_SIZES, 'bge-m3')).to eq(1024)
    end

    # Ollama identifies a model by name and tag, while the tables are keyed by name alone.
    it 'returns the value for a tagged model' do
      expect(AI::Provider::Ollama.known_embedding_default(:EMBEDDING_SIZES, 'bge-m3:latest')).to eq(1024)
    end

    # The tables are shared across the providers: what a model is called does not depend on
    # where it is served, so it resolves behind a custom OpenAI compatible endpoint just like
    # behind Ollama.
    it 'resolves the same value regardless of the provider' do
      expect(AI::Provider::OpenAI.known_embedding_default(:EMBEDDING_SIZES, 'bge-m3')).to eq(1024)
    end

    it 'returns nil for a model the table does not know' do
      expect(AI::Provider::Ollama.known_embedding_default(:EMBEDDING_SIZES, 'something-else')).to be_nil
    end

    it 'returns nil without a model', :aggregate_failures do
      expect(AI::Provider::Ollama.known_embedding_default(:EMBEDDING_SIZES, nil)).to be_nil
      expect(AI::Provider::Ollama.known_embedding_default(:EMBEDDING_SIZES, '')).to be_nil
    end
  end

  describe '.ping!' do
    # Providers that validate the config in check_temperature_support! do not implement it.
    it 'does nothing by default' do
      expect(described_class.ping!(nil)).to be_nil
    end
  end

  # Saving a connection validates its config through one of these two methods: ping!, or
  # check_temperature_support! for the providers that talk to the endpoint there anyway. A
  # provider overriding neither would silently accept an unreachable endpoint or a bad token.
  # That the implementation really issues a request is covered per provider in
  # check_temperature_support_spec.rb and the 'provider/ping!' shared example.
  describe 'config validation contract' do
    let(:provider_files) { Rails.root.glob('lib/ai/provider/*.rb') }
    let(:providers)      { provider_files.filter_map { |path| described_class.by_name(path.basename('.rb').to_s) } }

    let(:validation_methods) { %i[ping! check_temperature_support!] }

    it 'is fulfilled by every provider', :aggregate_failures do
      # Every file has to resolve, otherwise a provider would be skipped instead of checked.
      expect(providers.size).to eq(provider_files.size)

      providers.each do |provider|
        implemented = validation_methods.reject do |method|
          provider.method(method).owner == described_class.singleton_class
        end

        expect(implemented).not_to be_empty, "#{provider} implements neither of #{validation_methods}"
      end
    end
  end

  describe '#log_options' do
    let(:connection) { create(:ai_provider_connection) }

    it 'attributes the HTTP log to the related object' do
      instance = described_class.new(config: {}, related_object: connection)

      expect(instance.log_options).to include(facility: 'AI::Provider', related_object: connection)
    end

    it 'omits the reference without a related object' do
      expect(described_class.new(config: {}).log_options.keys).not_to include(:related_object)
    end

    # ping! and check_temperature_support! run before a connection exists.
    it 'has no reference on class level' do
      expect(described_class.log_options(only_on_error: true))
        .to eq(facility: 'AI::Provider', log_only_on_error: true)
    end
  end

  describe '.by_name' do
    it 'returns the correct class' do
      expect(described_class.by_name('open_ai')).to eq(AI::Provider::OpenAI)
    end

    it 'returns nil for an unknown provider' do
      expect(described_class.by_name('does_not_exist')).to be_nil
    end

    # The namespace holds the provider errors and the concerns as well. Resolving one of those
    # would pass for a provider - through the model validation and into a request against it.
    it 'returns nil for a name that resolves to something other than a provider', :aggregate_failures do
      expect(described_class.by_name('request_error')).to be_nil
      expect(described_class.by_name('concerns')).to be_nil
      expect(described_class.by_name('provider')).to be_nil
    end
  end

  # The single source of what an unnamed model resolves to: it reaches the connection dialog
  # through the model listing endpoint, so the AIProviders registry keeps no copy of it.
  describe '.default_model' do
    it 'has none on the base class' do
      expect(described_class.default_model).to be_nil
    end

    it 'answers with the default of the adapter', :aggregate_failures do
      expect(AI::Provider::OpenAI.default_model).to eq('gpt-4.1')
      expect(AI::Provider::Anthropic.default_model).to eq('claude-sonnet-4-6')
      expect(AI::Provider::Mistral.default_model).to eq('mistral-large-2512')
      expect(AI::Provider::Ollama.default_model).to eq('mistral-small3.2')
    end

    # A custom endpoint serves whatever was deployed there, and Azure AI names its deployment in
    # the URL - neither has a model to default to.
    it 'answers with nothing for a provider without a default', :aggregate_failures do
      expect(AI::Provider::CustomOpenAI.default_model).to be_nil
      expect(AI::Provider::Azure.default_model).to be_nil
      expect(AI::Provider::ZammadAI.default_model).to be_nil
    end
  end

  describe '#initialize' do
    it 'ignores a blank config model so the provider default applies' do
      provider = AI::Provider::OpenAI.new(config: { token: 'sk-test', model: '' })

      expect(provider.options[:model]).to eq(AI::Provider::OpenAI::DEFAULT_OPTIONS[:model])
    end

    # There is no default to apply for the embedding model: it is whatever the connection names.
    it 'leaves a blank config embedding model unresolved' do
      provider = AI::Provider::OpenAI.new(config: { token: 'sk-test', embedding_model: '' })

      expect(provider.embedding_model).to be_nil
    end
  end

  describe '#validate_response!' do
    let(:code)     { 0 }
    let(:success)  { nil }
    let(:response) { UserAgent::Result.new(code:, success:) }
    let(:provider) { AI::Provider::OpenAI }

    context 'when the response code is 200' do
      let(:code) { 200 }
      let(:success) { true }

      it 'returns the response content' do
        expect { ai_provider.validate_response!(response) }.not_to raise_error
      end
    end

    context 'when the response code is 400' do
      let(:code) { 400 }
      let(:success) { false }

      it "raises an error with message 'Invalid request - please check your input'" do
        expect { ai_provider.validate_response!(response) }
          .to raise_error(AI::Provider::ResponseError, 'Invalid request - please check your input')
      end
    end

    context 'when the response code is 401' do
      let(:code) { 401 }
      let(:success) { false }

      it "raises an error with message 'Invalid API key - please check your configuration'" do
        expect { ai_provider.validate_response!(response) }
          .to raise_error(AI::Provider::ResponseError, 'Invalid API key - please check your configuration')
      end
    end

    context 'when the response code is 402' do
      let(:code) { 402 }
      let(:success) { false }

      it "raises an error with message 'Payment required - please top up your account'" do
        expect { ai_provider.validate_response!(response) }
          .to raise_error(AI::Provider::ResponseError, 'Payment required - please top up your account')
      end
    end

    context 'when the response code is 403' do
      let(:code) { 403 }
      let(:success) { false }

      it "raises an error with message 'Forbidden - you do not have permission to access this resource'" do
        expect { ai_provider.validate_response!(response) }
          .to raise_error(AI::Provider::ResponseError, 'Forbidden - you do not have permission to access this resource')
      end
    end

    context 'when the response code is 429' do
      let(:code) { 429 }
      let(:success) { false }

      it "raises an error with message 'Rate limit exceeded - please wait a moment'" do
        expect { ai_provider.validate_response!(response) }
          .to raise_error(AI::Provider::ResponseError, 'Rate limit exceeded - please wait a moment')
      end
    end

    context 'when the response code is 500' do
      let(:code) { 500 }
      let(:success) { false }

      it "raises an error with message 'API server error - please try again'" do
        expect { ai_provider.validate_response!(response) }
          .to raise_error(AI::Provider::ResponseError, 'API server error - please try again')
      end
    end

    context 'when the response code is 502' do
      let(:code) { 502 }
      let(:success) { false }

      it "raises an error with message 'API server unavailable - please try again later'" do
        expect { ai_provider.validate_response!(response) }
          .to raise_error(AI::Provider::ResponseError, 'API server unavailable - please try again later')
      end
    end

    context 'when the response code is 503' do
      let(:code) { 503 }
      let(:success) { false }

      it "raises an error with message 'API server unavailable - please try again later'" do
        expect { ai_provider.validate_response!(response) }
          .to raise_error(AI::Provider::ResponseError, 'API server unavailable - please try again later')
      end
    end

    context 'when the response code is unknown' do
      let(:code) { 999 }
      let(:success) { false }

      it "raises an error with message 'An unknown error occurred'" do
        expect { ai_provider.validate_response!(response) }
          .to raise_error(AI::Provider::ResponseError, 'An unknown error occurred')
      end
    end
  end
end
