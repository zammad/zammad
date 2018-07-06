require 'test_helper'

class OrganizationControllerTest < ActionDispatch::IntegrationTest
  include SearchindexHelper

  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w[Admin Agent])
    groups = Group.all

    UserInfo.current_user_id = 1

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

  test '04.01 organization show and response format' do
    organization = Organization.create!(
      name: 'Rest Org NEW',
      members: [@customer_without_org],
      updated_by_id: @admin.id,
      created_by_id: @admin.id,
    )

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')
    get "/api/v1/organizations/#{organization.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(organization.id, result['id'])
    assert_equal(organization.name, result['name'])
    assert_not(result['members'])
    assert_equal([@customer_without_org.id], result['member_ids'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(@admin.id, result['created_by_id'])

    get "/api/v1/organizations/#{organization.id}?expand=true", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(organization.id, result['id'])
    assert_equal(organization.name, result['name'])
    assert(result['members'])
    assert_equal([@customer_without_org.id], result['member_ids'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(@admin.id, result['created_by_id'])

    get "/api/v1/organizations/#{organization.id}?expand=false", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(organization.id, result['id'])
    assert_equal(organization.name, result['name'])
    assert_not(result['members'])
    assert_equal([@customer_without_org.id], result['member_ids'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(@admin.id, result['created_by_id'])

    get "/api/v1/organizations/#{organization.id}?full=true", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)

    assert_equal(Hash, result.class)
    assert_equal(organization.id, result['id'])
    assert(result['assets'])
    assert(result['assets']['Organization'])
    assert(result['assets']['Organization'][organization.id.to_s])
    assert_equal(organization.id, result['assets']['Organization'][organization.id.to_s]['id'])
    assert_equal(organization.name, result['assets']['Organization'][organization.id.to_s]['name'])
    assert_equal(organization.member_ids, result['assets']['Organization'][organization.id.to_s]['member_ids'])
    assert_not(result['assets']['Organization'][organization.id.to_s]['members'])

    get "/api/v1/organizations/#{organization.id}?full=false", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(organization.id, result['id'])
    assert_equal(organization.name, result['name'])
    assert_not(result['members'])
    assert_equal([@customer_without_org.id], result['member_ids'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(@admin.id, result['created_by_id'])
  end

  test '04.02 organization index and response format' do
    organization = Organization.create!(
      name: 'Rest Org NEW',
      members: [@customer_without_org],
      updated_by_id: @admin.id,
      created_by_id: @admin.id,
    )

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')
    get '/api/v1/organizations', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(Hash, result[0].class)
    assert_equal(organization.id, result.last['id'])
    assert_equal(organization.name, result.last['name'])
    assert_not(result.last['members'])
    assert_equal(organization.member_ids, result.last['member_ids'])
    assert_equal(@admin.id, result.last['updated_by_id'])
    assert_equal(@admin.id, result.last['created_by_id'])

    get '/api/v1/organizations?expand=true', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(Hash, result[0].class)
    assert_equal(organization.id, result.last['id'])
    assert_equal(organization.name, result.last['name'])
    assert_equal(organization.member_ids, result.last['member_ids'])
    assert_equal(organization.members.pluck(:login), [@customer_without_org.login])
    assert_equal(@admin.id, result.last['updated_by_id'])
    assert_equal(@admin.id, result.last['created_by_id'])

    get '/api/v1/organizations?expand=false', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(Hash, result[0].class)
    assert_equal(organization.id, result.last['id'])
    assert_equal(organization.name, result.last['name'])
    assert_not(result.last['members'])
    assert_equal(organization.member_ids, result.last['member_ids'])
    assert_equal(@admin.id, result.last['updated_by_id'])
    assert_equal(@admin.id, result.last['created_by_id'])

    get '/api/v1/organizations?full=true', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)

    assert_equal(Hash, result.class)
    assert_equal(Array, result['record_ids'].class)
    assert_equal(1, result['record_ids'][0])
    assert_equal(organization.id, result['record_ids'].last)
    assert(result['assets'])
    assert(result['assets']['Organization'])
    assert(result['assets']['Organization'][organization.id.to_s])
    assert_equal(organization.id, result['assets']['Organization'][organization.id.to_s]['id'])
    assert_equal(organization.name, result['assets']['Organization'][organization.id.to_s]['name'])
    assert_equal(organization.member_ids, result['assets']['Organization'][organization.id.to_s]['member_ids'])
    assert_not(result['assets']['Organization'][organization.id.to_s]['members'])

    get '/api/v1/organizations?full=false', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(Hash, result[0].class)
    assert_equal(organization.id, result.last['id'])
    assert_equal(organization.name, result.last['name'])
    assert_not(result.last['members'])
    assert_equal(organization.member_ids, result.last['member_ids'])
    assert_equal(@admin.id, result.last['updated_by_id'])
    assert_equal(@admin.id, result.last['created_by_id'])
  end

  test '04.03 ticket create and response format' do
    params = {
      name: 'Rest Org NEW',
      members: [@customer_without_org.login],
    }
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')

    post '/api/v1/organizations', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    organization = Organization.find(result['id'])
    assert_equal(organization.name, result['name'])
    assert_equal(organization.member_ids, result['member_ids'])
    assert_not(result['members'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(@admin.id, result['created_by_id'])

    params[:name] = 'Rest Org NEW #2'
    post '/api/v1/organizations?expand=true', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    organization = Organization.find(result['id'])
    assert_equal(organization.name, result['name'])
    assert_equal(organization.member_ids, result['member_ids'])
    assert_equal(organization.members.pluck(:login), result['members'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(@admin.id, result['created_by_id'])

    params[:name] = 'Rest Org NEW #3'
    post '/api/v1/organizations?full=true', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    organization = Organization.find(result['id'])
    assert(result['assets'])
    assert(result['assets']['Organization'])
    assert(result['assets']['Organization'][organization.id.to_s])
    assert_equal(organization.id, result['assets']['Organization'][organization.id.to_s]['id'])
    assert_equal(organization.name, result['assets']['Organization'][organization.id.to_s]['name'])
    assert_equal(organization.member_ids, result['assets']['Organization'][organization.id.to_s]['member_ids'])
    assert_not(result['assets']['Organization'][organization.id.to_s]['members'])

  end

  test '04.04 ticket update and response formats' do
    organization = Organization.create!(
      name: 'Rest Org NEW',
      members: [@customer_without_org],
      updated_by_id: @admin.id,
      created_by_id: @admin.id,
    )

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')

    params = {
      name: 'a update name #1',
    }
    put "/api/v1/organizations/#{organization.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    organization = Organization.find(result['id'])
    assert_equal(params[:name], result['name'])
    assert_equal(organization.member_ids, result['member_ids'])
    assert_not(result['members'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(@admin.id, result['created_by_id'])

    params = {
      name: 'a update name #2',
    }
    put "/api/v1/organizations/#{organization.id}?expand=true", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    organization = Organization.find(result['id'])
    assert_equal(params[:name], result['name'])
    assert_equal(organization.member_ids, result['member_ids'])
    assert_equal(organization.members.pluck(:login), [@customer_without_org.login])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(@admin.id, result['created_by_id'])

    params = {
      name: 'a update name #3',
    }
    put "/api/v1/organizations/#{organization.id}?full=true", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    organization = Organization.find(result['id'])
    assert(result['assets'])
    assert(result['assets']['Organization'])
    assert(result['assets']['Organization'][organization.id.to_s])
    assert_equal(organization.id, result['assets']['Organization'][organization.id.to_s]['id'])
    assert_equal(params[:name], result['assets']['Organization'][organization.id.to_s]['name'])
    assert_equal(organization.member_ids, result['assets']['Organization'][organization.id.to_s]['member_ids'])
    assert_not(result['assets']['Organization'][organization.id.to_s]['members'])

  end

  test '05.01 csv example - customer no access' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-customer1@example.com', 'customer1pw')

    get '/api/v1/organizations/import_example', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal('Not authorized (user)!', result['error'])
  end

  test '05.02 csv example - admin access' do

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')

    get '/api/v1/organizations/import_example', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)

    rows = CSV.parse(@response.body)
    header = rows.shift

    assert_equal('id', header[0])
    assert_equal('name', header[1])
    assert_equal('shared', header[2])
    assert_equal('domain', header[3])
    assert_equal('domain_assignment', header[4])
    assert_equal('active', header[5])
    assert_equal('note', header[6])
    assert(header.include?('members'))
  end

  test '05.03 csv import - admin access' do

    UserInfo.current_user_id = 1
    customer1 = User.create!(
      login: 'customer1-members@example.com',
      firstname: 'Member',
      lastname: 'Customer',
      email: 'customer1-members@example.com',
      password: 'customerpw',
      active: true,
    )
    customer2 = User.create!(
      login: 'customer2-members@example.com',
      firstname: 'Member',
      lastname: 'Customer',
      email: 'customer2-members@example.com',
      password: 'customerpw',
      active: true,
    )
    UserInfo.current_user_id = nil

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('rest-admin@example.com', 'adminpw')

    # invalid file
    csv_file_path = Rails.root.join('test', 'data', 'csv', 'organization_simple_col_not_existing.csv')
    csv_file = ::Rack::Test::UploadedFile.new(csv_file_path, 'text/csv')
    post '/api/v1/organizations/import?try=true', params: { file: csv_file, col_sep: ';' }, headers: { 'Authorization' => credentials }
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert_equal(true, result['try'])
    assert_equal(2, result['records'].count)
    assert_equal('failed', result['result'])
    assert_equal(2, result['errors'].count)
    assert_equal("Line 1: unknown attribute 'name2' for Organization.", result['errors'][0])
    assert_equal("Line 2: unknown attribute 'name2' for Organization.", result['errors'][1])

    # valid file try
    csv_file_path = Rails.root.join('test', 'data', 'csv', 'organization_simple.csv')
    csv_file = ::Rack::Test::UploadedFile.new(csv_file_path, 'text/csv')
    post '/api/v1/organizations/import?try=true', params: { file: csv_file, col_sep: ';' }, headers: { 'Authorization' => credentials }
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert_equal(true, result['try'])
    assert_equal(2, result['records'].count)
    assert_equal('success', result['result'])

    assert_nil(Organization.find_by(name: 'organization-member-import1'))
    assert_nil(Organization.find_by(name: 'organization-member-import2'))

    # valid file
    csv_file_path = Rails.root.join('test', 'data', 'csv', 'organization_simple.csv')
    csv_file = ::Rack::Test::UploadedFile.new(csv_file_path, 'text/csv')
    post '/api/v1/organizations/import', params: { file: csv_file, col_sep: ';' }, headers: { 'Authorization' => credentials }
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    assert_equal(false, result['try'])
    assert_equal(2, result['records'].count)
    assert_equal('success', result['result'])

    organization1 = Organization.find_by(name: 'organization-member-import1')
    assert(organization1)
    assert_equal(organization1.name, 'organization-member-import1')
    assert_equal(organization1.members.count, 1)
    assert_equal(organization1.members.first.login, customer1.login)
    assert_equal(organization1.active, true)
    organization2 = Organization.find_by(name: 'organization-member-import2')
    assert(organization2)
    assert_equal(organization2.name, 'organization-member-import2')
    assert_equal(organization2.members.count, 1)
    assert_equal(organization2.members.first.login, customer2.login)
    assert_equal(organization2.active, false)

  end

end
