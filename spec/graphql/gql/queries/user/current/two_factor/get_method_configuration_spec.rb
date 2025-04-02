# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'graphql/gql/shared_examples/two_factor_token_validity_check'

RSpec.describe Gql::Queries::User::Current::TwoFactor::GetMethodConfiguration, :aggregate_failures, type: :graphql do
  let(:user)            { create(:agent) }
  let(:token)           { create(:token, action: 'PasswordCheck', persistent: false, user: user, expires_at: 1.hour.from_now).token }
  let(:variables)       { { methodName: 'security_keys', token: token } }
  let(:user_preference) { create(:user_two_factor_preference, :security_keys, user:) }

  let(:query) do
    <<~GQL
      query userCurrentTwoFactorGetMethodConfiguration(
        $methodName: String!
        $token: String!
      ) {
        userCurrentTwoFactorGetMethodConfiguration(
          methodName: $methodName
          token: $token
        )
      }
    GQL
  end

  context 'when user is not authenticated' do
    it 'returns an error' do
      gql.execute(query, variables: variables)

      expect(gql.result.error).to include('message' => 'Authentication required')
    end
  end

  context 'when user is authenticated', authenticated_as: :user do
    it 'calls get method configuration service' do
      allow(Service::User::TwoFactor::GetMethodConfiguration)
        .to receive(:new)
        .and_call_original

      expect_any_instance_of(Service::User::TwoFactor::GetMethodConfiguration)
        .to receive(:execute)
        .and_call_original

      gql.execute(query, variables: variables)

      expect(Service::User::TwoFactor::GetMethodConfiguration)
        .to have_received(:new).with(user: user, method_name: 'security_keys')
    end

    context 'when given method exists' do
      context 'when method is configured' do
        before { user_preference }

        it 'returns configuration' do
          gql.execute(query, variables: variables)

          expect(gql.result.data).to eq(user_preference.configuration)
        end

        context 'with authenticator app method' do
          let(:variables)       { { methodName: 'authenticator_app', token: token } }
          let(:user_preference) { create(:user_two_factor_preference, :authenticator_app, user:) }

          it 'returns nil' do
            gql.execute(query, variables: variables)

            expect(gql.result.data).to be_nil
          end
        end
      end

      context 'when method is not configured' do
        it 'returns nil' do
          gql.execute(query, variables: variables)

          expect(gql.result.data).to be_nil
        end
      end
    end

    context 'when given method does not exist' do
      let(:variables) { { methodName: 'nonsense', token: token } }

      it 'returns error' do
        gql.execute(query, variables: variables)

        expect(gql.result.error).to be_present
      end
    end

    it_behaves_like 'having token validity check', operation_name: :query
  end
end
