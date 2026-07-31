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

    context 'when the embedding model has a known input limit' do
      subject(:ai_provider) do
        AI::Provider::OpenAI.new(
          config: { provider: 'open_ai', token: '123' },
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
  end

  describe '#initialize' do
    it 'ignores blank config model values so provider defaults apply', :aggregate_failures do
      provider = AI::Provider::OpenAI.new(config: { token: 'sk-test', model: '', embedding_model: '' })

      expect(provider.options[:model]).to eq(AI::Provider::OpenAI::DEFAULT_OPTIONS[:model])
      expect(provider.options[:embedding_model]).to eq(AI::Provider::OpenAI::DEFAULT_OPTIONS[:embedding_model])
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
