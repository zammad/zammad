# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::TwoFactor::RemoveMethod, :aggregate_failures, type: :graphql do
  let(:user)      { create(:agent) }
  let(:variables) { { methodName: 'authenticator_app' } }

  let(:mutation) do
    <<~MUTATION
      mutation userCurrentTwoFactorRemoveMethod($methodName: String!) {
        userCurrentTwoFactorRemoveMethod(methodName: $methodName) {
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
    it 'calls RemoveMethod service' do
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
    end

    context 'when given method does not exist' do
      let(:variables) { { methodName: 'nonsense' } }

      it 'returns error' do
        gql.execute(mutation, variables: variables)
        expect(gql.result.error).to be_present
      end
    end
  end
end
