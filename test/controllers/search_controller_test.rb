# encoding: utf-8
require 'test_helper'
require 'rake'

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set current user
    UserInfo.current_user_id = 1

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w(Admin Agent))
    groups = Group.all

    @admin = User.create_or_update(
      login: 'search-admin',
      firstname: 'Search',
      lastname: 'Admin',
      email: 'search-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create agent
    roles = Role.where(name: 'Agent')
    @agent = User.create_or_update(
      login: 'search-agent@example.com',
      firstname: 'Search 1234',
      lastname: 'Agent',
      email: 'search-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create customer without org
    roles = Role.where(name: 'Customer')
    @customer_without_org = User.create_or_update(
      login: 'search-customer1@example.com',
      firstname: 'Search',
      lastname: 'Customer1',
      email: 'search-customer1@example.com',
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
    @customer_with_org2 = User.create_or_update(
      login: 'search-customer2@example.com',
      firstname: 'Search',
      lastname: 'Customer2',
      email: 'search-customer2@example.com',
      password: 'customer2pw',
      active: true,
      roles: roles,
      organization_id: @organization.id,
    )

    @customer_with_org3 = User.create_or_update(
      login: 'search-customer3@example.com',
      firstname: 'Search',
      lastname: 'Customer3',
      email: 'search-customer3@example.com',
      password: 'customer3pw',
      active: true,
      roles: roles,
      organization_id: @organization.id,
    )

    @ticket1 = Ticket.create!(
      title: 'test 1234-1',
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
    )
    @article1 = Ticket::Article.create!(
      ticket_id: @ticket1.id,
      from: 'some_sender1@example.com',
      to: 'some_recipient1@example.com',
      subject: 'some subject1',
      message_id: 'some@id',
      body: 'some message1',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
    )
    travel 1.second
    @ticket2 = Ticket.create!(
      title: 'test 1234-2',
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_with_org2.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
    )
    @article2 = Ticket::Article.create!(
      ticket_id: @ticket2.id,
      from: 'some_sender2@example.com',
      to: 'some_recipient2@example.com',
      subject: 'some subject2',
      message_id: 'some@id',
      body: 'some message2',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
    )
    travel 1.second
    @ticket3 = Ticket.create!(
      title: 'test 1234-2',
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_with_org3.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
    )
    @article3 = Ticket::Article.create!(
      ticket_id: @ticket3.id,
      from: 'some_sender3@example.com',
      to: 'some_recipient3@example.com',
      subject: 'some subject3',
      message_id: 'some@id',
      body: 'some message3',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
    )

    # configure es
    if ENV['ES_URL'].present?
      #fail "ERROR: Need ES_URL - hint ES_URL='http://127.0.0.1:9200'"
      Setting.set('es_url', ENV['ES_URL'])

      # Setting.set('es_url', 'http://127.0.0.1:9200')
      # Setting.set('es_index', 'estest.local_zammad')
      # Setting.set('es_user', 'elasticsearch')
      # Setting.set('es_password', 'zammad')

      if ENV['ES_INDEX_RAND'].present?
        ENV['ES_INDEX'] = "es_index_#{rand(999_999_999)}"
      end
      if ENV['ES_INDEX'].blank?
        raise "ERROR: Need ES_INDEX - hint ES_INDEX='estest.local_zammad'"
      end
      Setting.set('es_index', ENV['ES_INDEX'])

      # set max attachment size in mb
      Setting.set('es_attachment_max_size_in_mb', 1)

      travel 1.minute

      # drop/create indexes
      Rake::Task.clear
      Zammad::Application.load_tasks
      #Rake::Task["searchindex:drop"].execute
      #Rake::Task["searchindex:create"].execute
      Rake::Task['searchindex:rebuild'].execute

      # execute background jobs
      Scheduler.worker(true)

      sleep 6
    end
  end

  teardown do
    if ENV['ES_URL'].present?
      Rake::Task['searchindex:drop'].execute
    end
  end

  test 'settings index with nobody' do
    params = {
      query: 'test 1234',
      limit: 2,
    }

    post '/api/v1/search/ticket', params.to_json, @headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result.empty?)
    assert_equal('authentication failed', result['error'])

    post '/api/v1/search/user', params.to_json, @headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result.empty?)
    assert_equal('authentication failed', result['error'])

    post '/api/v1/search', params.to_json, @headers
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result.empty?)
    assert_equal('authentication failed', result['error'])
  end

  test 'settings index with admin' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('search-admin@example.com', 'adminpw')

    params = {
      query: '1234*',
      limit: 1,
    }
    post '/api/v1/search', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result)
    assert_equal('Ticket', result['result'][0]['type'])
    assert_equal(@ticket3.id, result['result'][0]['id'])
    assert_equal('User', result['result'][1]['type'])
    assert_equal(@agent.id, result['result'][1]['id'])
    assert_not(result['result'][2])

    params = {
      query: '1234*',
      limit: 10,
    }

    post '/api/v1/search', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result)
    assert_equal('Ticket', result['result'][0]['type'])
    assert_equal(@ticket3.id, result['result'][0]['id'])
    assert_equal('Ticket', result['result'][1]['type'])
    assert_equal(@ticket2.id, result['result'][1]['id'])
    assert_equal('Ticket', result['result'][2]['type'])
    assert_equal(@ticket1.id, result['result'][2]['id'])
    assert_equal('User', result['result'][3]['type'])
    assert_equal(@agent.id, result['result'][3]['id'])
    assert_not(result['result'][4])

    params = {
      query: '1234*',
      limit: 10,
    }

    post '/api/v1/search/ticket', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result)
    assert_equal('Ticket', result['result'][0]['type'])
    assert_equal(@ticket3.id, result['result'][0]['id'])
    assert_equal('Ticket', result['result'][1]['type'])
    assert_equal(@ticket2.id, result['result'][1]['id'])
    assert_equal('Ticket', result['result'][2]['type'])
    assert_equal(@ticket1.id, result['result'][2]['id'])
    assert_not(result['result'][3])

    params = {
      query: '1234*',
      limit: 10,
    }

    post '/api/v1/search/user', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('User', result['result'][0]['type'])
    assert_equal(@agent.id, result['result'][0]['id'])
    assert_not(result['result'][1])
  end

  test 'settings index with agent' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('search-agent@example.com', 'agentpw')

    params = {
      query: '1234*',
      limit: 1,
    }

    post '/api/v1/search', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result)
    assert_equal('Ticket', result['result'][0]['type'])
    assert_equal(@ticket3.id, result['result'][0]['id'])
    assert_equal('User', result['result'][1]['type'])
    assert_equal(@agent.id, result['result'][1]['id'])
    assert_not(result['result'][2])

    params = {
      query: '1234*',
      limit: 10,
    }

    post '/api/v1/search', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result)
    assert_equal('Ticket', result['result'][0]['type'])
    assert_equal(@ticket3.id, result['result'][0]['id'])
    assert_equal('Ticket', result['result'][1]['type'])
    assert_equal(@ticket2.id, result['result'][1]['id'])
    assert_equal('Ticket', result['result'][2]['type'])
    assert_equal(@ticket1.id, result['result'][2]['id'])
    assert_equal('User', result['result'][3]['type'])
    assert_equal(@agent.id, result['result'][3]['id'])
    assert_not(result['result'][4])

    params = {
      query: '1234*',
      limit: 10,
    }

    post '/api/v1/search/ticket', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result)
    assert_equal('Ticket', result['result'][0]['type'])
    assert_equal(@ticket3.id, result['result'][0]['id'])
    assert_equal('Ticket', result['result'][1]['type'])
    assert_equal(@ticket2.id, result['result'][1]['id'])
    assert_equal('Ticket', result['result'][2]['type'])
    assert_equal(@ticket1.id, result['result'][2]['id'])
    assert_not(result['result'][3])

    params = {
      query: '1234*',
      limit: 10,
    }

    post '/api/v1/search/user', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('User', result['result'][0]['type'])
    assert_equal(@agent.id, result['result'][0]['id'])
    assert_not(result['result'][1])
  end

  test 'settings index with customer 1' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('search-customer1@example.com', 'customer1pw')

    params = {
      query: '1234*',
      limit: 10,
    }

    post '/api/v1/search', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result)
    assert_equal('Ticket', result['result'][0]['type'])
    assert_equal(@ticket1.id, result['result'][0]['id'])
    assert_not(result['result'][1])

    params = {
      query: '1234*',
      limit: 10,
    }

    post '/api/v1/search/ticket', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result)
    assert_equal('Ticket', result['result'][0]['type'])
    assert_equal(@ticket1.id, result['result'][0]['id'])
    assert_not(result['result'][1])

    params = {
      query: '1234*',
      limit: 10,
    }

    post '/api/v1/search/user', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['result'][0])
  end

  test 'settings index with customer 2' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('search-customer2@example.com', 'customer2pw')

    params = {
      query: '1234*',
      limit: 10,
    }

    post '/api/v1/search', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result)
    assert_equal('Ticket', result['result'][0]['type'])
    assert_equal(@ticket3.id, result['result'][0]['id'])
    assert_equal('Ticket', result['result'][1]['type'])
    assert_equal(@ticket2.id, result['result'][1]['id'])
    assert_not(result['result'][2])

    params = {
      query: '1234*',
      limit: 10,
    }

    post '/api/v1/search/ticket', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result)
    assert_equal('Ticket', result['result'][0]['type'])
    assert_equal(@ticket3.id, result['result'][0]['id'])
    assert_equal('Ticket', result['result'][1]['type'])
    assert_equal(@ticket2.id, result['result'][1]['id'])
    assert_not(result['result'][2])

    params = {
      query: '1234*',
      limit: 10,
    }

    post '/api/v1/search/user', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_not(result['result'][0])
  end

end
