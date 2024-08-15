# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Checklist::ItemOrderUpdate, type: :graphql do
  let(:group)     { create(:group) }
  let(:agent)     { create(:agent, groups: [group]) }
  let(:ticket)    { create(:ticket, group: group) }
  let(:checklist) { create(:checklist, ticket: ticket) }

  let(:order) do
    checklist.sorted_item_ids.reverse.map do |item_id|
      Gql::ZammadSchema.id_from_internal_id('Checklist::Item', item_id)
    end
  end

  let(:query) do
    <<~QUERY
      mutation ticketChecklistItemOrderUpdate($checklistId: ID!, $order: [ID!]!) {
        ticketChecklistItemOrderUpdate(checklistId: $checklistId, order: $order) {
          success
        }
      }
    QUERY
  end

  let(:variables) { { checklistId: gql.id(checklist), order: order } }

  before do
    gql.execute(query, variables: variables)
  end

  shared_examples 'updating the ticket checklist item order' do
    it 'updates the ticket checklist item order' do
      expect(gql.result.data['success']).to be(true)
    end
  end

  shared_examples 'returning an error payload' do |error_message, error_type|
    it 'returns an error payload', aggregate_failures: true do
      expect(gql.result.payload['errors'].first['message']).to eq(error_message)
      expect(gql.result.payload['errors'].first['extensions']['type']).to eq(error_type)
    end
  end

  context 'with authenticated session', authenticated_as: :agent do
    it_behaves_like 'updating the ticket checklist item order'

    context 'without access to the ticket' do
      let(:agent) { create(:agent) }

      it_behaves_like 'returning an error payload', 'not allowed to update? this Ticket', 'Pundit::NotAuthorizedError'
    end

    context 'with ticket read permission' do
      let(:agent) { create(:agent, groups: [group], group_names_access_map: { group.name => 'read' }) }

      it_behaves_like 'returning an error payload', 'not allowed to update? this Ticket', 'Pundit::NotAuthorizedError'
    end

    context 'with ticket read+change permissions' do
      let(:agent) { create(:agent, groups: [group], group_names_access_map: { group.name => %w[read change] }) }

      it_behaves_like 'updating the ticket checklist item order'
    end

    context 'when ticket checklist does not exist' do
      let(:variables) { { checklistId: 'gid://Zammad/Checklist/0', order: order } }

      it_behaves_like 'returning an error payload', "Couldn't find Checklist with 'id'=0", 'ActiveRecord::RecordNotFound'
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end