# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Checklist', authenticated_as: :agent_1, current_user_id: 1, type: :request do
  let(:group_1)        { create(:group) }
  let(:group_2)        { create(:group) }
  let(:agent_1)        { create(:agent, groups: [group_1]) }
  let(:ticket_1)       { create(:ticket, group: group_1) }
  let(:ticket_2)       { create(:ticket, group: group_2) }
  let(:ticket_1_empty) { create(:ticket, group: group_1) }
  let(:ticket_2_empty) { create(:ticket, group: group_2) }
  let(:checklist_1)    { create(:checklist, ticket: ticket_1) }
  let(:checklist_2)    { create(:checklist, ticket: ticket_2) }

  before do
    Setting.set('checklist', true)
    checklist_1
    checklist_2
  end

  it 'does show checklist', :aggregate_failures do
    get "/api/v1/checklists/#{checklist_1.id}", params: {}, as: :json
    expect(response).to have_http_status(:ok)
    expect(json_response).to include('id' => checklist_1.id)
  end

  it 'does not show inaccessible checklist' do
    get "/api/v1/checklists/#{checklist_2.id}", params: {}, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'does not show nonexistant checklist' do
    get '/api/v1/checklists/1234', params: {}, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'does create checklist', :aggregate_failures do
    post '/api/v1/checklists', params: { name: SecureRandom.uuid, ticket_id: ticket_1_empty.id }, as: :json
    expect(response).to have_http_status(:created)
    expect(json_response).to include('id' => Checklist.last.id)
  end

  it 'does not create checklist' do
    post '/api/v1/checklists', params: { name: SecureRandom.uuid, ticket_id: ticket_2_empty.id }, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'does update checklist', :aggregate_failures do
    put "/api/v1/checklists/#{checklist_1.id}", params: { name: SecureRandom.uuid }, as: :json
    expect(response).to have_http_status(:ok)
    expect(json_response).to include('id' => checklist_1.id)
  end

  it 'does not update checklist' do
    put "/api/v1/checklists/#{checklist_2.id}", params: { name: SecureRandom.uuid }, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'does destroy checklist' do
    delete "/api/v1/checklists/#{checklist_1.id}", params: {}, as: :json
    expect(response).to have_http_status(:ok)
  end

  it 'does not destroy checklist' do
    delete "/api/v1/checklists/#{checklist_2.id}", params: {}, as: :json
    expect(response).to have_http_status(:forbidden)
  end
end
