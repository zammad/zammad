# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'graphql/gql/shared_examples/two_factor_token_validity_check'

RSpec.describe Gql::Queries::User::Current::TwoFactor::InitiateMethodConfiguration, type: :graphql do
  context 'when fetching two factor configuration for current user' do
    let(:agent)     { create(:agent) }
    let(:token)     { create(:token, action: 'PasswordCheck', persistent: false, user: agent, expires_at: 1.hour.from_now).token }
    let(:variables) { { methodName: 'authenticator_app', token: token } }
    let(:query) do
      <<~QUERY
        query userCurrentTwoFactorInitiateMethodConfiguration(
          $methodName: EnumTwoFactorAuthenticationMethod!
          $token: String!
        ) {
          userCurrentTwoFactorInitiateMethodConfiguration(
            methodName: $methodName
            token: $token
          )
        }
      QUERY
    end

    context 'when authorized', authenticated_as: :agent do
      context 'when a two factor authentication method is enabled' do
        before do
          Setting.set('two_factor_authentication_method_authenticator_app', true)
        end

        it 'enabled authentication method exists' do
          gql.execute(query, variables: variables)
          expect(gql.result.data).to include(:secret).and include(:provisioning_uri)
        end
      end

      it_behaves_like 'having token validity check', operation_name: :query
    end

    context 'when unauthenticated' do
      before do
        gql.execute(query, variables: variables)
      end

      it_behaves_like 'graphql responds with error if unauthenticated'
    end
  end
end
