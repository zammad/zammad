# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Checklist::ItemDelete, current_user_id: 1, type: :graphql do
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
          errors {
            message
          }
        }
      }
    QUERY
  end

  let(:variables) { { checklistId: gql.id(checklist), checklistItemId: gql.id(checklist_item) } }

  before do
    setup if defined?(setup)
    gql.execute(query, variables: variables)
  end

  shared_examples 'deleting the ticket checklist item' do
    it 'deletes the ticket checklist item' do
      expect(gql.result.data[:success]).to be(true)
    end
  end

  shared_examples 'raising an error' do |error_type|
    it 'raises an error' do
      expect(gql.result.error_type).to eq(error_type)
    end
  end

  context 'with authenticated session', authenticated_as: :agent do
    it_behaves_like 'deleting the ticket checklist item'

    context 'with disabled checklist feature' do
      let(:setup) do
        Setting.set('checklist', false)
      end

      it_behaves_like 'raising an error', Exceptions::Forbidden
    end

    context 'without access to the ticket' do
      let(:agent) { create(:agent) }

      it_behaves_like 'raising an error', Exceptions::Forbidden
    end

    context 'with ticket read permission' do
      let(:agent) { create(:agent, groups: [group], group_names_access_map: { group.name => 'read' }) }

      it_behaves_like 'raising an error', Pundit::NotAuthorizedError
    end

    context 'with ticket read+change permissions' do
      let(:agent) { create(:agent, groups: [group], group_names_access_map: { group.name => %w[read change] }) }

      it_behaves_like 'deleting the ticket checklist item'
    end

    context 'when ticket checklist does not exist' do
      let(:variables) { { checklistId: 'gid://Zammad/Checklist/0', checklistItemId: gql.id(checklist_item) } }

      it_behaves_like 'raising an error', ActiveRecord::RecordNotFound
    end

    context 'when ticket checklist item does not exist' do
      let(:variables) { { checklistId: gql.id(checklist), checklistItemId: 'gid://Zammad/Checklist::Item/0' } }

      it_behaves_like 'raising an error', ActiveRecord::RecordNotFound
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
