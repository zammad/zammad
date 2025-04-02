# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::PasswordReset::Verify do
  subject(:service) { described_class.new(token: token) }

  let(:user)  { create(:user) }
  let(:token) { User.password_reset_new_token(user.login)[:token].token }

  shared_examples 'raising an error' do |klass, message|
    it 'raises an error' do
      expect { service.execute }.to raise_error(klass, message)
    end
  end

  shared_examples 'returning user' do
    it 'returns user' do
      expect(service.execute).to eq(user)
    end
  end

  describe '#execute' do
    context 'with disabled lost password feature' do
      before do
        Setting.set('user_lost_password', false)
      end

      it_behaves_like 'raising an error', Service::CheckFeatureEnabled::FeatureDisabledError, 'This feature is not enabled.'
    end

    context 'with a valid token' do
      it_behaves_like 'returning user'
    end

    context 'with an invalid token' do
      let(:token) { SecureRandom.urlsafe_base64(48) }

      it_behaves_like 'raising an error', Service::User::PasswordReset::Verify::InvalidTokenError, 'The provided token is invalid.'
    end
  end
end
