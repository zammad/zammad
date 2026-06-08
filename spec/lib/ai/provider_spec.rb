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

  describe '.ping!' do
    it 'raises an error' do
      expect { described_class.ping!(nil) }.to raise_error(RuntimeError, 'not implemented')
    end
  end

  describe '.by_name' do
    it 'returns the correct class' do
      expect(described_class.by_name('open_ai')).to eq(AI::Provider::OpenAI)
    end
  end

  describe '.by_config' do
    it 'returns the correct class' do
      config = { provider: 'open_ai' }
      expect(described_class.by_config(config)).to eq(AI::Provider::OpenAI)
    end

    it 'returns nil when provider is blank' do
      config = {}
      expect(described_class.by_config(config)).to be_nil
    end
  end

  describe '.current' do
    before do
      Setting.set('ai_provider_config', config, validate: false)
      Setting.set('ai_provider', flag, validate: false)
    end

    context 'when config is provided' do
      let(:config) { { provider: 'open_ai' } }

      context 'when AI provider flag is true' do
        let(:flag) { true }

        it 'returns the correct class' do
          expect(described_class.current).to eq(AI::Provider::OpenAI)
        end
      end

      context 'when AI provider flag is false' do
        let(:flag) { false }

        it 'returns nil' do
          expect(described_class.current).to be_nil
        end
      end
    end

    context 'when config is blank' do
      let(:config) { {} }
      let(:flag)   { true }

      it 'returns nil' do
        expect(described_class.current).to be_nil
      end
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
