# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::ContentTranslationService do
  let(:setting_name) { 'content_translation_service' }

  shared_examples 'not raising an error' do |value:|
    it 'does not raise an error' do
      expect { Setting.set(setting_name, value) }.not_to raise_error
    end
  end

  shared_examples 'raising an error' do |value:|
    it 'raises an error' do
      expect { Setting.set(setting_name, value) }
        .to raise_error(ActiveRecord::RecordInvalid, %r{Translation service is missing})
    end
  end

  context 'with a false value' do
    it_behaves_like 'not raising an error', value: false

    context 'when the config names a service' do
      before { Setting.set('content_translation_service_config', { 'provider' => 'ai' }) }

      it_behaves_like 'not raising an error', value: false
    end
  end

  context 'with a true value' do
    it_behaves_like 'raising an error', value: true

    context 'when the config names a service' do
      before { Setting.set('content_translation_service_config', { 'provider' => 'ai' }) }

      it_behaves_like 'not raising an error', value: true
    end

    # The config validation refuses this; a backend removed later leaves the same state behind.
    context 'when the config names an unknown service' do
      before { Setting.set('content_translation_service_config', { 'provider' => 'nope' }, validate: false) }

      it_behaves_like 'raising an error', value: true
    end
  end
end
