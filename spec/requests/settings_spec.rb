require 'rails_helper'

RSpec.describe 'Settings', type: :request do

  let(:admin_user) do
    create(:admin_user)
  end
  let(:admin_api_user) do
    role_api = create(:role)
    role_api.permission_grant('admin.api')

    create(:admin_user, roles: [role_api])
  end
  let(:agent_user) do
    create(:agent_user)
  end
  let(:customer_user) do
    create(:customer_user)
  end

  describe 'request handling' do

    it 'does settings index with nobody' do

      # index
      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['settings']).to be_falsey

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('authentication failed')
    end

    it 'does settings index with admin' do

      # index
      authenticated_as(admin_user)
      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
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
      expect(hit_api).to eq(true)
      expect(hit_product_name).to eq(true)

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['name']).to eq('product_name')

      setting = Setting.find_by(name: 'api_token_access')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
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
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['name']).to eq('product_name')
      expect(json_response['preferences']['permission'].length).to eq(1)
      expect(json_response['preferences']['permission'][0]).to eq('admin.branding')
      expect(json_response['preferences']['some_new_key']).to eq(true)

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
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['name']).to eq('api_token_access')
      expect(json_response['preferences']['permission'].length).to eq(1)
      expect(json_response['preferences']['permission'][0]).to eq('admin.api')
      expect(json_response['preferences']['some_new_key']).to eq(true)

      # delete
      setting = Setting.find_by(name: 'product_name')
      delete "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Not authorized (feature not possible)')
    end

    it 'does settings index with admin-api' do

      # index
      authenticated_as(admin_api_user)
      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
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
      expect(hit_api).to eq(true)
      expect(hit_product_name).to eq(false)

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Not authorized (required ["admin.branding"])')

      setting = Setting.find_by(name: 'api_token_access')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
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
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Not authorized (required ["admin.branding"])')

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
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['name']).to eq('api_token_access')
      expect(json_response['preferences']['permission'].length).to eq(1)
      expect(json_response['preferences']['permission'][0]).to eq('admin.api')
      expect(json_response['preferences']['some_new_key']).to eq(true)

      # delete
      setting = Setting.find_by(name: 'product_name')
      delete "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Not authorized (feature not possible)')
    end

    it 'does settings index with agent' do

      # index
      authenticated_as(agent_user)
      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['settings']).to be_falsey
      expect(json_response['error']).to eq('Not authorized (user)!')

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Not authorized (user)!')
    end

    it 'does settings index with customer' do

      # index
      authenticated_as(customer_user)
      get '/api/v1/settings', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['settings']).to be_falsey
      expect(json_response['error']).to eq('Not authorized (user)!')

      # show
      setting = Setting.find_by(name: 'product_name')
      get "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Not authorized (user)!')

      # delete
      setting = Setting.find_by(name: 'product_name')
      delete "/api/v1/settings/#{setting.id}", params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Not authorized (user)!')
    end
  end
end
