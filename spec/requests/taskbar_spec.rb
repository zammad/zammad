require 'rails_helper'

RSpec.describe 'Taskbars', type: :request do

  let(:agent_user) do
    create(:agent_user)
  end
  let(:customer_user) do
    create(:customer_user)
  end

  describe 'request handling' do

    it 'does task ownership' do
      params = {
        user_id:   customer_user.id,
        client_id: '123',
        key:       'Ticket-5',
        callback:  'TicketZoom',
        state:     {
          ticket:  {
            owner_id: agent_user.id,
          },
          article: {},
        },
        params:    {
          ticket_id: 5,
          shown:     true,
        },
        prio:      3,
        notify:    false,
        active:    false,
      }

      authenticated_as(agent_user)
      post '/api/v1/taskbar', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['client_id']).to eq('123')
      expect(json_response['user_id']).to eq(agent_user.id)
      expect(json_response['params']['ticket_id']).to eq(5)
      expect(json_response['params']['shown']).to eq(true)

      taskbar_id = json_response['id']
      params[:user_id] = customer_user.id
      params[:params] = {
        ticket_id: 5,
        shown:     false,
      }
      put "/api/v1/taskbar/#{taskbar_id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['client_id']).to eq('123')
      expect(json_response['user_id']).to eq(agent_user.id)
      expect(json_response['params']['ticket_id']).to eq(5)
      expect(json_response['params']['shown']).to eq(false)

      # try to access with other user
      params = {
        active: true,
      }

      authenticated_as(customer_user)
      put "/api/v1/taskbar/#{taskbar_id}", params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not allowed to access this task.')

      delete "/api/v1/taskbar/#{taskbar_id}", params: {}, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not allowed to access this task.')

      # delete with correct user
      authenticated_as(agent_user)
      delete "/api/v1/taskbar/#{taskbar_id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_blank
    end
  end
end
