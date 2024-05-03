# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::User::Current::TwoFactor::GetMethodConfiguration, :aggregate_failures, type: :graphql do
  let(:user)            { create(:agent) }
  let(:variables)       { { methodName: 'authenticator_app' } }
  let(:user_preference) { create(:user_two_factor_preference, :authenticator_app, user:) }

  let(:query) do
    <<~GQL
      query userCurrentTwoFactorGetMethodConfiguration($methodName: String!) {
        userCurrentTwoFactorGetMethodConfiguration(methodName: $methodName)
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
    before do
      Setting.set('two_factor_authentication_method_authenticator_app', true)
    end

    it 'calls RemoveMethod service' do
      allow(Service::User::TwoFactor::GetMethodConfiguration)
        .to receive(:new)
        .and_call_original

      expect_any_instance_of(Service::User::TwoFactor::GetMethodConfiguration)
        .to receive(:execute)
        .and_call_original

      gql.execute(query, variables: variables)

      expect(Service::User::TwoFactor::GetMethodConfiguration)
        .to have_received(:new).with(user: user, method_name: 'authenticator_app')
    end

    context 'when given method exists' do
      context 'when method is configured' do
        before { user_preference }

        it 'returns configuration' do
          gql.execute(query, variables: variables)
          expect(gql.result.data).to eq(user_preference.configuration)
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
      let(:variables) { { methodName: 'nonsense' } }

      it 'returns error' do
        gql.execute(query, variables: variables)
        expect(gql.result.error).to be_present
      end
    end
  end
end
