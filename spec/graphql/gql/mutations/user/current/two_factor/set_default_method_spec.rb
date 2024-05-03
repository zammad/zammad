# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::TwoFactor::SetDefaultMethod, :aggregate_failures, type: :graphql do
  let(:user)      { create(:agent) }
  let(:variables) { { methodName: 'authenticator_app' } }

  let(:mutation) do
    <<~MUTATION
      mutation userCurrentTwoFactorSetDefaultMethod($methodName: String!) {
        userCurrentTwoFactorSetDefaultMethod(methodName: $methodName) {
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
    before do
      Setting.set('two_factor_authentication_method_authenticator_app', true)
      create(:user_two_factor_preference, :authenticator_app, user: user)
    end

    it 'calls SetDefaultMethod service' do
      allow(Service::User::TwoFactor::SetDefaultMethod).to receive(:new).and_call_original
      expect_any_instance_of(Service::User::TwoFactor::SetDefaultMethod).to receive(:execute)

      gql.execute(mutation, variables: variables)

      expect(Service::User::TwoFactor::SetDefaultMethod)
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

      it 'returns an error' do
        gql.execute(mutation, variables: variables)
        expect(gql.result.error).to be_present
      end
    end
  end
end
