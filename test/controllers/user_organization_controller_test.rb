# encoding: utf-8
require 'test_helper'

class UserOrganizationControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w(Admin Agent))
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create_or_update(
      login: 'rest-admin',
      firstname: 'Rest',
      lastname: 'Agent',
      email: 'rest-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create agent
    roles = Role.where(name: 'Agent')
    @agent = User.create_or_update(
      login: 'rest-agent@example.com',
      firstname: 'Rest',
      lastname: 'Agent',
      email: 'rest-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create customer without org
    roles = Role.where(name: 'Customer')
    @customer_without_org = User.create_or_update(
      login: 'rest-customer1@example.com',
      firstname: 'Rest',
      lastname: 'Customer1',
      email: 'rest-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

    # create orgs
    @organization = Organization.create_or_update(
      name: 'Rest Org',
    )
    @organization2 = Organization.create_or_update(
      name: 'Rest Org #2',
    )
    @organization3 = Organization.create_or_update(
      name: 'Rest Org #3',
    )

    # create customer with org
    @customer_with_org = User.create_or_update(
      login: 'rest-customer2@example.com',
      firstname: 'Rest',
      lastname: 'Customer2',
      email: 'rest-customer2@example.com',
      password: 'customer2pw',
      active: true,
      roles: roles,
      organization_id: @organization.id,
    )

  end

  test 'user create tests - no user' do

    # create user with disabled feature
    Setting.set('user_create_account', false)
    params = { email: 'some_new_customer@example.com' }
    post '/api/v1/users', params.to_json, @headers
    assert_response(422)
    result = JSON.parse(@response.body)
    assert(result['error'])
    assert_equal('Feature not enabled!', result['error'])

    Setting.set('user_create_account', true)

    # no signup param with enabled feature
    params = { email: 'some_new_customer@example.com' }
    post '/api/v1/users', params.to_json, @headers
    assert_response(422)
    result = JSON.parse(@response.body)
    assert(result['error'])
    assert_equal('Only signup with not authenticate user possible!', result['error'])

    # already existing user with enabled feature
    params = { email: 'rest-customer1@example.com', signup: true }
    post '/api/v1/users', params.to_json, @headers
    assert_response(422)
    result = JSON.parse(@response.body)
    assert(result['error'])
    assert_equal('User already exists!', result['error'])

    # create user with enabled feature
    params = { firstname: 'Me First', lastname: 'Me Last', email: 'new_here@example.com', signup: true }
    post '/api/v1/users', params.to_json, @headers
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)

    assert_equal('Me First', result['firstname'])
    assert_equal('Me Last', result['lastname'])
    assert_equal('new_here@example.com', result['login'])
    assert_equal('new_here@example.com', result['email'])

    # create user with admin role
    role = Role.lookup(name: 'Admin')
    params = { firstname: 'Admin First', lastname: 'Admin Last', email: 'new_admin@example.com', role_ids: [ role.id ], signup: true }
    post '/api/v1/users', params.to_json, @headers
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)
    user = User.find(result['id'])
    assert_not(user.role?('Admin'))
    assert_not(user.role?('Agent'))
    assert(user.role?('Customer'))

    # create user with agent role
    role = Role.lookup(name: 'Agent')
    params = { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent@example.com', role_ids: [ role.id ], signup: true }
    post '/api/v1/users', params.to_json, @headers
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)
    user = User.find(result['id'])
    assert_not(user.role?('Admin'))
    assert_not(user.role?('Agent'))
    assert(user.role?('Customer'))

    # no user
    get '/api/v1/users', {}, @headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('authentication failed', result['error'])
  end

  test 'auth tests - not existing user' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('not_existing@example.com', 'adminpw')

    get '/api/v1/users', {}, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('authentication failed', result['error'])
  end

  test 'auth tests - username auth, wrong pw' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin', 'not_existing')

    get '/api/v1/users', {}, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('authentication failed', result['error'])
  end

  test 'auth tests - email auth, wrong pw' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'not_existing')

    get '/api/v1/users', {}, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('authentication failed', result['error'])
  end

  test 'auth tests - username auth' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin', 'adminpw')

    get '/api/v1/users', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
  end

  test 'auth tests - email auth' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')

    get '/api/v1/users', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
  end

  test 'user index and create with admin' do

    # email auth
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')

    # index
    get '/api/v1/users', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)

    # index
    get '/api/v1/users', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
    assert_equal(result.class, Array)
    assert(result.length >= 3)

    # show/:id
    get "/api/v1/users/#{@agent.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
    assert_equal(result.class, Hash)
    assert_equal(result['email'], 'rest-agent@example.com')

    get "/api/v1/users/#{@customer_without_org.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
    assert_equal(result.class, Hash)
    assert_equal(result['email'], 'rest-customer1@example.com')

    # create user with admin role
    role = Role.lookup(name: 'Admin')
    params = { firstname: 'Admin First', lastname: 'Admin Last', email: 'new_admin_by_admin@example.com', role_ids: [ role.id ] }
    post '/api/v1/users', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)
    user = User.find(result['id'])
    assert(user.role?('Admin'))
    assert_not(user.role?('Agent'))
    assert_not(user.role?('Customer'))

    # create user with agent role
    role = Role.lookup(name: 'Agent')
    params = { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent_by_admin@example.com', role_ids: [ role.id ] }
    post '/api/v1/users', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)
    user = User.find(result['id'])
    assert_not(user.role?('Admin'))
    assert(user.role?('Agent'))
    assert_not(user.role?('Customer'))

  end

  test 'user index and create with agent' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-agent@example.com', 'agentpw')

    # index
    get '/api/v1/users', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)

    # index
    get '/api/v1/users', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
    assert_equal(result.class, Array)
    assert(result.length >= 3)

    # create user with admin role
    role = Role.lookup(name: 'Admin')
    params = { firstname: 'Admin First', lastname: 'Admin Last', email: 'new_admin_by_agent@example.com', role_ids: [ role.id ] }
    post '/api/v1/users', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert(result)

    # create user with agent role
    role = Role.lookup(name: 'Agent')
    params = { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent_by_agent@example.com', role_ids: [ role.id ] }
    post '/api/v1/users', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert(result)

    # create user with customer role
    role = Role.lookup(name: 'Customer')
    params = { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent_by_agent@example.com', role_ids: [ role.id ] }
    post '/api/v1/users', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)
    user = User.find(result['id'])
    assert_not(user.role?('Admin'))
    assert_not(user.role?('Agent'))
    assert(user.role?('Customer'))

  end

  test 'user index and create with customer1' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-customer1@example.com', 'customer1pw')

    # index
    get '/api/v1/users', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Array)
    assert_equal(result.length, 1)

    # show/:id
    get "/api/v1/users/#{@customer_without_org.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_equal(result['email'], 'rest-customer1@example.com')

    get "/api/v1/users/#{@customer_with_org.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert(result['error'])

    # create user with admin role
    role = Role.lookup(name: 'Admin')
    params = { firstname: 'Admin First', lastname: 'Admin Last', email: 'new_admin_by_customer1@example.com', role_ids: [ role.id ] }
    post '/api/v1/users', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)

    # create user with agent role
    role = Role.lookup(name: 'Agent')
    params = { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent_by_customer1@example.com', role_ids: [ role.id ] }
    post '/api/v1/users', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)

  end

  test 'user index with customer2' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-customer2@example.com', 'customer2pw')

    # index
    get '/api/v1/users', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Array)
    assert_equal(result.length, 1)

    # show/:id
    get "/api/v1/users/#{@customer_with_org.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_equal(result['email'], 'rest-customer2@example.com')

    get "/api/v1/users/#{@customer_without_org.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert(result['error'])

  end

  test 'organization index with agent' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-agent@example.com', 'agentpw')

    # index
    get '/api/v1/organizations', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Array)
    assert(result.length >= 3)

    # show/:id
    get "/api/v1/organizations/#{@organization.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal( result.class, Hash)
    assert_equal( result['name'], 'Rest Org')

    get "/api/v1/organizations/#{@organization2.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal( result.class, Hash)
    assert_equal( result['name'], 'Rest Org #2')

  end

  test 'organization index with customer1' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-customer1@example.com', 'customer1pw')

    # index
    get '/api/v1/organizations', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Array)
    assert_equal(result.length, 0)

    # show/:id
    get "/api/v1/organizations/#{@organization.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal( result.class, Hash)
    assert_equal( result['name'], nil)

    get "/api/v1/organizations/#{@organization2.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal( result.class, Hash)
    assert_equal( result['name'], nil)

  end

  test 'organization index with customer2' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-customer2@example.com', 'customer2pw')

    # index
    get '/api/v1/organizations', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Array)
    assert_equal(result.length, 1)

    # show/:id
    get "/api/v1/organizations/#{@organization.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal( result.class, Hash)
    assert_equal( result['name'], 'Rest Org')

    get "/api/v1/organizations/#{@organization2.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal( result.class, Hash)
    assert_equal( result['name'], nil)

  end
end
