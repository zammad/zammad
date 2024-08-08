# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Checklist::ItemUpsert, type: :graphql do
  let(:group)     { create(:group) }
  let(:agent)     { create(:agent, groups: [group]) }
  let(:ticket)    { create(:ticket, group: group) }
  let(:checklist) { create(:checklist, ticket: ticket) }
  let(:input)     { { 'text' => 'foobar', 'checked' => true } }

  let(:query) do
    <<~QUERY
      mutation ticketChecklistItemUpsert($checklistId: ID!, $checklistItemId: ID, $input: TicketChecklistItemInput!) {
        ticketChecklistItemUpsert(checklistId: $checklistId, checklistItemId: $checklistItemId, input: $input) {
          success
          checklistItemId
        }
      }
    QUERY
  end

  let(:variables) { { checklistId: gql.id(checklist), input: input } }

  before do
    gql.execute(query, variables: variables)
  end

  shared_examples 'creating the ticket checklist item' do
    it 'creates the ticket checklist item', aggregate_failures: true do
      expect(gql.result.data['success']).to be(true)
      expect(gql.result.data['checklistItemId']).to a_kind_of(String)
    end
  end

  shared_examples 'updating the ticket checklist item' do
    it 'updates the ticket checklist item', aggregate_failures: true do
      expect(gql.result.data['success']).to be(true)
      expect(gql.result.data['checklistItemId']).to eq(variables[:checklistItemId])
    end
  end

  shared_examples 'returning an error payload' do |error_message, error_type|
    it 'returns an error payload', aggregate_failures: true do
      expect(gql.result.payload['errors'].first['message']).to eq(error_message)
      expect(gql.result.payload['errors'].first['extensions']['type']).to eq(error_type)
    end
  end

  context 'with authenticated session', authenticated_as: :agent do
    it_behaves_like 'creating the ticket checklist item'

    context 'when providing both checked state and text' do
      let(:input) { { 'checked' => true, 'text' => '' } }

      it_behaves_like 'creating the ticket checklist item'
    end

    context 'when providing text value only' do
      let(:input) { { 'text' => 'foobar' } }

      it_behaves_like 'creating the ticket checklist item'
    end

    context 'with existing ticket checklist item' do
      let(:checklist_item) { create(:checklist_item, checklist: checklist) }
      let(:variables)      { { checklistId: gql.id(checklist), input: input, checklistItemId: gql.id(checklist_item) } }

      it_behaves_like 'updating the ticket checklist item'

      context 'when providing checked state only' do
        let(:input) { { 'checked' => true } }

        it_behaves_like 'updating the ticket checklist item'
      end

      context 'when providing text value only' do
        let(:input) { { 'text' => 'foobar' } }

        it_behaves_like 'updating the ticket checklist item'
      end
    end

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

      it_behaves_like 'creating the ticket checklist item'
    end

    context 'when ticket checklist does not exist' do
      let(:variables) { { checklistId: 'gid://Zammad/Checklist/0', input: input } }

      it_behaves_like 'returning an error payload', "Couldn't find Checklist with 'id'=0", 'ActiveRecord::RecordNotFound'
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
