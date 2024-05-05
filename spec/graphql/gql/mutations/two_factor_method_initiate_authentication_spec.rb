# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Login and logout work only via controller, so use type: request.
RSpec.describe Gql::Mutations::TwoFactorMethodInitiateAuthentication, :aggregate_failures, type: :request do
  let(:user)                       { create(:user, password: 'dummy') }
  let(:password)                   { 'dummy' }
  let(:two_factor_method)          { 'security_keys' }
  let(:user_two_factor_preference) { nil }
  let(:graphql_response)           { json_response }
  let(:enabled)                    { true }

  let(:query) do
    <<~QUERY
      mutation twoFactorMethodInitiateAuthentication(
        $login: String!
        $password: String!
        $twoFactorMethod: EnumTwoFactorAuthenticationMethod!
      ) {
        twoFactorMethodInitiateAuthentication(
          login: $login
          password: $password
          twoFactorMethod: $twoFactorMethod
        ) {
          initiationData
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
      login:           user.login,
      password:        password,
      twoFactorMethod: two_factor_method,
    }
  end

  before do
    Setting.set('two_factor_authentication_method_security_keys', enabled)
    stub_const('Auth::BRUTE_FORCE_SLEEP', 0)

    if defined?(user_two_factor_preference)
      user_two_factor_preference
      user.reload
    end

    post '/graphql', params: { query: query, variables: variables }, as: :json
  end

  context 'with missing variables' do
    let(:variables) { {} }

    it 'returns an error' do
      expect(graphql_response['errors']).to be_present
    end
  end

  context 'with valid variables' do
    let(:user_two_factor_preference) { create(:user_two_factor_preference, :security_keys, user: user) }

    context 'with invalid user/password' do
      let(:password) { 'invalid' }

      it 'returns an error' do
        expect(graphql_response['data']['twoFactorMethodInitiateAuthentication']['errors']).to be_present
      end
    end

    context 'with valid user/password' do
      it 'returns options for initiation phase', :aggregate_failures do
        expect(graphql_response['data']['twoFactorMethodInitiateAuthentication']['errors']).to be_blank
        expect(graphql_response['data']['twoFactorMethodInitiateAuthentication']['initiationData']).to include('challenge')
      end

      context 'with disabled authenticator method' do
        let(:enabled) { false }

        it 'fails with error message' do
          expect(graphql_response['data']['twoFactorMethodInitiateAuthentication']['errors']).to eq(
            [{
              'message' => 'The two-factor authentication method is not enabled.',
              'field'   => nil
            }]
          )
        end
      end
    end
  end
end
