# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'ActivityStream', type: :request do
  let(:group)              { create(:group) }
  let(:inaccessible_group) { create(:group) }
  let(:agent)              { create(:agent, groups: [group]) }
  let(:ticket)             { create(:ticket, group:, title: 'ticket title') }
  let!(:article)           { create(:ticket_article, ticket:, subject: 'article subject', body: 'article body') }

  let(:entry_ids) do
    [
      ActivityStream.find_by(activity_stream_object_id: ObjectLookup.by_name('Ticket'), o_id: ticket.id).id,
      ActivityStream.find_by(activity_stream_object_id: ObjectLookup.by_name('Ticket::Article'), o_id: article.id).id,
    ]
  end

  describe 'GET /api/v1/activity_stream', authenticated_as: :agent do
    context 'when the ticket is in an accessible group' do
      it 'lists the entries of the ticket and its article', :aggregate_failures do
        get '/api/v1/activity_stream', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response.pluck('id')).to include(*entry_ids)
      end

      it 'ships the assets of the ticket and its article', :aggregate_failures do
        get '/api/v1/activity_stream?full=true', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response.dig('assets', 'Ticket', ticket.id.to_s)).to include('title' => 'ticket title')
        expect(json_response.dig('assets', 'TicketArticle', article.id.to_s)).to include('body' => 'article body')
      end
    end

    context 'when the ticket was moved to an inaccessible group' do
      before do
        entry_ids
        ticket.update!(group: inaccessible_group)
      end

      it 'refuses the ticket itself' do
        get "/api/v1/tickets/#{ticket.id}", as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'does not list the entries of the ticket and its article', :aggregate_failures do
        get '/api/v1/activity_stream', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response.pluck('id')).not_to include(*entry_ids)
      end

      it 'does not list the entries in the expanded representation', :aggregate_failures do
        get '/api/v1/activity_stream?expand=true', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response.pluck('id')).not_to include(*entry_ids)
      end

      it 'does not ship the assets of the ticket and its article', :aggregate_failures do
        get '/api/v1/activity_stream?full=true', as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response.dig('assets', 'Ticket', ticket.id.to_s)).to be_nil
        expect(json_response.dig('assets', 'TicketArticle', article.id.to_s)).to be_nil
      end
    end
  end
end
