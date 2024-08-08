# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Checklist::ItemDelete, type: :graphql do
  let(:group)          { create(:group) }
  let(:agent)          { create(:agent, groups: [group]) }
  let(:ticket)         { create(:ticket, group: group) }
  let(:checklist)      { create(:checklist, ticket: ticket) }
  let(:checklist_item) { create(:checklist_item, checklist: checklist) }

  let(:query) do
    <<~QUERY
      mutation ticketChecklistItemDelete($checklistId: ID!, $checklistItemId: ID!) {
        ticketChecklistItemDelete(checklistId: $checklistId, checklistItemId: $checklistItemId) {
          success
        }
      }
    QUERY
  end

  let(:variables) { { checklistId: gql.id(checklist), checklistItemId: gql.id(checklist_item) } }

  before do
    gql.execute(query, variables: variables)
  end

  shared_examples 'deleting the ticket checklist item' do
    it 'deletes the ticket checklist item' do
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
    it_behaves_like 'deleting the ticket checklist item'

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

      it_behaves_like 'deleting the ticket checklist item'
    end

    context 'when ticket checklist does not exist' do
      let(:variables) { { checklistId: 'gid://Zammad/Checklist/0', checklistItemId: gql.id(checklist_item) } }

      it_behaves_like 'returning an error payload', "Couldn't find Checklist with 'id'=0", 'ActiveRecord::RecordNotFound'
    end

    context 'when ticket checklist item does not exist' do
      let(:variables) { { checklistId: gql.id(checklist), checklistItemId: 'gid://Zammad/Checklist::Item/0' } }

      it_behaves_like 'returning an error payload', "Couldn't find Checklist::Item with 'id'=0", 'ActiveRecord::RecordNotFound'
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
