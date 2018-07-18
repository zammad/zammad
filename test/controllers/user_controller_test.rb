require 'test_helper'

class UserControllerTest < ActionDispatch::IntegrationTest
  include SearchindexHelper

  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w[Admin Agent])
    groups = Group.all

    UserInfo.current_user_id = 1

    @backup_admin = User.create!(
      login: 'backup-admin',
      firstname: 'Backup',
      lastname: 'Agent',
      email: 'backup-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    @admin = User.create!(
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
    @agent = User.create!(
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
    @customer_without_org = User.create!(
      login: 'rest-customer1@example.com',
      firstname: 'Rest',
      lastname: 'Customer1',
      email: 'rest-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

    # create orgs
    @organization = Organization.create!(
      name: 'Rest Org',
    )
    @organization2 = Organization.create!(
      name: 'Rest Org #2',
    )
    @organization3 = Organization.create!(
      name: 'Rest Org #3',
    )

    # create customer with org
    @customer_with_org = User.create!(
      login: 'rest-customer2@example.com',
      firstname: 'Rest',
      lastname: 'Customer2',
      email: 'rest-customer2@example.com',
      password: 'customer2pw',
      active: true,
      roles: roles,
      organization_id: @organization.id,
    )

    configure_elasticsearch do

      travel 1.minute

      rebuild_searchindex

      # execute background jobs
      Scheduler.worker(true)

      sleep 6
    end

    UserInfo.current_user_id = nil
  end

  test 'user create tests - no user' do

    post '/api/v1/signshow', params: {}, headers: @headers

    # create user with disabled feature
    Setting.set('user_create_account', false)
    token = @response.headers['CSRF-TOKEN']

    # token based on form
    params = { email: 'some_new_customer@example.com', authenticity_token: token }
    post '/api/v1/users', params: params.to_json, headers: @headers
    assert_response(422)
    result = JSON.parse(@response.body)
    assert(result['error'])
    assert_equal('Feature not enabled!', result['error'])

    # token based on headers
    headers = @headers.merge('X-CSRF-Token' => token)
    params = { email: 'some_new_customer@example.com' }
    post '/api/v1/users', params: params.to_json, headers: headers
    assert_response(422)
    result = JSON.parse(@response.body)
    assert(result['error'])
    assert_equal('Feature not enabled!', result['error'])

    Setting.set('user_create_account', true)

    # no signup param with enabled feature
    params = { email: 'some_new_customer@example.com' }
    post '/api/v1/users', params: params.to_json, headers: headers
    assert_response(422)
    result = JSON.parse(@response.body)
    assert(result['error'])
    assert_equal('Only signup with not authenticate user possible!', result['error'])

    # already existing user with enabled feature
    params = { email: 'rest-customer1@example.com', signup: true }
    post '/api/v1/users', params: params.to_json, headers: headers
    assert_response(422)
    result = JSON.parse(@response.body)
    assert(result['error'])
    assert_equal('Email address is already used for other user.', result['error'])

    # email missing with enabled feature
    params = { firstname: 'some firstname', signup: true }
    post '/api/v1/users', params: params.to_json, headers: headers
    assert_response(422)
    result = JSON.parse(@response.body)
    assert(result['error'])
    assert_equal('Attribute \'email\' required!', result['error'])

    # email missing with enabled feature
    params = { firstname: 'some firstname', signup: true }
    post '/api/v1/users', params: params.to_json, headers: headers
    assert_response(422)
    result = JSON.parse(@response.body)
    assert(result['error'])
    assert_equal('Attribute \'email\' required!', result['error'])

    # create user with enabled feature (take customer role)
    params = { firstname: 'Me First', lastname: 'Me Last', email: 'new_here@example.com', signup: true }
    post '/api/v1/users', params: params.to_json, headers: headers
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)

    assert_equal('Me First', result['firstname'])
    assert_equal('Me Last', result['lastname'])
    assert_equal('new_here@example.com', result['login'])
    assert_equal('new_here@example.com', result['email'])
    user = User.find(result['id'])
    assert_not(user.role?('Admin'))
    assert_not(user.role?('Agent'))
    assert(user.role?('Customer'))

    # create user with admin role (not allowed for signup, take customer role)
    role = Role.lookup(name: 'Admin')
    params = { firstname: 'Admin First', lastname: 'Admin Last', email: 'new_admin@example.com', role_ids: [ role.id ], signup: true }
    post '/api/v1/users', params: params.to_json, headers: headers
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)
    user = User.find(result['id'])
    assert_not(user.role?('Admin'))
    assert_not(user.role?('Agent'))
    assert(user.role?('Customer'))

    # create user with agent role (not allowed for signup, take customer role)
    role = Role.lookup(name: 'Agent')
    params = { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent@example.com', role_ids: [ role.id ], signup: true }
    post '/api/v1/users', params: params.to_json, headers: headers
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)
    user = User.find(result['id'])
    assert_not(user.role?('Admin'))
    assert_not(user.role?('Agent'))
    assert(user.role?('Customer'))

    # no user (because of no session)
    get '/api/v1/users', params: {}, headers: headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('authentication failed', result['error'])

    # me
    get '/api/v1/users/me', params: {}, headers: headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('authentication failed', result['error'])
  end

  test 'auth tests - not existing user' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('not_existing@example.com', 'adminpw')

    # me
    get '/api/v1/users/me', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('authentication failed', result['error'])

    get '/api/v1/users', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('authentication failed', result['error'])
  end

  test 'auth tests - username auth, wrong pw' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin', 'not_existing')

    get '/api/v1/users', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('authentication failed', result['error'])
  end

  test 'auth tests - email auth, wrong pw' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'not_existing')

    get '/api/v1/users', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('authentication failed', result['error'])
  end

  test 'auth tests - username auth' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin', 'adminpw')

    get '/api/v1/users', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
  end

  test 'auth tests - email auth' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')

    get '/api/v1/users', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
  end

  test 'user index and create with admin' do

    # email auth
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')

    # me
    get '/api/v1/users/me', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
    assert_equal(result['email'], 'rest-admin@example.com')

    # index
    get '/api/v1/users', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)

    # index
    get '/api/v1/users', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
    assert_equal(result.class, Array)
    assert(result.length >= 3)

    # show/:id
    get "/api/v1/users/#{@agent.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
    assert_equal(result.class, Hash)
    assert_equal(result['email'], 'rest-agent@example.com')

    get "/api/v1/users/#{@customer_without_org.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
    assert_equal(result.class, Hash)
    assert_equal(result['email'], 'rest-customer1@example.com')

    # create user with admin role
    role = Role.lookup(name: 'Admin')
    params = { firstname: 'Admin First', lastname: 'Admin Last', email: 'new_admin_by_admin@example.com', role_ids: [ role.id ] }
    post '/api/v1/users', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)
    user = User.find(result['id'])
    assert(user.role?('Admin'))
    assert_not(user.role?('Agent'))
    assert_not(user.role?('Customer'))
    assert_equal('new_admin_by_admin@example.com', result['login'])
    assert_equal('new_admin_by_admin@example.com', result['email'])

    # create user with agent role
    role = Role.lookup(name: 'Agent')
    params = { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent_by_admin1@example.com', role_ids: [ role.id ] }
    post '/api/v1/users', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)
    user = User.find(result['id'])
    assert_not(user.role?('Admin'))
    assert(user.role?('Agent'))
    assert_not(user.role?('Customer'))
    assert_equal('new_agent_by_admin1@example.com', result['login'])
    assert_equal('new_agent_by_admin1@example.com', result['email'])

    role = Role.lookup(name: 'Agent')
    params = { firstname: 'Agent First', email: 'new_agent_by_admin2@example.com', role_ids: [ role.id ] }
    post '/api/v1/users', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)
    user = User.find(result['id'])
    assert_not(user.role?('Admin'))
    assert(user.role?('Agent'))
    assert_not(user.role?('Customer'))
    assert_equal('new_agent_by_admin2@example.com', result['login'])
    assert_equal('new_agent_by_admin2@example.com', result['email'])
    assert_equal('Agent', result['firstname'])
    assert_equal('First', result['lastname'])

    role = Role.lookup(name: 'Agent')
    params = { firstname: 'Agent First', email: 'new_agent_by_admin2@example.com', role_ids: [ role.id ] }
    post '/api/v1/users', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert(result)
    assert_equal('Email address is already used for other user.', result['error'])

    # missing required attributes
    params = { note: 'some note' }
    post '/api/v1/users', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert(result)
    assert_equal('Minimum one identifier (login, firstname, lastname, phone or email) for user is required.', result['error'])

    # invalid email
    params = { firstname: 'newfirstname123', email: 'some_what', note: 'some note' }
    post '/api/v1/users', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert(result)
    assert_equal('Invalid email', result['error'])

    # with valid attributes
    params = { firstname: 'newfirstname123', note: 'some note' }
    post '/api/v1/users', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert(result)
    user = User.find(result['id'])
    assert_not(user.role?('Admin'))
    assert_not(user.role?('Agent'))
    assert(user.role?('Customer'))
    assert(result['login'].start_with?('auto-'))
    assert_equal('', result['email'])
    assert_equal('newfirstname123', result['firstname'])
    assert_equal('', result['lastname'])
  end

  test 'user index and create with agent' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-agent@example.com', 'agentpw')

    # me
    get '/api/v1/users/me', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
    assert_equal(result['email'], 'rest-agent@example.com')

    # index
    get '/api/v1/users', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)

    # index
    get '/api/v1/users', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
    assert_equal(result.class, Array)
    assert(result.length >= 3)

    get '/api/v1/users?limit=40&page=1&per_page=2', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    users = User.order(:id).limit(2)
    assert_equal(users[0].id, result[0]['id'])
    assert_equal(users[1].id, result[1]['id'])
    assert_equal(2, result.count)

    get '/api/v1/users?limit=40&page=2&per_page=2', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    users = User.order(:id).limit(4)
    assert_equal(users[2].id, result[0]['id'])
    assert_equal(users[3].id, result[1]['id'])
    assert_equal(2, result.count)

    # create user with admin role
    firstname = "First test#{rand(999_999_999)}"
    role = Role.lookup(name: 'Admin')
    params = { firstname: "Admin#{firstname}", lastname: 'Admin Last', email: 'new_admin_by_agent@example.com', role_ids: [ role.id ] }
    post '/api/v1/users', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result_user1 = JSON.parse(@response.body)
    assert(result_user1)
    user = User.find(result_user1['id'])
    assert_not(user.role?('Admin'))
    assert_not(user.role?('Agent'))
    assert(user.role?('Customer'))
    assert_equal('new_admin_by_agent@example.com', result_user1['login'])
    assert_equal('new_admin_by_agent@example.com', result_user1['email'])

    # create user with agent role
    role = Role.lookup(name: 'Agent')
    params = { firstname: "Agent#{firstname}", lastname: 'Agent Last', email: 'new_agent_by_agent@example.com', role_ids: [ role.id ] }
    post '/api/v1/users', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result_user1 = JSON.parse(@response.body)
    assert(result_user1)
    user = User.find(result_user1['id'])
    assert_not(user.role?('Admin'))
    assert_not(user.role?('Agent'))
    assert(user.role?('Customer'))
    assert_equal('new_agent_by_agent@example.com', result_user1['login'])
    assert_equal('new_agent_by_agent@example.com', result_user1['email'])

    # create user with customer role
    role = Role.lookup(name: 'Customer')
    params = { firstname: "Customer#{firstname}", lastname: 'Customer Last', email: 'new_customer_by_agent@example.com', role_ids: [ role.id ] }
    post '/api/v1/users', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result_user1 = JSON.parse(@response.body)
    assert(result_user1)
    user = User.find(result_user1['id'])
    assert_not(user.role?('Admin'))
    assert_not(user.role?('Agent'))
    assert(user.role?('Customer'))
    assert_equal('new_customer_by_agent@example.com', result_user1['login'])
    assert_equal('new_customer_by_agent@example.com', result_user1['email'])

    # search as agent
    Scheduler.worker(true)
    sleep 2 # let es time to come ready
    get "/api/v1/users/search?query=#{CGI.escape("Customer#{firstname}")}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)

    assert_equal(result_user1['id'], result[0]['id'])
    assert_equal("Customer#{firstname}", result[0]['firstname'])
    assert_equal('Customer Last', result[0]['lastname'])
    assert(result[0]['role_ids'])
    assert_not(result[0]['roles'])

    get "/api/v1/users/search?query=#{CGI.escape("Customer#{firstname}")}&expand=true", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(result_user1['id'], result[0]['id'])
    assert_equal("Customer#{firstname}", result[0]['firstname'])
    assert_equal('Customer Last', result[0]['lastname'])
    assert(result[0]['role_ids'])
    assert(result[0]['roles'])

    get "/api/v1/users/search?query=#{CGI.escape("Customer#{firstname}")}&label=true", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(result_user1['id'], result[0]['id'])
    assert_equal("Customer#{firstname} Customer Last <new_customer_by_agent@example.com>", result[0]['label'])
    assert_equal("Customer#{firstname} Customer Last <new_customer_by_agent@example.com>", result[0]['value'])
    assert_not(result[0]['role_ids'])
    assert_not(result[0]['roles'])

    get "/api/v1/users/search?term=#{CGI.escape("Customer#{firstname}")}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(result_user1['id'], result[0]['id'])
    assert_equal("Customer#{firstname} Customer Last <new_customer_by_agent@example.com>", result[0]['label'])
    assert_equal('new_customer_by_agent@example.com', result[0]['value'])
    assert_not(result[0]['role_ids'])
    assert_not(result[0]['roles'])

    role = Role.find_by(name: 'Agent')
    get "/api/v1/users/search?query=#{CGI.escape("Customer#{firstname}")}&role_ids=#{role.id}&label=true", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(0, result.count)

    role = Role.find_by(name: 'Customer')
    get "/api/v1/users/search?query=#{CGI.escape("Customer#{firstname}")}&role_ids=#{role.id}&label=true", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(result_user1['id'], result[0]['id'])
    assert_equal("Customer#{firstname} Customer Last <new_customer_by_agent@example.com>", result[0]['label'])
    assert_equal("Customer#{firstname} Customer Last <new_customer_by_agent@example.com>", result[0]['value'])
    assert_not(result[0]['role_ids'])
    assert_not(result[0]['roles'])

    permission = Permission.find_by(name: 'ticket.agent')
    get "/api/v1/users/search?query=#{CGI.escape("Customer#{firstname}")}&permissions=#{permission.name}&label=true", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(0, result.count)

    permission = Permission.find_by(name: 'ticket.customer')
    get "/api/v1/users/search?query=#{CGI.escape("Customer#{firstname}")}&permissions=#{permission.name}&label=true", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(result_user1['id'], result[0]['id'])
    assert_equal("Customer#{firstname} Customer Last <new_customer_by_agent@example.com>", result[0]['label'])
    assert_equal("Customer#{firstname} Customer Last <new_customer_by_agent@example.com>", result[0]['value'])
    assert_not(result[0]['role_ids'])
    assert_not(result[0]['roles'])
  end

  test 'user index and create with customer1' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-customer1@example.com', 'customer1pw')

    # me
    get '/api/v1/users/me', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
    assert_equal(result['email'], 'rest-customer1@example.com')

    # index
    get '/api/v1/users', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Array)
    assert_equal(result.length, 1)

    # show/:id
    get "/api/v1/users/#{@customer_without_org.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_equal(result['email'], 'rest-customer1@example.com')

    get "/api/v1/users/#{@customer_with_org.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert(result['error'])

    # create user with admin role
    role = Role.lookup(name: 'Admin')
    params = { firstname: 'Admin First', lastname: 'Admin Last', email: 'new_admin_by_customer1@example.com', role_ids: [ role.id ] }
    post '/api/v1/users', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)

    # create user with agent role
    role = Role.lookup(name: 'Agent')
    params = { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent_by_customer1@example.com', role_ids: [ role.id ] }
    post '/api/v1/users', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)

    # search
    Scheduler.worker(true)
    get "/api/v1/users/search?query=#{CGI.escape('First')}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
  end

  test 'user index with customer2' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-customer2@example.com', 'customer2pw')

    # me
    get '/api/v1/users/me', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert(result)
    assert_equal(result['email'], 'rest-customer2@example.com')

    # index
    get '/api/v1/users', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Array)
    assert_equal(result.length, 1)

    # show/:id
    get "/api/v1/users/#{@customer_with_org.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_equal(result['email'], 'rest-customer2@example.com')

    get "/api/v1/users/#{@customer_without_org.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert(result['error'])

    # search
    Scheduler.worker(true)
    get "/api/v1/users/search?query=#{CGI.escape('First')}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
  end

  test '04.01 users show and response format' do
    roles = Role.where(name: 'Customer')
    organization = Organization.first
    user = User.create!(
      login: 'rest-customer3@example.com',
      firstname: 'Rest',
      lastname: 'Customer3',
      email: 'rest-customer3@example.com',
      password: 'customer3pw',
      active: true,
      organization: organization,
      roles: roles,
      updated_by_id: @admin.id,
      created_by_id: @admin.id,
    )

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')
    get "/api/v1/users/#{user.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(user.id, result['id'])
    assert_equal(user.firstname, result['firstname'])
    assert_not(result['organization'])
    assert_equal(user.organization_id, result['organization_id'])
    assert_not(result['password'])
    assert_equal(user.role_ids, result['role_ids'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(@admin.id, result['created_by_id'])

    get "/api/v1/users/#{user.id}?expand=true", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(user.id, result['id'])
    assert_equal(user.firstname, result['firstname'])
    assert_equal(user.organization_id, result['organization_id'])
    assert_equal(user.organization.name, result['organization'])
    assert_equal(user.role_ids, result['role_ids'])
    assert_not(result['password'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(@admin.id, result['created_by_id'])

    get "/api/v1/users/#{user.id}?expand=false", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(user.id, result['id'])
    assert_equal(user.firstname, result['firstname'])
    assert_not(result['organization'])
    assert_equal(user.organization_id, result['organization_id'])
    assert_not(result['password'])
    assert_equal(user.role_ids, result['role_ids'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(@admin.id, result['created_by_id'])

    get "/api/v1/users/#{user.id}?full=true", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)

    assert_equal(Hash, result.class)
    assert_equal(user.id, result['id'])
    assert(result['assets'])
    assert(result['assets']['User'])
    assert(result['assets']['User'][user.id.to_s])
    assert_equal(user.id, result['assets']['User'][user.id.to_s]['id'])
    assert_equal(user.firstname, result['assets']['User'][user.id.to_s]['firstname'])
    assert_equal(user.organization_id, result['assets']['User'][user.id.to_s]['organization_id'])
    assert_equal(user.role_ids, result['assets']['User'][user.id.to_s]['role_ids'])

    get "/api/v1/users/#{user.id}?full=false", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(user.id, result['id'])
    assert_equal(user.firstname, result['firstname'])
    assert_not(result['organization'])
    assert_equal(user.organization_id, result['organization_id'])
    assert_not(result['password'])
    assert_equal(user.role_ids, result['role_ids'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(@admin.id, result['created_by_id'])
  end

  test '04.02 user index and response format' do
    roles = Role.where(name: 'Customer')
    organization = Organization.first
    user = User.create!(
      login: 'rest-customer3@example.com',
      firstname: 'Rest',
      lastname: 'Customer3',
      email: 'rest-customer3@example.com',
      password: 'customer3pw',
      active: true,
      organization: organization,
      roles: roles,
      updated_by_id: @admin.id,
      created_by_id: @admin.id,
    )

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')
    get '/api/v1/users', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(Hash, result[0].class)
    assert_equal(user.id, result.last['id'])
    assert_equal(user.lastname, result.last['lastname'])
    assert_not(result.last['organization'])
    assert_equal(user.role_ids, result.last['role_ids'])
    assert_equal(user.organization_id, result.last['organization_id'])
    assert_not(result.last['password'])
    assert_equal(@admin.id, result.last['updated_by_id'])
    assert_equal(@admin.id, result.last['created_by_id'])

    get '/api/v1/users?expand=true', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(Hash, result[0].class)
    assert_equal(user.id, result.last['id'])
    assert_equal(user.lastname, result.last['lastname'])
    assert_equal(user.organization_id, result.last['organization_id'])
    assert_equal(user.organization.name, result.last['organization'])
    assert_not(result.last['password'])
    assert_equal(@admin.id, result.last['updated_by_id'])
    assert_equal(@admin.id, result.last['created_by_id'])

    get '/api/v1/users?expand=false', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(Hash, result[0].class)
    assert_equal(user.id, result.last['id'])
    assert_equal(user.lastname, result.last['lastname'])
    assert_not(result.last['organization'])
    assert_equal(user.role_ids, result.last['role_ids'])
    assert_equal(user.organization_id, result.last['organization_id'])
    assert_not(result.last['password'])
    assert_equal(@admin.id, result.last['updated_by_id'])
    assert_equal(@admin.id, result.last['created_by_id'])

    get '/api/v1/users?full=true', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)

    assert_equal(Hash, result.class)
    assert_equal(Array, result['record_ids'].class)
    assert_equal(1, result['record_ids'][0])
    assert_equal(user.id, result['record_ids'].last)
    assert(result['assets'])
    assert(result['assets']['User'])
    assert(result['assets']['User'][user.id.to_s])
    assert_equal(user.id, result['assets']['User'][user.id.to_s]['id'])
    assert_equal(user.lastname, result['assets']['User'][user.id.to_s]['lastname'])
    assert_equal(user.organization_id, result['assets']['User'][user.id.to_s]['organization_id'])
    assert_not(result['assets']['User'][user.id.to_s]['password'])

    get '/api/v1/users?full=false', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(Hash, result[0].class)
    assert_equal(user.id, result.last['id'])
    assert_equal(user.lastname, result.last['lastname'])
    assert_not(result.last['organization'])
    assert_equal(user.role_ids, result.last['role_ids'])
    assert_equal(user.organization_id, result.last['organization_id'])
    assert_not(result.last['password'])
    assert_equal(@admin.id, result.last['updated_by_id'])
    assert_equal(@admin.id, result.last['created_by_id'])
  end

  test '04.03 ticket create and response format' do
    organization = Organization.first
    params = {
      firstname: 'newfirstname123',
      note: 'some note',
      organization: organization.name,
    }
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')

    post '/api/v1/users', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    user = User.find(result['id'])
    assert_equal(user.firstname, result['firstname'])
    assert_equal(user.organization_id, result['organization_id'])
    assert_not(result['organization'])
    assert_not(result['password'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(@admin.id, result['created_by_id'])

    post '/api/v1/users?expand=true', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    user = User.find(result['id'])
    assert_equal(user.firstname, result['firstname'])
    assert_equal(user.organization_id, result['organization_id'])
    assert_equal(user.organization.name, result['organization'])
    assert_not(result['password'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(@admin.id, result['created_by_id'])

    post '/api/v1/users?full=true', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    user = User.find(result['id'])
    assert(result['assets'])
    assert(result['assets']['User'])
    assert(result['assets']['User'][user.id.to_s])
    assert_equal(user.id, result['assets']['User'][user.id.to_s]['id'])
    assert_equal(user.firstname, result['assets']['User'][user.id.to_s]['firstname'])
    assert_equal(user.lastname, result['assets']['User'][user.id.to_s]['lastname'])
    assert_not(result['assets']['User'][user.id.to_s]['password'])

    assert(result['assets']['User'][@admin.id.to_s])
    assert_equal(@admin.id, result['assets']['User'][@admin.id.to_s]['id'])
    assert_equal(@admin.firstname, result['assets']['User'][@admin.id.to_s]['firstname'])
    assert_equal(@admin.lastname, result['assets']['User'][@admin.id.to_s]['lastname'])
    assert_not(result['assets']['User'][@admin.id.to_s]['password'])

  end

  test '04.04 ticket update and response formats' do
    roles = Role.where(name: 'Customer')
    organization = Organization.first
    user = User.create!(
      login: 'rest-customer3@example.com',
      firstname: 'Rest',
      lastname: 'Customer3',
      email: 'rest-customer3@example.com',
      password: 'customer3pw',
      active: true,
      organization: organization,
      roles: roles,
      updated_by_id: @admin.id,
      created_by_id: @admin.id,
    )

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')

    params = {
      firstname: 'a update firstname #1',
    }
    put "/api/v1/users/#{user.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    user = User.find(result['id'])
    assert_equal(user.lastname, result['lastname'])
    assert_equal(params[:firstname], result['firstname'])
    assert_equal(user.organization_id, result['organization_id'])
    assert_not(result['organization'])
    assert_not(result['password'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(@admin.id, result['created_by_id'])

    params = {
      firstname: 'a update firstname #2',
    }
    put "/api/v1/users/#{user.id}?expand=true", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    user = User.find(result['id'])
    assert_equal(user.lastname, result['lastname'])
    assert_equal(params[:firstname], result['firstname'])
    assert_equal(user.organization_id, result['organization_id'])
    assert_equal(user.organization.name, result['organization'])
    assert_not(result['password'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(@admin.id, result['created_by_id'])

    params = {
      firstname: 'a update firstname #3',
    }
    put "/api/v1/users/#{user.id}?full=true", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    user = User.find(result['id'])
    assert(result['assets'])
    assert(result['assets']['User'])
    assert(result['assets']['User'][user.id.to_s])
    assert_equal(user.id, result['assets']['User'][user.id.to_s]['id'])
    assert_equal(params[:firstname], result['assets']['User'][user.id.to_s]['firstname'])
    assert_equal(user.lastname, result['assets']['User'][user.id.to_s]['lastname'])
    assert_not(result['assets']['User'][user.id.to_s]['password'])

    assert(result['assets']['User'][@admin.id.to_s])
    assert_equal(@admin.id, result['assets']['User'][@admin.id.to_s]['id'])
    assert_equal(@admin.firstname, result['assets']['User'][@admin.id.to_s]['firstname'])
    assert_equal(@admin.lastname, result['assets']['User'][@admin.id.to_s]['lastname'])
    assert_not(result['assets']['User'][@admin.id.to_s]['password'])

  end

  test '05.01 csv example - customer no access' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-customer1@example.com', 'customer1pw')

    get '/api/v1/users/import_example', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('Not authorized (user)!', result['error'])
  end

  test '05.02 csv example - admin access' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')

    get '/api/v1/users/import_example', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)

    rows = CSV.parse(@response.body)
    header = rows.shift

    assert_equal('id', header[0])
    assert_equal('login', header[1])
    assert_equal('firstname', header[2])
    assert_equal('lastname', header[3])
    assert_equal('email', header[4])
    assert(header.include?('organization'))
  end

  test '05.03 csv import - admin access' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')

    # invalid file
    csv_file_path = Rails.root.join('test', 'data', 'csv', 'user_simple_col_not_existing.csv')
    csv_file = ::Rack::Test::UploadedFile.new(csv_file_path, 'text/csv')
    post '/api/v1/users/import?try=true', params: { file: csv_file, col_sep: ';' }, headers: { 'Authorization' => credentials }
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert_equal(true, result['try'])
    assert_equal(2, result['records'].count)
    assert_equal('failed', result['result'])
    assert_equal(2, result['errors'].count)
    assert_equal("Line 1: unknown attribute 'firstname2' for User.", result['errors'][0])
    assert_equal("Line 2: unknown attribute 'firstname2' for User.", result['errors'][1])

    # valid file try
    csv_file_path = Rails.root.join('test', 'data', 'csv', 'user_simple.csv')
    csv_file = ::Rack::Test::UploadedFile.new(csv_file_path, 'text/csv')
    post '/api/v1/users/import?try=true', params: { file: csv_file, col_sep: ';' }, headers: { 'Authorization' => credentials }
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert_equal(true, result['try'])
    assert_equal(2, result['records'].count)
    assert_equal('success', result['result'])

    assert_nil(User.find_by(login: 'user-simple-import1'))
    assert_nil(User.find_by(login: 'user-simple-import2'))

    # valid file
    csv_file_path = Rails.root.join('test', 'data', 'csv', 'user_simple.csv')
    csv_file = ::Rack::Test::UploadedFile.new(csv_file_path, 'text/csv')
    post '/api/v1/users/import', params: { file: csv_file, col_sep: ';' }, headers: { 'Authorization' => credentials }
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert_equal(false, result['try'])
    assert_equal(2, result['records'].count)
    assert_equal('success', result['result'])

    user1 = User.find_by(login: 'user-simple-import1')
    assert(user1)
    assert_equal(user1.login, 'user-simple-import1')
    assert_equal(user1.firstname, 'firstname-simple-import1')
    assert_equal(user1.lastname, 'lastname-simple-import1')
    assert_equal(user1.email, 'user-simple-import1@example.com')
    assert_equal(user1.active, true)
    user2 = User.find_by(login: 'user-simple-import2')
    assert(user2)
    assert_equal(user2.login, 'user-simple-import2')
    assert_equal(user2.firstname, 'firstname-simple-import2')
    assert_equal(user2.lastname, 'lastname-simple-import2')
    assert_equal(user2.email, 'user-simple-import2@example.com')
    assert_equal(user2.active, false)

    user1.destroy!
    user2.destroy!
  end

  test 'user search sortable' do
    firstname = "user_search_sortable #{rand(999_999_999)}"

    roles = Role.where(name: 'Customer')
    user1 = User.create_or_update(
      login: 'rest-user_search_sortableA@example.com',
      firstname: "#{firstname} A",
      lastname: 'user_search_sortableA',
      email: 'rest-user_search_sortableA@example.com',
      password: 'user_search_sortableA',
      active: true,
      roles: roles,
      organization_id: @organization.id,
      out_of_office: false,
      created_at: '2016-02-05 17:42:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    user2 = User.create_or_update(
      login: 'rest-user_search_sortableB@example.com',
      firstname: "#{firstname} B",
      lastname: 'user_search_sortableB',
      email: 'rest-user_search_sortableB@example.com',
      password: 'user_search_sortableB',
      active: true,
      roles: roles,
      organization_id: @organization.id,
      out_of_office_start_at: '2016-02-06 19:42:00',
      out_of_office_end_at: '2016-02-07 19:42:00',
      out_of_office_replacement_id: 1,
      out_of_office: true,
      created_at: '2016-02-05 19:42:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    Scheduler.worker(true)
    sleep 2 # let es time to come ready

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')
    get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: 'created_at', order_by: 'asc' }, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    result.collect! { |v| v['id'] }
    assert_equal([user1.id, user2.id], result)

    get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: 'firstname', order_by: 'asc' }, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    result.collect! { |v| v['id'] }
    assert_equal([user1.id, user2.id], result)

    get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: 'firstname', order_by: 'desc' }, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    result.collect! { |v| v['id'] }
    assert_equal([user2.id, user1.id], result)

    get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: %w[firstname created_at], order_by: %w[desc asc] }, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    result.collect! { |v| v['id'] }
    assert_equal([user2.id, user1.id], result)

    get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: %w[firstname created_at], order_by: %w[desc asc] }, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    result.collect! { |v| v['id'] }
    assert_equal([user2.id, user1.id], result)

    get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: 'out_of_office', order_by: 'asc' }, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    result.collect! { |v| v['id'] }
    assert_equal([user1.id, user2.id], result)

    get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: 'out_of_office', order_by: 'desc' }, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    result.collect! { |v| v['id'] }
    assert_equal([user2.id, user1.id], result)

    get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: %w[created_by_id created_at], order_by: %w[asc asc] }, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    result.collect! { |v| v['id'] }
    assert_equal([user1.id, user2.id], result)
  end

end
