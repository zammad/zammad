# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::SharedDraft::Start::List, type: :graphql do
  let(:group)                { create(:group) }
  let(:shared_draft)         { create(:ticket_shared_draft_start, group:) }
  let(:another_shared_draft) { create(:ticket_shared_draft_start) }
  let(:variables)            { { groupId: gql.id(group) } }

  let(:query) do
    <<~QUERY
      query ticketSharedDraftStartList($groupId: ID!) {
        ticketSharedDraftStartList(groupId: $groupId) {
          id
          name
        }
      }
    QUERY
  end

  before do
    shared_draft && another_shared_draft

    gql.execute(query, variables: variables)
  end

  context 'with an agent', authenticated_as: :agent do
    let(:access) { :create }
    let(:agent) do
      create(:agent)
        .tap { |elem| elem.user_groups.create!(group:, access:) if access }
    end

    context 'when agent has access to the given group' do
      context 'when shared drafts are enabled' do
        it 'lists shared drafts in the given group' do
          expect(gql.result.data)
            .to contain_exactly(include('id' => gql.id(shared_draft)))
        end
      end

      context 'when shared drafts not enabled' do
        let(:group) { create(:group, shared_drafts: false) }

        it 'raises an error' do
          expect(gql.result.error_message).to eq('Shared drafts are not activated for the selected group')
        end
      end
    end

    context 'when agent has insufficient access to the given group' do
      let(:access) { 'read' }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when agent has no access to the given group' do
      let(:access) { false }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
