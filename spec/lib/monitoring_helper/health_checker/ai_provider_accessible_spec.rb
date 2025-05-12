# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MonitoringHelper::HealthChecker::AIProviderAccessible, integration: true do
  let(:instance) { described_class.new }

  describe '#check_health' do
    context 'when AI integration is not configured' do
      it 'reports no issue' do
        expect(instance.check_health.issues).to be_blank
      end
    end

    context 'when AI integration has an empty configuration' do
      before do
        Setting.set('ai_provider', 'open_ai')
        Setting.set('ai_provider_config', {})
      end

      it 'reports no issue' do
        expect(instance.check_health.issues).to be_blank
      end
    end

    context 'when AI integration is configured' do
      before do
        # Reset preferences to avoid validation errors.
        ai_config = Setting.find_by(name: 'ai_provider_config')
        ai_config.update!(preferences: {})
        Setting.set('ai_provider', 'open_ai')
        Setting.set('ai_provider_config', { 'token' => '123' })
      end

      context 'when AI provider is accessible' do
        it 'reports no issue' do
          allow(AI::Provider::OpenAI).to receive(:ping!).and_return(nil)
          expect(instance.check_health.issues).to be_blank
        end
      end

      context 'when AI provider is not accessible' do
        it 'reports an issue' do
          allow(AI::Provider::OpenAI).to receive(:ping!).and_raise(AI::Provider::ResponseError)
          expect(instance.check_health.issues.first).to match('The AI Provider is not accessible.')
        end
      end
    end
  end
end
