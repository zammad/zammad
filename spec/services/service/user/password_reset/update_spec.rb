# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::PasswordReset::Update do
  subject(:service) { described_class.new(token: token, password: password) }

  let(:user)     { create(:user) }
  let(:token)    { User.password_reset_new_token(user.login)[:token].token }
  let(:password) { 'Cw8OH8yT2b' }

  shared_examples 'raising an error' do |klass, message, message_placeholder: nil|
    it 'raises an error', :aggregate_failures do
      if message_placeholder
        expect { service.execute }.to raise_error do |error|
          expect(error).to be_a(klass)
            .and have_attributes(
              message:  include(message),
              metadata: [include(message), *message_placeholder], # rubocop:disable Layout/EmptyLinesAfterModuleInclusion
            )
        end
      else
        expect { service.execute }.to raise_error(klass, include(message))
      end
    end
  end

  shared_examples 'changing password of the user' do
    it 'returns user' do
      expect(service.execute).to eq(user)
    end

    it 'changes password of the user' do
      expect { service.execute }.to change { user.reload.password }
    end

    it 'sends an email notification' do
      message = nil

      allow(NotificationFactory::Mailer).to receive(:deliver) do |params|
        message = params[:body]
      end

      service.execute

      expect(message).to include 'If you did not initiate this change, please contact your system administrator.'
    end
  end

  describe '#execute' do
    context 'with disabled lost password feature' do
      before do
        Setting.set('user_lost_password', false)
      end

      it_behaves_like 'raising an error', Service::CheckFeatureEnabled::FeatureDisabledError, 'This feature is not enabled.'
    end

    context 'with a valid token and valid password' do
      it_behaves_like 'changing password of the user'
    end

    context 'with an invalid token' do
      let(:token) { SecureRandom.urlsafe_base64(48) }

      it_behaves_like 'raising an error', Service::User::PasswordReset::Update::InvalidTokenError, 'The provided token is invalid.'
    end

    context 'with an invalid password' do
      let(:password) { 'foobar9' }

      it_behaves_like 'raising an error', PasswordPolicy::Error, 'Invalid password'
    end

    context 'with a password which is too short' do
      let(:password) { 'fooBAR42' }

      it_behaves_like 'raising an error', PasswordPolicy::Error, 'Invalid password, it must be at least %s characters long!', message_placeholder: [10]
    end
  end
end
