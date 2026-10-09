# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::PushSubscription::Delete, type: :graphql do
  let(:agent)        { create(:agent) }
  let(:subscription) { create(:push_subscription, user: agent) }

  let(:mutation) do
    <<~GQL
      mutation userCurrentPushSubscriptionDelete($endpoint: String!) {
        userCurrentPushSubscriptionDelete(endpoint: $endpoint) {
          success
          errors {
            message
            field
          }
        }
      }
    GQL
  end

  let(:variables) { { endpoint: subscription.endpoint } }

  def execute_graphql_query
    gql.execute(mutation, variables: variables)
  end

  context 'when user is not authenticated' do
    before { execute_graphql_query }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  context 'when user is an agent', authenticated_as: :agent do
    it 'passes the endpoint to the service' do
      allow(Service::User::PushSubscription::Delete).to receive(:execute).and_call_original

      execute_graphql_query

      expect(Service::User::PushSubscription::Delete)
        .to have_received(:execute)
        .with(endpoint: subscription.endpoint, current_user: agent)
    end

    it 'returns success' do
      execute_graphql_query

      expect(gql.result.data).to include('success' => true)
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
