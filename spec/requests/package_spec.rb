require 'rails_helper'

RSpec.describe 'Packages', type: :request do

  let(:admin_user) do
    create(:admin_user)
  end
  let(:agent_user) do
    create(:agent_user)
  end
  let(:customer_user) do
    create(:customer_user)
  end

  describe 'request handling' do

    it 'does packages index with nobody' do
      get '/api/v1/packages', as: :json
      expect(response).to have_http_status(:unauthorized)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['packages']).to be_falsey
      expect(json_response['error']).to eq('authentication failed')
    end

    it 'does packages index with admin' do
      authenticated_as(admin_user)
      get '/api/v1/packages', as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['packages']).to be_truthy
    end

    it 'does packages index with admin and wrong pw' do
      authenticated_as(admin_user, password: 'wrongadminpw')
      get '/api/v1/packages', as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('authentication failed')
    end

    it 'does packages index with inactive admin' do
      admin_user = create(:admin_user, active: false, password: 'we need a password here')

      authenticated_as(admin_user)
      get '/api/v1/packages', as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('authentication failed')
    end

    it 'does packages index with agent' do
      authenticated_as(agent_user)
      get '/api/v1/packages', as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['packages']).to be_falsey
      expect(json_response['error']).to eq('Not authorized (user)!')
    end

    it 'does packages index with customer' do
      authenticated_as(customer_user)
      get '/api/v1/packages', as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['packages']).to be_falsey
      expect(json_response['error']).to eq('Not authorized (user)!')
    end
  end
end
