# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::AIProviderConfig, required_envs: %w[OPEN_AI_TOKEN], use_vcr: true do

  let(:setting_name) { 'ai_provider_config' }

  context 'with blank settings' do
    it 'does not raise error' do
      expect { Setting.set(setting_name, {}) }.not_to raise_error
    end
  end

  context 'with missing provider' do
    it 'does not raise error' do
      expect { Setting.set(setting_name, { 'token' => nil }) }.not_to raise_error
    end
  end

  context 'when provider is ollama' do
    context 'with missing url' do
      before do
        Setting.set('ai_provider', 'ollama')
      end

      it 'raises error' do
        expect { Setting.set(setting_name, { 'url' => nil }) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'with valid url' do
      before do
        Setting.set('ai_provider', 'ollama')
      end

      it 'does not raise error' do
        expect { Setting.set(setting_name, { 'url' => 'https://ollama.ai' }) }.not_to raise_error
      end
    end
  end

  context 'when provider is not ollama' do
    before do
      Setting.set('ai_provider', 'open_ai')
    end

    context 'with missing token' do
      it 'raises error' do
        expect { Setting.set(setting_name, { 'token' => nil }) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'with valid token' do
      it 'does not raise error' do
        expect { Setting.set(setting_name, { 'token' => ENV['OPEN_AI_TOKEN'] }) }.not_to raise_error
      end
    end

    context 'with invalid token' do
      it 'raises error' do
        expect { Setting.set(setting_name, { 'token' => 'invalid_token' }) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
