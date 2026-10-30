# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Shared Draft consumption API endpoints', type: :request do

  let(:group) { create(:group, shared_drafts: true) }

  let(:agent) do
    user = create(:agent)
    user.user_groups.create! group: group, access: :full
    user
  end

  let(:agent_without_access) { create(:agent) }
  let(:customer)             { create(:customer) }

  describe 'POST /api/v1/tickets with a shared start draft' do
    let(:draft) { create(:ticket_shared_draft_start, group: group) }

    let(:params) do
      {
        title:           'ticket from a shared draft',
        group_id:        group.id,
        customer_id:     customer.id,
        shared_draft_id: draft.id,
        article:         {
          content_type: 'text/plain',
          body:         'some body',
        },
      }
    end

    context 'when the user has no access to the draft group', authenticated_as: :customer do
      it 'does not destroy the draft' do
        expect { post '/api/v1/tickets', params: params, as: :json }
          .not_to change { Ticket::SharedDraftStart.exists? draft.id }
      end

      it 'answers with unprocessable content' do
        post '/api/v1/tickets', params: params, as: :json

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    # This case is already covered by the surrounding transaction: the agent
    #   cannot create the ticket, so the destroy is rolled back. Kept to catch a
    #   future change that consumes the draft outside of the transaction.
    context 'when an agent has no create access to the draft group', authenticated_as: :agent_without_access do
      it 'does not destroy the draft' do
        expect { post '/api/v1/tickets', params: params, as: :json }
          .not_to change { Ticket::SharedDraftStart.exists? draft.id }
      end
    end

    context 'when the agent has create access to the draft group', authenticated_as: :agent do
      it 'creates the ticket' do
        post '/api/v1/tickets', params: params, as: :json

        expect(response).to have_http_status(:created)
      end

      it 'destroys the draft' do
        expect { post '/api/v1/tickets', params: params, as: :json }
          .to change { Ticket::SharedDraftStart.exists? draft.id }.to(false)
      end
    end
  end

  describe 'PUT /api/v1/tickets/:id with a shared zoom draft' do
    let(:ticket) { create(:ticket, group: group, customer: customer) }
    let(:draft)  { create(:ticket_shared_draft_zoom, ticket: ticket) }

    let(:params) do
      {
        article: {
          content_type:    'text/plain',
          body:            'some body',
          shared_draft_id: draft.id,
        },
      }
    end

    context 'when the customer of the ticket follows up', authenticated_as: :customer do
      it 'does not destroy the draft' do
        expect { put "/api/v1/tickets/#{ticket.id}", params: params, as: :json }
          .not_to change { Ticket::SharedDraftZoom.exists? draft.id }
      end

      it 'answers with forbidden' do
        put "/api/v1/tickets/#{ticket.id}", params: params, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when the agent may update the ticket', authenticated_as: :agent do
      it 'updates the ticket' do
        put "/api/v1/tickets/#{ticket.id}", params: params, as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'destroys the draft' do
        expect { put "/api/v1/tickets/#{ticket.id}", params: params, as: :json }
          .to change { Ticket::SharedDraftZoom.exists? draft.id }.to(false)
      end
    end
  end
end
