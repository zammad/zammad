# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::BetaUi::SendFeedback do
  let(:type)       { 'manual_feedback' }
  let(:comment)    { Faker::Lorem.unique.paragraph }
  let(:time_spent) { Faker::Number.unique.between(from: 300, to: 1200) }
  let(:rating)     { Faker::Number.unique.between(from: 1, to: 5) }

  describe '#execute' do
    subject(:service_result) { described_class.execute(type:, comment:, time_spent:, rating:) }

    context 'when beta ui is enabled' do
      let(:service_instance)    { described_class.new(type:, comment:, time_spent:, rating:) }
      let(:form_config_route)   { "#{service_instance.api_host}/api/v1/form_config" }
      let(:form_submit_route)   { "#{service_instance.api_host}/api/v1/form_submit" }
      let(:form_config_success) { true }
      let(:form_submit_success) { true }

      let(:form_config_data) do
        {
          'enabled'  => true,
          'endpoint' => form_submit_route,
          'token'    => SecureRandom.urlsafe_base64(216),
        }
      end

      let(:form_submit_data) do
        {
          'ticket' => {
            'id'     => 2,
            'number' => '99002',
          },
        }
      end

      before do
        Setting.set('ui_desktop_beta_switch', true)

        fingerprint = SecureRandom.uuid

        allow_any_instance_of(described_class).to receive(:fingerprint).and_return(fingerprint)

        allow(UserAgent).to receive(:post).with(form_config_route, { fingerprint: }, any_args).and_return(
          UserAgent::Result.new(
            success: form_config_success,
            data:    form_config_success ? form_config_data : nil,
          )
        )

        form_submit_args = {
          fingerprint:,
          token:         form_config_data['token'],
          fqdn:          Setting.get('fqdn'),
          feedback_type: type,
          feedback_text: comment,
          time_spent:,
          rating:,
          title:         Setting.get('fqdn'),
          body:          comment,
          name:          described_class::BETA_UI_FEEDBACK_NAME,
          email:         described_class::BETA_UI_FEEDBACK_EMAIL_ADDRESS,
        }

        allow(UserAgent).to receive(:post).with(form_submit_route, form_submit_args, any_args).and_return(
          UserAgent::Result.new(
            success: form_submit_success,
            data:    form_submit_success ? form_submit_data : nil,
          )
        )
      end

      it 'returns the success' do
        expect(service_result).to be(true)
      end

      context 'when form config fetch fails' do
        let(:form_config_success) { false }

        it 'raises a communication error' do
          expect { service_result }.to raise_error(described_class::CommunicationError)
        end
      end

      context 'when form config does not return a token' do
        let(:form_config_data) { {} }

        it 'raises an invalid token error' do
          expect { service_result }.to raise_error(described_class::InvalidTokenError)
        end
      end

      context 'when form submit fails' do
        let(:form_submit_success) { false }

        it 'raises a communication error' do
          expect { service_result }.to raise_error(described_class::CommunicationError)
        end
      end

      context 'when form submit does not return a ticket number' do
        let(:form_submit_data) { {} }

        it 'raises an invalid token error' do
          expect { service_result }.to raise_error(described_class::InvalidFeedbackError)
        end
      end
    end

    context 'when beta ui is disabled' do
      it 'raises an error' do
        expect { service_result }.to raise_error(Service::CheckFeatureEnabled::FeatureDisabledError, 'This feature is not enabled.')
      end
    end
  end
end
