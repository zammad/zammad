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

  # A bad request passing for a temperature rejection would hide a broken config.
  shared_examples 'a temperature check not fooled by other errors' do
    it 'detects a rejected temperature with only a type and a message' do
      stub_response(failed_response(400, {
        error: { type: 'invalid_request_error', message: 'invalid temperature: only 1 is allowed for this model' },
      }.to_json))

      expect(provider.check_temperature_support!(config)).to be(false)
    end

    it 'raises for a bad request that does not mention the temperature' do
      stub_response(failed_response(400, {
        error: { type: 'invalid_request_error', message: 'invalid model: k9 does not exist' },
      }.to_json))

      expect { provider.check_temperature_support!(config) }
        .to raise_error(AI::Provider::CheckTemperatureSupportError)
    end

    it 'raises when another parameter is named as the problem' do
      stub_response(failed_response(400, {
        error: { type: 'invalid_request_error', param: 'model', message: 'model is invalid, temperature is fine' },
      }.to_json))

      expect { provider.check_temperature_support!(config) }
        .to raise_error(AI::Provider::CheckTemperatureSupportError)
    end

    it 'raises when an error code other than the temperature one is given' do
      stub_response(failed_response(400, {
        error: { type: 'invalid_request_error', code: 'model_not_found', message: 'model not found, temperature is fine' },
      }.to_json))

      expect { provider.check_temperature_support!(config) }
        .to raise_error(AI::Provider::CheckTemperatureSupportError)
    end

    it 'raises for another error type that happens to mention the temperature' do
      stub_response(failed_response(500, {
        error: { type: 'server_error', message: 'temperature sensor offline' },
      }.to_json))

      expect { provider.check_temperature_support!(config) }
        .to raise_error(AI::Provider::CheckTemperatureSupportError)
    end

    it 'raises when the error is not an object' do
      stub_response(failed_response(400, { error: 'temperature' }.to_json))

      expect { provider.check_temperature_support!(config) }
        .to raise_error(AI::Provider::CheckTemperatureSupportError)
    end

    it 'maps a message with invalid UTF-8 to the provider message' do
      stub_response(failed_response(400, %({"error":{"type":"invalid_request_error","message":"\xFF temperature"}}).b))

      expect { provider.check_temperature_support!(config) }
        .to raise_error(AI::Provider::CheckTemperatureSupportError, 'Invalid request - please check your input')
    end
  end

  shared_examples 'a temperature check skipping known models' do
    it 'leaves the temperature out for a model known to reject it', :aggregate_failures do
      stub_response(UserAgent::Result.new(success: true, code: 200, data: {}))

      expect(provider.check_temperature_support!(config.merge(model: known_model))).to be(false)
      expect(UserAgent).to have_received(:post).with(anything, hash_excluding(:temperature), anything)
    end
  end

  context 'with OpenAI' do
    let(:provider)    { AI::Provider::OpenAI }
    let(:config)      { { token: 'sk-123' } }
    let(:known_model) { 'gpt-6' }

    include_examples 'a config validating temperature check'
    include_examples 'a temperature check skipping known models'
    include_examples 'a temperature check not fooled by other errors'
  end

  context 'with Azure' do
    let(:provider) { AI::Provider::Azure }
    let(:config)   { { token: 'sk-123', url_completions: 'https://example.com/openai/deployments/test/chat/completions' } }

    include_examples 'a config validating temperature check'
    include_examples 'a temperature check not fooled by other errors'
  end

  context 'with a custom OpenAI compatible provider' do
    let(:provider)    { AI::Provider::CustomOpenAI }
    let(:config)      { { token: 'sk-123', url: 'https://example.com', model: 'gpt-4o' } }
    let(:known_model) { 'o3' }

    include_examples 'a config validating temperature check'
    include_examples 'a temperature check skipping known models'
    include_examples 'a temperature check not fooled by other errors'

    it 'leaves the temperature out of chat requests once the probe detected the rejection', :aggregate_failures do
      stub_response(failed_response(400, {
        error: { type: 'invalid_request_error', message: 'invalid temperature: only 1 is allowed for this model' },
      }.to_json))

      detected = provider.check_temperature_support!(config.merge(model: 'k3.1-pro'))

      stub_response(UserAgent::Result.new(success: true, code: 200, data: { 'choices' => [{ 'message' => { 'content' => 'Hi' } }] }))
      chat_config = config.merge(model: 'k3.1-pro', model_temperature_support: detected)

      expect(provider.new(config: chat_config).chat(prompt_system: 'sys', prompt_user: 'usr', prompt_image: nil)).to eq('Hi')
      expect(UserAgent).to have_received(:post).with(anything, hash_excluding(:temperature), anything)
    end
  end

  context 'with Anthropic' do
    let(:provider)    { AI::Provider::Anthropic }
    let(:config)      { { token: 'sk-123' } }
    let(:known_model) { 'claude-opus-5' }

    include_examples 'a config validating temperature check'
    include_examples 'a temperature check skipping known models'

    it 'detects a rejected temperature without the param/code fields' do
      stub_response(failed_response(400, {
        type:  'error',
        error: {
          type:    'invalid_request_error',
          message: 'temperature: Input should be less than or equal to 1',
        },
      }.to_json))

      expect(provider.check_temperature_support!(config)).to be(false)
    end
  end
end
