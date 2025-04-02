# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::User::Current::Ticket::OverviewUpdates, authenticated_as: :agent, type: :graphql do
  let(:mock_channel)              { build_mock_channel }
  let(:mock_channel_with_sorting) { build_mock_channel }
  let(:overview1)                 { create(:overview, name: 'Test Overview 1') }
  let(:overview2)                 { create(:overview, name: 'Test Overview 2') }
  let(:agent)                     { create(:agent) }
  let(:subscription) do
    <<~QUERY
      subscription userCurrentTicketOverviewUpdates($ignoreUserConditions: Boolean!) {
        userCurrentTicketOverviewUpdates(ignoreUserConditions: $ignoreUserConditions) {
          ticketOverviews {
            id
            name
          }
        }
      }
    QUERY
  end

  before do
    overview1 && overview2
    create(:user_overview_sorting, overview: overview1, prio: 2, user: agent)
    create(:user_overview_sorting, overview: overview2, prio: 1, user: agent)

    gql.execute(subscription, variables: { ignoreUserConditions: false }, context: { channel: mock_channel })
  end

  context 'when subscribed' do
    it 'subscribes' do
      expect(gql.result.data).to eq({ 'ticketOverviews' => nil })
    end

    it 'receives ticket overview updates according to sorting of the user' do
      overview1.touch
      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'userCurrentTicketOverviewUpdates', 'ticketOverviews').first['name']).to eq('Test Overview 2')
    end

    it 'receives updates whenever a ticket overview was created' do
      create(:overview)

      # We have 7 default overviews + the two we created in the before block.+
      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'userCurrentTicketOverviewUpdates', 'ticketOverviews').size).to eq(10)
    end

    it 'receives updates whenever a ticket overview was deleted' do
      overview1.destroy!

      # We have 7 default overviews + the two we created in the before block.
      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'userCurrentTicketOverviewUpdates', 'ticketOverviews').size).to eq(8)
    end
  end
end
