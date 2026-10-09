# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'User', performs_jobs: true, type: :request do

  describe 'request handling' do
    let!(:admin) do
      create(
        :admin,
        groups:    Group.all,
        login:     'rest-admin',
        firstname: 'Rest',
        lastname:  'Agent',
        email:     'rest-admin@example.com',
      )
    end
    let!(:admin_with_pw) do
      create(
        :admin,
        groups:    Group.all,
        login:     'rest-admin-pw',
        firstname: 'Rest',
        lastname:  'Agent',
        email:     'rest-admin-pw@example.com',
        password:  'adminpw',
      )
    end
    let!(:agent) do
      create(
        :agent,
        groups:    Group.all,
        login:     'rest-agent@example.com',
        firstname: 'Rest',
        lastname:  'Agent',
        email:     'rest-agent@example.com',
      )
    end
    let!(:customer) do
      create(
        :customer,
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
    let!(:customer2) do
      create(
        :customer,
        organization: organization,
        login:        'rest-customer2@example.com',
        firstname:    'Rest',
        lastname:     'Customer2',
        email:        'rest-customer2@example.com',
      )
    end

    let!(:customer_inactive) do
      create(
        :customer,
        organization: organization,
        login:        'rest-customer_inactive@example.com',
        firstname:    'Rest',
        lastname:     'CustomerInactive',
        email:        'rest-customer_inactive@example.com',
        active:       false,
      )
    end

    context 'when signing up without a session' do
      let(:token) do
        post '/api/v1/signshow', params: {}, as: :json
        response.headers['CSRF-TOKEN']
      end

      it 'accepts the CSRF token from the form and from the headers', :aggregate_failures do
        Setting.set('user_create_account', false)

        post '/api/v1/users', params: { email: 'some_new_customer@example.com', signup: true, authenticity_token: token }, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq('This feature is not enabled.')

        post '/api/v1/users', params: { email: 'some_new_customer@example.com', signup: true }, headers: { 'X-CSRF-Token' => token }, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq('This feature is not enabled.')
      end

      it 'requires a password', :aggregate_failures do
        post '/api/v1/users', params: { email: 'some_new_customer@example.com', signup: true }, headers: { 'X-CSRF-Token' => token }, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['message']).to eq('failed')
        expect(User.find_by(email: 'some_new_customer@example.com')).to be_nil
      end

      it 'ignores a requested admin role', :aggregate_failures do
        params = { firstname: 'Admin First', lastname: 'Admin Last', email: 'new_admin@example.com', role_ids: [Role.lookup(name: 'Admin').id], signup: true, password: '1asdASDasd' }
        post '/api/v1/users', params: params, headers: { 'X-CSRF-Token' => token }, as: :json
        expect(response).to have_http_status(:created)

        user = User.find_by(email: 'new_admin@example.com')
        expect(user).not_to be_role('Admin')
        expect(user).to be_role('Customer')
      end

      it 'does not list users', :aggregate_failures do
        get '/api/v1/users', params: {}, as: :json
        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('Authentication required')

        get '/api/v1/users/me', params: {}, as: :json
        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('Authentication required')
      end
    end

    it 'does not create user with verified state' do
      params = { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent@example.com', signup: true, password: '1asdASDasd', verified: true }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy
      user = User.find_by email: 'new_agent@example.com'
      expect(user.verified).to be(false)
    end

    it 'does not create user with ticket groups permissions' do
      users_group = Group.find_by(name: 'Users')
      params = { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent@example.com', signup: true, password: '1asdASDasd', verified: true, group_ids: { users_group.id => 'full' } }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_truthy
      user = User.find_by email: 'new_agent@example.com'
      expect(user.groups).to eq([])
    end

    it 'does not create user with verified state as customer' do
      authenticated_as(customer)
      params = { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent@example.com', signup: true, password: '1asdASDasd', verified: true }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(User.find_by(email: 'new_agent@example.com')).to be_nil
    end

    it 'does not create user with ticket groups permissions as customer' do
      authenticated_as(customer)
      users_group = Group.find_by(name: 'Users')
      params = { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent@example.com', signup: true, password: '1asdASDasd', verified: true, group_ids: { users_group.id => 'full' } }
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(User.find_by(email: 'new_agent@example.com')).to be_nil
    end

    context 'password security' do
      it 'verified with no current user' do
        params = { email: 'some_new_customer@example.com', password: 'asdasdasdasd', signup: true }
        post '/api/v1/users', params: params, headers: headers, as: :json
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['notice']).to include(include('Invalid password'))
      end

      it 'is not verified with current admin user', authenticated_as: :admin do
        params = { email: 'some_new_customer@example.com', password: 'asd' }
        post '/api/v1/users', params: params, headers: headers, as: :json
        expect(response).to have_http_status(:created)
        expect(User.find_by(email: 'some_new_customer@example.com')).to be_present
      end
    end

    it 'does auth tests - not existing user' do
      authenticated_as(nil, login: 'not_existing@example.com', password: 'adminpw')
      get '/api/v1/users/me', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Invalid BasicAuth credentials')

      get '/api/v1/users', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Invalid BasicAuth credentials')
    end

    it 'does auth tests - username auth, wrong pw' do
      authenticated_as(admin, password: 'not_existing')
      get '/api/v1/users', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Invalid BasicAuth credentials')
    end

    it 'does auth tests - email auth, wrong pw' do
      authenticated_as(nil, login: 'rest-admin@example.com', password: 'not_existing')
      get '/api/v1/users', params: {}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Invalid BasicAuth credentials')
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

    context 'when requested by an admin' do
      before { authenticated_as(admin) }

      it 'shows the current user, the user list and single users', :aggregate_failures do
        get '/api/v1/users/me', params: {}, as: :json
        expect(json_response['email']).to eq('rest-admin@example.com')

        get '/api/v1/users', params: {}, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response.pluck('id')).to include(admin.id, agent.id, customer.id)

        get "/api/v1/users/#{agent.id}", params: {}, as: :json
        expect(json_response['email']).to eq('rest-agent@example.com')

        get "/api/v1/users/#{customer.id}", params: {}, as: :json
        expect(json_response['email']).to eq('rest-customer1@example.com')
      end

      it 'creates a user with the admin role', :aggregate_failures do
        post '/api/v1/users', params: { firstname: 'Admin First', lastname: 'Admin Last', email: 'new_admin_by_admin@example.com', role_ids: [Role.lookup(name: 'Admin').id] }, as: :json

        expect(response).to have_http_status(:created)
        expect(json_response).to include('login' => 'new_admin_by_admin@example.com', 'email' => 'new_admin_by_admin@example.com')
        expect(User.find(json_response['id']).roles.map(&:name)).to eq(['Admin'])
      end

      it 'creates a user with the agent role', :aggregate_failures do
        post '/api/v1/users', params: { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent_by_admin1@example.com', role_ids: [Role.lookup(name: 'Agent').id] }, as: :json

        expect(response).to have_http_status(:created)
        expect(User.find(json_response['id']).roles.map(&:name)).to eq(['Agent'])
      end

      it 'splits a lone first name into first and last name' do
        post '/api/v1/users', params: { firstname: 'Agent First', email: 'new_agent_by_admin2@example.com' }, as: :json

        expect(json_response).to include('firstname' => 'Agent', 'lastname' => 'First')
      end

      it 'rejects an email address that is already used', :aggregate_failures do
        post '/api/v1/users', params: { firstname: 'Agent First', email: agent.email }, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq("Email address '#{agent.email}' is already used for another user.")
      end

      it 'creates a customer without email with a generated login', :aggregate_failures do
        post '/api/v1/users', params: { firstname: 'newfirstname123', note: 'some note' }, as: :json

        expect(response).to have_http_status(:created)
        expect(json_response).to include('email' => '', 'firstname' => 'newfirstname123', 'lastname' => '')
        expect(json_response['login']).to start_with('auto-')
        expect(User.find(json_response['id']).roles.map(&:name)).to eq(['Customer'])
      end
    end

    context 'when requested by an agent' do
      before { authenticated_as(agent) }

      it 'pages the user list', :aggregate_failures do
        users = User.reorder(:id).limit(4)

        get '/api/v1/users?limit=40&page=1&per_page=2', params: {}, as: :json
        expect(json_response.pluck('id')).to eq(users[0..1].map(&:id))

        get '/api/v1/users?limit=40&page=2&per_page=2', params: {}, as: :json
        expect(json_response.pluck('id')).to eq(users[2..3].map(&:id))
      end

      %w[Admin Agent Customer].each do |role_name|
        it "creates a customer when the #{role_name} role is requested", :aggregate_failures do
          post '/api/v1/users', params: { firstname: 'First', lastname: 'Last', email: "new_#{role_name.downcase}_by_agent@example.com", role_ids: [Role.lookup(name: role_name).id] }, as: :json

          expect(response).to have_http_status(:created)
          expect(json_response).to include('login' => "new_#{role_name.downcase}_by_agent@example.com")
          expect(User.find(json_response['id']).roles.map(&:name)).to eq(['Customer'])
        end
      end

      context 'when searching' do
        let(:firstname)     { "Customer#{SecureRandom.uuid}" }
        let!(:new_customer) { create(:customer, firstname:, lastname: 'Customer Last', email: 'new_customer_by_agent@example.com') }

        def search(**params)
          get '/api/v1/users/search', params: { query: firstname, label: true }.merge(params), as: :json
          json_response.pluck('id')
        end

        it 'filters by role', :aggregate_failures do
          expect(search(role_ids: Role.find_by(name: 'Agent').id)).to be_empty
          expect(search(role_ids: Role.find_by(name: 'Customer').id)).to eq([new_customer.id])
        end

        it 'filters by permission', :aggregate_failures do
          expect(search(permissions: 'ticket.agent')).to be_empty
          expect(search(permissions: 'ticket.customer')).to eq([new_customer.id])
        end

        it 'returns the display string as label and value in a label search', :aggregate_failures do
          get '/api/v1/users/search', params: { query: firstname, label: true }, as: :json

          expect(json_response.first).to include(
            'label' => "#{firstname} Customer Last <new_customer_by_agent@example.com>",
            'value' => "#{firstname} Customer Last <new_customer_by_agent@example.com>",
          )
        end

        it 'returns the email address as value in a term search', :aggregate_failures do
          get '/api/v1/users/search', params: { term: firstname }, as: :json

          expect(json_response.first).to include(
            'label' => "#{firstname} Customer Last <new_customer_by_agent@example.com>",
            'value' => 'new_customer_by_agent@example.com',
          )
        end

        it 'flags inactive users in a term search' do
          get '/api/v1/users/search', params: { term: 'CustomerInactive' }, as: :json

          expect(json_response.first).to include('id' => customer_inactive.id, 'inactive' => true)
        end

        # Regression test for issue #2539 - search pagination broken in users_controller.rb
        it 'returns one user per page' do
          get '/api/v1/users/search', params: { query: '*' }, as: :json
          total_number = json_response.count

          counts = (1..total_number).map do |page|
            get '/api/v1/users/search', params: { query: '*', per_page: 1, page: }, as: :json
            json_response.count
          end

          expect(counts).to all(eq(1))
        end
      end
    end

    shared_examples 'restricting a customer to itself' do |email|
      it 'shows the customer and nobody else', :aggregate_failures do
        get '/api/v1/users/me', params: {}, as: :json
        expect(json_response['email']).to eq(email)

        get '/api/v1/users', params: {}, as: :json
        expect(json_response.pluck('email')).to eq([email])

        get "/api/v1/users/#{other_customer.id}", params: {}, as: :json
        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('Not authorized')
      end

      it 'does not search users' do
        get '/api/v1/users/search', params: { query: 'First' }, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when requested by customer1' do
      let(:other_customer) { customer2 }

      before { authenticated_as(customer) }

      include_examples 'restricting a customer to itself', 'rest-customer1@example.com'

      it 'does not create users', :aggregate_failures do
        post '/api/v1/users', params: { firstname: 'Agent First', lastname: 'Agent Last', email: 'new_agent_by_customer1@example.com', role_ids: [Role.lookup(name: 'Agent').id] }, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(User.find_by(email: 'new_agent_by_customer1@example.com')).to be_nil
      end
    end

    context 'when requested by customer2' do
      let(:other_customer) { customer }

      before { authenticated_as(customer2) }

      include_examples 'restricting a customer to itself', 'rest-customer2@example.com'
    end

    it 'does users show and response format (04.01)' do
      user = create(
        :customer,
        login:         'rest-customer3@example.com',
        firstname:     'Rest',
        lastname:      'Customer3',
        email:         'rest-customer3@example.com',
        password:      'customer3pw',
        active:        true,
        organization:  organization,
        updated_by_id: admin.id,
        created_by_id: admin.id,
      )

      authenticated_as(admin)
      get "/api/v1/users/#{user.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['id']).to eq(user.id)
      expect(json_response['firstname']).to eq(user.firstname)
      expect(json_response['organization']).to be_falsey
      expect(json_response['organization_id']).to eq(user.organization_id)
      expect(json_response['password']).to be_falsey
      expect(json_response['role_ids']).to eq(user.role_ids)
      expect(json_response['updated_by_id']).to eq(admin.id)
      expect(json_response['created_by_id']).to eq(admin.id)

      get "/api/v1/users/#{user.id}?expand=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['id']).to eq(user.id)
      expect(json_response['firstname']).to eq(user.firstname)
      expect(json_response['organization_id']).to eq(user.organization_id)
      expect(json_response['organization']).to eq(user.organization.name)
      expect(json_response['role_ids']).to eq(user.role_ids)
      expect(json_response['password']).to be_falsey
      expect(json_response['updated_by_id']).to eq(admin.id)
      expect(json_response['created_by_id']).to eq(admin.id)

      get "/api/v1/users/#{user.id}?expand=false", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['id']).to eq(user.id)
      expect(json_response['firstname']).to eq(user.firstname)
      expect(json_response['organization']).to be_falsey
      expect(json_response['organization_id']).to eq(user.organization_id)
      expect(json_response['password']).to be_falsey
      expect(json_response['role_ids']).to eq(user.role_ids)
      expect(json_response['updated_by_id']).to eq(admin.id)
      expect(json_response['created_by_id']).to eq(admin.id)

      get "/api/v1/users/#{user.id}?full=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a(Hash)
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
      expect(json_response).to be_a(Hash)
      expect(json_response['id']).to eq(user.id)
      expect(json_response['firstname']).to eq(user.firstname)
      expect(json_response['organization']).to be_falsey
      expect(json_response['organization_id']).to eq(user.organization_id)
      expect(json_response['password']).to be_falsey
      expect(json_response['role_ids']).to eq(user.role_ids)
      expect(json_response['updated_by_id']).to eq(admin.id)
      expect(json_response['created_by_id']).to eq(admin.id)
    end

    it 'does user index and response format (04.02)' do
      user = create(
        :customer,
        login:         'rest-customer3@example.com',
        firstname:     'Rest',
        lastname:      'Customer3',
        email:         'rest-customer3@example.com',
        password:      'customer3pw',
        active:        true,
        organization:  organization,
        updated_by_id: admin.id,
        created_by_id: admin.id,
      )

      authenticated_as(admin)
      get '/api/v1/users', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response[0].class).to eq(Hash)
      expect(json_response.last['id']).to eq(user.id)
      expect(json_response.last['lastname']).to eq(user.lastname)
      expect(json_response.last['organization']).to be_falsey
      expect(json_response.last['role_ids']).to eq(user.role_ids)
      expect(json_response.last['organization_id']).to eq(user.organization_id)
      expect(json_response.last['password']).to be_falsey
      expect(json_response.last['updated_by_id']).to eq(admin.id)
      expect(json_response.last['created_by_id']).to eq(admin.id)

      get '/api/v1/users?expand=true', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response[0].class).to eq(Hash)
      expect(json_response.last['id']).to eq(user.id)
      expect(json_response.last['lastname']).to eq(user.lastname)
      expect(json_response.last['organization_id']).to eq(user.organization_id)
      expect(json_response.last['organization']).to eq(user.organization.name)
      expect(json_response.last['password']).to be_falsey
      expect(json_response.last['updated_by_id']).to eq(admin.id)
      expect(json_response.last['created_by_id']).to eq(admin.id)

      get '/api/v1/users?expand=false', params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response[0].class).to eq(Hash)
      expect(json_response.last['id']).to eq(user.id)
      expect(json_response.last['lastname']).to eq(user.lastname)
      expect(json_response.last['organization']).to be_falsey
      expect(json_response.last['role_ids']).to eq(user.role_ids)
      expect(json_response.last['organization_id']).to eq(user.organization_id)
      expect(json_response.last['password']).to be_falsey
      expect(json_response.last['updated_by_id']).to eq(admin.id)
      expect(json_response.last['created_by_id']).to eq(admin.id)

      get '/api/v1/users?full=true', params: {}, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a(Hash)
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
      expect(json_response).to be_a(Array)
      expect(json_response[0].class).to eq(Hash)
      expect(json_response.last['id']).to eq(user.id)
      expect(json_response.last['lastname']).to eq(user.lastname)
      expect(json_response.last['organization']).to be_falsey
      expect(json_response.last['role_ids']).to eq(user.role_ids)
      expect(json_response.last['organization_id']).to eq(user.organization_id)
      expect(json_response.last['password']).to be_falsey
      expect(json_response.last['updated_by_id']).to eq(admin.id)
      expect(json_response.last['created_by_id']).to eq(admin.id)
    end

    it 'does ticket create and response format (04.03)' do
      organization = Organization.first
      params = {
        firstname:    'newfirstname123',
        note:         'some note',
        organization: organization.name,
      }

      authenticated_as(admin)
      post '/api/v1/users', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)

      user = User.find(json_response['id'])
      expect(json_response['firstname']).to eq(user.firstname)
      expect(json_response['organization_id']).to eq(user.organization_id)
      expect(json_response['organization']).to be_falsey
      expect(json_response['password']).to be_falsey
      expect(json_response['updated_by_id']).to eq(admin.id)
      expect(json_response['created_by_id']).to eq(admin.id)

      post '/api/v1/users?expand=true', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)

      user = User.find(json_response['id'])
      expect(json_response['firstname']).to eq(user.firstname)
      expect(json_response['organization_id']).to eq(user.organization_id)
      expect(json_response['organization']).to eq(user.organization.name)
      expect(json_response['password']).to be_falsey
      expect(json_response['updated_by_id']).to eq(admin.id)
      expect(json_response['created_by_id']).to eq(admin.id)

      post '/api/v1/users?full=true', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)

      user = User.find(json_response['id'])
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][user.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][user.id.to_s]['id']).to eq(user.id)
      expect(json_response['assets']['User'][user.id.to_s]['firstname']).to eq(user.firstname)
      expect(json_response['assets']['User'][user.id.to_s]['lastname']).to eq(user.lastname)
      expect(json_response['assets']['User'][user.id.to_s]['password']).to be_falsey
    end

    it 'does ticket update and response formats (04.04)' do
      user = create(
        :customer,
        login:         'rest-customer3@example.com',
        firstname:     'Rest',
        lastname:      'Customer3',
        email:         'rest-customer3@example.com',
        password:      'customer3pw',
        active:        true,
        organization:  organization,
        updated_by_id: admin.id,
        created_by_id: admin.id,
      )

      authenticated_as(admin)
      params = {
        firstname: 'a update firstname #1',
      }
      put "/api/v1/users/#{user.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      user = User.find(json_response['id'])
      expect(json_response['lastname']).to eq(user.lastname)
      expect(json_response['firstname']).to eq(params[:firstname])
      expect(json_response['organization_id']).to eq(user.organization_id)
      expect(json_response['organization']).to be_falsey
      expect(json_response['password']).to be_falsey
      expect(json_response['updated_by_id']).to eq(admin.id)
      expect(json_response['created_by_id']).to eq(admin.id)

      params = {
        firstname: 'a update firstname #2',
      }
      put "/api/v1/users/#{user.id}?expand=true", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      user = User.find(json_response['id'])
      expect(json_response['lastname']).to eq(user.lastname)
      expect(json_response['firstname']).to eq(params[:firstname])
      expect(json_response['organization_id']).to eq(user.organization_id)
      expect(json_response['organization']).to eq(user.organization.name)
      expect(json_response['password']).to be_falsey
      expect(json_response['updated_by_id']).to eq(admin.id)
      expect(json_response['created_by_id']).to eq(admin.id)

      params = {
        firstname: 'a update firstname #3',
      }
      put "/api/v1/users/#{user.id}?full=true", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      user = User.find(json_response['id'])
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['User']).to be_truthy
      expect(json_response['assets']['User'][user.id.to_s]).to be_truthy
      expect(json_response['assets']['User'][user.id.to_s]['id']).to eq(user.id)
      expect(json_response['assets']['User'][user.id.to_s]['firstname']).to eq(params[:firstname])
      expect(json_response['assets']['User'][user.id.to_s]['lastname']).to eq(user.lastname)
      expect(json_response['assets']['User'][user.id.to_s]['password']).to be_falsey
    end

    it 'does csv example - customer no access (05.01)' do

      authenticated_as(customer)
      get '/api/v1/users/import_example', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('User authorization failed.')
    end

    it 'does csv example - admin access (05.02)' do

      authenticated_as(admin)
      get '/api/v1/users/import_example', params: {}, as: :json
      expect(response).to have_http_status(:ok)

      rows = CSV.parse(response.body)
      header = rows.shift

      expect(header[0]).to eq('id')
      expect(header[1]).to eq('login')
      expect(header[2]).to eq('firstname')
      expect(header[3]).to eq('lastname')
      expect(header[4]).to eq('email')
      expect(header).to include('organization')
    end

    it 'does csv import - admin access (05.03)' do

      authenticated_as(admin)

      # valid file try
      csv_file = fixture_file_upload('csv_import/user/simple.csv', 'text/csv')
      post '/api/v1/users/import?try=true', params: { file: csv_file, col_sep: ';' }
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      expect(json_response['try']).to be(true)
      expect(json_response['records'].count).to eq(2)
      expect(json_response['result']).to eq('success')

      expect(User.find_by(login: 'user-simple-import1')).to be_nil
      expect(User.find_by(login: 'user-simple-import2')).to be_nil

      # valid file
      csv_file = fixture_file_upload('csv_import/user/simple.csv', 'text/csv')
      post '/api/v1/users/import', params: { file: csv_file, col_sep: ';' }
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      expect(json_response['try']).to be(false)
      expect(json_response['records'].count).to eq(2)
      expect(json_response['result']).to eq('success')

      user1 = User.find_by(login: 'user-simple-import1')
      expect(user1).to be_truthy
      expect(user1.login).to eq('user-simple-import1')
      expect(user1.firstname).to eq('firstname-simple-import1')
      expect(user1.lastname).to eq('lastname-simple-import1')
      expect(user1.email).to eq('user-simple-import1@example.com')
      expect(user1.active).to be(true)
      user2 = User.find_by(login: 'user-simple-import2')
      expect(user2).to be_truthy
      expect(user2.login).to eq('user-simple-import2')
      expect(user2.firstname).to eq('firstname-simple-import2')
      expect(user2.lastname).to eq('lastname-simple-import2')
      expect(user2.email).to eq('user-simple-import2@example.com')
      expect(user2.active).to be(false)

      user1.destroy!
      user2.destroy!
    end

    it 'does user history' do
      user1 = create(
        :customer,
        login:     'history@example.com',
        firstname: 'History',
        lastname:  'Customer1',
        email:     'history@example.com',
      )

      authenticated_as(agent)
      get "/api/v1/users/history/#{user1.id}", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['history'].class).to eq(Array)
      expect(json_response['assets'].class).to eq(Hash)
      expect(json_response['assets']['Ticket']).to be_nil
      expect(json_response['assets']['User'][user1.id.to_s]).not_to be_nil
    end

    it 'does user search sortable' do
      firstname = "user_search_sortable #{SecureRandom.uuid}"

      user1 = create(
        :customer,
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
        :customer,
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
      perform_enqueued_jobs

      authenticated_as(admin)
      get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: 'created_at', order_by: 'asc' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to eq([user1.id, user2.id])

      get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: 'firstname', order_by: 'asc' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to eq([user1.id, user2.id])

      get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: 'firstname', order_by: 'desc' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to eq([user2.id, user1.id])

      get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: %w[firstname created_at], order_by: %w[desc asc] }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to eq([user2.id, user1.id])

      get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: %w[firstname created_at], order_by: %w[desc asc] }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to eq([user2.id, user1.id])

      get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: 'out_of_office', order_by: 'asc' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to eq([user1.id, user2.id])

      get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: 'out_of_office', order_by: 'desc' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to eq([user2.id, user1.id])

      get "/api/v1/users/search?query=#{CGI.escape(firstname)}", params: { sort_by: %w[created_by_id created_at], order_by: %w[asc asc] }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      result = json_response
      result.collect! { |v| v['id'] }
      expect(result).to eq([user1.id, user2.id])
    end

    context 'does password reset send work' do
      let(:user) { create(:customer, login: 'somebody', email: 'somebody@example.com') }

      context 'for user without email address' do
        let(:user) { create(:customer, login: 'somebody', email: '') }

        it 'return failed' do
          post '/api/v1/users/password_reset', params: { username: user.login }, as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response).to be_a(Hash)
          expect(json_response['message']).to eq('ok')
        end
      end

      context 'for user with email address' do
        it 'return ok' do
          post '/api/v1/users/password_reset', params: { username: user.login }, as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response).to be_a(Hash)
          expect(json_response['message']).to eq('ok')
        end
      end

      context 'for user with email address but disabled feature' do
        before { Setting.set('user_lost_password', false) }

        it 'raise 422' do
          post '/api/v1/users/password_reset', params: { username: user.login }, as: :json

          expect(response).to have_http_status(:unprocessable_content)
          expect(json_response['error']).to be_truthy
          expect(json_response['error']).to eq('This feature is not enabled.')
        end
      end
    end

    context 'does password reset by token work' do
      let(:user)  { create(:customer, login: 'somebody', email: 'somebody@example.com') }
      let(:token) { create(:token, action: 'PasswordReset', user_id: user.id) }

      context 'for user without email address' do
        let(:user) { create(:customer, login: 'somebody', email: '') }

        it 'return failed' do
          post '/api/v1/users/password_reset_verify', params: { username: user.login, token: token.token, password: 'Test1234#.' }, as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response).to be_a(Hash)
          expect(json_response['message']).to eq('failed')
        end
      end

      context 'for user with email address' do
        it 'return ok' do
          post '/api/v1/users/password_reset_verify', params: { username: user.login, token: token.token, password: 'TEst1234#.' }, as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response).to be_a(Hash)
          expect(json_response['message']).to eq('ok')
        end
      end

      context 'for user with email address but disabled feature' do
        before { Setting.set('user_lost_password', false) }

        it 'raise 422' do
          post '/api/v1/users/password_reset_verify', params: { username: user.login, token: token.token, password: 'Test1234#.' }, as: :json

          expect(response).to have_http_status(:unprocessable_content)
          expect(json_response['error']).to be_truthy
          expect(json_response['error']).to eq('This feature is not enabled.')
        end
      end
    end

    context 'password change' do
      let(:user) { create(:customer, login: 'somebody', email: 'somebody@example.com', password: 'Test1234#.') }

      before { authenticated_as(user, login: 'somebody', password: 'Test1234#.') }

      context 'user without email address' do
        let(:user) { create(:customer, login: 'somebody', email: '', password: 'Test1234#.') }

        it 'return ok' do
          post '/api/v1/users/password_change', params: { password_old: 'Test1234#.', password_new: 'TEst12345#.' }, as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response).to be_a(Hash)
          expect(json_response['message']).to eq('ok')
        end
      end

      context 'user with email address' do
        it 'return ok' do
          post '/api/v1/users/password_change', params: { password_old: 'Test1234#.', password_new: 'TEst12345#.' }, as: :json

          expect(response).to have_http_status(:ok)
          expect(json_response).to be_a(Hash)
          expect(json_response['message']).to eq('ok')
        end
      end
    end

    context 'ultra long password', authenticated_as: :user do
      let(:user)        { create(:agent, :with_valid_password) }
      let(:long_string) { "asd1ASDasd!#{Faker::Lorem.characters(number: 1_000)}" }

      it 'does not reach verifying when old password is too long' do
        allow(PasswordHash).to receive(:verified?).and_call_original

        post '/api/v1/users/password_change', params: { password_old: long_string, password_new: long_string }, as: :json

        expect(PasswordHash).not_to have_received(:verified?).with(any_args, long_string)
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['message']).to eq('failed')
      end

      it 'does not reach hashing when saving' do
        allow(PasswordHash).to receive(:crypt).and_call_original

        post '/api/v1/users/password_change', params: { password_old: user.password_plain, password_new: long_string }, as: :json

        expect(PasswordHash).not_to have_received(:crypt)
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['message']).to eq('failed')
      end
    end
  end

  describe 'POST /api/v1/users', authenticated_as: -> { create(:admin) } do
    def make_request(params)
      post '/api/v1/users', params: params, as: :json
    end

    let(:successful_params)  { { email: attributes_for(:admin)[:email] } }
    let(:params_with_role)   { successful_params.merge({ role_ids: [Role.find_by(name: 'Admin').id] }) }
    let(:params_with_invite) { successful_params.merge({ invite: true }) }

    it 'succeeds' do
      make_request successful_params

      expect(response).to have_http_status(:created)
    end

    it 'returns user data' do
      make_request successful_params

      expect(json_response).to have_key('email').and(have_value(successful_params[:email]))
    end

    it 'no session treated as signup', authenticated_as: false do
      make_request successful_params

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'does not accept requests from customers', authenticated_as: -> { create(:customer) } do
      make_request successful_params

      expect(response).to have_http_status(:forbidden)
      expect(User.find_by(email: successful_params[:email])).to be_nil
    end

    context 'with API token authentication' do
      let(:admin) { create(:admin) }
      let(:token) { create(:token, user_id: admin.id, preferences: { permission: }) }

      context 'when token has only ticket.agent permission' do
        let(:permission) { ['ticket.agent'] }

        before { authenticated_as(admin, token:) }

        it 'can create users' do
          make_request successful_params
          expect(response).to have_http_status(:created)
          expect(User.find_by(email: successful_params[:email])).to be_present
        end

        it 'cannot assign admin role' do
          make_request params_with_role
          expect(User.last).not_to be_role 'Admin'
        end
      end

      context 'when token has no relevant permissions' do
        let(:permission) { ['ticket.customer'] }

        before { authenticated_as(admin, token:) }

        it 'cannot create users' do
          make_request successful_params
          expect(response).to have_http_status(:forbidden)
          expect(User.find_by(email: successful_params[:email])).to be_nil
        end

        it 'cannot assign admin role' do
          make_request params_with_role
          expect(response).to have_http_status(:forbidden)
          expect(User.find_by(email: params_with_role[:email])).to be_nil
        end
      end

      context 'when using token authentication' do
        it 'does not leak token between requests' do
          admin = create(:admin)
          token = create(:token, user_id: admin.id, preferences: { permission: %w[ticket.agent] })

          authenticated_as(admin, token:)
          get '/api/v1/users/me'
          expect(UserInfo.current_token).to be_nil

          allow(UserInfo).to receive(:current_token=).and_call_original

          authenticated_as(admin)
          get '/api/v1/users/me'
          expect(UserInfo).not_to have_received(:current_token=).with(token)
        end
      end
    end

    it 'does not send email verification notifications' do
      allow(NotificationFactory::Mailer).to receive(:notification)
      make_request successful_params
      expect(NotificationFactory::Mailer).not_to have_received(:notification).with(hash_including(template: 'signup'))
    end

    it 'does not send invitation notification by default' do
      allow(NotificationFactory::Mailer).to receive(:notification)
      make_request successful_params
      expect(NotificationFactory::Mailer).not_to have_received(:notification).with(hash_including(template: 'user_invite'))
    end

    it 'sends invitation notification when required' do
      allow(NotificationFactory::Mailer).to receive(:notification)
      make_request params_with_invite
      expect(NotificationFactory::Mailer).to have_received(:notification).with(hash_including(template: 'user_invite'))
    end

    it 'requires at least one identifier' do
      make_request({ web: 'example.com' })
      expect(json_response['error']).to start_with('At least one identifier')
    end

    it 'takes first name as identifier' do
      make_request({ firstname: 'name' })
      expect(response).to have_http_status(:created)
      expect(User.find(json_response['id'])).to have_attributes(firstname: 'name')
    end

    it 'takes last name as identifier' do
      make_request({ lastname: 'name' })
      expect(response).to have_http_status(:created)
      expect(User.find(json_response['id'])).to have_attributes(lastname: 'name')
    end

    it 'takes login as identifier' do
      make_request({ login: 'name' })
      expect(response).to have_http_status(:created)
      expect(User.find(json_response['id'])).to have_attributes(login: 'name')
    end

    it 'requires valid email if present' do
      make_request({ email: 'not_valid_email' })
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'POST /api/v1/users processed by #create_admin', authenticated_as: false do
    before do
      User.all[2...].each(&:destroy) # destroy previously created users
      Setting.set('system_init_done', false)
    end

    def make_request(params)
      post '/api/v1/users', params: params, as: :json
    end

    let(:successful_params) do
      email = attributes_for(:admin)[:email]

      { firstname: 'Admin First', lastname: 'Admin Last', email: email, password: 'asd1ASDasd!' }
    end

    it 'succeeds' do
      make_request successful_params
      expect(response).to have_http_status(:created)
    end

    it 'returns success message' do
      make_request successful_params
      expect(json_response).to have_key('message').and(have_value('ok'))
    end

    it 'does not allow to create 2nd administrator account' do
      create(:admin)
      make_request successful_params
      expect(response).to have_http_status(:unprocessable_content)
      expect(User.find_by(email: successful_params[:email])).to be_nil
    end

    it 'requires email' do
      make_request successful_params.merge(email: nil)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'requires valid email' do
      make_request successful_params.merge(email: 'invalid_email')
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'checks password policy' do
      make_request successful_params.merge(password: '1234')
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'loads calendar' do
      allow(Calendar).to receive(:init_setup)
      make_request successful_params
      expect(Calendar).to have_received(:init_setup)
    end

    it 'loads text module' do
      allow(TextModule).to receive(:load)
      make_request successful_params
      expect(TextModule).to have_received(:load)
    end

    it 'does not send any notifications' do
      allow(NotificationFactory::Mailer).to receive(:notification)
      make_request successful_params
      expect(NotificationFactory::Mailer).not_to have_received(:notification)
    end
  end

  describe 'POST /api/v1/users processed by #create_signup', authenticated_as: false do
    def make_request(params)
      post '/api/v1/users', params: params, as: :json
    end

    let(:successful_params) do
      email = attributes_for(:admin)[:email]

      { firstname: 'Customer First', lastname: 'Customer Last', email: email, password: 'gsd1ASDasd!', signup: true }
    end

    before do
      create(:admin) # simulate functional system with admin created
    end

    it 'succeeds' do
      make_request successful_params
      expect(response).to have_http_status(:created)
    end

    it 'requires csrf', allow_forgery_protection: true do
      make_request successful_params
      expect(response).to have_http_status(:unauthorized)
      expect(User.find_by(email: successful_params[:email])).to be_nil
    end

    it 'requires honeypot attribute' do
      params = successful_params.clone
      params.delete :signup

      make_request params
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'requires signup to be enabled' do
      Setting.set('user_create_account', false)
      make_request successful_params
      expect(response).to have_http_status(:unprocessable_content)
      expect(User.find_by(email: successful_params[:email])).to be_nil
    end

    it 'requires email' do
      make_request successful_params.merge(email: nil)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'requires valid email' do
      make_request successful_params.merge(email: 'not_valid_email')
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns false positive when email already used' do
      create(:customer, email: successful_params[:email])
      make_request successful_params
      expect(response).to have_http_status(:created)
    end

    it 'sends email verification notifications' do
      allow(NotificationFactory::Mailer).to receive(:notification)
      perform_enqueued_jobs(only: NotificationMailerJob) { make_request successful_params }
      expect(NotificationFactory::Mailer).to have_received(:notification).with(hash_including(template: 'signup'))
    end

    it 'sends password reset notification when email already used' do
      create(:customer, email: successful_params[:email])
      allow(NotificationFactory::Mailer).to receive(:notification)
      perform_enqueued_jobs(only: NotificationMailerJob) { make_request successful_params }
      expect(NotificationFactory::Mailer).to have_received(:notification).with(hash_including(template: 'signup_taken_reset'))
    end

    it 'sets role to Customer' do
      make_request successful_params
      expect(User.last).to be_role('Customer')
    end

    it 'ignores given Agent role' do
      make_request successful_params.merge(role_ids: [Role.find_by(name: 'Agent').id])
      expect(User.last).not_to be_role('Agent')
    end
  end

  describe 'POST /api/v1/users/search group ids and generic model_search_render tests' do
    let(:group1)         { create(:group) }
    let(:group2)         { create(:group) }
    let!(:agent1)        { create(:agent, firstname: '9U7Z-agent1', groups: [group1]) }
    let!(:agent2)        { create(:agent, firstname: '9U7Z-agent2', groups: [group2]) }
    let!(:random_agents) { create_list(:agent, 20) }

    def make_request(params)
      authenticated_as(agent1)
      post '/api/v1/users/search', params: params, as: :json
    end

    describe 'without searchindex' do
      before do
        Setting.set('es_url', nil)
      end

      it 'does find both users' do
        make_request(query: '9U7Z')
        expect(json_response.count).to eq(2)
      end

      it 'does find only agent 1' do
        make_request(query: '9U7Z', group_ids: { group1.id => 'read' })
        expect(json_response[0]['firstname']).to eq(agent1.firstname)
        expect(json_response.count).to eq(1)
      end

      it 'does find only agent 2' do
        make_request(query: '9U7Z', group_ids: { group2.id => 'read' })
        expect(json_response[0]['firstname']).to eq(agent2.firstname)
        expect(json_response.count).to eq(1)
      end

      it 'does find none' do
        make_request(query: '9U7Z', group_ids: { 999 => 'read' })
        expect(json_response.count).to eq(0)
      end

      it 'does not list user with id 1' do
        make_request(query: '')
        not_in_response = json_response.none? { |item| item['id'] == 1 }
        expect(not_in_response).to be(true)
      end

      it 'does return data' do
        make_request(offset: 0, limit: 10)
        expect(json_response).to be_a(Array)
        expect(json_response.count).to eq(10)
      end

      it 'does return expand data' do
        make_request(expand: true, offset: 0, limit: 10)
        expect(json_response).to be_a(Array)
        expect(json_response.count).to eq(10)
        expect(json_response[0]['groups']).to be_present
      end

      it 'does return full data with total count' do
        make_request(query: '9U7Z', full: true, offset: 0, limit: 1)
        expect(json_response['assets']).to be_present
        expect(json_response['record_ids'].count).to eq(1)
        expect(json_response['total_count']).to eq(2)
      end

      it 'does return label data' do
        make_request(query: '9U7Z', label: true, offset: 0, limit: 1)
        expect(json_response).to be_a(Array)
        expect(json_response[0].keys).to include('id', 'label', 'value')
      end

      it 'does return term data' do
        make_request(term: '9U7Z', offset: 0, limit: 1)
        expect(json_response).to be_a(Array)
        expect(json_response[0].keys).to include('id', 'label', 'value', 'inactive')
      end

      it 'does return only total count' do
        make_request(term: '9U7Z', offset: 0, limit: 1, only_total_count: true)
        expect(json_response).to be_a(Hash)
        expect(json_response.keys).to eq(['total_count'])
        expect(json_response['total_count']).to eq(2)
      end
    end

    describe 'with searchindex', searchindex: true do
      before do
        searchindex_model_reload([User])
      end

      it 'does find both users' do
        make_request(query: '9U7Z')
        expect(json_response.count).to eq(2)
      end

      it 'does find only agent 1' do
        make_request(query: '9U7Z', group_ids: { group1.id => 'read' })
        expect(json_response[0]['firstname']).to eq(agent1.firstname)
        expect(json_response.count).to eq(1)
      end

      it 'does find only agent 2' do
        make_request(query: '9U7Z', group_ids: { group2.id => 'read' })
        expect(json_response[0]['firstname']).to eq(agent2.firstname)
        expect(json_response.count).to eq(1)
      end

      it 'does find none' do
        make_request(query: '9U7Z', group_ids: { 999 => 'read' })
        expect(json_response.count).to eq(0)
      end

      it 'does not list user with id 1' do
        make_request(query: '')
        not_in_response = json_response.none? { |item| item['id'] == 1 }
        expect(not_in_response).to be(true)
      end

      it 'does return data' do
        make_request(offset: 0, limit: 10)
        expect(json_response).to be_a(Array)
        expect(json_response.count).to eq(10)
      end

      it 'does return expand data' do
        make_request(expand: true, offset: 0, limit: 10)
        expect(json_response).to be_a(Array)
        expect(json_response.count).to eq(10)
        expect(json_response[0]['groups']).to be_present
      end

      it 'does return full data with total count' do
        make_request(query: '9U7Z', full: true, offset: 0, limit: 1)
        expect(json_response['assets']).to be_present
        expect(json_response['record_ids'].count).to eq(1)
        expect(json_response['total_count']).to eq(2)
      end

      it 'does return label data' do
        make_request(query: '9U7Z', label: true, offset: 0, limit: 1)
        expect(json_response).to be_a(Array)
        expect(json_response[0].keys).to include('id', 'label', 'value')
      end

      it 'does return term data' do
        make_request(term: '9U7Z', offset: 0, limit: 1)
        expect(json_response).to be_a(Array)
        expect(json_response[0].keys).to include('id', 'label', 'value', 'inactive')
      end

      it 'does return only total count' do
        make_request(term: '9U7Z', offset: 0, limit: 1, only_total_count: true)
        expect(json_response).to be_a(Hash)
        expect(json_response.keys).to eq(['total_count'])
        expect(json_response['total_count']).to eq(2)
      end
    end
  end

  describe 'GET /api/v1/users/search, checks ES Usage', authenticated_as: :agent, searchindex: true do
    let!(:agent) { create(:agent) }

    def make_request(params)
      get '/api/v1/users/search', params: params, as: :json
    end

    before do
      # create some users that can be found
      create(:agent, firstname: 'Test-Agent1')
      create(:agent, firstname: 'Test-Agent2')

      searchindex_model_reload([User])
    end

    it 'uses elasticsearch when query is non empty' do
      # Check if ES is used
      allow(SearchIndexBackend).to receive(:search_by_index)

      make_request(query: 'Test')
      expect(SearchIndexBackend).to have_received(:search_by_index)
    end

    it 'does not uses elasticsearch when query is empty' do
      allow(SearchIndexBackend).to receive(:search_by_index)

      make_request(query: '')
      expect(SearchIndexBackend).not_to have_received(:search_by_index)
    end
  end

  describe 'POST /api/v1/users/avatar', authenticated_as: :user do
    let(:user)   { create(:user) }
    let(:base64) { 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==' }

    def make_request(params)
      post '/api/v1/users/avatar', params: params, as: :json
    end

    it 'returns verbose error when full image is missing' do
      make_request(avatar_full: '')
      expect(json_response).to include('error' => 'The image is invalid.')
    end

    it 'returns verbose error when resized image is missing' do
      make_request(avatar_full: base64)
      expect(json_response).to include('error' => 'The image is invalid.')
    end

    it 'successfully changes avatar' do
      expect { make_request(avatar_full: base64, avatar_resize: base64) }
        .to change { Avatar.list('User', user.id) }
    end

    context 'with a not allowed mime-type' do
      let(:base64) { 'data:image/svg+xml;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==' }

      it 'returns verbose error for a not allowed mime-type' do
        make_request(avatar_full: base64)
        expect(json_response).to include('error' => 'The MIME type of the image is invalid.')
      end
    end

    context 'with a not allowed resized image mime-type' do
      let(:resized_base64) { 'data:image/svg+xml;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==' }

      it 'returns verbose error for a not allowed mime-type' do
        make_request(avatar_full: base64, avatar_resize: resized_base64)
        expect(json_response).to include('error' => 'The MIME type of the image is invalid.')
      end
    end
  end

  describe 'GET /api/v1/users/image/:hash', authenticated_as: :user do
    let(:user) { create(:user) }
    let(:avatar_mime_type) { 'image/png' }
    let(:avatar) do
      Avatar.add(
        object:        'User',
        o_id:          user.id,
        default:       true,
        resize:        {
          content:   File.binread('test/data/image/1000x1000.png'),
          mime_type: avatar_mime_type,
        },
        source:        'web',
        deletable:     true,
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    let(:avatar_content) { Avatar.get_by_hash(avatar.store_hash).content }

    before do
      user.update!(image: avatar.store_hash)
    end

    def make_request(image_hash, params: {})
      get "/api/v1/users/image/#{image_hash}", params: params, as: :json
    end

    it 'returns the image with caching headers', :aggregate_failures do
      make_request(avatar.store_hash)
      expect(response.body).to eq(avatar_content)
      expect(response.headers['Cache-Control']).to match('^max-age=\d{9,}, private, must-revalidate$')
    end

    context 'with a not allowed inline mime-type' do
      let(:avatar_mime_type) { 'image/svg+xml' }

      it 'returns the default image' do
        make_request(avatar.store_hash)
        expect(response.headers['Content-Type']).to include('image/gif')
      end
    end
  end

  describe 'GET /api/v1/users/search, checks usage of the ids parameter', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    let!(:search_agents) { create_list(:agent, 3, firstname: 'Nick') }

    shared_examples 'ids requests' do

      before do
        post '/api/v1/users/search', params: { query: 'Nick', ids: search_ids, sort_by: ['created_at'], order_by: ['ASC'] }, as: :json
      end

      shared_examples 'result check' do

        it 'returns only agents matching search parameter ids' do
          expect(json_response.pluck('id')).to eq(search_ids)
        end
      end

      context 'when searching for first two agents' do
        let(:search_ids) { search_agents.first(2).map(&:id) }

        include_examples 'result check'
      end

      context 'when searching for last two agents' do
        let(:search_ids) { search_agents.last(2).map(&:id) }

        include_examples 'result check'
      end
    end

    context 'with elasticsearch', searchindex: true do
      before do
        searchindex_model_reload([User])
      end

      include_examples 'ids requests'
    end

    context 'without elasticsearch' do
      before do
        Setting.set('es_url', nil)
      end

      include_examples 'ids requests'
    end
  end

  describe 'GET /api/v1/users/search, with invalid attributes', authenticated_as: :agent do
    let(:agent) { create(:agent) }
    let(:customer_invalid) do
      create(
        :customer,
        login:     'customer1@example.com',
        firstname: 'Some',
        lastname:  'Customer1',
        email:     'customer1@example.com',
      )
    end

    context 'when email address is invalid' do
      before do
        customer_invalid.update_attribute(:email, 'eee lala')
        post '/api/v1/users/search', params: { term: 'Customer1' }, as: :json
      end

      it 'succeeds' do
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PUT /api/v1/users/{id}', authenticated_as: :admin do
    let(:admin) { create(:admin) }
    let(:agent) { create(:agent) }

    context 'with secondary organizations' do
      let(:primary_org) { create(:organization) }
      let(:secondary_org) { create(:organization) }

      before { put "/api/v1/users/#{agent.id}", params: params, as: :json }

      context 'with primary organization' do
        let(:params) { { organization_id: primary_org.id, organization_ids: [secondary_org.id] } }

        it 'succeeds' do
          expect(response).to have_http_status(:success)
        end
      end

      context 'without primary organization' do
        let(:params) { { organization_ids: [secondary_org.id] } }

        it 'fails with validation error' do
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context 'when swapping primary and secondary organizations' do
        let(:agent)  { create(:agent, organization: primary_org) }
        let(:params) { { organization_id: secondary_org.id, organization_ids: [primary_org.id] } }

        it 'moves the primary organization to the secondary ones', :aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(agent.reload).to have_attributes(organization: secondary_org, organizations: [primary_org])
        end
      end
    end

    context 'with a password change' do
      before do
        allow(NotificationFactory::Mailer).to receive(:notification)

        put "/api/v1/users/#{agent.id}", params: { password: 'SomeTestPassword123!' }, as: :json
      end

      it 'notifies the user' do
        expect(NotificationFactory::Mailer).to have_received(:notification).with(include(template: 'password_change'))
      end
    end
  end

  describe 'PUT /api/v1/users/unlock/{id}' do
    let(:admin) { create(:admin) }
    let(:agent)    { create(:agent) }
    let(:customer) { create(:customer, login_failed: 2) }

    def make_request(id)
      put "/api/v1/users/unlock/#{id}", params: {}, as: :json
    end

    context 'with authenticated admin user', authenticated_as: :admin do
      it 'returns success' do
        make_request(customer.id)
        expect(response).to have_http_status(:ok)
      end

      it 'check that login failed was reseted' do
        expect { make_request(customer.id) }.to change { customer.reload.login_failed }.from(2).to(0)
      end

      it 'fail with not existing user id' do
        make_request(99_999)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with authenticated agent user', authenticated_as: :agent do
      it 'fail without admin permission' do
        make_request(customer.id)
        expect(response).to have_http_status(:forbidden)
      end

      it 'check that login failed was not changed' do
        expect { make_request(customer.id) }.not_to change { customer.reload.login_failed }
      end
    end
  end

  describe 'POST /api/v1/preferences_notifications_reset', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'return ok' do
      post '/api/v1/users/preferences_notifications_reset', as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include('message' => 'ok')
    end

    it 'calls notification reset method' do
      allow(User)
        .to receive(:reset_personal_notifications_preferences!)

      post '/api/v1/users/preferences_notifications_reset', as: :json

      expect(User).to have_received(:reset_personal_notifications_preferences!).with(agent)
    end
  end

  describe 'POST /api/v1/users/password_check', :aggregate_failures, authenticated_as: :user do
    let(:user) { create(:agent, login: 'benderrodriguez', password: 'beer') }

    before { post '/api/v1/users/password_check', params: { password: password }, as: :json }

    context 'with no password' do
      let(:password) { nil }

      it 'raises an error' do
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'with wrong password' do
      let(:password) { 'wrong' }

      it 'returns false for success and does not include a token' do
        expect(response).to have_http_status(:ok)
        expect(json_response['success']).to be false
        expect(json_response['token']).to be_nil
      end
    end

    context 'with correct password' do
      let(:password) { 'beer' }

      it 'returns true for success and includes a token' do
        expect(response).to have_http_status(:ok)
        expect(json_response['success']).to be true
        expect(json_response['token']).to be_a String
      end
    end
  end

  describe 'GET /api/v1/users/search, regression test for issue #6004 - users without email shown as blank lines', authenticated_as: :agent do
    let(:agent)     { create(:agent) }
    let!(:customer) { create(:customer, firstname: 'Tick', lastname: nil, email: nil, login: 'tick-no-email') }

    before do
      Setting.set('es_url', nil)
      get "/api/v1/users/search?term=#{CGI.escape('Tick')}", params: {}, as: :json
    end

    it 'returns a non-blank label for users without email' do
      expect(response).to have_http_status(:ok)

      result = json_response.find { |u| u['id'] == customer.id }
      expect(result['label']).to eq('Tick')
    end
  end
end
