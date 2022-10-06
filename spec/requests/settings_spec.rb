# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Settings', type: :request do

  let(:admin) do
    create(:admin)
  end
  let(:admin_api) do
    role_api = create(:role)
    role_api.permission_grant('admin.api')

    create(:admin, roles: [role_api])
  end
  let(:agent) do
    create(:agent)
  end
  let(:customer) do
    create(:customer)
  end

  describe 'request handling' do

    it 'does settings index with nobody' do

      # index
      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['settings']).to be_falsey

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Authentication required')
    end

    it 'does settings index with admin' do

      # index
      authenticated_as(admin)
      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy
      hit_api = false
      hit_product_name = false
      json_response.each do |setting|
        if setting['name'] == 'api_token_access'
          hit_api = true
        end
        if setting['name'] == 'product_name'
          hit_product_name = true
        end
      end
      expect(hit_api).to be(true)
      expect(hit_product_name).to be(true)

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq('product_name')

      setting = Setting.find_by(name: 'api_token_access')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq('api_token_access')

      # update
      setting = Setting.find_by(name: 'product_name')
      params = {
        id:          setting.id,
        name:        'some_new_name',
        preferences: {
          permission:   ['admin.branding', 'admin.some_new_permission'],
          some_new_key: true,
        }
      }
      put "/api/v1/settings/#{setting.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq('product_name')
      expect(json_response['preferences']['permission'].length).to eq(1)
      expect(json_response['preferences']['permission'][0]).to eq('admin.branding')
      expect(json_response['preferences']['some_new_key']).to be(true)

      # update
      setting = Setting.find_by(name: 'api_token_access')
      params = {
        id:          setting.id,
        name:        'some_new_name',
        preferences: {
          permission:   ['admin.branding', 'admin.some_new_permission'],
          some_new_key: true,
        }
      }
      put "/api/v1/settings/#{setting.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq('api_token_access')
      expect(json_response['preferences']['permission'].length).to eq(1)
      expect(json_response['preferences']['permission'][0]).to eq('admin.api')
      expect(json_response['preferences']['some_new_key']).to be(true)

      # delete
      setting = Setting.find_by(name: 'product_name')
      delete "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Not authorized (feature not possible)')
    end

    it 'does settings index with admin-api' do

      # index
      authenticated_as(admin_api)
      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy
      hit_api = false
      hit_product_name = false
      json_response.each do |setting|
        if setting['name'] == 'api_token_access'
          hit_api = true
        end
        if setting['name'] == 'product_name'
          hit_product_name = true
        end
      end
      expect(hit_api).to be(true)
      expect(hit_product_name).to be(false)

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Not authorized (required ["admin.branding"])!')

      setting = Setting.find_by(name: 'api_token_access')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq('api_token_access')

      # update
      setting = Setting.find_by(name: 'product_name')
      params = {
        id:          setting.id,
        name:        'some_new_name',
        preferences: {
          permission:   ['admin.branding', 'admin.some_new_permission'],
          some_new_key: true,
        }
      }
      put "/api/v1/settings/#{setting.id}", params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Not authorized (required ["admin.branding"])!')

      # update
      setting = Setting.find_by(name: 'api_token_access')
      params = {
        id:          setting.id,
        name:        'some_new_name',
        preferences: {
          permission:   ['admin.branding', 'admin.some_new_permission'],
          some_new_key: true,
        }
      }
      put "/api/v1/settings/#{setting.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['name']).to eq('api_token_access')
      expect(json_response['preferences']['permission'].length).to eq(1)
      expect(json_response['preferences']['permission'][0]).to eq('admin.api')
      expect(json_response['preferences']['some_new_key']).to be(true)

      # delete
      setting = Setting.find_by(name: 'product_name')
      delete "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Not authorized (feature not possible)')
    end

    it 'does settings index with agent' do

      # index
      authenticated_as(agent)
      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['settings']).to be_falsey
      expect(json_response['error']).to eq('Not authorized (user)!')

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Not authorized (user)!')
    end

    it 'does settings index with customer' do

      # index
      authenticated_as(customer)
      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['settings']).to be_falsey
      expect(json_response['error']).to eq('Not authorized (user)!')

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Not authorized (user)!')

      # delete
      setting = Setting.find_by(name: 'product_name')
      delete "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Not authorized (user)!')
    end

    it 'protected setting not existing in list' do
      authenticated_as(admin)
      get '/api/v1/settings', params: {}, as: :json
      expect(json_response.detect { |setting| setting['name'] == 'application_secret' }).to be_nil
    end

    it 'can not show protected setting' do
      setting = Setting.find_by(name: 'application_secret')
      authenticated_as(admin)
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'can not update protected setting' do
      setting = Setting.find_by(name: 'application_secret')
      params = {
        id:    setting.id,
        state: 'Examaple'
      }
      put "/api/v1/settings/#{setting.id}", params: params, as: :json

      authenticated_as(admin)
      put "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
