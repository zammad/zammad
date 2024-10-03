# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Checklist Item', authenticated_as: :agent_1, current_user_id: 1, type: :request do
  let(:group_1)        { create(:group) }
  let(:group_2)        { create(:group) }
  let(:agent_1)        { create(:agent, groups: [group_1]) }
  let(:ticket_1)       { create(:ticket, group: group_1) }
  let(:ticket_2)       { create(:ticket, group: group_2) }
  let(:checklist_1)    { create(:checklist, ticket: ticket_1) }
  let(:checklist_2)    { create(:checklist, ticket: ticket_2) }

  before do
    Setting.set('checklist', true)
    checklist_1
    checklist_2
  end

  it 'does show checklist items', :aggregate_failures do
    get "/api/v1/checklist_items/#{checklist_1.items.first.id}", params: {}, as: :json
    expect(response).to have_http_status(:ok)
    expect(json_response).to include('id' => checklist_1.items.first.id)
  end

  it 'does not show inaccessible checklist items' do
    get "/api/v1/checklist_items/#{checklist_2.items.first.id}", params: {}, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'does not show nonexistant checklist items' do
    get '/api/v1/checklist_items/1234', params: {}, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'does create checklist items', :aggregate_failures do
    post '/api/v1/checklist_items', params: { checklist_id: checklist_1.id, text: SecureRandom.uuid }, as: :json
    expect(response).to have_http_status(:created)
    expect(json_response).to include('id' => Checklist::Item.last.id)
  end

  it 'does not create checklist items' do
    post '/api/v1/checklist_items', params: { checklist_id: checklist_2.id, text: SecureRandom.uuid }, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'does update checklist items', :aggregate_failures do
    put "/api/v1/checklist_items/#{checklist_1.items.first.id}", params: { id: checklist_1.items.first.id, text: SecureRandom.uuid }, as: :json
    expect(response).to have_http_status(:ok)
    expect(json_response).to include('id' => checklist_1.items.first.id)
  end

  it 'does not update checklist items' do
    put "/api/v1/checklist_items/#{checklist_2.items.first.id}", params: { id: checklist_2.items.first.id, text: SecureRandom.uuid }, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'does destroy checklist items' do
    delete "/api/v1/checklist_items/#{checklist_1.items.first.id}", params: {}, as: :json
    expect(response).to have_http_status(:ok)
  end

  it 'does not destroy checklist items' do
    delete "/api/v1/checklist_items/#{checklist_2.items.first.id}", params: {}, as: :json
    expect(response).to have_http_status(:forbidden)
  end
end
