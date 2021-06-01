# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mention', type: :request, authenticated_as: -> { user } do
  let(:group) { create(:group) }
  let(:ticket1) { create(:ticket, group: group) }
  let(:ticket2) { create(:ticket, group: group) }
  let(:ticket3) { create(:ticket, group: group) }
  let(:ticket4) { create(:ticket, group: group) }
  let(:user) { create(:agent, groups: [group]) }

  describe 'GET /api/v1/mentions' do
    before do
      create(:mention, mentionable: ticket1, user: user)
      create(:mention, mentionable: ticket2, user: user)
      create(:mention, mentionable: ticket3, user: user)
    end

    it 'returns good status code' do
      get '/api/v1/mentions', params: {}, as: :json
      expect(response).to have_http_status(:ok)
    end

    it 'returns mentions by user' do
      get '/api/v1/mentions', params: {}, as: :json
      expect(json_response['mentions'].count).to eq(3)
    end

    it 'returns mentions by mentionable' do
      get '/api/v1/mentions', params: { mentionable_type: 'Ticket', mentionable_id: ticket3.id }, as: :json
      expect(json_response['mentions'].count).to eq(1)
    end

    it 'returns mentions by id' do
      mention = create(:mention, mentionable: ticket4, user: user)
      get '/api/v1/mentions', params: { id: mention.id }, as: :json
      expect(json_response['mentions'].count).to eq(1)
    end
  end

  describe 'POST /api/v1/mentions' do

    let(:params) do
      {
        mentionable_type: 'Ticket',
        mentionable_id:   ticket1.id
      }
    end

    it 'returns good status code for subscribe' do
      post '/api/v1/mentions', params: params, as: :json
      expect(response).to have_http_status(:created)
    end

    it 'updates mention count' do
      expect { post '/api/v1/mentions', params: params, as: :json }.to change(Mention, :count).from(0).to(1)
    end
  end

  describe 'DELETE /api/v1/mentions/:id' do

    let!(:mention) { create(:mention, user: user) }

    it 'returns good status code' do
      delete "/api/v1/mentions/#{mention.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
    end

    it 'clears mention count' do
      expect { delete "/api/v1/mentions/#{mention.id}", params: {}, as: :json }.to change(Mention, :count).from(1).to(0)
    end
  end
end
