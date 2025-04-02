# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'graphql/gql/shared_examples/two_factor_token_validity_check'

RSpec.describe Gql::Mutations::User::Current::TwoFactor::RemoveMethodCredentials, :aggregate_failures, type: :graphql do
  let(:user)          { create(:agent) }
  let(:credential_id) { 'credentialKey' }
  let(:token)         { create(:token, action: 'PasswordCheck', persistent: false, user: user, expires_at: 1.hour.from_now).token }
  let(:variables)     { { methodName: 'security_keys', token: token, credentialId: credential_id } }

  let(:user_preference) do
    create(:user_two_factor_preference,
           :security_keys,
           credential_public_key: credential_id,
           user:)
  end

  let(:mutation) do
    <<~GQL
      mutation userCurrentTwoFactorRemoveMethodCredentials(
        $methodName: String!
        $token: String!
        $credentialId: String!
      ) {
        userCurrentTwoFactorRemoveMethodCredentials(
          methodName: $methodName
          token: $token
          credentialId: $credentialId
        ) {
          success
        }
      }
    GQL
  end

  before { user_preference }

  context 'when user is not authenticated' do
    it 'returns an error' do
      gql.execute(mutation, variables: variables)

      expect(gql.result.error).to include('message' => 'Authentication required')
    end
  end

  context 'when user is authenticated', authenticated_as: :user do
    it 'calls remove method credentials service' do
      allow(Service::User::TwoFactor::RemoveMethodCredentials)
        .to receive(:new)
        .and_call_original

      expect_any_instance_of(Service::User::TwoFactor::RemoveMethodCredentials)
        .to receive(:execute)
        .and_call_original

      gql.execute(mutation, variables: variables)

      expect(Service::User::TwoFactor::RemoveMethodCredentials)
        .to have_received(:new).with(user: user, method_name: 'security_keys', credential_id:)
    end

    context 'when given method exists' do
      it 'returns success' do
        gql.execute(mutation, variables: variables)

        expect(gql.result.data).to include('success' => be_truthy)
      end
    end

    context 'when given method does not exist' do
      let(:variables) { { methodName: 'nonsense', token: token } }

      it 'returns error' do
        gql.execute(mutation, variables: variables)

        expect(gql.result.error).to be_present
      end
    end

    it_behaves_like 'having token validity check', operation_name: :mutation
  end
end
