# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Session handling works only via controller, so use type: request.
RSpec.describe Gql::Mutations::User::SignupVerify, :aggregate_failures, type: :request do
  context 'when verifying signed up user' do
    let(:user) { create(:user, verified: false) }
    let(:query) do
      <<~QUERY
        mutation userSignupVerify($token: String!) {
          userSignupVerify(token: $token) {
            success
            errors {
              message
            }
          }
        }
      QUERY
    end

    let(:variables) { { token: token } }

    let(:graphql_response) do
      execute_graphql_query
      json_response
    end

    def execute_graphql_query
      post '/graphql', params: { query: query, variables: variables }, as: :json
    end

    shared_examples 'returning an error' do |message|
      it 'returns an error' do
        expect(graphql_response['data']['userSignupVerify']).to include({ 'errors' => include({ 'message' => message }) }).and include({ 'success' => nil })
      end
    end

    shared_examples 'returning success' do
      it 'returns success' do
        expect(graphql_response['data']['userSignupVerify']).to include({ 'success' => true }).and include({ 'errors' => nil })
      end
    end

    shared_examples 'not signing the user in' do
      it 'does not establish a session' do
        execute_graphql_query

        expect(session[:user_id]).to be_nil
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

      it_behaves_like 'returning success'
      it_behaves_like 'not signing the user in'
    end

    context 'with an invalid token' do
      let(:token) { SecureRandom.urlsafe_base64(48) }

      it_behaves_like 'returning an error', 'The provided token is invalid.'
    end
  end
end
