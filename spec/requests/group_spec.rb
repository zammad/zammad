# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Group', authenticated_as: -> { user }, type: :request do
  describe 'Zammad returns stack error when one tries to remove groups via API #3841' do
    let(:group)  { create(:group) }
    let(:ticket) { create(:ticket, group: group) }
    let(:user)   { create(:admin) }

    before do
      ticket
    end

    it 'does return reference error on delete if related objects exist' do
      delete "/api/v1/groups/#{group.id}", params: {}, as: :json
      expect(json_response['error']).to eq("Can't delete, object has references.")
    end
  end

  describe 'search index is updated inline on request', searchindex: true do
    let(:user) { create(:admin) }

    def search_ids(query)
      Group.search(query: query, current_user: user).map(&:id)
    end

    context 'when the client asks for it' do
      before do
        add_headers('X-Zammad-Search-Index-Inline' => 'true')
      end

      it 'finds a created group', :aggregate_failures do
        post '/api/v1/groups', params: { name: 'Searchable Group' }, as: :json

        expect(response).to have_http_status(:created)
        expect(response.headers['X-Zammad-Search-Index-Updated']).to eq('true')
        expect(search_ids('Searchable')).to eq([json_response['id']])
      end

      it 'reports a failed inline update', :aggregate_failures do
        allow(SearchIndexBackend).to receive(:update_inline).and_raise('Elasticsearch is not available')

        post '/api/v1/groups', params: { name: 'Searchable Group' }, as: :json

        expect(response).to have_http_status(:created)
        expect(response.headers['X-Zammad-Search-Index-Updated']).to eq('false')
      end

      it 'finds an updated group', :aggregate_failures do
        group = create(:group, name: 'Searchable Group')

        put "/api/v1/groups/#{group.id}", params: { name: 'Renamed Group' }, as: :json

        expect(response).to have_http_status(:ok)
        expect(search_ids('Renamed')).to eq([group.id])
      end
    end

    context 'when the client does not ask for it' do
      it 'leaves indexing to the background job', :aggregate_failures do
        post '/api/v1/groups', params: { name: 'Searchable Group' }, as: :json

        expect(response).to have_http_status(:created)
        expect(response.headers).not_to have_key('X-Zammad-Search-Index-Updated')
        expect(search_ids('Searchable')).to be_empty
      end
    end
  end
end
