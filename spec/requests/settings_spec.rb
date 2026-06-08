# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    it 'performs masking and unmasking of sensitive settings' do
      idoit_config = {
        api_token: 'some_api_token',
        endpoint:  'https://idoit.example.com/i-doit/',
        client_id: '',
      }

      Setting.set('idoit_config', idoit_config)

      authenticated_as(admin)

      # Masks sensitive data when fetching by value hash key
      setting = Setting.find_by(name: 'idoit_config')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['state_current']['value']['api_token']).to eq(SensitiveParamsHelper::SENSITIVE_MASK)

      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response.find { it['name'] == 'idoit_config' }['state_current']['value']['api_token']).to eq(SensitiveParamsHelper::SENSITIVE_MASK)

      # Unmasks sensitive data when updating by value hask key
      params = {
        id:            setting.id,
        state_current: {
          value: idoit_config.merge(api_token: SensitiveParamsHelper::SENSITIVE_MASK, client_id: 'new_client_id'),
        }
      }
      put "/api/v1/settings/#{setting.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['state_current']['value']['api_token']).to eq(SensitiveParamsHelper::SENSITIVE_MASK)
      expect(Setting.get('idoit_config')).to include(api_token: 'some_api_token', client_id: 'new_client_id')

      # Masks sensitive data when fetching by name
      setting = Setting.find_by(name: 'proxy_password')
      Setting.set('proxy_password', 'some_password')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['state_current']['value']).to eq(SensitiveParamsHelper::SENSITIVE_MASK)

      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response.find { it['name'] == 'proxy_password' }['state_current']['value']).to eq(SensitiveParamsHelper::SENSITIVE_MASK)

      # Unmasks sensitive data when updating by name
      params = {
        id:            setting.id,
        state_current: {
          value: SensitiveParamsHelper::SENSITIVE_MASK,
        }
      }
      put "/api/v1/settings/#{setting.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['state_current']['value']).to eq(SensitiveParamsHelper::SENSITIVE_MASK)
      expect(Setting.get('proxy_password')).to eq('some_password')

      # Updates sensitive data when updating by name
      params = {
        id:            setting.id,
        state_current: {
          value: 'new_password',
        }
      }
      put "/api/v1/settings/#{setting.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['state_current']['value']).to eq(SensitiveParamsHelper::SENSITIVE_MASK)
      expect(Setting.get('proxy_password')).to eq('new_password')

      # Does not mask sensitive-matching names that are in the NOT_SENSITIVE_NAMES list
      setting = Setting.find_by(name: 'user_lost_password')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['state_current']['value']).to be(true)

      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response.find { it['name'] == 'user_lost_password' }['state_current']['value']).to be(true)
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
      expect(json_response['error']).to eq('User authorization failed.')

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('User authorization failed.')
    end

    it 'does settings index with customer' do

      # index
      authenticated_as(customer)
      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['settings']).to be_falsey
      expect(json_response['error']).to eq('User authorization failed.')

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('User authorization failed.')

      # delete
      setting = Setting.find_by(name: 'product_name')
      delete "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('User authorization failed.')
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

    context 'when reset is used', authenticated_as: :admin do
      it 'can not reset protected setting' do
        setting = Setting.find_by(name: 'application_secret')
        post "/api/v1/settings/reset/#{setting.id}", params: {}, as: :json
        expect(response).to have_http_status(:forbidden)
      end

      it 'reset a setting', :aggregate_failures do
        setting = Setting.find_by(name: 'product_name')

        setting.update(state_current: { value: 'Other name' })

        post "/api/v1/settings/reset/#{setting.id}", params: {}, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to be_a(Hash)
        expect(json_response['state_current']).to eq(setting[:state_initial])
      end
    end
  end
end
