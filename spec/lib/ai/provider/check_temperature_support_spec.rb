# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# For the providers implementing it, check_temperature_support! is the only validation a config
# gets when a connection is saved (see the config validation contract in provider_spec.rb), so
# its error mapping is covered here without network access - the per-provider specs are tagged
# `integration` and need real credentials, hence they do not run in a regular pipeline.
RSpec.describe AI::Provider, '.check_temperature_support!' do
  def stub_response(response)
    allow(UserAgent).to receive(:post).and_return(response)
  end

  def failed_response(code, body = nil)
    UserAgent::Result.new(success: false, code:, body:)
  end

  shared_examples 'a config validating temperature check' do
    it 'detects a model that accepts the temperature' do
      stub_response(UserAgent::Result.new(success: true, code: 200, data: {}))

      expect(provider.check_temperature_support!(config)).to be(true)
    end

    it 'detects a model that rejects the temperature' do
      stub_response(failed_response(400, {
        error: {
          type:    'invalid_request_error',
          param:   'temperature',
          code:    'unsupported_value',
          message: 'Unsupported value: temperature',
        },
      }.to_json))

      expect(provider.check_temperature_support!(config)).to be(false)
    end

    it 'maps a rejected token to the provider message' do
      stub_response(failed_response(401, { error: { message: 'Incorrect API key provided' } }.to_json))

      expect { provider.check_temperature_support!(config) }
        .to raise_error(AI::Provider::CheckTemperatureSupportError, 'Invalid API key - please check your configuration')
    end

    # UserAgent answers transport failures with code 0 and no body at all.
    it 'maps an unreachable endpoint to the provider message' do
      stub_response(UserAgent::Result.new(success: false, code: 0, error: '#<Errno::ECONNREFUSED>'))

      expect { provider.check_temperature_support!(config) }
        .to raise_error(AI::Provider::CheckTemperatureSupportError, 'An unknown error occurred')
    end

    it 'maps a non-JSON error body to the provider message' do
      stub_response(failed_response(502, '<html><head><title>502 Bad Gateway</title></head></html>'))

      expect { provider.check_temperature_support!(config) }
        .to raise_error(AI::Provider::CheckTemperatureSupportError, 'API server unavailable - please try again later')
    end
  end

  context 'with OpenAI' do
    let(:provider) { AI::Provider::OpenAI }
    let(:config)   { { token: 'sk-123' } }

    include_examples 'a config validating temperature check'
  end

  context 'with Azure' do
    let(:provider) { AI::Provider::Azure }
    let(:config)   { { token: 'sk-123', url_completions: 'https://example.com/openai/deployments/test/chat/completions' } }

    include_examples 'a config validating temperature check'
  end

  context 'with a custom OpenAI compatible provider' do
    let(:provider) { AI::Provider::CustomOpenAI }
    let(:config)   { { token: 'sk-123', url: 'https://example.com', model: 'gpt-4o' } }

    include_examples 'a config validating temperature check'
  end
end
