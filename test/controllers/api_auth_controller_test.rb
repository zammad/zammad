
require 'test_helper'

class ApiAuthControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w[Admin Agent])
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create!(
      login: 'api-admin',
      firstname: 'API',
      lastname: 'Admin',
      email: 'api-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create agent
    roles = Role.where(name: 'Agent')
    @agent = User.create!(
      login: 'api-agent@example.com',
      firstname: 'API',
      lastname: 'Agent',
      email: 'api-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create customer without org
    roles = Role.where(name: 'Customer')
    @customer = User.create!(
      login: 'api-customer1@example.com',
      firstname: 'API',
      lastname: 'Customer1',
      email: 'api-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

  end

  test 'basic auth - admin' do

    admin_credentials = ActionController::HttpAuthentication::Basic.encode_credentials('api-admin@example.com', 'adminpw')

    Setting.set('api_password_access', false)
    get '/api/v1/sessions', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(401)
    assert_not(@response.header.key?('Access-Control-Allow-Origin'))
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('API password access disabled!', result['error'])

    Setting.set('api_password_access', true)
    get '/api/v1/sessions', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(200)
    assert_equal('*', @response.header['Access-Control-Allow-Origin'])
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result)
  end

  test 'basic auth - agent' do

    agent_credentials = ActionController::HttpAuthentication::Basic.encode_credentials('api-agent@example.com', 'agentpw')

    Setting.set('api_password_access', false)
    get '/api/v1/tickets', params: {}, headers: @headers.merge('Authorization' => agent_credentials)
    assert_response(401)
    assert_not(@response.header.key?('Access-Control-Allow-Origin'))
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('API password access disabled!', result['error'])

    Setting.set('api_password_access', true)
    get '/api/v1/tickets', params: {}, headers: @headers.merge('Authorization' => agent_credentials)
    assert_response(200)
    assert_equal('*', @response.header['Access-Control-Allow-Origin'])
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)
  end

  test 'basic auth - customer' do

    customer_credentials = ActionController::HttpAuthentication::Basic.encode_credentials('api-customer1@example.com', 'customer1pw')

    Setting.set('api_password_access', false)
    get '/api/v1/tickets', params: {}, headers: @headers.merge('Authorization' => customer_credentials)
    assert_response(401)
    assert_not(@response.header.key?('Access-Control-Allow-Origin'))
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('API password access disabled!', result['error'])

    Setting.set('api_password_access', true)
    get '/api/v1/tickets', params: {}, headers: @headers.merge('Authorization' => customer_credentials)
    assert_response(200)
    assert_equal('*', @response.header['Access-Control-Allow-Origin'])
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)
  end

  test 'token auth - admin' do

    admin_token = Token.create(
      action:      'api',
      persistent:  true,
      user_id:     @admin.id,
      preferences: {
        permission: ['admin.session'],
      },
    )
    admin_credentials = "Token token=#{admin_token.name}"

    Setting.set('api_token_access', false)
    get '/api/v1/sessions', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(401)
    assert_not(@response.header.key?('Access-Control-Allow-Origin'))
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('API token access disabled!', result['error'])

    Setting.set('api_token_access', true)
    get '/api/v1/sessions', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(200)
    assert_equal('*', @response.header['Access-Control-Allow-Origin'])

    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result)

    admin_token.preferences[:permission] = ['admin.session_not_existing']
    admin_token.save!

    get '/api/v1/sessions', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (token)!', result['error'])

    admin_token.preferences[:permission] = []
    admin_token.save!

    get '/api/v1/sessions', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (token)!', result['error'])

    @admin.active = false
    @admin.save!

    get '/api/v1/sessions', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('User is inactive!', result['error'])

    admin_token.preferences[:permission] = ['admin.session']
    admin_token.save!

    get '/api/v1/sessions', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('User is inactive!', result['error'])

    @admin.active = true
    @admin.save!

    get '/api/v1/sessions', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result)

    get '/api/v1/roles', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (token)!', result['error'])

    admin_token.preferences[:permission] = ['admin.session_not_existing', 'admin.role']
    admin_token.save!

    get '/api/v1/roles', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)

    admin_token.preferences[:permission] = ['ticket.agent']
    admin_token.save!

    get '/api/v1/organizations', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)

    name = "some org name #{rand(999_999_999)}"
    post '/api/v1/organizations', params: { name: name }.to_json, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(name, result['name'])
    assert(result)

    name = "some org name #{rand(999_999_999)} - 2"
    put "/api/v1/organizations/#{result['id']}", params: { name: name }.to_json, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(name, result['name'])
    assert(result)

    admin_token.preferences[:permission] = ['admin.organization']
    admin_token.save!

    get '/api/v1/organizations', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)

    name = "some org name #{rand(999_999_999)}"
    post '/api/v1/organizations', params: { name: name }.to_json, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(name, result['name'])
    assert(result)

    name = "some org name #{rand(999_999_999)} - 2"
    put "/api/v1/organizations/#{result['id']}", params: { name: name }.to_json, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(name, result['name'])
    assert(result)

    admin_token.preferences[:permission] = ['admin']
    admin_token.save!

    get '/api/v1/organizations', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)

    name = "some org name #{rand(999_999_999)}"
    post '/api/v1/organizations', params: { name: name }.to_json, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(name, result['name'])
    assert(result)

    name = "some org name #{rand(999_999_999)} - 2"
    put "/api/v1/organizations/#{result['id']}", params: { name: name }.to_json, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(name, result['name'])
    assert(result)

  end

  test 'token auth - agent' do

    agent_token = Token.create(
      action:     'api',
      persistent: true,
      user_id:    @agent.id,
    )
    agent_credentials = "Token token=#{agent_token.name}"

    Setting.set('api_token_access', false)
    get '/api/v1/tickets', params: {}, headers: @headers.merge('Authorization' => agent_credentials)
    assert_response(401)
    assert_not(@response.header.key?('Access-Control-Allow-Origin'))
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('API token access disabled!', result['error'])

    Setting.set('api_token_access', true)
    get '/api/v1/tickets', params: {}, headers: @headers.merge('Authorization' => agent_credentials)
    assert_response(200)
    assert_equal('*', @response.header['Access-Control-Allow-Origin'])
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)

    get '/api/v1/organizations', params: {}, headers: @headers.merge('Authorization' => agent_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)

    name = "some org name #{rand(999_999_999)}"
    post '/api/v1/organizations', params: { name: name }.to_json, headers: @headers.merge('Authorization' => agent_credentials)
    assert_response(401)

  end

  test 'token auth - customer' do

    customer_token = Token.create(
      action:     'api',
      persistent: true,
      user_id:    @customer.id,
    )
    customer_credentials = "Token token=#{customer_token.name}"

    Setting.set('api_token_access', false)
    get '/api/v1/tickets', params: {}, headers: @headers.merge('Authorization' => customer_credentials)
    assert_response(401)
    assert_not(@response.header.key?('Access-Control-Allow-Origin'))
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('API token access disabled!', result['error'])

    Setting.set('api_token_access', true)
    get '/api/v1/tickets', params: {}, headers: @headers.merge('Authorization' => customer_credentials)
    assert_equal('*', @response.header['Access-Control-Allow-Origin'])
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)

    get '/api/v1/organizations', params: {}, headers: @headers.merge('Authorization' => customer_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)

    name = "some org name #{rand(999_999_999)}"
    post '/api/v1/organizations', params: { name: name }.to_json, headers: @headers.merge('Authorization' => customer_credentials)
    assert_response(401)
  end

  test 'token auth - invalid user - admin' do

    admin_token = Token.create(
      action:     'api',
      persistent: true,
      user_id:    @admin.id,
    )
    admin_credentials = "Token token=#{admin_token.name}"

    @admin.active = false
    @admin.save!

    Setting.set('api_token_access', false)
    get '/api/v1/sessions', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(401)
    assert_not(@response.header.key?('Access-Control-Allow-Origin'))
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('API token access disabled!', result['error'])

    Setting.set('api_token_access', true)
    get '/api/v1/sessions', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(401)
    assert_not(@response.header.key?('Access-Control-Allow-Origin'))
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('User is inactive!', result['error'])
  end

  test 'token auth - expired' do

    Setting.set('api_token_access', true)

    admin_token = Token.create(
      action:     'api',
      persistent: true,
      user_id:    @admin.id,
      expires_at: Time.zone.today
    )
    admin_credentials = "Token token=#{admin_token.name}"

    get '/api/v1/tickets', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(401)
    assert_not(@response.header.key?('Access-Control-Allow-Origin'))
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (token expired)!', result['error'])

    admin_token.reload
    assert_in_delta(admin_token.last_used_at, Time.zone.now, 1.second)
  end

  test 'token auth - not expired' do

    Setting.set('api_token_access', true)

    admin_token = Token.create(
      action:     'api',
      persistent: true,
      user_id:    @admin.id,
      expires_at: Time.zone.tomorrow
    )
    admin_credentials = "Token token=#{admin_token.name}"

    get '/api/v1/tickets', params: {}, headers: @headers.merge('Authorization' => admin_credentials)
    assert_response(200)
    assert_equal('*', @response.header['Access-Control-Allow-Origin'])
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)

    admin_token.reload
    assert_in_delta(admin_token.last_used_at, Time.zone.now, 1.second)
  end

  test 'session auth - admin' do

    post '/api/v1/signin', params: { username: 'api-admin@example.com', password: 'adminpw', fingerprint: '123456789' }
    assert_not(@response.header.key?('Access-Control-Allow-Origin'))
    assert_response(201)

    get '/api/v1/sessions', params: {}
    assert_response(200)
    assert_not(@response.header.key?('Access-Control-Allow-Origin'))
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result)
  end
end
