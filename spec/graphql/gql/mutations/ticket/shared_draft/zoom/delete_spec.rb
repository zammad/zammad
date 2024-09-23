# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::SharedDraft::Zoom::Delete, :aggregate_failures, type: :graphql do
  let(:owner)           { create(:user) }
  let(:ticket)          { create(:ticket, owner: owner) }
  let(:shared_draft)    { create(:ticket_shared_draft_zoom, ticket: ticket) }
  let(:shared_draft_id) { gql.id(shared_draft) }

  let(:query) do
    <<~QUERY
      mutation ticketSharedDraftZoomDelete($sharedDraftId: ID!) {
        ticketSharedDraftZoomDelete(sharedDraftId: $sharedDraftId) {
          success
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  before do
    gql.execute(query, variables: { sharedDraftId: shared_draft_id })
  end

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    context 'when agent has no permission on related ticket' do
      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when agent has permission on related ticket' do
      let(:owner) { agent }

      it 'deletes the shared draft zoom' do
        expect { shared_draft.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'returns success' do
        expect(gql.result.data).to include(
          'success' => true,
          'errors'  => be_nil
        )
      end
    end

    context 'when shared draft does not exist' do
      let(:shared_draft_id) do
        id = gql.id(shared_draft)
        shared_draft.destroy

        id
      end

      it 'raises an error' do
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
