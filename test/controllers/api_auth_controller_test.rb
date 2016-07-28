# encoding: utf-8
require 'test_helper'

class ApiAuthControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w(Admin Agent))
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create_or_update(
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
    @agent = User.create_or_update(
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
    @customer = User.create_or_update(
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
    get '/api/v1/settings', {}, @headers.merge('Authorization' => admin_credentials)
    assert_response(401)

    Setting.set('api_password_access', true)
    get '/api/v1/settings', {}, @headers.merge('Authorization' => admin_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)

  end

  test 'basic auth - agent' do

    agent_credentials = ActionController::HttpAuthentication::Basic.encode_credentials('api-agent@example.com', 'agentpw')

    Setting.set('api_password_access', false)
    get '/api/v1/tickets', {}, @headers.merge('Authorization' => agent_credentials)
    assert_response(401)

    Setting.set('api_password_access', true)
    get '/api/v1/tickets', {}, @headers.merge('Authorization' => agent_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)

  end

  test 'basic auth - customer' do

    customer_credentials = ActionController::HttpAuthentication::Basic.encode_credentials('api-customer1@example.com', 'customer1pw')

    Setting.set('api_password_access', false)
    get '/api/v1/tickets', {}, @headers.merge('Authorization' => customer_credentials)
    assert_response(401)

    Setting.set('api_password_access', true)
    get '/api/v1/tickets', {}, @headers.merge('Authorization' => customer_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)

  end

  test 'token auth - admin' do

    admin_token = Token.create(
      action:     'api',
      persistent: true,
      user_id:    @admin.id,
    )
    admin_credentials = "Token token=#{admin_token.name}"

    Setting.set('api_token_access', false)
    get '/api/v1/settings', {}, @headers.merge('Authorization' => admin_credentials)
    assert_response(401)

    Setting.set('api_token_access', true)
    get '/api/v1/settings', {}, @headers.merge('Authorization' => admin_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
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
    get '/api/v1/tickets', {}, @headers.merge('Authorization' => agent_credentials)
    assert_response(401)

    Setting.set('api_token_access', true)
    get '/api/v1/tickets', {}, @headers.merge('Authorization' => agent_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)

  end

  test 'token auth - customer' do

    customer_token = Token.create(
      action:     'api',
      persistent: true,
      user_id:    @customer.id,
    )
    customer_credentials = "Token token=#{customer_token.name}"

    Setting.set('api_token_access', false)
    get '/api/v1/tickets', {}, @headers.merge('Authorization' => customer_credentials)
    assert_response(401)

    Setting.set('api_token_access', true)
    get '/api/v1/tickets', {}, @headers.merge('Authorization' => customer_credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert(result)

  end

end
