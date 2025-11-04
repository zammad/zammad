# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Search', type: :request do

  let(:group) { create(:group) }
  let(:agent) { create(:agent, firstname: 'Search superuniqstring1337', groups: [Group.lookup(name: 'Users'), group]) }

  let(:ticket1) { create(:ticket, title: 'test superuniqstring1337-1', group:) }
  let(:ticket2) { create(:ticket, title: 'test superuniqstring1337-2', group:) }
  let(:ticket3) { create(:ticket, title: 'test superuniqstring1337-2', group:) }

  let(:article1) { create(:ticket_article, ticket_id: ticket1.id) }
  let(:article2) { create(:ticket_article, ticket_id: ticket2.id) }
  let(:article3) { create(:ticket_article, ticket_id: ticket3.id) }

  describe 'request handling', performs_jobs: true, searchindex: true do
    before do
      agent
      article1 && article2 && article3
      searchindex_model_reload([Ticket, User, Organization])
    end

    let(:term) { 'test superuniqstring1337' }
    let(:params) { { query: term } }

    context 'when not logged in' do
      it 'returns authentication error for global search' do
        post '/api/v1/search', params: params, as: :json
        expect(response).to have_http_status(:forbidden)
        expect(json_response).to include('error' => 'Authentication required')
      end

      it 'returns authentication error for object search' do
        post '/api/v1/search/ticket', params: params, as: :json
        expect(response).to have_http_status(:forbidden)
        expect(json_response).to include('error' => 'Authentication required')
      end
    end

    context 'when logged in as authenticated user', authenticated_as: :admin do
      let(:admin) { create(:admin, groups: [Group.lookup(name: 'Users'), group]) }
      let(:term)  { 'superuniqstring1337' }

      it 'passes on limit to search service' do
        params[:limit] = 123

        allow(Service::Search).to receive(:new).and_call_original

        post '/api/v1/search', params: params, as: :json

        expect(Service::Search)
          .to have_received(:new)
          .with(hash_including(options: include(limit: 123)))
      end

      it 'returns flattened search results' do
        post '/api/v1/search', params: params, as: :json

        expect(json_response).to include('result' => contain_exactly(
          include('type' => 'Ticket', 'id' => ticket1.id),
          include('type' => 'Ticket', 'id' => ticket2.id),
          include('type' => 'Ticket', 'id' => ticket3.id),
          include('type' => 'User', 'id' => agent.id),
        ), 'assets' => include_assets_of(ticket1, ticket2, ticket3, agent))
      end

      it 'returns flattened search results when searching for multiple objects' do
        post '/api/v1/search/ticket-user', params: params, as: :json

        expect(json_response).to include('result' => contain_exactly(
          include('type' => 'Ticket', 'id' => ticket1.id),
          include('type' => 'Ticket', 'id' => ticket2.id),
          include('type' => 'Ticket', 'id' => ticket3.id),
          include('type' => 'User', 'id' => agent.id),
        ), 'assets' => include_assets_of(ticket1, ticket2, ticket3, agent))
      end

      it 'returns flattened search results when searching for for a single object' do
        post '/api/v1/search/ticket', params: params, as: :json

        expect(json_response).to include('result' => contain_exactly(
          include('type' => 'Ticket', 'id' => ticket1.id),
          include('type' => 'Ticket', 'id' => ticket2.id),
          include('type' => 'Ticket', 'id' => ticket3.id),
        ), 'assets' => include_assets_of(ticket1, ticket2, ticket3).and(not_include_assets_of(agent)))
      end

      context 'when searching by object' do
        let(:params) { super().merge(by_object: true) }

        it 'returns search results by object' do
          post '/api/v1/search', params: params, as: :json

          expect(json_response).to include('result' => include(
            'Ticket' => include(
              'object_ids'  => contain_exactly(ticket1.id, ticket2.id, ticket3.id),
              'total_count' => 3
            ),
            'User'   => include(
              'object_ids'  => contain_exactly(agent.id),
              'total_count' => 1
            )
          ), 'assets' => include_assets_of(ticket1, ticket2, ticket3, agent))
        end

        it 'returns search results by object when searching for multiple objects' do
          post '/api/v1/search/user-ticket', params: params, as: :json

          expect(json_response).to include('result' => match(
            'Ticket' => include(
              'object_ids'  => contain_exactly(ticket1.id, ticket2.id, ticket3.id),
              'total_count' => 3
            ),
            'User'   => include(
              'object_ids'  => contain_exactly(agent.id),
              'total_count' => 1
            )
          ), 'assets' => include_assets_of(ticket1, ticket2, ticket3, agent))
        end

        it 'returns search results by object when searching for a single object' do
          post '/api/v1/search/user', params: params, as: :json

          expect(json_response).to include('result' => match(
            'User' => include(
              'object_ids'  => contain_exactly(agent.id),
              'total_count' => 1
            )
          ), 'assets' => include_assets_of(agent).and(not_include_assets_of(ticket1, ticket2, ticket3)))
        end
      end
    end
  end

  describe 'getting "undefined method assets for nil:NilClass #5618', searchindex: true do
    before do
      ticket1
      searchindex_model_reload([Ticket, User, Organization])
      ticket1.destroy
    end

    it 'does not throw error if the ticket exists in the search index but not in DB' do
      params = {
        query:     ticket1.number,
        limit:     1,
        by_object: true
      }

      authenticated_as(agent)
      post '/api/v1/search', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['result']['Ticket']['object_ids']).to be_blank
    end
  end
end
