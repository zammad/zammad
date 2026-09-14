# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::PasswordReset::Send, performs_jobs: true do
  subject(:service_result) { described_class.execute(username:) }

  let(:user)     { create(:user) }
  let(:username) { user.login }

  shared_examples 'raising an error' do |klass, message|
    it 'raises an error' do
      expect { service_result }.to raise_error(klass, message)
    end
  end

  shared_examples 'sending the token' do
    it 'returns success' do
      expect(service_result).to be(true)
    end

    it 'generates a new token' do
      expect { service_result }.to change(Token, :count)
    end

    it 'defers the delivery to a background job' do
      expect { service_result }.to have_enqueued_job(NotificationMailerJob)
    end

    it 'does not deliver the email within the request' do
      allow(NotificationFactory::Mailer).to receive(:deliver)

      service_result

      expect(NotificationFactory::Mailer).not_to have_received(:deliver)
    end

    it 'keeps the token out of the job arguments' do
      service_result

      expect(enqueued_jobs.to_s).not_to include(Token.last.token)
    end

    it 'sends a valid password reset link' do
      message = nil

      allow(NotificationFactory::Mailer).to receive(:deliver) do |params|
        message = params[:body]
      end

      perform_enqueued_jobs { service_result }

      expect(message).to include "<a href=\"http://zammad.example.com/desktop/reset-password/verify/#{Token.last.token}\">"
    end
  end

  shared_examples 'returning success' do
    it 'returns success' do
      expect(service_result).to be(true)
    end

    it 'does not generate a new token' do
      expect { service_result }.to not_change(Token, :count)
    end

    it 'does not enqueue a delivery' do
      expect { service_result }.not_to have_enqueued_job(NotificationMailerJob)
    end
  end

  shared_examples 'holding the response deadline' do
    it 'holds the response until the deadline' do
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      service_result

      elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).seconds

      expect(elapsed).to be >= Service::Concerns::HoldsResponseDeadline::RESPONSE_DEADLINE
    end
  end

  shared_examples 'raising error if import mode is on' do
    context 'when in import mode' do
      before { Setting.set('import_mode', true) }

      it 'raises an error' do
        expect { service_result }
          .to raise_error(Exceptions::UnprocessableContent, %r{import_mode})
      end

      it 'does not generate a new token' do
        expect { service_result rescue nil } # rubocop:disable Style/RescueModifier
          .to not_change(Token, :count)
      end

      it 'adds message to the log' do
        allow(Rails.logger).to receive(:error)

        service_result rescue nil # rubocop:disable Style/RescueModifier

        expect(Rails.logger)
          .to have_received(:error)
          .with("Could not send password reset email to user #{username} because import_mode setting is on.")
      end
    end
  end

  # The tolerance covers scheduler jitter only; both calls are held to the same deadline.
  def expect_indistinguishable(first, second)
    durations = [first, second].map do |username|
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      described_class.execute(username:)

      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).seconds
    end

    expect((durations.first - durations.last).abs)
      .to be < (Service::Concerns::HoldsResponseDeadline::RESPONSE_DEADLINE / 10)
  end

  describe '#execute' do
    context 'with disabled lost password feature' do
      before do
        Setting.set('user_lost_password', false)
      end

      it_behaves_like 'raising an error', Service::CheckFeatureEnabled::FeatureDisabledError, 'This feature is not enabled.'
      it_behaves_like 'raising error if import mode is on'
    end

    context 'with a valid user login' do
      it_behaves_like 'sending the token'
      it_behaves_like 'holding the response deadline'
      it_behaves_like 'raising error if import mode is on'
    end

    context 'with a valid user email' do
      let(:username) { user.email }

      it_behaves_like 'sending the token'
      it_behaves_like 'raising error if import mode is on'
    end

    it 'takes the same time for a known and an unknown user name' do
      expect_indistinguishable(user.login, 'foobar')
    end

    context 'with an invalid user login' do
      let(:username) { 'foobar' }

      it_behaves_like 'returning success'
      it_behaves_like 'holding the response deadline'
      it_behaves_like 'raising error if import mode is on'
    end
  end
end
