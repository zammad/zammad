# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative 'shared_examples/check_temperature_support'
require_relative 'shared_examples/embed'

RSpec.describe AI::Provider::Anthropic, integration: true, required_envs: %w[ANTHROPIC_API_KEY], use_vcr: true do
  subject(:ai_provider) { described_class.new(config: default_ai_provider_config, options: { json_response: true }) }

  let(:prompt_system) { '' }
  let(:prompt_user)   { 'This is a connection test. Return in unprettified JSON \'{ "connected": "true" }\' if you got the message. Respond in plain JSON format only and do not wrap it in code block markers.' }

  before do
    setup_ai_provider('anthropic', token: ENV['ANTHROPIC_API_KEY'])
  end

  include_examples 'provider/check_temperature_support'
  include_examples 'provider/embed_not_implemented'

  describe '#ask' do
    context 'when specifying a model' do
      context 'without a model' do
        it 'does exchange data with anthropic endpoint' do
          expect(ai_provider.ask(prompt_system:, prompt_user:)).to match({ 'connected' => 'true' })
        end
      end

      context 'with a valid model' do
        before do
          update_ai_provider_config(model: 'claude-haiku-4-5')
        end

        it 'does exchange data with anthropic endpoint' do
          expect(ai_provider.ask(prompt_system:, prompt_user:)).to match({ 'connected' => 'true' })
        end
      end

      context 'with an invalid model' do
        before do
          update_ai_provider_config(model: 'nonexisting-model')
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

    context 'when the response contains thinking blocks' do
      it 'returns the content of the text block' do
        allow(UserAgent).to receive(:post).and_return(
          UserAgent::Result.new(
            success: true,
            code:    200,
            data:    {
              'content' => [
                { 'type' => 'thinking', 'thinking' => '', 'signature' => 'Et...' },
                { 'type' => 'text', 'text' => '{ "connected": "true" }' },
              ],
              'usage'   => { 'input_tokens' => 1, 'output_tokens' => 1 },
            },
          )
        )

        expect(ai_provider.ask(prompt_system:, prompt_user:)).to match({ 'connected' => 'true' })
      end
    end

    context 'when the response reaches the output limit' do
      let(:stop_reason) { 'max_tokens' }

      before do
        allow(UserAgent).to receive(:post).and_return(
          UserAgent::Result.new(
            success: true,
            code:    200,
            data:    {
              'content'     => [{ 'type' => 'text', 'text' => '{ "connected": "tr' }],
              'stop_reason' => stop_reason,
              'usage'       => { 'input_tokens' => 1, 'output_tokens' => 64_000 },
            },
          )
        )
      end

      it 'raises an error naming the cut-off' do
        expect do
          ai_provider.ask(prompt_system:, prompt_user:)
        end.to raise_error(AI::Provider::OutputTruncatedError, 'The response was cut off because it reached the maximum output length.')
      end

      it 'sends the default output limit', :aggregate_failures do
        expect { ai_provider.ask(prompt_system:, prompt_user:) }.to raise_error(AI::Provider::OutputTruncatedError)
        expect(UserAgent).to have_received(:post).with(anything, include(max_tokens: 64_000), anything)
      end

      context 'when the context window fills up first' do
        let(:stop_reason) { 'model_context_window_exceeded' }

        it 'raises an error naming the cut-off' do
          expect do
            ai_provider.ask(prompt_system:, prompt_user:)
          end.to raise_error(AI::Provider::OutputTruncatedError, 'The response was cut off because the request and the response together exceeded the context window of the model.')
        end
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
end
