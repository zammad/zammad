# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Packages', type: :request do

  let(:admin) do
    create(:admin)
  end
  let(:agent) do
    create(:agent)
  end
  let(:customer) do
    create(:customer)
  end

  describe 'request handling' do

    it 'does packages index with nobody' do
      get '/api/v1/packages', as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a(Hash)
      expect(json_response['packages']).to be_falsey
      expect(json_response['error']).to eq('Authentication required')
    end

    it 'does packages index with admin' do
      authenticated_as(admin)
      get '/api/v1/packages', as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['packages']).to be_truthy
    end

    it 'does packages index with admin and wrong pw' do
      authenticated_as(admin, password: 'wrongadminpw')
      get '/api/v1/packages', as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Invalid BasicAuth credentials')
    end

    it 'does packages index with inactive admin' do
      admin = create(:admin, active: false, password: 'we need a password here')

      authenticated_as(admin, password: 'wrong password')
      get '/api/v1/packages', as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Invalid BasicAuth credentials')
    end

    it 'does packages index with agent' do
      authenticated_as(agent)
      get '/api/v1/packages', as: :json

      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['packages']).to be_falsey
      expect(json_response['error']).to eq('Not authorized (user)!')
    end

    it 'does packages index with customer' do
      authenticated_as(customer)
      get '/api/v1/packages', as: :json

      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['packages']).to be_falsey
      expect(json_response['error']).to eq('Not authorized (user)!')
    end
  end
end
