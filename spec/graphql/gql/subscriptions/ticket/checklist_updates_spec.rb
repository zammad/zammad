# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::Ticket::ChecklistUpdates, :aggregate_failures, type: :graphql do
  let(:group)        { create(:group) }
  let(:agent)        { create(:agent, groups: [group]) }
  let(:ticket)       { create(:ticket, group: group) }
  let(:variables)    { { ticketId: gql.id(ticket) } }
  let(:mock_channel) { build_mock_channel }
  let(:subscription) do
    <<~QUERY
      subscription ticketChecklistUpdates($ticketId: ID!) {
        ticketChecklistUpdates(ticketId: $ticketId) {
          ticketChecklist {
            id
            name
            completed
            incomplete
            items {
              id
              text
              checked
            }
          }
          removedTicketChecklist
        }
      }
    QUERY
  end

  before do
    setup if defined?(setup)
    gql.execute(subscription, variables: variables, context: { channel: mock_channel })
  end

  context 'with an unauthenticated user' do
    it 'does not subscribe to checklist updates and returns an authorization error' do
      expect(gql.result.error_type).to eq(Exceptions::NotAuthorized)
    end
  end

  context 'with an authenticated user', authenticated_as: :agent do
    it 'subscribes to checklist updates' do
      expect(gql.result.data).not_to be_nil
    end

    context 'with disabled checklist feature' do
      let(:setup) do
        Setting.set('checklist', false)
      end

      it 'denies subscription with an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    it 'triggers after checklist create' do
      checklist = create(:checklist, ticket: ticket, item_count: nil)

      result = mock_channel.mock_broadcasted_messages.first[:result]['data']['ticketChecklistUpdates']

      expect(result).to include('ticketChecklist' => include(
        'id'         => gql.id(checklist),
        'completed'  => true,
        'incomplete' => 0,
      ))
    end

    context 'with an existing checklist' do
      let(:checklist) { create(:checklist, ticket: ticket, item_count: 1) }

      it 'triggers after checklist update' do
        checklist
        mock_channel.mock_broadcasted_messages.clear

        checklist.update!(name: 'foobar')
        result = mock_channel.mock_broadcasted_messages.first[:result]['data']['ticketChecklistUpdates']

        expect(result).to include('ticketChecklist' => include(
          'name' => 'foobar',
        ))
      end

      it 'triggers after checklist destroy' do
        checklist
        mock_channel.mock_broadcasted_messages.clear

        checklist.destroy!
        result = mock_channel.mock_broadcasted_messages.first[:result]['data']['ticketChecklistUpdates']

        expect(result).to include('ticketChecklist' => nil, 'removedTicketChecklist' => true)
      end

      it 'triggers after checklist item create' do
        checklist
        mock_channel.mock_broadcasted_messages.clear

        checklist.items.create!(text: 'foobar')
        result = mock_channel.mock_broadcasted_messages.first[:result]['data']['ticketChecklistUpdates']

        expect(result).to include('ticketChecklist' => include(
          'items' => include(
            include(
              'text' => 'foobar',
            )
          ),
        ))
      end

      it 'triggers after checklist item update' do
        checklist
        mock_channel.mock_broadcasted_messages.clear

        checklist.items.last.update!(text: 'foobar')
        result = mock_channel.mock_broadcasted_messages.first[:result]['data']['ticketChecklistUpdates']

        expect(result).to include('ticketChecklist' => include(
          'items' => include(
            include(
              'text' => 'foobar',
            )
          ),
        ))
      end

      it 'triggers after checklist item destroy' do
        checklist
        mock_channel.mock_broadcasted_messages.clear

        checklist.items.last.destroy!
        result = mock_channel.mock_broadcasted_messages.first[:result]['data']['ticketChecklistUpdates']

        expect(result['ticketChecklist']['items']).to be_empty
      end
    end
  end
end
