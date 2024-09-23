# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::SharedDraft::Zoom::Show, type: :graphql do
  let(:owner)             { create(:user) }
  let(:ticket)            { create(:ticket, owner: owner) }
  let(:shared_draft_zoom) { create(:ticket_shared_draft_zoom, ticket: ticket) }
  let(:variables)         { { sharedDraftId: gql.id(shared_draft_zoom) } }

  let(:query) do
    <<~QUERY
      query ticketSharedDraftZoomShow($sharedDraftId: ID!) {
        ticketSharedDraftZoomShow(sharedDraftId: $sharedDraftId) {
          id
          ticketId
          newArticle
          ticketAttributes
        }
      }
    QUERY
  end

  before do
    gql.execute(query, variables: variables)
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

      it 'returns the shared draft zoom' do
        expect(gql.result.data).to include(
          'id'               => gql.id(shared_draft_zoom),
          'ticketId'         => gql.id(shared_draft_zoom.ticket),
          'newArticle'       => shared_draft_zoom.new_article.merge('body' => ''),
          'ticketAttributes' => shared_draft_zoom.ticket_attributes
        )
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
