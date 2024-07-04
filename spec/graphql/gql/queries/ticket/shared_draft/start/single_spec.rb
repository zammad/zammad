# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::SharedDraft::Start::Single, type: :graphql do
  let(:group)        { create(:group) }
  let(:shared_draft) { create(:ticket_shared_draft_start, group:) }
  let(:variables)    { { sharedDraftId: gql.id(shared_draft) } }

  let(:query) do
    <<~QUERY
      query ticketSharedDraftStartSingle($sharedDraftId: ID!) {
        ticketSharedDraftStartSingle(sharedDraftId: $sharedDraftId) {
          id
          name
        }
      }
    QUERY
  end

  before do
    gql.execute(query, variables: variables)
  end

  context 'with an agent', authenticated_as: :agent do
    let(:access) { :create }

    let(:agent) do
      create(:agent)
        .tap { |elem| elem.user_groups.create!(group:, access:) if access }
    end

    context 'when agent has access to the draft group' do
      it 'returns the shared draft' do
        expect(gql.result.data).to include('id' => gql.id(shared_draft))
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
