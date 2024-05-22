# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::User::Current::TwoFactorUpdates, type: :graphql do

  let(:subscription) do
    <<~QUERY
      subscription userCurrentTwoFactorUpdates($userId: ID!) {
        userCurrentTwoFactorUpdates(userId: $userId) {
          configuration {
            recoveryCodesExist
            enabledAuthenticationMethods {
              configured
              default
              authenticationMethod
            }
          }
        }
      }
    QUERY
  end
  let(:mock_channel) { build_mock_channel }
  let(:target)       { create(:user) }
  let(:variables)    { { userId: gql.id(target) } }

  context 'when user is authenticated, but has no permission', authenticated_as: :agent do
    let(:agent) { create(:agent, roles: []) }

    before do
      gql.execute(subscription, variables: variables, context: { channel: mock_channel })
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  context 'with authenticated user', authenticated_as: :target do
    let(:result) do
      {
        'configuration' => {
          'enabledAuthenticationMethods' => enabled_authentication_methods,
          'recoveryCodesExist'           => recovery_codes_exist
        }
      }
    end
    let(:enabled_authentication_methods) { [] }
    let(:recovery_codes_exist)           { false }

    context 'with not activated two factor method' do
      it 'subscribes' do
        gql.execute(subscription, variables: variables, context: { channel: mock_channel })
        expect(gql.result.data).to eq(result)
      end
    end

    context 'with activated two factor method' do
      let(:enabled_authentication_methods) do
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

      it 'configuration includes enabled two factor methods' do
        gql.execute(subscription, variables: variables, context: { channel: mock_channel })
        expect(gql.result.data).to eq(result)
      end
    end

    context 'when subscribing for other users' do
      let(:variables) { { userId: gql.id(create(:user)) } }

      it 'does not subscribe but returns an authorization error' do
        gql.execute(subscription, variables: variables, context: { channel: mock_channel })
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
