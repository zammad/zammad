# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative 'shared_examples/ping'
require_relative 'shared_examples/embed'

RSpec.describe AI::Provider::ZammadAI, integration: true, required_envs: %w[ZAMMAD_AI_TOKEN], use_vcr: true do
  subject(:ai_provider) { described_class.new(config: default_ai_provider_config, options: { json_response: true }) }

  let(:prompt_system) { '' }
  let(:prompt_user)   { 'This is a connection test. Return in unprettified JSON \'{ "connected": "true" }\' if you got the message. Respond in plain JSON format only and do not wrap it in code block markers.' }

  before do
    setup_ai_provider('zammad_ai', token: ENV['ZAMMAD_AI_TOKEN'])

    VCR.configure do |c|
      c.before_record do |interaction|
        uri = URI(interaction.request.uri)

        next if uri.path != '/api/v1/me'

        json = JSON.parse(interaction.response.body)

        if json.is_a?(Hash) && json['current_user'].present?
          json['current_user'] = { id: '<ID>', email: '<EMAIL>' }
        end

        interaction.response.body = json.to_json
      end
    end
  end

  include_examples 'provider/ping!'
  include_examples 'provider/embed', dimensions: 1024

  describe '#ask' do
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

    context 'when metadata is extracted' do
      it 'stores metadata from response', :aggregate_failures do
        ai_provider.ask(prompt_system:, prompt_user:)

        metadata = ai_provider.metadata

        expect(metadata).to include(
          model: be_present,
        )
      end
    end
  end
end
