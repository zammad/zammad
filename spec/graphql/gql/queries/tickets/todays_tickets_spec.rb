# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Tickets::TodaysTickets, type: :graphql do
  let(:query) do
    <<~QUERY
      query todaysTickets {
        todaysTickets {
          totalCount
          edges {
            node {
              id
              internalId
              number
              title
            }
          }
        }
      }
    QUERY
  end

  let(:group) { create(:group) }
  let(:agent) { create(:agent, groups: [group]) }
  let(:customer) { create(:customer) }

  before do
    gql.execute(query)
  end

  context 'with an agent', authenticated_as: :agent do
    context 'when tickets were created today' do
      let!(:ticket_today) { create(:ticket, group: group, created_at: Time.zone.now) }
      let!(:ticket_yesterday) { create(:ticket, group: group, created_at: 1.day.ago) }

      it 'returns only tickets created today' do
        expect(gql.result.nodes.size).to eq(1)
        expect(gql.result.nodes.first).to include(
          'number' => ticket_today.number,
          'internalId' => ticket_today.id
        )
      end

      it 'has correct total count' do
        expect(gql.result.data[:totalCount]).to eq(1)
      end
    end

    context 'when no tickets were created today' do
      let!(:ticket_yesterday) { create(:ticket, group: group, created_at: 1.day.ago) }
      let!(:ticket_last_week) { create(:ticket, group: group, created_at: 1.week.ago) }

      it 'returns empty result' do
        expect(gql.result.nodes).to eq([])
      end

      it 'has zero total count' do
        expect(gql.result.data[:totalCount]).to be_zero
      end
    end

    context 'with timezone considerations', time_zone: 'America/Los_Angeles' do
      let!(:ticket_early_today) { create(:ticket, group: group, created_at: Time.zone.now.beginning_of_day + 1.hour) }
      let!(:ticket_late_today) { create(:ticket, group: group, created_at: Time.zone.now.end_of_day - 1.hour) }
      let!(:ticket_yesterday_late) { create(:ticket, group: group, created_at: Time.zone.now.beginning_of_day - 1.hour) }

      it 'correctly filters tickets by timezone-aware today range' do
        expect(gql.result.nodes.size).to eq(2)
        ticket_numbers = gql.result.nodes.map { |node| node['number'] }
        expect(ticket_numbers).to contain_exactly(ticket_early_today.number, ticket_late_today.number)
      end
    end

    context 'without visible tickets due to group permissions' do
      let(:other_group) { create(:group) }
      let!(:ticket_other_group) { create(:ticket, group: other_group, created_at: Time.zone.now) }

      it 'returns no tickets' do
        expect(gql.result.nodes).to eq([])
      end

      it 'has zero total count' do
        expect(gql.result.data[:totalCount]).to be_zero
      end
    end
  end

  context 'with a customer', authenticated_as: :customer do
    let!(:ticket_today) { create(:ticket, group: group, created_at: Time.zone.now) }

    it 'raises authorization error' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
