# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative 'shared_examples/ping'

RSpec.describe AI::Provider::Anthropic, required_envs: %w[ANTHROPIC_API_KEY], use_vcr: true do
  subject(:ai_provider) { described_class.new(options: { json_response: true }) }

  let(:prompt_system) { '' }
  let(:prompt_user)   { 'This is a connection test. Return in unprettified JSON \'{ "connected": "true" }\' if you got the message. Respond in plain JSON format only and do not wrap it in code block markers.' }

  before do
    # Ping is tested manually, so we don't need to have this in place for setting the provider.
    setting = Setting.find_by(name: 'ai_provider_config')
    setting.update!(preferences: {})

    Setting.set('ai_provider', 'anthropic')
    Setting.set('ai_provider_config', {
                  token:    ENV['ANTHROPIC_API_KEY'],
                  provider: 'anthropic',
                })
  end

  include_examples 'provider/ping!'

  context 'when specifying a model' do
    context 'without a model' do
      it 'does exchange data with anthropic endpoint' do
        expect(ai_provider.ask(prompt_system:, prompt_user:)).to match({ 'connected' => 'true' })
      end
    end

    context 'with a valid model' do
      before do
        Setting.set('ai_provider_config', Setting.get('ai_provider_config').merge(model: 'claude-3-7-sonnet-latest'))
      end

      it 'does exchange data with anthropic endpoint' do
        expect(ai_provider.ask(prompt_system:, prompt_user:)).to match({ 'connected' => 'true' })
      end
    end

    context 'with an invalid model' do
      before do
        Setting.set('ai_provider_config', Setting.get('ai_provider_config').merge(model: 'nonexisting-model'))
      end

      it 'raises an error' do
        expect do
          ai_provider.ask(prompt_system:, prompt_user:)
        end.to raise_error(AI::Provider::ResponseError, 'Not found - resource not found')
      end
    end
  end

  context 'when API is faulty' do
    it 'raises an error' do
      allow(UserAgent).to receive(:post).and_return(
        UserAgent::Result.new(
          error:   '',
          success: false,
          code:    400,
        )
      )

      expect do
        ai_provider.ask(prompt_system:, prompt_user:)
      end.to raise_error(AI::Provider::ResponseError, 'Invalid request - please check your input')
    end
  end

  context 'when embeddings are requested' do
    it 'raises an error' do
      expect { ai_provider.embeddings(input: 'test') }.to raise_error(RuntimeError, 'not implemented yet due to missing API')
    end
  end

  context 'when metadata is extracted' do
    it 'stores metadata from response' do
      ai_provider.ask(prompt_system:, prompt_user:)

      metadata = ai_provider.metadata

      expect(metadata).to include(
        model:             be_present,
        prompt_tokens:     be_a(Numeric),
        completion_tokens: be_a(Numeric),
        total_tokens:      be_a(Numeric)
      )
    end
  end
end
