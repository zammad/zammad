# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::User::Current::TwoFactor::InitiateMethodConfiguration, type: :graphql do
  context 'when fetching two factor configuration for current user' do
    let(:variables) { { methodName: 'authenticator_app' } }
    let(:query) do
      <<~QUERY
        query userCurrentTwoFactorInitiateMethodConfiguration($methodName: EnumTwoFactorAuthenticationMethod!) {
          userCurrentTwoFactorInitiateMethodConfiguration(methodName: $methodName)
        }
      QUERY
    end

    context 'when authorized', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      context 'when a two factor authentication method is enabled' do
        before do
          Setting.set('two_factor_authentication_method_authenticator_app', true)
        end

        it 'enabled authentication method exists' do
          gql.execute(query, variables: variables)
          expect(gql.result.data).to include(:secret).and include(:provisioning_uri)
        end
      end
    end

    context 'when unauthenticated' do
      before do
        gql.execute(query, variables: variables)
      end

      it_behaves_like 'graphql responds with error if unauthenticated'
    end
  end
end
