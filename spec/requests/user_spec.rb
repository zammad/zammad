require 'rails_helper'

RSpec.describe 'User', type: :request, searchindex: true do

  let!(:admin_user) do
    create(
      :admin_user,
      groups:    Group.all,
      login:     'rest-admin',
      firstname: 'Rest',
      lastname:  'Agent',
      email:     'rest-admin@example.com',
    )
  end
  let!(:admin_user_pw) do
    create(
      :admin_user,
      groups:    Group.all,
      login:     'rest-admin-pw',
      firstname: 'Rest',
      lastname:  'Agent',
      email:     'rest-admin-pw@example.com',
      password:  'adminpw',
    )
  end
  let!(:agent_user) do
    create(
      :agent_user,
      groups:    Group.all,
      login:     'rest-agent@example.com',
      firstname: 'Rest',
      lastname:  'Agent',
      email:     'rest-agent@example.com',
    )
  end
  let!(:customer_user) do
    create(
      :customer_user,
      login:     'rest-customer1@example.com',
      firstname: 'Rest',
      lastname:  'Customer1',
      email:     'rest-customer1@example.com',
    )
  end
  let!(:organization) do
    create(:organization, name: 'Rest Org')
  end
  let!(:organization2) do
    create(:organization, name: 'Rest Org #2')
  end
  let!(:organization3) do
    create(:organization, name: 'Rest Org #3')
  end
  let!(:customer_user2) do
    create(
      :customer_user,
      organization: organization,
      login:        'rest-customer2@example.com',
      firstname:    'Rest',
      lastname:     'Customer2',
      email:        'rest-customer2@example.com',
    )
  end

  before do
    configure_elasticsearch do

      travel 1.minute

      rebuild_searchindex

      # execute background jobs
      Scheduler.worker(true)

      sleep 6
    end
  end

  describe 'request handling' do

    it 'does user create tests - no user' do

      post '/api/v1/signshow', params: {}, as: :json

      # create user with disabled feature
      Setting.set('user_create_account', false)
      token = @response.headers['CSRF-TOKEN']

      # token based on form
      params = { email: 'some_new_customer@example.com', authenticity_token: token }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']).to be_truthy
      expect(json_response['error']).to eq('Feature not enabled!')

      # token based on headers
      headers = { 'X-CSRF-Token' => token }
      params = { email: 'some_new_customer@example.com' }
      post '/api/v1/users', params: params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']).to be_truthy
      expect(json_response['error']).to eq('Feature not enabled!')

      Setting.set('user_create_account', true)

      # no signup param with enabled feature
      params = { email: 'some_new_customer@example.com' }
      post '/api/v1/users', params: params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']).to be_truthy
      expect(json_response['error']).to eq('Only signup with not authenticate user possible!')

      # already existing user with enabled feature
      params = { email: 'rest-customer1@example.com', signup: true }
      post '/api/v1/users', params: params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']).to be_truthy
      expect(json_response['error']).to eq('Email address is already used for other user.')

      # email missing with enabled feature
      params = { firstname: 'some firstname', signup: true }
      post '/api/v1/users', params: params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']).to be_truthy
      expect(json_response['error']).to eq('Attribute \'email\' required!')

      # email missing with enabled feature
      params = { firstname: 'some firstname', signup: true }
      post '/api/v1/users', params: params, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']).to be_truthy
      expect(json_response['error']).to eq('Attribute \'email\' required!')

      # create user with enabled feature (take customer role)
      params = { firstname: 'Me First', lastname: 'Me Last', email: 'new_here@example.com', signup: true }
      post '/api/v1/users', params: params, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy

      expect(json_response['firstname']).to eq('Me First')
      expect(json_response['lastname']).to eq('Me Last')
      expect(json_response['login']).to eq('new_here@example.com')
      expect(json_response['email']).to eq('new_here@example.com')
      user = User.find(json_response['id'])
      expect(user).not_to be_role('Admin')
      expect(user).not_to be_role('Agent')
      expect(user).to be_role('Customer')

      # create user with admin role (not allowed for signup, take customer role)
      role = Role.lookup(name: 'Admin')
      params = { firstname: 'Admin First', lastname: 'Admin Last', email: 'new_admin@example.com', role_ids: [ role.id ], signup: true }
      post '/api/v1/users', params: params, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy
      user = User.find(json_response['id'])
      expect(user).not_to be_role('Admin')
      expect(user).not_to be_role('Agent')
      expect(user).to be_role('Customer')

      # create user with agent role (not allowed for signup, take customer role)
      role = Role.lookup(name: 'Agent')
      params = { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent@example.com', role_ids: [ role.id ], signup: true }
      post '/api/v1/users', params: params, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy
      user = User.find(json_response['id'])
      expect(user).not_to be_role('Admin')
      expect(user).not_to be_role('Agent')
      expect(user).to be_role('Customer')

      # no user (because of no session)
      get '/api/v1/users', params: {}, headers: headers, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('authentication failed')

      # me
      get '/api/v1/users/me', params: {}, headers: headers, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('authentication failed')
    end

    it 'does auth tests - not existing user' do
      authenticated_as(nil, login: 'not_existing@example.com', password: 'adminpw')
      get '/api/v1/users/me', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('authentication failed')

      get '/api/v1/users', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('authentication failed')
    end

    it 'does auth tests - username auth, wrong pw' do
      authenticated_as(admin_user, password: 'not_existing')
      get '/api/v1/users', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('authentication failed')
    end

    it 'does auth tests - email auth, wrong pw' do
      authenticated_as(nil, login: 'rest-admin@example.com', password: 'not_existing')
      get '/api/v1/users', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('authentication failed')
    end

    it 'does auth tests - username auth' do
      authenticated_as(nil, login: 'rest-admin-pw', password: 'adminpw')
      get '/api/v1/users', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
    end

    it 'does auth tests - email auth' do
      authenticated_as(nil, login: 'rest-admin-pw@example.com', password: 'adminpw')
      get '/api/v1/users', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
    end

    it 'does user index and create with admin' do
      authenticated_as(admin_user)
      get '/api/v1/users/me', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
      expect('rest-admin@example.com').to eq(json_response['email'])

      # index
      get '/api/v1/users', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy

      # index
      get '/api/v1/users', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
      expect(Array).to eq(json_response.class)
      expect(json_response.length >= 3).to be_truthy

      # show/:id
      get "/api/v1/users/#{agent_user.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
      expect(Hash).to eq(json_response.class)
      expect('rest-agent@example.com').to eq(json_response['email'])

      get "/api/v1/users/#{customer_user.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
      expect(Hash).to eq(json_response.class)
      expect('rest-customer1@example.com').to eq(json_response['email'])

      # create user with admin role
      role = Role.lookup(name: 'Admin')
      params = { firstname: 'Admin First', lastname: 'Admin Last', email: 'new_admin_by_admin@example.com', role_ids: [ role.id ] }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy
      user = User.find(json_response['id'])
      expect(user).to be_role('Admin')
      expect(user).not_to be_role('Agent')
      expect(user).not_to be_role('Customer')
      expect(json_response['login']).to eq('new_admin_by_admin@example.com')
      expect(json_response['email']).to eq('new_admin_by_admin@example.com')

      # create user with agent role
      role = Role.lookup(name: 'Agent')
      params = { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent_by_admin1@example.com', role_ids: [ role.id ] }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy
      user = User.find(json_response['id'])
      expect(user).not_to be_role('Admin')
      expect(user).to be_role('Agent')
      expect(user).not_to be_role('Customer')
      expect(json_response['login']).to eq('new_agent_by_admin1@example.com')
      expect(json_response['email']).to eq('new_agent_by_admin1@example.com')

      role = Role.lookup(name: 'Agent')
      params = { firstname: 'Agent First', email: 'new_agent_by_admin2@example.com', role_ids: [ role.id ] }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy
      user = User.find(json_response['id'])
      expect(user).not_to be_role('Admin')
      expect(user).to be_role('Agent')
      expect(user).not_to be_role('Customer')
      expect(json_response['login']).to eq('new_agent_by_admin2@example.com')
      expect(json_response['email']).to eq('new_agent_by_admin2@example.com')
      expect(json_response['firstname']).to eq('Agent')
      expect(json_response['lastname']).to eq('First')

      role = Role.lookup(name: 'Agent')
      params = { firstname: 'Agent First', email: 'new_agent_by_admin2@example.com', role_ids: [ role.id ] }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_truthy
      expect(json_response['error']).to eq('Email address is already used for other user.')

      # missing required attributes
      params = { note: 'some note' }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_truthy
      expect(json_response['error']).to eq('Minimum one identifier (login, firstname, lastname, phone or email) for user is required.')

      # invalid email
      params = { firstname: 'newfirstname123', email: 'some_what', note: 'some note' }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_truthy
      expect(json_response['error']).to eq('Invalid email')

      # with valid attributes
      params = { firstname: 'newfirstname123', note: 'some note' }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy
      user = User.find(json_response['id'])
      expect(user).not_to be_role('Admin')
      expect(user).not_to be_role('Agent')
      expect(user).to be_role('Customer')
      expect(json_response['login']).to be_start_with('auto-')
      expect(json_response['email']).to eq('')
      expect(json_response['firstname']).to eq('newfirstname123')
      expect(json_response['lastname']).to eq('')
    end

    it 'does user index and create with agent' do
      authenticated_as(agent_user)
      get '/api/v1/users/me', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
      expect('rest-agent@example.com').to eq(json_response['email'])

      # index
      get '/api/v1/users', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy

      # index
      get '/api/v1/users', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
      expect(Array).to eq(json_response.class)
      expect(json_response.length >= 3).to be_truthy

      get '/api/v1/users?limit=40&page=1&per_page=2', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      users = User.order(:id).limit(2)
      expect(json_response[0]['id']).to eq(users[0].id)
      expect(json_response[1]['id']).to eq(users[1].id)
      expect(json_response.count).to eq(2)

      get '/api/v1/users?limit=40&page=2&per_page=2', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      users = User.order(:id).limit(4)
      expect(json_response[0]['id']).to eq(users[2].id)
      expect(json_response[1]['id']).to eq(users[3].id)
      expect(json_response.count).to eq(2)

      # create user with admin role
      firstname = "First test#{rand(999_999_999)}"
      role = Role.lookup(name: 'Admin')
      params = { firstname: "Admin#{firstname}", lastname: 'Admin Last', email: 'new_admin_by_agent@example.com', role_ids: [ role.id ] }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:created)
      json_response_user1 = JSON.parse(@response.body)
      expect(json_response_user1).to be_truthy
      user = User.find(json_response_user1['id'])
      expect(user).not_to be_role('Admin')
      expect(user).not_to be_role('Agent')
      expect(user).to be_role('Customer')
      expect(json_response_user1['login']).to eq('new_admin_by_agent@example.com')
      expect(json_response_user1['email']).to eq('new_admin_by_agent@example.com')

      # create user with agent role
      role = Role.lookup(name: 'Agent')
      params = { firstname: "Agent#{firstname}", lastname: 'Agent Last', email: 'new_agent_by_agent@example.com', role_ids: [ role.id ] }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:created)
      json_response_user1 = JSON.parse(@response.body)
      expect(json_response_user1).to be_truthy
      user = User.find(json_response_user1['id'])
      expect(user).not_to be_role('Admin')
      expect(user).not_to be_role('Agent')
      expect(user).to be_role('Customer')
      expect(json_response_user1['login']).to eq('new_agent_by_agent@example.com')
      expect(json_response_user1['email']).to eq('new_agent_by_agent@example.com')

      # create user with customer role
      role = Role.lookup(name: 'Customer')
      params = { firstname: "Customer#{firstname}", lastname: 'Customer Last', email: 'new_customer_by_agent@example.com', role_ids: [ role.id ] }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:created)
      json_response_user1 = JSON.parse(@response.body)
      expect(json_response_user1).to be_truthy
      user = User.find(json_response_user1['id'])
      expect(user).not_to be_role('Admin')
      expect(user).not_to be_role('Agent')
      expect(user).to be_role('Customer')
      expect(json_response_user1['login']).to eq('new_customer_by_agent@example.com')
      expect(json_response_user1['email']).to eq('new_customer_by_agent@example.com')

      # search as agent
      Scheduler.worker(true)
      sleep 2 # let es time to come ready
      get "/api/v1/users/search?query=#{CGI.escape("Customer#{firstname}")}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)

      expect(json_response[0]['id']).to eq(json_response_user1['id'])
      expect(json_response[0]['firstname']).to eq("Customer#{firstname}")
      expect(json_response[0]['lastname']).to eq('Customer Last')
      expect(json_response[0]['role_ids']).to be_truthy
      expect(json_response[0]['roles']).to be_falsey

      get "/api/v1/users/search?query=#{CGI.escape("Customer#{firstname}")}&expand=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0]['id']).to eq(json_response_user1['id'])
      expect(json_response[0]['firstname']).to eq("Customer#{firstname}")
      expect(json_response[0]['lastname']).to eq('Customer Last')
      expect(json_response[0]['role_ids']).to be_truthy
      expect(json_response[0]['roles']).to be_truthy

      get "/api/v1/users/search?query=#{CGI.escape("Customer#{firstname}")}&label=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0]['id']).to eq(json_response_user1['id'])
      expect(json_response[0]['label']).to eq("Customer#{firstname} Customer Last <new_customer_by_agent@example.com>")
      expect(json_response[0]['value']).to eq("Customer#{firstname} Customer Last <new_customer_by_agent@example.com>")
      expect(json_response[0]['role_ids']).to be_falsey
      expect(json_response[0]['roles']).to be_falsey

      get "/api/v1/users/search?term=#{CGI.escape("Customer#{firstname}")}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0]['id']).to eq(json_response_user1['id'])
      expect(json_response[0]['label']).to eq("Customer#{firstname} Customer Last <new_customer_by_agent@example.com>")
      expect(json_response[0]['value']).to eq('new_customer_by_agent@example.com')
      expect(json_response[0]['role_ids']).to be_falsey
      expect(json_response[0]['roles']).to be_falsey

      # Regression test for issue #2539 - search pagination broken in users_controller.rb
      # Get the total number of users N, then search with one result per page, so there should N pages with one result each
      get '/api/v1/users/search', params: { query: '*' }, as: :json
      total_user_number = json_response.count
      (1..total_user_number).each do |i|
        get '/api/v1/users/search', params: { query: '*', per_page: 1, page: i }, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response).to be_a_kind_of(Array)
        expect(json_response.count).to eq(1), "Page #{i}/#{total_user_number} of the user search pagination test have the wrong result!"
      end

      role = Role.find_by(name: 'Agent')
      get "/api/v1/users/search?query=#{CGI.escape("Customer#{firstname}")}&role_ids=#{role.id}&label=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response.count).to eq(0)

      role = Role.find_by(name: 'Customer')
      get "/api/v1/users/search?query=#{CGI.escape("Customer#{firstname}")}&role_ids=#{role.id}&label=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0]['id']).to eq(json_response_user1['id'])
      expect(json_response[0]['label']).to eq("Customer#{firstname} Customer Last <new_customer_by_agent@example.com>")
      expect(json_response[0]['value']).to eq("Customer#{firstname} Customer Last <new_customer_by_agent@example.com>")
      expect(json_response[0]['role_ids']).to be_falsey
      expect(json_response[0]['roles']).to be_falsey

      permission = Permission.find_by(name: 'ticket.agent')
      get "/api/v1/users/search?query=#{CGI.escape("Customer#{firstname}")}&permissions=#{permission.name}&label=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response.count).to eq(0)

      permission = Permission.find_by(name: 'ticket.customer')
      get "/api/v1/users/search?query=#{CGI.escape("Customer#{firstname}")}&permissions=#{permission.name}&label=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0]['id']).to eq(json_response_user1['id'])
      expect(json_response[0]['label']).to eq("Customer#{firstname} Customer Last <new_customer_by_agent@example.com>")
      expect(json_response[0]['value']).to eq("Customer#{firstname} Customer Last <new_customer_by_agent@example.com>")
      expect(json_response[0]['role_ids']).to be_falsey
      expect(json_response[0]['roles']).to be_falsey
    end

    it 'does user index and create with customer1' do
      authenticated_as(customer_user)
      get '/api/v1/users/me', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
      expect('rest-customer1@example.com').to eq(json_response['email'])

      # index
      get '/api/v1/users', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(Array).to eq(json_response.class)
      expect(1).to eq(json_response.length)

      # show/:id
      get "/api/v1/users/#{customer_user.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(Hash).to eq(json_response.class)
      expect('rest-customer1@example.com').to eq(json_response['email'])

      get "/api/v1/users/#{customer_user2.id}", params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(Hash).to eq(json_response.class)
      expect(json_response['error']).to be_truthy

      # create user with admin role
      role = Role.lookup(name: 'Admin')
      params = { firstname: 'Admin First', lastname: 'Admin Last', email: 'new_admin_by_customer1@example.com', role_ids: [ role.id ] }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:unauthorized)

      # create user with agent role
      role = Role.lookup(name: 'Agent')
      params = { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent_by_customer1@example.com', role_ids: [ role.id ] }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:unauthorized)

      # search
      Scheduler.worker(true)
      get "/api/v1/users/search?query=#{CGI.escape('First')}", params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'does user index with customer2' do
      authenticated_as(customer_user2)
      get '/api/v1/users/me', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_truthy
      expect('rest-customer2@example.com').to eq(json_response['email'])

      # index
      get '/api/v1/users', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(Array).to eq(json_response.class)
      expect(1).to eq(json_response.length)

      # show/:id
      get "/api/v1/users/#{customer_user2.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(Hash).to eq(json_response.class)
      expect('rest-customer2@example.com').to eq(json_response['email'])

      get "/api/v1/users/#{customer_user.id}", params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(Hash).to eq(json_response.class)
      expect(json_response['error']).to be_truthy

      # search
      Scheduler.worker(true)
      get "/api/v1/users/search?query=#{CGI.escape('First')}", params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'does users show and response format (04.01)' do
      user = create(
        :customer_user,
        login:         'rest-customer3@example.com',
        firstname:     'Rest',
        lastname:      'Customer3',
        email:         'rest-customer3@example.com',
        password:      'customer3pw',
        active:        true,
        organization:  organization,
        updated_by_id: admin_user.id,
        created_by_id: admin_user.id,
      )

      authenticated_as(admin_user)
      get "/api/v1/users/#{user.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(user.id)
      expect(json_response['firstname']).to eq(user.firstname)
      expect(json_response['organization']).to be_falsey
      expect(json_response['organization_id']).to eq(user.organization_id)
      expect(json_response['password']).to be_falsey
      expect(json_response['role_ids']).to eq(user.role_ids)
      expect(json_response['updated_by_id']).to eq(admin_user.id)
      expect(json_response['created_by_id']).to eq(admin_user.id)

      get "/api/v1/users/#{user.id}?expand=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(user.id)
      expect(json_response['firstname']).to eq(user.firstname)
      expect(json_response['organization_id']).to eq(user.organization_id)
      expect(json_response['organization']).to eq(user.organization.name)
      expect(json_response['role_ids']).to eq(user.role_ids)
      expect(json_response['password']).to be_falsey
      expect(json_response['updated_by_id']).to eq(admin_user.id)
      expect(json_response['created_by_id']).to eq(admin_user.id)

      get "/api/v1/users/#{user.id}?expand=false", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(user.id)
      expect(json_response['firstname']).to eq(user.firstname)
      expect(json_response['organization']).to be_falsey
      expect(json_response['organization_id']).to eq(user.organization_id)
      expect(json_response['password']).to be_falsey
      expect(json_response['role_ids']).to eq(user.role_ids)
      expect(json_response['updated_by_id']).to eq(admin_user.id)
      expect(json_response['created_by_id']).to eq(admin_user.id)

      get "/api/v1/users/#{user.id}?full=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(user.id)
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][user.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][user.id.to_s]['id']).to eq(user.id)
      expect(json_response['assets']['User'][user.id.to_s]['firstname']).to eq(user.firstname)
      expect(json_response['assets']['User'][user.id.to_s]['organization_id']).to eq(user.organization_id)
      expect(json_response['assets']['User'][user.id.to_s]['role_ids']).to eq(user.role_ids)

      get "/api/v1/users/#{user.id}?full=false", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['id']).to eq(user.id)
      expect(json_response['firstname']).to eq(user.firstname)
      expect(json_response['organization']).to be_falsey
      expect(json_response['organization_id']).to eq(user.organization_id)
      expect(json_response['password']).to be_falsey
      expect(json_response['role_ids']).to eq(user.role_ids)
      expect(json_response['updated_by_id']).to eq(admin_user.id)
      expect(json_response['created_by_id']).to eq(admin_user.id)
    end

    it 'does user index and response format (04.02)' do
      user = create(
        :customer_user,
        login:         'rest-customer3@example.com',
        firstname:     'Rest',
        lastname:      'Customer3',
        email:         'rest-customer3@example.com',
        password:      'customer3pw',
        active:        true,
        organization:  organization,
        updated_by_id: admin_user.id,
        created_by_id: admin_user.id,
      )

      authenticated_as(admin_user)
      get '/api/v1/users', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0].class).to eq(Hash)
      expect(json_response.last['id']).to eq(user.id)
      expect(json_response.last['lastname']).to eq(user.lastname)
      expect(json_response.last['organization']).to be_falsey
      expect(json_response.last['role_ids']).to eq(user.role_ids)
      expect(json_response.last['organization_id']).to eq(user.organization_id)
      expect(json_response.last['password']).to be_falsey
      expect(json_response.last['updated_by_id']).to eq(admin_user.id)
      expect(json_response.last['created_by_id']).to eq(admin_user.id)

      get '/api/v1/users?expand=true', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0].class).to eq(Hash)
      expect(json_response.last['id']).to eq(user.id)
      expect(json_response.last['lastname']).to eq(user.lastname)
      expect(json_response.last['organization_id']).to eq(user.organization_id)
      expect(json_response.last['organization']).to eq(user.organization.name)
      expect(json_response.last['password']).to be_falsey
      expect(json_response.last['updated_by_id']).to eq(admin_user.id)
      expect(json_response.last['created_by_id']).to eq(admin_user.id)

      get '/api/v1/users?expand=false', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0].class).to eq(Hash)
      expect(json_response.last['id']).to eq(user.id)
      expect(json_response.last['lastname']).to eq(user.lastname)
      expect(json_response.last['organization']).to be_falsey
      expect(json_response.last['role_ids']).to eq(user.role_ids)
      expect(json_response.last['organization_id']).to eq(user.organization_id)
      expect(json_response.last['password']).to be_falsey
      expect(json_response.last['updated_by_id']).to eq(admin_user.id)
      expect(json_response.last['created_by_id']).to eq(admin_user.id)

      get '/api/v1/users?full=true', params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['record_ids'].class).to eq(Array)
      expect(json_response['record_ids'][0]).to eq(1)
      expect(json_response['record_ids'].last).to eq(user.id)
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][user.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][user.id.to_s]['id']).to eq(user.id)
      expect(json_response['assets']['User'][user.id.to_s]['lastname']).to eq(user.lastname)
      expect(json_response['assets']['User'][user.id.to_s]['organization_id']).to eq(user.organization_id)
      expect(json_response['assets']['User'][user.id.to_s]['password']).to be_falsey

      get '/api/v1/users?full=false', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response[0].class).to eq(Hash)
      expect(json_response.last['id']).to eq(user.id)
      expect(json_response.last['lastname']).to eq(user.lastname)
      expect(json_response.last['organization']).to be_falsey
      expect(json_response.last['role_ids']).to eq(user.role_ids)
      expect(json_response.last['organization_id']).to eq(user.organization_id)
      expect(json_response.last['password']).to be_falsey
      expect(json_response.last['updated_by_id']).to eq(admin_user.id)
      expect(json_response.last['created_by_id']).to eq(admin_user.id)
    end

    it 'does ticket create and response format (04.03)' do
      organization = Organization.first
      params = {
        firstname:    'newfirstname123',
        note:         'some note',
        organization: organization.name,
      }

      authenticated_as(admin_user)
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)

      user = User.find(json_response['id'])
      expect(json_response['firstname']).to eq(user.firstname)
      expect(json_response['organization_id']).to eq(user.organization_id)
      expect(json_response['organization']).to be_falsey
      expect(json_response['password']).to be_falsey
      expect(json_response['updated_by_id']).to eq(admin_user.id)
      expect(json_response['created_by_id']).to eq(admin_user.id)

      post '/api/v1/users?expand=true', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)

      user = User.find(json_response['id'])
      expect(json_response['firstname']).to eq(user.firstname)
      expect(json_response['organization_id']).to eq(user.organization_id)
      expect(json_response['organization']).to eq(user.organization.name)
      expect(json_response['password']).to be_falsey
      expect(json_response['updated_by_id']).to eq(admin_user.id)
      expect(json_response['created_by_id']).to eq(admin_user.id)

      post '/api/v1/users?full=true', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)

      user = User.find(json_response['id'])
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][user.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][user.id.to_s]['id']).to eq(user.id)
      expect(json_response['assets']['User'][user.id.to_s]['firstname']).to eq(user.firstname)
      expect(json_response['assets']['User'][user.id.to_s]['lastname']).to eq(user.lastname)
      expect(json_response['assets']['User'][user.id.to_s]['password']).to be_falsey

      expect(json_response['assets']['User'][admin_user.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][admin_user.id.to_s]['id']).to eq(admin_user.id)
      expect(json_response['assets']['User'][admin_user.id.to_s]['firstname']).to eq(admin_user.firstname)
      expect(json_response['assets']['User'][admin_user.id.to_s]['lastname']).to eq(admin_user.lastname)
      expect(json_response['assets']['User'][admin_user.id.to_s]['password']).to be_falsey

    end

    it 'does ticket update and response formats (04.04)' do
      user = create(
        :customer_user,
        login:         'rest-customer3@example.com',
        firstname:     'Rest',
        lastname:      'Customer3',
        email:         'rest-customer3@example.com',
        password:      'customer3pw',
        active:        true,
        organization:  organization,
        updated_by_id: admin_user.id,
        created_by_id: admin_user.id,
      )

      authenticated_as(admin_user)
      params = {
        firstname: 'a update firstname #1',
      }
      put "/api/v1/users/#{user.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      user = User.find(json_response['id'])
      expect(json_response['lastname']).to eq(user.lastname)
      expect(json_response['firstname']).to eq(params[:firstname])
      expect(json_response['organization_id']).to eq(user.organization_id)
      expect(json_response['organization']).to be_falsey
      expect(json_response['password']).to be_falsey
      expect(json_response['updated_by_id']).to eq(admin_user.id)
      expect(json_response['created_by_id']).to eq(admin_user.id)

      params = {
        firstname: 'a update firstname #2',
      }
      put "/api/v1/users/#{user.id}?expand=true", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      user = User.find(json_response['id'])
      expect(json_response['lastname']).to eq(user.lastname)
      expect(json_response['firstname']).to eq(params[:firstname])
      expect(json_response['organization_id']).to eq(user.organization_id)
      expect(json_response['organization']).to eq(user.organization.name)
      expect(json_response['password']).to be_falsey
      expect(json_response['updated_by_id']).to eq(admin_user.id)
      expect(json_response['created_by_id']).to eq(admin_user.id)

      params = {
        firstname: 'a update firstname #3',
      }
      put "/api/v1/users/#{user.id}?full=true", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      user = User.find(json_response['id'])
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][user.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][user.id.to_s]['id']).to eq(user.id)
      expect(json_response['assets']['User'][user.id.to_s]['firstname']).to eq(params[:firstname])
      expect(json_response['assets']['User'][user.id.to_s]['lastname']).to eq(user.lastname)
      expect(json_response['assets']['User'][user.id.to_s]['password']).to be_falsey

      expect(json_response['assets']['User'][admin_user.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][admin_user.id.to_s]['id']).to eq(admin_user.id)
      expect(json_response['assets']['User'][admin_user.id.to_s]['firstname']).to eq(admin_user.firstname)
      expect(json_response['assets']['User'][admin_user.id.to_s]['lastname']).to eq(admin_user.lastname)
      expect(json_response['assets']['User'][admin_user.id.to_s]['password']).to be_falsey

    end

    it 'does csv example - customer no access (05.01)' do

      authenticated_as(customer_user)
      get '/api/v1/users/import_example', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Not authorized (user)!')
    end

    it 'does csv example - admin access (05.02)' do

      authenticated_as(admin_user)
      get '/api/v1/users/import_example', params: {}, as: :json
      expect(response).to have_http_status(:ok)

      rows = CSV.parse(@response.body)
      header = rows.shift

      expect(header[0]).to eq('id')
      expect(header[1]).to eq('login')
      expect(header[2]).to eq('firstname')
      expect(header[3]).to eq('lastname')
      expect(header[4]).to eq('email')
      expect(header).to include('organization')
    end

    it 'does csv import - admin access (05.03)' do

      # invalid file
      csv_file = fixture_file_upload('csv_import/user/simple_col_not_existing.csv', 'text/csv')
      authenticated_as(admin_user)
      post '/api/v1/users/import?try=true', params: { file: csv_file, col_sep: ';' }
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['try']).to eq(true)
      expect(json_response['records'].count).to eq(2)
      expect(json_response['result']).to eq('failed')
      expect(json_response['errors'].count).to eq(2)
      expect(json_response['errors'][0]).to eq("Line 1: Unable to create record - unknown attribute 'firstname2' for User.")
      expect(json_response['errors'][1]).to eq("Line 2: Unable to create record - unknown attribute 'firstname2' for User.")

      # valid file try
      csv_file = fixture_file_upload('csv_import/user/simple.csv', 'text/csv')
      post '/api/v1/users/import?try=true', params: { file: csv_file, col_sep: ';' }
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['try']).to eq(true)
      expect(json_response['records'].count).to eq(2)
      expect(json_response['result']).to eq('success')

      expect(User.find_by(login: 'user-simple-import1')).to be_nil
      expect(User.find_by(login: 'user-simple-import2')).to be_nil

      # valid file
      csv_file = fixture_file_upload('csv_import/user/simple.csv', 'text/csv')
      post '/api/v1/users/import', params: { file: csv_file, col_sep: ';' }
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['try']).to eq(false)
      expect(json_response['records'].count).to eq(2)
      expect(json_response['result']).to eq('success')

      user1 = User.find_by(login: 'user-simple-import1')
      expect(user1).to be_truthy
      expect(user1.login).to eq('user-simple-import1')
      expect(user1.firstname).to eq('firstname-simple-import1')
      expect(user1.lastname).to eq('lastname-simple-import1')
      expect(user1.email).to eq('user-simple-import1@example.com')
      expect(user1.active).to eq(true)
      user2 = User.find_by(login: 'user-simple-import2')
      expect(user2).to be_truthy
      expect(user2.login).to eq('user-simple-import2')
      expect(user2.firstname).to eq('firstname-simple-import2')
      expect(user2.lastname).to eq('lastname-simple-import2')
      expect(user2.email).to eq('user-simple-import2@example.com')
      expect(user2.active).to eq(false)

      user1.destroy!
      user2.destroy!
    end

    it 'does user history' do
      user1 = create(
        :customer_user,
        login:     'history@example.com',
        firstname: 'History',
        lastname:  'Customer1',
        email:     'history@example.com',
      )

      authenticated_as(agent_user)
      get "/api/v1/users/history/#{user1.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['history'].class).to eq(Array)
      expect(json_response['assets'].class).to eq(Hash)
      expect(json_response['assets']['Ticket']).to be_nil
      expect(json_response['assets']['User'][user1.id.to_s]).not_to be_nil
    end

    it 'does user search sortable' do
      firstname = "user_search_sortable #{rand(999_999_999)}"

      user1 = create(
        :customer_user,
        login:           'rest-user_search_sortableA@example.com',
        firstname:       "#{firstname} A",
        lastname:        'user_search_sortableA',
        email:           'rest-user_search_sortableA@example.com',
        password:        'user_search_sortableA',
        active:          true,
        organization_id: organization.id,
        out_of_office:   false,
        created_at:      '2016-02-05 17:42:00',
      )
      user2 = create(
        :customer_user,
        login:                        'rest-user_search_sortableB@example.com',
        firstname:                    "#{firstname} B",
        lastname:                     'user_search_sortableB',
        email:                        'rest-user_search_sortableB@example.com',
        password:                     'user_search_sortableB',
        active:                       true,
        organization_id:              organization.id,
        out_of_office_start_at:       '2016-02-06 19:42:00',
        out_of_office_end_at:         '2016-02-07 19:42:00',
        out_of_office_replacement_id: 1,
        out_of_office:                true,
        created_at:                   '2016-02-05 19:42:00',
      )
      Scheduler.worker(true)
      sleep 2 # let es time to come ready

      authenticated_as(admin_user)
      get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: 'created_at', order_by: 'asc' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to eq([user1.id, user2.id])

      get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: 'firstname', order_by: 'asc' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to eq([user1.id, user2.id])

      get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: 'firstname', order_by: 'desc' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to eq([user2.id, user1.id])

      get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: %w[firstname created_at], order_by: %w[desc asc] }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to eq([user2.id, user1.id])

      get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: %w[firstname created_at], order_by: %w[desc asc] }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to eq([user2.id, user1.id])

      get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: 'out_of_office', order_by: 'asc' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to eq([user1.id, user2.id])

      get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: 'out_of_office', order_by: 'desc' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to eq([user2.id, user1.id])

      get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: %w[created_by_id created_at], order_by: %w[asc asc] }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to eq([user1.id, user2.id])
    end
  end
end
