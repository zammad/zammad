# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::VectorDB do
  let(:setting_name) { 'vectordb_enabled' }

  shared_examples 'not raising an error' do |value:|
    it 'does not raise an error' do
      expect { Setting.set(setting_name, value) }.not_to raise_error
    end
  end

  shared_examples 'raising an error' do |value:, message:|
    it "raises an error mentioning #{message}" do
      expect { Setting.set(setting_name, value) }
        .to raise_error(ActiveRecord::RecordInvalid, "Validation failed: #{message}")
    end
  end

  context 'with a false value' do
    it_behaves_like 'not raising an error', value: false

    context 'when no provider connection is present' do
      it_behaves_like 'not raising an error', value: false
    end
  end

  context 'with a true value' do
    context 'when no provider connection is present' do
      it_behaves_like 'raising an error', value: true, message: 'No AI provider with a valid embedding model is configured.'
    end

    context 'when a provider connection is present, but the AI provider configuration is disabled' do
      before { create(:ai_provider_connection) }

      it_behaves_like 'raising an error', value: true, message: 'No AI provider with a valid embedding model is configured.'
    end

    context 'when the configured provider cannot generate embeddings' do
      before do
        create(:ai_provider_connection, provider: 'anthropic')
        Setting.set('ai_provider', true)
      end

      it_behaves_like 'raising an error', value: true, message: 'No AI provider with a valid embedding model is configured.'
    end

    context 'when an embedding capable provider is configured' do
      before { setup_ai_provider }

      it_behaves_like 'not raising an error', value: true
    end
  end
end
