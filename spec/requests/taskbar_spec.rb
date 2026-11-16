# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Taskbars', type: :request do

  let(:agent) do
    create(:agent)
  end
  let(:customer) do
    create(:customer)
  end

  describe 'request handling' do

    it 'does task ownership' do
      params = {
        user_id:  customer.id,
        key:      'Ticket-5',
        callback: 'TicketZoom',
        state:    {
          ticket:  {
            owner_id: agent.id,
          },
          article: {},
        },
        params:   {
          ticket_id: 5,
          shown:     true,
        },
        prio:     3,
        notify:   false,
        active:   false,
      }

      authenticated_as(agent)
      post '/api/v1/taskbar', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)
      expect(json_response['user_id']).to eq(agent.id)
      expect(json_response['params']['ticket_id']).to eq(5)
      expect(json_response['params']['shown']).to be(true)

      taskbar_id = json_response['id']
      params[:user_id] = customer.id
      params[:params] = {
        ticket_id: 5,
        shown:     false,
      }
      put "/api/v1/taskbar/#{taskbar_id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['user_id']).to eq(agent.id)
      expect(json_response['params']['ticket_id']).to eq(5)
      expect(json_response['params']['shown']).to be(false)

      # try to access with other user
      params = {
        active: true,
      }

      authenticated_as(customer)
      put "/api/v1/taskbar/#{taskbar_id}", params: params, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Not allowed to access this task.')

      delete "/api/v1/taskbar/#{taskbar_id}", params: {}, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Not allowed to access this task.')

      # delete with correct user
      authenticated_as(agent)
      delete "/api/v1/taskbar/#{taskbar_id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).to be_blank
    end
  end

  describe 'GET /api/v1/taskbar/:id', authenticated_as: :agent do
    let!(:taskbar) { create(:taskbar, user: agent) }

    it 'returns the requested taskbar' do
      expect { get "/api/v1/taskbar/#{taskbar.id}", as: :json }.not_to change(Taskbar, :count)

      expect(response).to have_http_status(:ok)
      expect(json_response).to include('id' => taskbar.id, 'user_id' => agent.id, 'key' => taskbar.key)
    end

    it 'does not create a taskbar from request params' do
      params = {
        user_id:  customer.id,
        key:      'Ticket-12345',
        callback: 'TicketZoom',
        params:   { ticket_id: 12_345 },
        prio:     1,
      }

      expect { get "/api/v1/taskbar/#{taskbar.id}", params: params, as: :json }.not_to change(Taskbar, :count)

      expect(response).to have_http_status(:ok)
      expect(json_response).to include('id' => taskbar.id, 'key' => taskbar.key)
      expect(customer.taskbars).to be_empty
    end

    it 'refuses a taskbar of another user' do
      other_taskbar = create(:taskbar, user: customer)

      get "/api/v1/taskbar/#{other_taskbar.id}", as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to eq('Not allowed to access this task.')
    end

    it 'returns not found for an unknown taskbar' do
      get "/api/v1/taskbar/#{Taskbar.maximum(:id) + 1}", as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'Init', authenticated_as: :agent do
    let(:tickets)       { create_list(:ticket, 3, group: Group.first) }
    let(:customers)     { create_list(:customer, 3) }
    let(:organizations) { create_list(:organization, 3) }
    let(:agent)         { create(:agent, groups: [Group.first]) }

    before do
      tickets.each do |ticket|
        create(:taskbar, key: "Ticket-#{ticket.id}", params: { ticket_id: ticket.id }, user_id: agent.id)
      end
      customers.each do |customer|
        create(:taskbar, key: "User-#{customer.id}", callback: 'UserProfile', params: { user_id: customer.id }, user_id: agent.id)
      end
      organizations.each do |organization|
        create(:taskbar, key: "Organization-#{organization.id}", callback: 'OrganizationProfile', params: { organization_id: organization.id }, user_id: agent.id)
      end
    end

    it 'does return ticket create data' do
      get '/api/v1/taskbar/init', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['ticket_create']).to be_present
    end

    it 'does return tickets' do
      get '/api/v1/taskbar/init', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['assets']).to include_assets_of(*tickets)
    end

    it 'does return user profiles' do
      get '/api/v1/taskbar/init', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['assets']).to include_assets_of(*customers)
    end

    it 'does return user profile stats' do
      get '/api/v1/taskbar/init', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['ticket_stats_user'].keys.map(&:to_i)).to include(*customers.pluck(:id))
    end

    it 'does return organization profiles' do
      get '/api/v1/taskbar/init', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['assets']).to include_assets_of(*organizations)
    end

    it 'does return organization profile stats' do
      get '/api/v1/taskbar/init', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['ticket_stats_organization'].keys.map(&:to_i)).to include(*organizations.pluck(:id))
    end
  end
end
