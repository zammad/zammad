# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::User::Current::TwoFactor::Configuration, type: :graphql do
  context 'when fetching two factor configuration for current user' do
    let(:query) do
      <<~QUERY
        query userCurrentTwoFactorConfiguration {
          userCurrentTwoFactorConfiguration {
            recoveryCodesExist
            enabledAuthenticationMethods {
              configured
              default
              authenticationMethod
            }
          }
        }
      QUERY
    end

    context 'when authorized', authenticated_as: :agent do
      let(:agent)                                 { create(:agent) }
      let(:result_recover_codes)                  { false }
      let(:result_enabled_authentication_methods) { [] }
      let(:result) do
        {
          'recoveryCodesExist'           => result_recover_codes,
          'enabledAuthenticationMethods' => result_enabled_authentication_methods,
        }
      end

      context 'when no two factor authentication method is enabled' do
        it 'no enabled authentication methods and existing recovery codes' do
          gql.execute(query)
          expect(gql.result.data).to eq(result)
        end
      end

      context 'when a two factor authentication method is enabled' do
        let(:result_enabled_authentication_methods) do
          [
            {
              'authenticationMethod' => 'authenticator_app',
              'default'              => false,
              'configured'           => false,
            }
          ]
        end

        before do
          Setting.set('two_factor_authentication_method_authenticator_app', true)
        end

        it 'enabled authentication method exists' do
          gql.execute(query)
          expect(gql.result.data).to eq(result)
        end
      end
    end

    context 'when unauthenticated' do
      before do
        gql.execute(query)
      end

      it_behaves_like 'graphql responds with error if unauthenticated'
    end
  end
end
