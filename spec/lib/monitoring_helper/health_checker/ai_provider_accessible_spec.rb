# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MonitoringHelper::HealthChecker::AIProviderAccessible do
  let(:instance) { described_class.new }

  describe '#check_health' do
    context 'when the AI provider is disabled' do
      before do
        Setting.set('ai_provider', false)
      end

      it 'reports no issue' do
        expect(instance.check_health.issues).to be_blank
      end
    end

    context 'when the AI provider is enabled but no connection exists' do
      before do
        Setting.set('ai_provider', true, validate: false)
      end

      it 'reports a configuration issue' do
        expect(instance.check_health.issues.first).to match('The AI provider is not configured.')
      end
    end

    context 'when connections exist' do
      before do
        Setting.set('ai_provider', true, validate: false)
      end

      it 'reports no issue for a never-used connection' do
        create(:ai_provider_connection, name: 'default', default_chat: true)

        expect(instance.check_health.issues).to be_blank
      end

      it 'reports no issue for a connection whose last call succeeded' do
        create(:ai_provider_connection, name: 'default', default_chat: true).record_status_ok!

        expect(instance.check_health.issues).to be_blank
      end

      it 'reports an issue for a connection whose last call failed', :aggregate_failures do
        create(:ai_provider_connection, name: 'default', default_chat: true).record_status_error!('quota exceeded')

        issue = instance.check_health.issues.first
        expect(issue).to match("The AI provider connection 'default' is not accessible.")
        expect(issue).to include('quota exceeded')
      end

      it 'reports one issue per errored connection' do
        create(:ai_provider_connection, name: 'default', default_chat: true).record_status_error!('boom')
        create(:ai_provider_connection, name: 'embedding').record_status_error!('boom')

        expect(instance.check_health.issues.size).to eq(2)
      end

      it 'ignores healthy connections while reporting the errored one' do
        create(:ai_provider_connection, name: 'default', default_chat: true).record_status_ok!
        create(:ai_provider_connection, name: 'embedding').record_status_error!('boom')

        expect(instance.check_health.issues.size).to eq(1)
      end
    end
  end
end
