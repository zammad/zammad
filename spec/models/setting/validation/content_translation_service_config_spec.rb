# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::ContentTranslationServiceConfig do
  let(:setting_name) { 'content_translation_service_config' }

  shared_examples 'not raising an error' do |value:|
    it 'does not raise an error' do
      expect { Setting.set(setting_name, value) }.not_to raise_error
    end
  end

  shared_examples 'raising an error' do |value:, message:|
    it 'raises an error' do
      expect { Setting.set(setting_name, value) }
        .to raise_error(ActiveRecord::RecordInvalid, %r{#{Regexp.escape(message)}})
    end
  end

  context 'with a blank config' do
    it_behaves_like 'not raising an error', value: {}
  end

  context 'with a config that names no service' do
    it_behaves_like 'raising an error', value: { 'token' => 'secret' }, message: 'Translation service is missing'
  end

  context 'with an unknown service' do
    it_behaves_like 'raising an error', value: { 'provider' => 'nope' }, message: 'Translation service is not supported'
  end

  context 'with the AI service' do
    it_behaves_like 'not raising an error', value: { 'provider' => 'ai' }
  end

  context 'with a service that needs credentials' do
    let(:backend) do
      Class.new(Service::ContentTranslation::Backend::Base) do
        def self.backend_name = 'keyed'

        def self.required_config_keys = %w[token]
      end
    end

    before { stub_const('Service::ContentTranslation::Backend::Keyed', backend) }

    it_behaves_like 'raising an error', value: { 'provider' => 'keyed' }, message: 'Translation service configuration is incomplete'
    it_behaves_like 'not raising an error', value: { 'provider' => 'keyed', 'token' => 'secret' }
  end
end
