# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'User password reset verify endpoint', authenticated_as: false, type: :request do
  let(:user)   { create(:user) }
  let(:token)  { User.password_reset_new_token(user.login)[:token].token }

  let(:send_request) do
    post api_v1_users_password_reset_verify_path, params: params
  end

  shared_examples 'returning unprocessable entity' do |message:|
    it 'returns unprocessable entity' do
      send_request
      expect(response).to have_http_status(:unprocessable_entity).and have_attributes(body: include(message))
    end
  end

  shared_examples 'returning success' do |with_password_change: false|
    it 'returns success' do
      send_request
      expect(json_response).to include({ 'message' => 'ok', 'user_login' => user.login })
    end

    it 'does not change user password', if: !with_password_change do
      expect { send_request }.to not_change { user.reload.password }
    end

    it 'changes user password', if: with_password_change do
      expect { send_request }.to change { user.reload.password }
    end

    it 'sends an email notification to the user', if: with_password_change do
      message = nil

      allow(NotificationFactory::Mailer).to receive(:deliver) do |params|
        message = params[:body]
      end

      send_request

      expect(message).to include('This activity is not known to you? If not, contact your system administrator.')
    end
  end

  shared_examples 'returning failure' do |notice: nil|
    it 'returns failure with notice', if: !notice do
      send_request
      expect(json_response).to include({ 'message' => 'failed' })
    end

    it 'returns failure with notice', if: notice do
      send_request
      expect(json_response).to include({ 'message' => 'failed', 'notice' => [include(notice)] })
    end
  end

  context 'when user verifies with a token only' do
    let(:params) { { token: token } }

    context 'with disabled user signup' do
      before do
        Setting.set('user_lost_password', false)
      end

      it_behaves_like 'returning unprocessable entity', message: 'This feature is not enabled.'
    end

    context 'with a valid token' do
      it_behaves_like 'returning success'
    end

    context 'without a token parameter' do
      let(:params) { { foo: 'bar' } }

      it_behaves_like 'returning unprocessable entity', message: 'token param needed!'
    end

    context 'with an invalid token' do
      let(:token) { SecureRandom.urlsafe_base64(48) }

      it_behaves_like 'returning failure'
    end
  end

  context 'when user verifies with a token and a password' do
    let(:password) { 'cMeSMvAP2o' }
    let(:params)   { { token: token, password: password } }

    context 'with disabled user signup' do
      before do
        Setting.set('user_lost_password', false)
      end

      it_behaves_like 'returning unprocessable entity', message: 'This feature is not enabled.'
    end

    context 'with a valid password' do
      it_behaves_like 'returning success', with_password_change: true
    end

    context 'with an invalid password' do
      let(:password) { 'foobar9' }

      it_behaves_like 'returning failure', notice: 'Invalid password'
    end
  end
end
