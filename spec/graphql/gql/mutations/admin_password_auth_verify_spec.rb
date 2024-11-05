# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::AdminPasswordAuthVerify, type: :graphql do
  context 'when verifying' do
    let(:query) do
      <<~QUERY
        mutation adminPasswordAuthVerify($token: String!) {
          adminPasswordAuthVerify(token: $token) {
            login
          }
        }
      QUERY
    end

    let(:variables) { { token: token } }

    before do
      setup if defined?(setup)

      gql.execute(query, variables: variables)
    end

    context 'with enabled password login' do
      let(:setup) do
        Setting.set('user_show_password_login', true)
      end

      let(:token) { 'valid-token' }

      it 'raises an error' do
        expect(gql.result.error_message).to eq 'This feature is not enabled.'
      end
    end

    context 'with disabled password login' do
      context 'when no third-party authenticator is enabled' do
        let(:setup) do
          Setting.set('user_show_password_login', false)
        end

        let(:token) { 'dummy' }

        it 'raises an error' do
          expect(gql.result.error_message).to eq 'This feature is not enabled.'
        end
      end

      context 'when any third-party authenticator is enabled' do
        let(:setup) do
          Setting.set('user_show_password_login', false)
          Setting.set('auth_saml', true)

          user = create(:admin)
          Token.create(action: 'AdminAuth', user_id: user.id, persistent: false)
        end

        context 'with invalid token' do
          let(:token) { 'invalid' }

          it 'raises an error' do
            expect(gql.result.error_message).to eq 'The login is not possible.'
          end
        end

        context 'with valid token' do
          let(:token) { Token.last.token }

          it 'returns the login' do
            expect(gql.result.data[:login]).to eq User.last.login
          end
        end
      end
    end
  end
end
