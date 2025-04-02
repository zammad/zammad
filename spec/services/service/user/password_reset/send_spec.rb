# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::PasswordReset::Send do
  subject(:service) { described_class.new(username:) }

  let(:user)     { create(:user) }
  let(:username) { user.login }

  shared_examples 'raising an error' do |klass, message|
    it 'raises an error' do
      expect { service.execute }.to raise_error(klass, message)
    end
  end

  shared_examples 'sending the token' do
    it 'returns success' do
      expect(service.execute).to be(true)
    end

    it 'generates a new token' do
      expect { service.execute }.to change(Token, :count)
    end

    it 'sends a valid password reset link' do
      message = nil

      allow(NotificationFactory::Mailer).to receive(:deliver) do |params|
        message = params[:body]
      end

      service.execute

      expect(message).to include "<a href=\"http://zammad.example.com/desktop/reset-password/verify/#{Token.last.token}\">"
    end
  end

  shared_examples 'returning success' do
    it 'returns success' do
      expect(service.execute).to be(true)
    end

    it 'does not generate a new token' do
      expect { service.execute }.to not_change(Token, :count)
    end
  end

  shared_examples 'raising error if import mode is on' do
    context 'when in import mode' do
      before { Setting.set('import_mode', true) }

      it 'raises an error' do
        expect { service.execute }
          .to raise_error(Exceptions::UnprocessableEntity, %r{import_mode})
      end

      it 'does not generate a new token' do
        expect { service.execute rescue nil } # rubocop:disable Style/RescueModifier
          .to not_change(Token, :count)
      end

      it 'adds message to the log' do
        allow(Rails.logger).to receive(:error)

        service.execute rescue nil # rubocop:disable Style/RescueModifier

        expect(Rails.logger)
          .to have_received(:error)
          .with("Could not send password reset email to user #{username} because import_mode setting is on.")
      end
    end
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
      it_behaves_like 'raising error if import mode is on'
    end

    context 'with a valid user email' do
      let(:username) { user.email }

      it_behaves_like 'sending the token'
      it_behaves_like 'raising error if import mode is on'
    end

    context 'with an invalid user login' do
      let(:username) { 'foobar' }

      it_behaves_like 'returning success'
      it_behaves_like 'raising error if import mode is on'
    end
  end
end
