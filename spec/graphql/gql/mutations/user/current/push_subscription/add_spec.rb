# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::PushSubscription::Add, type: :graphql do
  let(:agent)  { create(:agent) }
  let(:p256dh) { Base64.urlsafe_encode64(SecureRandom.random_bytes(65), padding: false) }
  let(:auth)   { Base64.urlsafe_encode64(SecureRandom.random_bytes(16), padding: false) }

  let(:mutation) do
    <<~GQL
      mutation userCurrentPushSubscriptionAdd($input: UserPushSubscriptionInput!) {
        userCurrentPushSubscriptionAdd(input: $input) {
          success
          errors {
            message
            field
          }
        }
      }
    GQL
  end

  let(:variables) do
    {
      input: {
        endpoint: 'https://fcm.googleapis.com/fcm/send/1',
        keys:     { p256dh:, auth: },
      }
    }
  end

  def execute_graphql_query
    gql.execute(mutation, variables: variables)
  end

  context 'when user is not authenticated' do
    before { execute_graphql_query }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  context 'when user is an agent', authenticated_as: :agent do
    it 'passes the subscription to the service' do
      allow(Service::User::PushSubscription::Add).to receive(:execute).and_call_original

      execute_graphql_query

      expect(Service::User::PushSubscription::Add)
        .to have_received(:execute)
        .with(
          endpoint:     'https://fcm.googleapis.com/fcm/send/1',
          keys:         { p256dh:, auth: },
          current_user: agent,
        )
    end

    it 'returns success' do
      execute_graphql_query

      expect(gql.result.data).to include('success' => true)
    end

    context 'with the endpoint of an unknown push service' do
      let(:variables) do
        {
          input: {
            endpoint: 'https://push.example.com/subscription/1',
            keys:     { p256dh:, auth: },
          }
        }
      end

      it 'returns the validation error' do
        execute_graphql_query

        expect(gql.result.data).to include(
          'success' => nil,
          'errors'  => [{ 'message' => 'This field is not an endpoint of a known push service', 'field' => 'endpoint' }],
        )
      end
    end
  end

  context 'when user is a customer', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    before { execute_graphql_query }

    it 'is forbidden' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end
end
