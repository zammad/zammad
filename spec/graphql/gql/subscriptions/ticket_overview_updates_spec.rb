# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::TicketOverviewUpdates, authenticated_as: :agent, type: :graphql do
  let(:mock_channel) { build_mock_channel }
  let(:overview)     { create(:overview) }
  let(:agent)        { create(:agent) }
  let(:subscription) do
    <<~QUERY
      subscription ticketOverviewUpdates {
        ticketOverviewUpdates {
          ticketOverviews {
            edges {
              node {
                id
                name
              }
            }
          }
        }
      }
    QUERY
  end

  before do
    overview

    gql.execute(subscription, context: { channel: mock_channel })
  end

  context 'when subscribed' do
    it 'subscribes' do
      expect(gql.result.data).to eq({ 'ticketOverviews' => nil })
    end

    it 'receives ticket overview updates' do
      overview.update!(name: 'example overview')
      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'ticketOverviewUpdates', 'ticketOverviews', 'edges').first['node']['name']).to eq('example overview')
    end

    it 'receives updates whenever a ticket overview was created' do
      create(:overview)

      # We have 7 default overviews + the one we created in the before block.
      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'ticketOverviewUpdates', 'ticketOverviews', 'edges').size).to eq(9)
    end

    it 'receives updates whenever a ticket overview was deleted' do
      overview.destroy!

      # We have 7 default overviews + the one we created in the before block.
      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'ticketOverviewUpdates', 'ticketOverviews', 'edges').size).to eq(7)
    end
  end
end
