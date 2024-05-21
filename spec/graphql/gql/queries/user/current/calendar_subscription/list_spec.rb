# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::User::Current::CalendarSubscription::List, type: :graphql do
  let(:query) do
    <<~QUERY
      query userCurrentCalendarSubscriptionList {
        userCurrentCalendarSubscriptionList {
          combinedUrl
          globalOptions {
            alarm
          }
          newOpen {
            url
            options {
              own
              notAssigned
            }
          }
        }
      }
    QUERY
  end

  context 'when authorized', authenticated_as: :user do
    let(:user) { create(:agent) }

    it 'returns combined "all" calendar url and alarm' do
      gql.execute(query)

      expect(gql.result.data)
        .to include(
          'combinedUrl'   => 'http://zammad.example.com/ical/tickets',
          'globalOptions' => include('alarm' => false)
        )
    end

    it 'returns specific calendar subscription' do
      gql.execute(query)

      expect(gql.result.data)
        .to include(
          'newOpen' => include(
            'url'     => 'http://zammad.example.com/ical/tickets/new_open',
            'options' => include('own' => true, 'notAssigned' => false)
          )
        )
    end

    it 'calls CalendarSubscription::TicketPreferencesWithUrls service', aggregate_failures: true do
      allow(Service::User::CalendarSubscription::TicketPreferencesWithUrls).to receive(:new).and_call_original
      expect_any_instance_of(Service::User::CalendarSubscription::TicketPreferencesWithUrls).to receive(:execute)

      gql.execute(query)

      expect(Service::User::CalendarSubscription::TicketPreferencesWithUrls)
        .to have_received(:new)
        .with(user)
    end

    context 'when permissions are insufficient' do
      let(:user) { create(:customer) }

      before do
        gql.execute(query)
      end

      it_behaves_like 'graphql responds with error if unauthenticated'
    end
  end

  context 'when unauthenticated' do
    before do
      gql.execute(query)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
