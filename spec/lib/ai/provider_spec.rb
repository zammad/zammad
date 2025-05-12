# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
    it 'raises an error' do
      expect do
        ai_provider.ask(
          prompt_system: Faker::Lorem.sentence,
          prompt_user:   Faker::Lorem.sentence
        )
      end.to raise_error(RuntimeError, 'not implemented')
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
      expect { described_class.ping! }.to raise_error(RuntimeError, 'not implemented')
    end
  end

  describe '.by_name' do
    it 'returns the correct class' do
      expect(described_class.by_name('open_ai')).to eq(AI::Provider::OpenAI)
    end
  end

  describe '.list' do
    it 'returns a list of providers' do
      expect(described_class.list).to eq([AI::Provider::Ollama, AI::Provider::OpenAI, AI::Provider::ZammadAI])
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
