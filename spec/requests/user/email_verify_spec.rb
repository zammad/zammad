# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'User email verify endpoint', authenticated_as: false, type: :request do
  context 'when user verifies via email' do
    let(:user)   { create(:user, verified: false) }
    let(:params) { { token: token } }

    shared_examples 'returning unprocessable entity' do |message|
      it 'returns unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity).and have_attributes(body: include(message))
      end
    end

    shared_examples 'returning success' do
      it 'returns success' do
        expect(response).to have_http_status(:ok)
      end
    end

    before do
      disable_user_create_account if defined?(disable_user_create_account)
      post api_v1_users_email_verify_path, params: params
    end

    context 'with disabled user signup' do
      let(:token) { User.signup_new_token(user)[:token].token } # NB: Don't ask!

      let(:disable_user_create_account) do
        Setting.set('user_create_account', false)
      end

      it_behaves_like 'returning unprocessable entity', 'This feature is not enabled.'
    end

    context 'with a valid token' do
      let(:token) { User.signup_new_token(user)[:token].token } # NB: Don't ask!

      it_behaves_like 'returning success'
    end

    context 'without a token parameter' do
      let(:params) { { foo: 'bar' } }

      it_behaves_like 'returning unprocessable entity', 'No token!'
    end

    context 'with an invalid token' do
      let(:token) { SecureRandom.urlsafe_base64(48) }

      it_behaves_like 'returning unprocessable entity', 'The provided token is invalid.'
    end
  end
end
