# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Exercised through AI::Provider::Anthropic, one of the providers that include the concern and
# whose DEFAULT_OPTIONS carry a non-trivial models_without_temperature list.
RSpec.describe AI::Provider::Concerns::HasModelsWithoutTemperatureFallback do
  subject(:provider) { AI::Provider::Anthropic.new(config:, options: { model: }) }

  let(:config) { {} }
  let(:model)  { 'claude-sonnet-4-6' }

  describe '#model_supports_temperature?' do
    context 'when the dynamically detected flag is stored as false' do
      let(:config) { { model_temperature_support: false } }

      it 'is honored even for a model absent from the hardcoded list' do
        expect(provider.send(:model_supports_temperature?)).to be(false)
      end
    end

    context 'when the dynamically detected flag is stored as true' do
      let(:config) { { model_temperature_support: true } }
      let(:model)  { 'claude-opus-5' } # present in the hardcoded no-temperature list

      it 'is honored over the hardcoded list' do
        expect(provider.send(:model_supports_temperature?)).to be(true)
      end
    end

    context 'when the flag is not stored' do
      context 'with a model in the hardcoded no-temperature list' do
        let(:model) { 'claude-opus-5' }

        it 'falls back to false' do
          expect(provider.send(:model_supports_temperature?)).to be(false)
        end
      end

      context 'with a model absent from the hardcoded list' do
        it 'falls back to true' do
          expect(provider.send(:model_supports_temperature?)).to be(true)
        end
      end
    end
  end
end
