# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative 'shared_examples/ping'

RSpec.describe AI::Provider::ZammadAI, integration: true, required_envs: %w[ZAMMAD_AI_TOKEN], use_vcr: true do
  subject(:ai_provider) { described_class.new(options: { json_response: true }) }

  let(:prompt_system) { '' }
  let(:prompt_user)   { 'This is a connection test. Return in unprettified JSON \'{ "connected": "true" }\' if you got the message. Respond in plain JSON format only and do not wrap it in code block markers.' }

  before do
    # Ping is tested manually, so we don't need to have this in place for setting the provider.
    setting = Setting.find_by(name: 'ai_provider_config')
    setting.update!(preferences: {})

    setup_ai_provider('zammad_ai', token: ENV['ZAMMAD_AI_TOKEN'])
  end

  include_examples 'provider/ping!'

  it 'does exchange data with ZammadAI endpoint' do
    expect(ai_provider.ask(prompt_system:, prompt_user:)).to match({ 'connected' => 'true' })
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
      expect { ai_provider.embeddings(input: 'test') }.to raise_error(NotImplementedError, 'not implemented yet due to missing API')
    end
  end

  context 'when metadata is extracted' do
    it 'stores metadata from response', :aggregate_failures do
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
