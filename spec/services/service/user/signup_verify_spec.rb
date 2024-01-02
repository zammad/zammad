# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::SignupVerify do
  subject(:service) { described_class.new(token: token) }

  let(:user) { create(:user, verified: false) }

  shared_examples 'raising an error' do |klass, message|
    it 'raises an error' do
      expect { service.execute }.to raise_error(klass, message)
    end
  end

  shared_examples 'returning the verified user' do
    it 'returns the verified user' do
      expect(service.execute).to eq(user).and have_attributes(verified: true)
    end
  end

  describe '#execute' do
    context 'with disabled user signup' do
      let(:token) { User.signup_new_token(user)[:token].token } # NB: Don't ask!

      before do
        Setting.set('user_create_account', false)
      end

      it_behaves_like 'raising an error', Service::CheckFeatureEnabled::FeatureDisabledError, 'This feature is not enabled.'
    end

    context 'with a valid token' do
      let(:token) { User.signup_new_token(user)[:token].token } # NB: Don't ask!

      it_behaves_like 'returning the verified user'
    end

    context 'without a token parameter' do
      let(:token) { nil }

      it_behaves_like 'raising an error', Service::User::SignupVerify::InvalidTokenError, 'The provided token is invalid.'
    end

    context 'with an invalid token' do
      let(:token) { SecureRandom.urlsafe_base64(48) }

      it_behaves_like 'raising an error', Service::User::SignupVerify::InvalidTokenError, 'The provided token is invalid.'
    end

    context 'with current user' do
      context 'when same as the user being verified' do
        subject(:service) { described_class.new(token: token, current_user: user) }
        let(:token)       { User.signup_new_token(user)[:token].token } # NB: Don't ask!

        it_behaves_like 'returning the verified user'
      end

      context 'when different than the user being verified' do
        subject(:service) { described_class.new(token: token, current_user: agent) }

        let(:token)       { User.signup_new_token(user)[:token].token } # NB: Don't ask!
        let(:agent)       { create(:agent) }

        it_behaves_like 'raising an error', Service::User::SignupVerify::InvalidTokenError, 'The provided token is invalid.'
      end
    end
  end
end
