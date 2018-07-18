require 'test_helper'

class UserOrganizationControllerTest < ActionDispatch::IntegrationTest
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
      note: 'Rest Org A',
    )
    @organization2 = Organization.create!(
      name: 'Rest Org #2',
      note: 'Rest Org B',
    )
    @organization3 = Organization.create!(
      name: 'Rest Org #3',
      note: 'Rest Org C',
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

  test 'organization index with agent' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-agent@example.com', 'agentpw')

    # index
    get '/api/v1/organizations', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Array)
    assert_equal(result[0]['member_ids'].class, Array)
    assert(result.length >= 3)

    get '/api/v1/organizations?limit=40&page=1&per_page=2', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    organizations = Organization.order(:id).limit(2)
    assert_equal(organizations[0].id, result[0]['id'])
    assert_equal(organizations[0].member_ids, result[0]['member_ids'])
    assert_equal(organizations[1].id, result[1]['id'])
    assert_equal(organizations[1].member_ids, result[1]['member_ids'])
    assert_equal(2, result.count)

    get '/api/v1/organizations?limit=40&page=2&per_page=2', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    organizations = Organization.order(:id).limit(4)
    assert_equal(organizations[2].id, result[0]['id'])
    assert_equal(organizations[2].member_ids, result[0]['member_ids'])
    assert_equal(organizations[3].id, result[1]['id'])
    assert_equal(organizations[3].member_ids, result[1]['member_ids'])

    assert_equal(2, result.count)

    # show/:id
    get "/api/v1/organizations/#{@organization.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_equal(result['member_ids'].class, Array)
    assert_not(result['members'])
    assert_equal(result['name'], 'Rest Org')

    get "/api/v1/organizations/#{@organization2.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_equal(result['member_ids'].class, Array)
    assert_not(result['members'])
    assert_equal(result['name'], 'Rest Org #2')

    # search as agent
    Scheduler.worker(true)
    get "/api/v1/organizations/search?query=#{CGI.escape('Zammad')}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal('Zammad Foundation', result[0]['name'])
    assert(result[0]['member_ids'])
    assert_not(result[0]['members'])

    get "/api/v1/organizations/search?query=#{CGI.escape('Zammad')}&expand=true", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal('Zammad Foundation', result[0]['name'])
    assert(result[0]['member_ids'])
    assert(result[0]['members'])

    get "/api/v1/organizations/search?query=#{CGI.escape('Zammad')}&label=true", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal('Zammad Foundation', result[0]['label'])
    assert_equal('Zammad Foundation', result[0]['value'])
    assert_not(result[0]['member_ids'])
    assert_not(result[0]['members'])
  end

  test 'organization index with customer1' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-customer1@example.com', 'customer1pw')

    # index
    get '/api/v1/organizations', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Array)
    assert_equal(result.length, 0)

    # show/:id
    get "/api/v1/organizations/#{@organization.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_nil(result['name'])

    get "/api/v1/organizations/#{@organization2.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_nil(result['name'])

    # search
    Scheduler.worker(true)
    get "/api/v1/organizations/search?query=#{CGI.escape('Zammad')}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
  end

  test 'organization index with customer2' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-customer2@example.com', 'customer2pw')

    # index
    get '/api/v1/organizations', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Array)
    assert_equal(result.length, 1)

    # show/:id
    get "/api/v1/organizations/#{@organization.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_equal(result['name'], 'Rest Org')

    get "/api/v1/organizations/#{@organization2.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(result.class, Hash)
    assert_nil(result['name'])

    # search
    Scheduler.worker(true)
    get "/api/v1/organizations/search?query=#{CGI.escape('Zammad')}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
  end

  test 'organization search sortable' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin', 'adminpw')

    get "/api/v1/organizations/search?query=#{CGI.escape('Rest Org')}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    result.collect! { |v| v['id'] }
    assert_equal(Array, result.class)
    assert_equal([ @organization.id, @organization2.id, @organization3.id ], result)

    get "/api/v1/organizations/search?query=#{CGI.escape('Rest Org')}", params: { sort_by: 'note', order_by: 'asc' }, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    result.collect! { |v| v['id'] }
    assert_equal(Array, result.class)
    assert_equal([ @organization.id, @organization2.id, @organization3.id ], result)

    get "/api/v1/organizations/search?query=#{CGI.escape('Rest Org')}", params: { sort_by: 'note', order_by: 'desc' }, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    result.collect! { |v| v['id'] }
    assert_equal(Array, result.class)
    assert_equal([ @organization3.id, @organization2.id, @organization.id ], result)

    get "/api/v1/organizations/search?query=#{CGI.escape('Rest Org')}", params: { sort_by: %w[note created_at], order_by: %w[desc asc] }, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    result.collect! { |v| v['id'] }
    assert_equal(Array, result.class)
    assert_equal([ @organization3.id, @organization2.id, @organization.id ], result)
  end

end
