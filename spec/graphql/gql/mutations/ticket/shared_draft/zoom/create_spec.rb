# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::SharedDraft::Zoom::Create, type: :graphql do
  let(:agent)             { create(:agent) }
  let(:ticket)            { create(:ticket) }
  let(:form_id)           { '123' }
  let(:new_article)       { { new_article: true } }
  let(:ticket_attributes) { { ticket_attributes: true } }

  let(:variables) do
    {
      input: {
        formId:           form_id,
        ticketId:         gql.id(ticket),
        newArticle:       new_article,
        ticketAttributes: ticket_attributes
      }
    }
  end

  let(:query) do
    <<~QUERY
      mutation ticketSharedDraftZoomCreate($input: TicketSharedDraftZoomInput!) {
        ticketSharedDraftZoomCreate(input: $input) {
          sharedDraft {
            id
          }
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  before do
    gql.execute(query, variables:)
  end

  it_behaves_like 'graphql responds with error if unauthenticated'

  context 'with an agent', authenticated_as: :agent do
    context 'with insufficient access to the draft related ticket' do
      it 'fails with error message' do
        expect(gql.result.error_message).to eq('Access forbidden by Gql::Types::TicketType')
      end

      it 'fails with error type' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'with sufficient access to the draft related ticket' do
      let(:agent) do
        create(:agent).tap do |agent|
          agent.user_groups.create! group: ticket.group, access: :full
        end
      end

      it 'creates a shared draft' do
        draft = Gql::ZammadSchema.verified_object_from_id(
          gql.result.data.dig('sharedDraft', 'id'),
          type: Ticket::SharedDraftZoom
        )

        expect(draft).to have_attributes(ticket_id: ticket.id, new_article:, ticket_attributes:)
      end
    end
  end
end
