# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Checklist::TitleUpdate, current_user_id: 1, type: :graphql do
  let(:group)     { create(:group) }
  let(:agent)     { create(:agent, groups: [group]) }
  let(:ticket)    { create(:ticket, group: group) }
  let(:checklist) { create(:checklist, ticket: ticket) }
  let(:title)     { 'foobar' }

  let(:query) do
    <<~QUERY
      mutation ticketChecklistTitleUpdate($checklistId: ID!, $title: String) {
        ticketChecklistTitleUpdate(checklistId: $checklistId, title: $title) {
          checklist {
            id
            name
          }
          errors {
            message
          }
        }
      }
    QUERY
  end

  let(:variables) { { checklistId: gql.id(checklist), title: title } }

  before do
    setup if defined?(setup)
    gql.execute(query, variables: variables)
  end

  shared_examples 'updating the ticket checklist title' do
    it 'updates the ticket checklist title' do
      expect(gql.result.data[:checklist][:name]).to eq(title)
    end
  end

  shared_examples 'raising an error' do |error_type|
    it 'raises an error' do
      expect(gql.result.error_type).to eq(error_type)
    end
  end

  context 'with authenticated session', authenticated_as: :agent do
    it_behaves_like 'updating the ticket checklist title'

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

      it_behaves_like 'updating the ticket checklist title'
    end

    context 'when ticket checklist does not exist' do
      let(:variables) { { checklistId: 'gid://Zammad/Checklist/0', title: title } }

      it_behaves_like 'raising an error', ActiveRecord::RecordNotFound
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
