# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'graphql/gql/shared_examples/two_factor_token_validity_check'

RSpec.describe Gql::Mutations::User::Current::TwoFactor::RemoveMethod, :aggregate_failures, type: :graphql do
  let(:user)      { create(:agent) }
  let(:token)     { create(:token, action: 'PasswordCheck', persistent: false, user: user, expires_at: 1.hour.from_now).token }
  let(:variables) { { methodName: 'authenticator_app', token: token } }

  let(:mutation) do
    <<~MUTATION
      mutation userCurrentTwoFactorRemoveMethod(
        $methodName: String!
        $token: String!
      ) {
        userCurrentTwoFactorRemoveMethod(
          methodName: $methodName
          token: $token
        ) {
          success
          errors {
            message
            field
          }
        }
      }
    MUTATION
  end

  context 'when user is not authenticated' do
    it 'returns an error' do
      gql.execute(mutation, variables: variables)

      expect(gql.result.error).to include('message' => 'Authentication required')
    end
  end

  context 'when user is authenticated', authenticated_as: :user do
    it 'calls remove method service' do
      allow(Service::User::TwoFactor::RemoveMethod)
        .to receive(:new)
        .and_call_original

      expect_any_instance_of(Service::User::TwoFactor::RemoveMethod)
        .to receive(:execute)
        .and_call_original

      gql.execute(mutation, variables: variables)

      expect(Service::User::TwoFactor::RemoveMethod)
        .to have_received(:new).with(user: user, method_name: 'authenticator_app')
    end

    context 'when given method exists' do
      it 'returns success' do
        gql.execute(mutation, variables: variables)

        expect(gql.result.data).to include('success' => be_truthy)
      end

      it_behaves_like 'cleaning up used token', operation_name: :mutation
    end

    context 'when given method does not exist' do
      let(:variables) { { methodName: 'nonsense' } }

      it 'returns error' do
        gql.execute(mutation, variables: variables)

        expect(gql.result.error).to be_present
      end

      it_behaves_like 'keeping used token', operation_name: :mutation
    end

    it_behaves_like 'having token validity check', operation_name: :mutation
  end
end
