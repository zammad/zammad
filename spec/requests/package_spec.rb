# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
      expect(json_response['error']).to eq('User authorization failed.')
    end

    it 'does packages index with customer' do
      authenticated_as(customer)
      get '/api/v1/packages', as: :json

      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['packages']).to be_falsey
      expect(json_response['error']).to eq('User authorization failed.')
    end
  end

  describe 'request handling in container environments' do

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ZAMMAD_DOCKER').and_return('true')
      authenticated_as(admin)
    end

    it 'does packages index with admin' do
      get '/api/v1/packages', as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response['packages']).to be_truthy
    end

    it 'refuses package install' do
      post '/api/v1/packages', as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to eq('Installing, updating or uninstalling packages is not possible in container environments.')
    end

    it 'refuses package uninstall' do
      delete '/api/v1/packages', as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'refuses package install via api' do
      post '/api/v1/packages/api', as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'refuses package update via api' do
      put '/api/v1/packages/api', as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
