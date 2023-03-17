# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Merge, :aggregate_failures, type: :graphql do
  let(:query) do
    <<~QUERY
      mutation ticketMerge($sourceTicketId: ID!, $targetTicketId: ID!) {
        ticketMerge(sourceTicketId: $sourceTicketId, targetTicketId: $targetTicketId) {
          targetTicket {
            id
            title
          }
          errors {
            message
            field
          }
        }
      }
    QUERY
  end
  let(:agent)    { create(:agent, groups: [ Group.find_by(name: 'Users')]) }
  let(:customer) { create(:customer) }
  # let(:user)     { agent }
  let(:group)    { agent.groups.first }
  let(:priority)        { Ticket::Priority.last }
  let(:source_ticket)   { create(:ticket, group: agent.groups.first, customer: customer) }
  let!(:source_article) { create(:ticket_article, ticket: source_ticket) }
  let(:target_ticket)   { create(:ticket, group: agent.groups.first, customer: customer) }

  let(:input_payload) { input_base_payload }
  let(:variables)     do
    {
      sourceTicketId: gql.id(source_ticket),
      targetTicketId: gql.id(target_ticket),
    }
  end

  let(:expected_base_response) do
    {
      'id'    => gql.id(target_ticket),
      'title' => target_ticket.title,
    }
  end

  let(:expected_response) do
    expected_base_response
  end

  context 'when merging a ticket' do

    context 'with an agent', authenticated_as: :agent do

      it 'creates Ticket record' do
        gql.execute(query, variables: variables)
        expect(gql.result.data['targetTicket']).to eq(expected_response)
        expect(source_article.reload.ticket_id).to eq(target_ticket.id)
      end

      context 'with no permission to the group' do
        let(:source_ticket) { create(:ticket, group: create(:group)) }

        it 'raises an error', :aggregate_failures do
          gql.execute(query, variables: variables)
          expect(gql.result.error_type).to eq(Exceptions::Forbidden)
          expect(gql.result.error_message).to eq('Access forbidden by Gql::Types::TicketType')
        end
      end

      context 'when merging a ticket into itself' do
        let(:target_ticket) { source_ticket }

        it 'raises a user error' do
          gql.execute(query, variables: variables)
          expect(gql.result.data['errors']).to eq([{ 'field' => nil, 'message' => 'A ticket cannot be merged into itself.' }])
        end
      end

      context 'when merging into a merged ticket' do
        let(:target_ticket) { create(:ticket, group: agent.groups.first, customer: customer, state: Ticket::State.find_by(name: 'merged')) }

        it 'raises a user error' do
          gql.execute(query, variables: variables)
          expect(gql.result.data['errors']).to eq([{ 'field' => nil, 'message' => 'It is not possible to merge into an already merged ticket.' }])
        end
      end

    end

    context 'with a customer', authenticated_as: :customer do
      it 'raises an error', :aggregate_failures do
        gql.execute(query, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
        expect(gql.result.error_message).to eq("Failed Gql::EntryPoints::Mutations's authorization check on field ticketMerge")
      end
    end
  end
end
