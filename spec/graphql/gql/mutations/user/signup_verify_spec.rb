# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Session handling works only via controller, so use type: request.
RSpec.describe Gql::Mutations::User::SignupVerify, :aggregate_failures, type: :request do
  context 'when verifying signed up user' do
    let(:user) do
      create(:role, name: 'user_preferences_device', default_at_signup: true, permission_names: ['user_preferences.device'])
      create(:user, verified: false)
    end
    let(:query) do
      <<~QUERY
        mutation userSignupVerify($token: String!) {
          userSignupVerify(token: $token) {
            session {
              id
              afterAuth {
                type
                data
              }
            }
            errors {
              message
            }
          }
        }
      QUERY
    end

    let(:variables) { { token: token } }

    let(:headers) do
      {
        'X-Browser-Fingerprint' => 'some-fingerprint',
      }
    end

    let(:graphql_response) do
      execute_graphql_query
      json_response
    end

    def execute_graphql_query
      post '/graphql', params: { query: query, variables: variables }, headers: headers, as: :json
    end

    shared_examples 'returning an error' do |message|
      it 'returns an error' do
        expect(graphql_response['data']['userSignupVerify']).to include({ 'errors' => include({ 'message' => message }) }).and include({ 'session' => nil })
      end
    end

    shared_examples 'returning a session' do
      it 'returns the session' do
        expect(graphql_response['data']['userSignupVerify']).to include({ 'session' => include({ 'id' => a_kind_of(String) }) }).and include({ 'errors' => nil })
      end
    end

    context 'with disabled user signup' do
      before do
        Setting.set('user_create_account', false)
      end

      let(:token) { SecureRandom.urlsafe_base64(48) }

      it 'raises an gql error' do
        expect(graphql_response['errors'].first['message']).to eq('This feature is not enabled.')
      end
    end

    context 'with a valid token' do
      let(:token) { User.signup_new_token(user)[:token].token } # NB: Don't ask!

      it_behaves_like 'returning a session'
    end

    context 'with an invalid token' do
      let(:token) { SecureRandom.urlsafe_base64(48) }

      it_behaves_like 'returning an error', 'The provided token is invalid.'
    end
  end
end
