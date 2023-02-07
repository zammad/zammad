# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'User endpoint', authenticated_as: false, type: :request do
  describe 'admin_auth' do
    context 'with enabled password login' do
      before { Setting.set('user_show_password_login', true) }

      it 'is not processable' do
        post api_v1_users_admin_password_auth_path, params: { username: 'john.doe' }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with disabled password login' do
      before { Setting.set('user_show_password_login', false) }

      context 'when no third-party authenticator is enabled' do
        it 'is not processable' do
          post api_v1_users_admin_password_auth_path, params: { username: 'john.doe' }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'when any third-party authenticator is enabled' do
        before { Setting.set('auth_saml', true) }

        it 'is processable' do
          post api_v1_users_admin_password_auth_path, params: { username: 'john.doe' }
          expect(response).to have_http_status(:ok)
        end

        it 'sends a valid login link' do
          user = create(:admin)

          message = nil

          allow(NotificationFactory::Mailer).to receive(:send) do |params|
            message = params[:body]
          end

          post api_v1_users_admin_password_auth_path, params: { username: user.email }

          expect(message).to include "http://zammad.example.com/#login/admin/#{Token.last.name}"
        end
      end
    end

    # For the throttling, see config/initializers/rack_attack.rb.
    context 'when user requests admin auth more than throttle allows', :rack_attack do

      let(:static_username) { create(:admin).login }
      let(:static_ipv4)     { Faker::Internet.ip_v4_address }

      it 'blocks due to username throttling (multiple IPs)' do
        4.times do
          post api_v1_users_admin_password_auth_path, params: { username: static_username }, headers: { 'X-Forwarded-For': Faker::Internet.ip_v4_address }
        end

        expect(response).to have_http_status(:too_many_requests)
      end

      it 'blocks due to source IP address throttling (multiple usernames)' do
        4.times do
          # Ensure throttling even on modified path.
          post "#{api_v1_users_admin_password_auth_path}.json", params: { username: create(:admin).login }, headers: { 'X-Forwarded-For': static_ipv4 }
        end

        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end

  describe 'admin_password_auth_verify' do
    context 'with enabled password login' do
      before { Setting.set('user_show_password_login', true) }

      it 'is not processable' do
        post api_v1_users_admin_password_auth_verify_path, params: { token: 4711, }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with disabled password login' do
      before { Setting.set('user_show_password_login', false) }

      context 'when no third-party authenticator is enabled' do
        it 'is not processable' do
          post api_v1_users_admin_password_auth_verify_path, params: { token: 4711 }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'when any third-party authenticator is enabled' do
        before { Setting.set('auth_saml', true) }

        it 'is processable' do
          post api_v1_users_admin_password_auth_verify_path, params: { token: 4711 }
          expect(response).to have_http_status(:ok)
        end
      end
    end

    describe 'returns valid content' do
      before do
        Setting.set('user_show_password_login', false)
        Setting.set('auth_saml', true)
      end

      it "'failed' if invalid token" do
        post api_v1_users_admin_password_auth_verify_path, params: { token: 4711 }
        expect(JSON.parse(response.body)).to include('message' => 'failed')
      end

      it "'ok' and user login if valid token" do
        user  = create(:admin)
        token = Token.create(action: 'AdminAuth', user_id: user.id, persistent: false)

        post api_v1_users_admin_password_auth_verify_path, params: { token: token.name }
        expect(JSON.parse(response.body)).to include('message' => 'ok', 'user_login' => user.login)
      end
    end
  end
end
