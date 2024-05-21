# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::CalendarSubscription::Update, type: :graphql do
  let(:user) { create(:agent) }

  let(:mutation) do
    <<~GQL
      mutation userCurrentCalendarSubscriptionUpdate($input: UserCalendarSubscriptionsConfigInput!) {
        userCurrentCalendarSubscriptionUpdate(input: $input) {
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
        alarm:      true,
        newOpen:    { own: false, notAssigned: false },
        pending:    { own: true, notAssigned: true },
        escalation: { own: true, notAssigned: false },
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

  context 'when user is authenticated', authenticated_as: :user do
    it 'updates preferences', aggregate_failures: true do
      execute_graphql_query

      expect(user.reload.preferences[:calendar_subscriptions])
        .to include(
          tickets: include(
            new_open:   include(own: false, not_assigned: false),
            pending:    include(own: true, not_assigned: true),
            escalation: include(own: true, not_assigned: false),
            alarm:      true
          )
        )
    end

    it 'sends correct data to the service', aggregate_failures: true do
      allow(Service::User::CalendarSubscription::Update).to receive(:new).and_call_original
      expect_any_instance_of(Service::User::CalendarSubscription::Update).to receive(:execute)

      execute_graphql_query

      expect(Service::User::CalendarSubscription::Update)
        .to have_received(:new)
        .with(
          user,
          include(
            input: include(
              alarm:    true,
              new_open: include(own: false, not_assigned: false),
            )
          )
        )
    end

    context 'when user has insufficicent permissions' do
      let(:user) { create(:customer) }

      before { execute_graphql_query }

      it_behaves_like 'graphql responds with error if unauthenticated'
    end
  end
end
