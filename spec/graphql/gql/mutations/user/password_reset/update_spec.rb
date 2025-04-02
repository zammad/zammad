# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::PasswordReset::Update, type: :graphql do
  context 'when updating a password for a user' do
    let(:user)     { create(:user) }
    let(:token)    { User.password_reset_new_token(user.login)[:token].token }
    let(:password) { 'q48X9cV2IR' }

    let(:query) do
      <<~QUERY
        mutation userPasswordResetUpdate($token: String!, $password: String!) {
          userPasswordResetUpdate(token: $token, password: $password) {
            success
            errors {
              message
              field
            }
          }
        }
      QUERY
    end

    let(:variables) do
      {
        token:    token,
        password: password,
      }
    end

    def execute_graphql_query
      gql.execute(query, variables: variables)
    end

    shared_examples 'not updating user password' do
      it 'does not update user password' do
        expect { execute_graphql_query }.to not_change { user.reload.password }
      end
    end

    shared_examples 'raising an error' do |message:|
      it 'raises an error' do
        execute_graphql_query
        expect(gql.result.error_message).to eq(message)
      end

      it_behaves_like 'not updating user password'
    end

    shared_examples 'updating user password' do
      it 'returns success' do
        execute_graphql_query
        expect(gql.result.data).to eq({ 'success' => true, 'errors' => nil })
      end

      it 'updates user password' do
        expect { execute_graphql_query }.to change { user.reload.password }
      end

      it 'sends an email notification to the user' do
        message = nil

        allow(NotificationFactory::Mailer).to receive(:deliver) do |params|
          message = params[:body]
        end

        execute_graphql_query

        expect(message).to include('This activity is not known to you? If not, contact your system administrator.')
      end
    end

    shared_examples 'returning an error' do |message:, field: nil|
      it 'returns an error', :aggregate_failures do
        execute_graphql_query

        errors = gql.result.data[:errors].first
        expect(errors.keys).to include('message', 'field')
        expect(errors['message']).to include(message)
        expect(errors['field']).to eq(field)
      end

      it_behaves_like 'not updating user password'
    end

    context 'with disabled lost password feature' do
      before do
        Setting.set('user_lost_password', false)
      end

      it_behaves_like 'raising an error', message: 'This feature is not enabled.'
    end

    context 'with valid token and password' do
      it_behaves_like 'updating user password'
    end

    context 'with an invalid token' do
      let(:token) { SecureRandom.urlsafe_base64(48) }

      it_behaves_like 'returning an error', message: 'The provided token is invalid.'
    end

    context 'with an invalid password' do
      let(:password) { 'foobar9' }

      it_behaves_like 'returning an error', message: 'Invalid password', field: 'password'
    end
  end
end
