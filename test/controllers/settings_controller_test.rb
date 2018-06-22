
require 'test_helper'

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w[Admin Agent])
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin_full = User.create!(
      login: 'setting-admin',
      firstname: 'Setting',
      lastname: 'Admin',
      email: 'setting-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    role_api = Role.create!(
      name: 'AdminApi',
      note: 'To configure your api.',
      preferences: {
        not: ['Customer'],
      },
      default_at_signup: false,
      updated_by_id: 1,
      created_by_id: 1
    )
    role_api.permission_grant('admin.api')
    @admin_api = User.create!(
      login: 'setting-admin-api',
      firstname: 'Setting',
      lastname: 'Admin Api',
      email: 'setting-admin-api@example.com',
      password: 'adminpw',
      active: true,
      roles: [role_api],
      groups: groups,
    )

    # create agent
    roles = Role.where(name: 'Agent')
    @agent = User.create!(
      login: 'setting-agent@example.com',
      firstname: 'Setting',
      lastname: 'Agent',
      email: 'setting-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create customer without org
    roles = Role.where(name: 'Customer')
    @customer_without_org = User.create!(
      login: 'setting-customer1@example.com',
      firstname: 'Setting',
      lastname: 'Customer1',
      email: 'setting-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

  end

  test 'settings index with nobody' do

    # index
    get '/api/v1/settings', params: {}, headers: @headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['settings'])

    # show
    setting = Setting.find_by(name: 'product_name')
    get "/api/v1/settings/#{setting.id}", params: {}, headers: @headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('authentication failed', result['error'])
  end

  test 'settings index with admin' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('setting-admin@example.com', 'adminpw')

    # index
    get '/api/v1/settings', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)
    hit_api = false
    hit_product_name = false
    result.each do |setting|
      if setting['name'] == 'api_token_access'
        hit_api = true
      end
      if setting['name'] == 'product_name'
        hit_product_name = true
      end
    end
    assert_equal(true, hit_api)
    assert_equal(true, hit_product_name)

    # show
    setting = Setting.find_by(name: 'product_name')
    get "/api/v1/settings/#{setting.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('product_name', result['name'])

    setting = Setting.find_by(name: 'api_token_access')
    get "/api/v1/settings/#{setting.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('api_token_access', result['name'])

    # update
    setting = Setting.find_by(name: 'product_name')
    params = {
      id: setting.id,
      name: 'some_new_name',
      preferences: {
        permission: ['admin.branding', 'admin.some_new_permission'],
        some_new_key: true,
      }
    }
    put "/api/v1/settings/#{setting.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('product_name', result['name'])
    assert_equal(1, result['preferences']['permission'].length)
    assert_equal('admin.branding', result['preferences']['permission'][0])
    assert_equal(true, result['preferences']['some_new_key'])

    # update
    setting = Setting.find_by(name: 'api_token_access')
    params = {
      id: setting.id,
      name: 'some_new_name',
      preferences: {
        permission: ['admin.branding', 'admin.some_new_permission'],
        some_new_key: true,
      }
    }
    put "/api/v1/settings/#{setting.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('api_token_access', result['name'])
    assert_equal(1, result['preferences']['permission'].length)
    assert_equal('admin.api', result['preferences']['permission'][0])
    assert_equal(true, result['preferences']['some_new_key'])

    # delete
    setting = Setting.find_by(name: 'product_name')
    delete "/api/v1/settings/#{setting.id}", params: {}.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('Not authorized (feature not possible)', result['error'])
  end

  test 'settings index with admin-api' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('setting-admin-api@example.com', 'adminpw')

    # index
    get '/api/v1/settings', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)
    hit_api = false
    hit_product_name = false
    result.each do |setting|
      if setting['name'] == 'api_token_access'
        hit_api = true
      end
      if setting['name'] == 'product_name'
        hit_product_name = true
      end
    end
    assert_equal(true, hit_api)
    assert_equal(false, hit_product_name)

    # show
    setting = Setting.find_by(name: 'product_name')
    get "/api/v1/settings/#{setting.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('Not authorized (required ["admin.branding"])', result['error'])

    setting = Setting.find_by(name: 'api_token_access')
    get "/api/v1/settings/#{setting.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('api_token_access', result['name'])

    # update
    setting = Setting.find_by(name: 'product_name')
    params = {
      id: setting.id,
      name: 'some_new_name',
      preferences: {
        permission: ['admin.branding', 'admin.some_new_permission'],
        some_new_key: true,
      }
    }
    put "/api/v1/settings/#{setting.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('Not authorized (required ["admin.branding"])', result['error'])

    # update
    setting = Setting.find_by(name: 'api_token_access')
    params = {
      id: setting.id,
      name: 'some_new_name',
      preferences: {
        permission: ['admin.branding', 'admin.some_new_permission'],
        some_new_key: true,
      }
    }
    put "/api/v1/settings/#{setting.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('api_token_access', result['name'])
    assert_equal(1, result['preferences']['permission'].length)
    assert_equal('admin.api', result['preferences']['permission'][0])
    assert_equal(true, result['preferences']['some_new_key'])

    # delete
    setting = Setting.find_by(name: 'product_name')
    delete "/api/v1/settings/#{setting.id}", params: {}.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('Not authorized (feature not possible)', result['error'])
  end

  test 'settings index with agent' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('setting-agent@example.com', 'agentpw')

    # index
    get '/api/v1/settings', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['settings'])
    assert_equal('Not authorized (user)!', result['error'])

    # show
    setting = Setting.find_by(name: 'product_name')
    get "/api/v1/settings/#{setting.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('Not authorized (user)!', result['error'])
  end

  test 'settings index with customer' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('setting-customer1@example.com', 'customer1pw')

    # index
    get '/api/v1/settings', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['settings'])
    assert_equal('Not authorized (user)!', result['error'])

    # show
    setting = Setting.find_by(name: 'product_name')
    get "/api/v1/settings/#{setting.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('Not authorized (user)!', result['error'])

    # delete
    setting = Setting.find_by(name: 'product_name')
    delete "/api/v1/settings/#{setting.id}", params: {}.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('Not authorized (user)!', result['error'])
  end

end
