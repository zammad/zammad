
require 'test_helper'

class TicketsControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w[Admin Agent])
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create!(
      login: 'tickets-admin',
      firstname: 'Tickets',
      lastname: 'Admin',
      email: 'tickets-admin@example.com',
      password: 'adminpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create agent
    roles = Role.where(name: 'Agent')
    @agent = User.create!(
      login: 'tickets-agent@example.com',
      firstname: 'Tickets',
      lastname: 'Agent',
      email: 'tickets-agent@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    # create customer without org
    roles = Role.where(name: 'Customer')
    @customer_without_org = User.create!(
      login: 'tickets-customer1@example.com',
      firstname: 'Tickets',
      lastname: 'Customer1',
      email: 'tickets-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )
    UserInfo.current_user_id = nil

  end

  test '01.01 ticket create with agent - missing group' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #1',
      article: {
        content_type: 'text/plain', # or text/html
        body: 'some body',
        sender: 'Customer',
        type: 'note',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Group can\'t be blank', result['error_human'])
  end

  test '01.02 ticket create with agent - wrong group' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #2',
      group: 'not_existing',
      article: {
        content_type: 'text/plain', # or text/html
        body: 'some body',
        sender: 'Customer',
        type: 'note',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('No lookup value found for \'group\': "not_existing"', result['error'])
  end

  test '01.03 ticket create with agent - missing article.body' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #3',
      group: 'Users',
      priority: '2 normal',
      state: 'new',
      customer_id: @customer_without_org.id,
      article: {},
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Need at least article: { body: "some text" }', result['error'])
  end

  test '01.03 ticket create with agent - minimal article' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #3',
      group: 'Users',
      priority: '2 normal',
      state: 'new',
      customer_id: @customer_without_org.id,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #3', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
  end

  test '01.04 ticket create with agent - minimal article and customer.email' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #3',
      group: 'Users',
      priority: '2 normal',
      state: 'new',
      customer: @customer_without_org.email,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #3', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
  end

  test '01.05 ticket create with agent - wrong owner_id - 0' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #4',
      group: 'Users',
      priority: '2 normal',
      owner_id: 0,
      state: 'new',
      customer_id: @customer_without_org.id,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Invalid value for param \'owner_id\': 0', result['error'])
  end

  test '01.06 ticket create with agent - wrong owner_id - ""' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #5',
      group: 'Users',
      priority: '2 normal',
      owner_id: '',
      state: 'new',
      customer_id: @customer_without_org.id,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    #assert_response(422)
    #result = JSON.parse(@response.body)
    #assert_equal(Hash, result.class)
    #assert_equal('Invalid value for param \'owner_id\': ""', result['error'])
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #5', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
  end

  test '01.07 ticket create with agent - wrong owner_id - 99999' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #6',
      group: 'Users',
      priority: '2 normal',
      owner_id: 99_999,
      state: 'new',
      customer_id: @customer_without_org.id,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Invalid value for param \'owner_id\': 99999', result['error'])
  end

  test '01.08 ticket create with agent - wrong owner_id - nil' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #7',
      group: 'Users',
      priority: '2 normal',
      owner_id: nil,
      state: 'new',
      customer_id: @customer_without_org.id,
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #7', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
  end

  test '01.09 ticket create with agent - minimal article with guess customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #9',
      group: 'Users',
      priority: '2 normal',
      state: 'new',
      customer_id: 'guess:some_new_customer@example.com',
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #9', result['title'])
    assert_equal(User.lookup(email: 'some_new_customer@example.com').id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
  end

  test '01.10 ticket create with agent - minimal article with guess customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #10',
      group: 'Users',
      customer_id: 'guess:some_new_customer@example.com',
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #10', result['title'])
    assert_equal(User.lookup(email: 'some_new_customer@example.com').id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
  end

  test '01.11 ticket create with agent - minimal article with customer hash' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #11',
      group: 'Users',
      customer: {
        firstname: 'some firstname',
        lastname: 'some lastname',
        email: 'some_new_customer@example.com',
      },
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #11', result['title'])
    assert_equal(User.lookup(email: 'some_new_customer@example.com').id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
  end

  test '01.11.1 ticket create with agent - minimal article with customer hash with article.origin_by' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #11.1',
      group: 'Users',
      customer: {
        firstname: 'some firstname',
        lastname: 'some lastname',
        email: 'some_new_customer@example.com',
      },
      article: {
        body: 'some test 123',
        origin_by: 'some_new_customer@example.com',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #11.1', result['title'])
    assert_equal(User.lookup(email: 'some_new_customer@example.com').id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
    ticket = Ticket.find(result['id'])
    article = ticket.articles.first
    assert_equal(@agent.id, article.updated_by_id)
    assert_equal(@agent.id, article.created_by_id)
    assert_equal(User.lookup(email: 'some_new_customer@example.com').id, article.origin_by_id)
    assert_equal('Customer', article.sender.name)
    assert_equal('note', article.type.name)
    assert_equal('some firstname some lastname', article.from)
  end

  test '01.11.2 ticket create with agent - minimal article with customer hash with article.origin_by' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #11.2',
      group: 'Users',
      customer: {
        firstname: 'some firstname',
        lastname: 'some lastname',
        email: 'some_new_customer@example.com',
      },
      article: {
        sender: 'Customer',
        body: 'some test 123',
        origin_by: 'some_new_customer@example.com',
      },
    }

    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #11.2', result['title'])
    assert_equal(User.lookup(email: 'some_new_customer@example.com').id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
    ticket = Ticket.find(result['id'])
    article = ticket.articles.first
    assert_equal(@agent.id, article.updated_by_id)
    assert_equal(@agent.id, article.created_by_id)
    assert_equal(User.lookup(email: 'some_new_customer@example.com').id, article.origin_by_id)
    assert_equal('Customer', article.sender.name)
    assert_equal('note', article.type.name)
    assert_equal('some firstname some lastname', article.from)
  end

  test '01.11.3 ticket create with agent - minimal article with customer hash with article.origin_by' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #11.3',
      group: 'Users',
      customer: {
        firstname: 'some firstname',
        lastname: 'some lastname',
        email: 'some_new_customer@example.com',
      },
      article: {
        sender: 'Agent',
        from: 'somebody',
        body: 'some test 123',
        origin_by: 'some_new_customer@example.com',
      },
    }

    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #11.3', result['title'])
    assert_equal(User.lookup(email: 'some_new_customer@example.com').id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
    ticket = Ticket.find(result['id'])
    article = ticket.articles.first
    assert_equal(@agent.id, article.updated_by_id)
    assert_equal(@agent.id, article.created_by_id)
    assert_equal(User.lookup(email: 'some_new_customer@example.com').id, article.origin_by_id)
    assert_equal('Customer', article.sender.name)
    assert_equal('note', article.type.name)
    assert_equal('some firstname some lastname', article.from)
  end

  test '01.11.4 ticket create with agent - minimal article with customer hash with article.origin_by' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #11.4',
      group: 'Users',
      customer: {
        firstname: 'some firstname',
        lastname: 'some lastname',
        email: 'some_new_customer@example.com',
      },
      article: {
        sender: 'Customer',
        body: 'some test 123',
        origin_by: @customer_without_org.login,
      },
    }

    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #11.4', result['title'])
    assert_equal(User.lookup(email: 'some_new_customer@example.com').id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
    ticket = Ticket.find(result['id'])
    article = ticket.articles.first
    assert_equal(@agent.id, article.updated_by_id)
    assert_equal(@agent.id, article.created_by_id)
    assert_equal(@customer_without_org.id, article.origin_by_id)
    assert_equal('Customer', article.sender.name)
    assert_equal('note', article.type.name)
    assert_equal('Tickets Customer1', article.from)
  end

  test '01.12 ticket create with agent - minimal article with missing body - with customer.id' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #12',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        subject: 'some test 123',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Need at least article: { body: "some text" }', result['error'])
  end

  test '01.13 ticket create with agent - minimal article and attachment with customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #13',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        subject: 'some test 123',
        body: 'some test 123',
        attachments: [
          'filename' => 'some_file.txt',
          'data' => 'dGVzdCAxMjM=',
          'mime-type' => 'text/plain',
        ],
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #13', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    ticket = Ticket.find(result['id'])
    assert_equal(1, ticket.articles.count)
    assert_equal(1, ticket.articles.first.attachments.count)
    file = ticket.articles.first.attachments.first
    assert_equal('test 123', file.content)
    assert_equal('some_file.txt', file.filename)
    assert_equal('text/plain', file.preferences['Mime-Type'])
    assert_not(file.preferences['Content-ID'])
  end

  test '01.14 ticket create with agent - minimal article and attachment with customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #14',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        subject: 'some test 123',
        body: 'some test 123',
        attachments: [
          {
            'filename' => 'some_file1.txt',
            'data' => 'dGVzdCAxMjM=',
            'mime-type' => 'text/plain',
          },
          {
            'filename' => 'some_file2.txt',
            'data' => 'w6TDtsO8w58=',
            'mime-type' => 'text/plain',
          },
        ],
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #14', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    ticket = Ticket.find(result['id'])
    assert_equal(1, ticket.articles.count)
    assert_equal(2, ticket.articles.first.attachments.count)
    file = ticket.articles.first.attachments.first
    assert_equal('test 123', file.content)
    assert_equal('some_file1.txt', file.filename)
    assert_equal('text/plain', file.preferences['Mime-Type'])
    assert_not(file.preferences['Content-ID'])
  end

  test '01.15 ticket create with agent - minimal article and attachment missing mine-type with customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #15',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        subject: 'some test 123',
        body: 'some test 123',
        attachments: [
          'filename' => 'some_file.txt',
          'data' => 'ABC_INVALID_BASE64',
          'mime-type' => 'text/plain',
        ],
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Invalid base64 for attachment with index \'0\'', result['error'])
  end

  test '01.16 ticket create with agent - minimal article and attachment invalid base64 with customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #16',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        subject: 'some test 123',
        body: 'some test 123',
        attachments: [
          'filename' => 'some_file.txt',
          'data' => 'dGVzdCAxMjM=',
        ],
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Attachment needs \'mime-type\' param for attachment with index \'0\'', result['error'])
  end

  test '01.17 ticket create with agent - minimal article and inline attachments with customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #17',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        content_type: 'text/html',
        subject: 'some test 123',
        body: 'some test 123 <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA
AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO
9TXL0Y4OHwAAAABJRU5ErkJggg==" alt="Red dot" /> <img src="data:image/jpeg;base64,/9j/4QAYRXhpZgAASUkqAAgAAAAAAAAAAAAAAP/sABFEdWNreQABAAQAAAAJAAD/4QMtaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLwA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJBZG9iZSBYTVAgQ29yZSA1LjMtYzAxMSA2Ni4xNDU2NjEsIDIwMTIvMDIvMDYtMTQ6NTY6MjcgICAgICAgICI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCBDUzYgKE1hY2ludG9zaCkiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6QzJCOTE2NzlGQUEwMTFFNjg0M0NGQjU0OUU4MTFEOEIiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6QzJCOTE2N0FGQUEwMTFFNjg0M0NGQjU0OUU4MTFEOEIiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpDMkI5MTY3N0ZBQTAxMUU2ODQzQ0ZCNTQ5RTgxMUQ4QiIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpDMkI5MTY3OEZBQTAxMUU2ODQzQ0ZCNTQ5RTgxMUQ4QiIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Pv/uAA5BZG9iZQBkwAAAAAH/2wCEABQRERoTGioZGSo1KCEoNTEpKCgpMUE4ODg4OEFEREREREREREREREREREREREREREREREREREREREREREREREQBFhoaIh0iKRoaKTkpIik5RDktLTlEREREOERERERERERERERERERERERERERERERERERERERERERERERERERERP/AABEIABAADAMBIgACEQEDEQH/xABbAAEBAAAAAAAAAAAAAAAAAAAEBQEBAQAAAAAAAAAAAAAAAAAABAUQAAEEAgMAAAAAAAAAAAAAAAABAhIDESIxBAURAAICAwAAAAAAAAAAAAAAAAESABNRoQP/2gAMAwEAAhEDEQA/AJDq1rfF3Imeg/1+lFy2oR564DKWWWbweV+Buf/Z">',
      },
    }

    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #17', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    ticket = Ticket.find(result['id'])
    assert_equal(1, ticket.articles.count)
    assert_equal(2, ticket.articles.first.attachments.count)
    file = ticket.articles.first.attachments[0]
    assert_equal('d3c1e09bdefb92b6a06b791a24ca9599', Digest::MD5.hexdigest(file.content))
    assert_equal('image1.png', file.filename)
    assert_equal('image/png', file.preferences['Mime-Type'])
    assert_match(/#{ticket.id}\..+?@zammad.example.com/, file.preferences['Content-ID'])
    assert(file.preferences['Content-ID'])
    file = ticket.articles.first.attachments[1]
    assert_equal('006a2ca3793b550c8fe444acdeb39252', Digest::MD5.hexdigest(file.content))
    assert_equal('image2.jpeg', file.filename)
    assert_equal('image/jpeg', file.preferences['Mime-Type'])
    assert_match(/#{ticket.id}\..+?@zammad.example.com/, file.preferences['Content-ID'])
    assert(file.preferences['Content-ID'])
  end

  test '01.18 ticket create with agent - minimal article and inline attachments with customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #18',
      group: 'Users',
      customer_id: @customer_without_org.id,
      article: {
        content_type: 'text/html',
        subject: 'some test 123',
        body: 'some test 123 <img src="data:image/jpeg;base64,/9j/4QAYRXhpZgAASUkqAAgAAAAAAAAAAAAAAP/sABFEdWNreQABAAQAAAAJAAD/4QMtaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLwA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJBZG9iZSBYTVAgQ29yZSA1LjMtYzAxMSA2Ni4xNDU2NjEsIDIwMTIvMDIvMDYtMTQ6NTY6MjcgICAgICAgICI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCBDUzYgKE1hY2ludG9zaCkiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6QzJCOTE2NzlGQUEwMTFFNjg0M0NGQjU0OUU4MTFEOEIiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6QzJCOTE2N0FGQUEwMTFFNjg0M0NGQjU0OUU4MTFEOEIiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpDMkI5MTY3N0ZBQTAxMUU2ODQzQ0ZCNTQ5RTgxMUQ4QiIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpDMkI5MTY3OEZBQTAxMUU2ODQzQ0ZCNTQ5RTgxMUQ4QiIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Pv/uAA5BZG9iZQBkwAAAAAH/2wCEABQRERoTGioZGSo1KCEoNTEpKCgpMUE4ODg4OEFEREREREREREREREREREREREREREREREREREREREREREREREQBFhoaIh0iKRoaKTkpIik5RDktLTlEREREOERERERERERERERERERERERERERERERERERERERERERERERERERERP/AABEIABAADAMBIgACEQEDEQH/xABbAAEBAAAAAAAAAAAAAAAAAAAEBQEBAQAAAAAAAAAAAAAAAAAABAUQAAEEAgMAAAAAAAAAAAAAAAABAhIDESIxBAURAAICAwAAAAAAAAAAAAAAAAESABNRoQP/2gAMAwEAAhEDEQA/AJDq1rfF3Imeg/1+lFy2oR564DKWWWbweV+Buf/Z"
>',
        attachments: [
          'filename' => 'some_file.txt',
          'data' => 'dGVzdCAxMjM=',
          'mime-type' => 'text/plain',
        ],
      },
    }

    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #18', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    ticket = Ticket.find(result['id'])
    assert_equal(1, ticket.articles.count)
    assert_equal(2, ticket.articles.first.attachments.count)
    file = ticket.articles.first.attachments[0]
    assert_equal('006a2ca3793b550c8fe444acdeb39252', Digest::MD5.hexdigest(file.content))
    assert_equal('image1.jpeg', file.filename)
    assert_equal('image/jpeg', file.preferences['Mime-Type'])
    assert(file.preferences['Content-ID'])
    assert_match(/#{ticket.id}\..+?@zammad.example.com/, file.preferences['Content-ID'])
    file = ticket.articles.first.attachments[1]
    assert_equal('39d0d586a701e199389d954f2d592720', Digest::MD5.hexdigest(file.content))
    assert_equal('some_file.txt', file.filename)
    assert_equal('text/plain', file.preferences['Mime-Type'])
    assert_not(file.preferences['Content-ID'])
  end

  test '02.02 ticket create with agent' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #1',
      state: 'new',
      priority: '2 normal',
      group: 'Users',
      customer: 'tickets-customer1@example.com',
      article: {
        content_type: 'text/plain', # or text/html
        body: 'some body',
      },
      links: {
        Ticket: {
          parent: [1],
        }
      }
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #1', result['title'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
    links = Link.list(
      link_object: 'Ticket',
      link_object_value: result['id'],
    )
    assert_equal('child', links[0]['link_type'])
    assert_equal('Ticket', links[0]['link_object'])
    assert_equal(1, links[0]['link_object_value'])
  end

  test '02.03 ticket with wrong ticket id' do
    group = Group.create!(
      name: "GroupWithoutPermission-#{rand(9_999_999_999)}",
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket = Ticket.create!(
      title: 'ticket with wrong ticket id',
      group_id: group.id,
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    get "/api/v1/tickets/#{ticket.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])

    params = {
      title: 'ticket with wrong ticket id - 2',
    }
    put "/api/v1/tickets/#{ticket.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])

    delete "/api/v1/tickets/#{ticket.id}", params: {}.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])
  end

  test '02.04 ticket with correct ticket id' do
    title = "ticket with corret ticket id testagent#{rand(999_999_999)}"
    ticket = Ticket.create!(
      title: title,
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    get "/api/v1/tickets/#{ticket.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert_equal(title, result['title'])
    assert_equal(ticket.customer_id, result['customer_id'])
    assert_equal(1, result['updated_by_id'])
    assert_equal(1, result['created_by_id'])

    params = {
      title: "#{title} - 2",
      customer_id: @agent.id,
    }
    put "/api/v1/tickets/#{ticket.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert_equal("#{title} - 2", result['title'])
    assert_equal(@agent.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(1, result['created_by_id'])

    params = {
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
    }
    post '/api/v1/ticket_articles', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    article_result = JSON.parse(@response.body)
    assert_equal(Hash, article_result.class)
    assert_equal(ticket.id, article_result['ticket_id'])
    assert_equal('Tickets Agent', article_result['from'])
    assert_equal('some subject', article_result['subject'])
    assert_equal('some body', article_result['body'])
    assert_equal('text/plain', article_result['content_type'])
    assert_equal(false, article_result['internal'])
    assert_equal(@agent.id, article_result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Agent').id, article_result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'note').id, article_result['type_id'])

    Scheduler.worker(true)
    get "/api/v1/tickets/search?query=#{CGI.escape(title)}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['tickets'][0])
    assert_equal(1, result['tickets_count'])

    params = {
      condition: {
        'ticket.title' => {
          operator: 'contains',
          value: title,
        },
      },
    }
    post '/api/v1/tickets/search', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['tickets'][0])
    assert_equal(1, result['tickets_count'])

    delete "/api/v1/ticket_articles/#{article_result['id']}", params: {}.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)

    params = {
      from: 'something which should not be changed on server side',
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
      type: 'email',
      internal: true,
    }
    post '/api/v1/ticket_articles', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['ticket_id'])
    assert_equal('"Tickets Agent via Zammad" <zammad@localhost>', result['from'])
    assert_equal('some subject', result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(true, result['internal'])
    assert_equal(@agent.id, result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Agent').id, result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'email').id, result['type_id'])

    params = {
      subject: 'new subject',
    }
    put "/api/v1/ticket_articles/#{result['id']}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['ticket_id'])
    assert_equal('"Tickets Agent via Zammad" <zammad@localhost>', result['from'])
    assert_equal('new subject', result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(true, result['internal'])
    assert_equal(@agent.id, result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Agent').id, result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'email').id, result['type_id'])

    delete "/api/v1/ticket_articles/#{result['id']}", params: {}.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (admin permission required)!', result['error'])

    delete "/api/v1/tickets/#{ticket.id}", params: {}.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (admin permission required)!', result['error'])
  end

  test '02.05 ticket with correct ticket id' do
    ticket = Ticket.create!(
      title: 'ticket with corret ticket id',
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')
    get "/api/v1/tickets/#{ticket.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert_equal('ticket with corret ticket id', result['title'])
    assert_equal(ticket.customer_id, result['customer_id'])
    assert_equal(1, result['updated_by_id'])
    assert_equal(1, result['created_by_id'])

    params = {
      title: 'ticket with corret ticket id - 2',
      customer_id: @agent.id,
    }
    put "/api/v1/tickets/#{ticket.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert_equal('ticket with corret ticket id - 2', result['title'])
    assert_equal(@agent.id, result['customer_id'])
    assert_equal(@admin.id, result['updated_by_id'])
    assert_equal(1, result['created_by_id'])

    params = {
      from: 'something which should not be changed on server side',
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
    }
    post '/api/v1/ticket_articles', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['ticket_id'])
    assert_equal('Tickets Admin', result['from'])
    assert_equal('some subject', result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(false, result['internal'])
    assert_equal(@admin.id, result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Agent').id, result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'note').id, result['type_id'])

    params = {
      subject: 'new subject',
      internal: true,
    }
    put "/api/v1/ticket_articles/#{result['id']}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['ticket_id'])
    assert_equal('Tickets Admin', result['from'])
    assert_equal('new subject', result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(true, result['internal'])
    assert_equal(@admin.id, result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Agent').id, result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'note').id, result['type_id'])

    delete "/api/v1/ticket_articles/#{result['id']}", params: {}.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)

    params = {
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
      type: 'email',
    }
    post '/api/v1/ticket_articles', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['ticket_id'])
    assert_equal('"Tickets Admin via Zammad" <zammad@localhost>', result['from'])
    assert_equal('some subject', result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(false, result['internal'])
    assert_equal(@admin.id, result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Agent').id, result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'email').id, result['type_id'])

    delete "/api/v1/ticket_articles/#{result['id']}", params: {}.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)

    delete "/api/v1/tickets/#{ticket.id}", params: {}.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
  end

  test '02.05 ticket pagination' do
    title = "ticket pagination #{rand(999_999_999)}"
    tickets = []
    (1..20).each do |count|
      ticket = Ticket.create!(
        title: "#{title} - #{count}",
        group: Group.lookup(name: 'Users'),
        customer_id: @customer_without_org.id,
        state: Ticket::State.lookup(name: 'new'),
        priority: Ticket::Priority.lookup(name: '2 normal'),
        updated_by_id: 1,
        created_by_id: 1,
      )
      Ticket::Article.create!(
        type: Ticket::Article::Type.lookup(name: 'note'),
        sender: Ticket::Article::Sender.lookup(name: 'Customer'),
        from: 'sender',
        subject: 'subject',
        body: 'some body',
        ticket_id: ticket.id,
        updated_by_id: 1,
        created_by_id: 1,
      )
      tickets.push ticket
      travel 2.seconds
    end

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')
    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(tickets[19].id, result['tickets'][0])
    assert_equal(tickets[0].id, result['tickets'][19])
    assert_equal(20, result['tickets_count'])

    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=10", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(tickets[19].id, result['tickets'][0])
    assert_equal(tickets[10].id, result['tickets'][9])
    assert_equal(10, result['tickets_count'])

    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40&page=1&per_page=5", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(tickets[19].id, result['tickets'][0])
    assert_equal(tickets[15].id, result['tickets'][4])
    assert_equal(5, result['tickets_count'])

    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40&page=2&per_page=5", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(tickets[14].id, result['tickets'][0])
    assert_equal(tickets[10].id, result['tickets'][4])
    assert_equal(5, result['tickets_count'])

    get '/api/v1/tickets?limit=40&page=1&per_page=5', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    tickets = Ticket.order(:id).limit(5)
    assert_equal(tickets[0].id, result[0]['id'])
    assert_equal(tickets[4].id, result[4]['id'])
    assert_equal(5, result.count)

    get '/api/v1/tickets?limit=40&page=2&per_page=5', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    tickets = Ticket.order(:id).limit(10)
    assert_equal(tickets[5].id, result[0]['id'])
    assert_equal(tickets[9].id, result[4]['id'])
    assert_equal(5, result.count)

  end

  test '03.01 ticket create with customer minimal' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-customer1@example.com', 'customer1pw')
    params = {
      title: 'a new ticket #c1',
      state: 'new',
      priority: '2 normal',
      group: 'Users',
      article: {
        body: 'some body',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #c1', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@customer_without_org.id, result['updated_by_id'])
    assert_equal(@customer_without_org.id, result['created_by_id'])
  end

  test '03.02 ticket create with customer with wrong customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-customer1@example.com', 'customer1pw')
    params = {
      title: 'a new ticket #c2',
      state: 'new',
      priority: '2 normal',
      group: 'Users',
      customer_id: @agent.id,
      article: {
        content_type: 'text/plain', # or text/html
        body: 'some body',
        sender: 'System',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #c2', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@customer_without_org.id, result['updated_by_id'])
    assert_equal(@customer_without_org.id, result['created_by_id'])
  end

  test '03.03 ticket create with customer with wrong customer hash' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-customer1@example.com', 'customer1pw')
    params = {
      title: 'a new ticket #c2',
      state: 'new',
      priority: '2 normal',
      group: 'Users',
      customer: {
        firstname: @agent.firstname,
        lastname: @agent.lastname,
        email: @agent.email,
      },
      article: {
        content_type: 'text/plain', # or text/html
        body: 'some body',
        sender: 'System',
      },
    }
    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #c2', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@customer_without_org.id, result['updated_by_id'])
    assert_equal(@customer_without_org.id, result['created_by_id'])
  end

  test '03.04 ticket with wrong ticket id' do
    ticket = Ticket.create!(
      title: 'ticket with wrong ticket id',
      group: Group.lookup(name: 'Users'),
      customer_id: @agent.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-customer1@example.com', 'customer1pw')
    get "/api/v1/tickets/#{ticket.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])

    params = {
      title: 'ticket with wrong ticket id - 2',
    }
    put "/api/v1/tickets/#{ticket.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])

    delete "/api/v1/tickets/#{ticket.id}", params: {}.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])
  end

  test '03.05 ticket with correct ticket id' do
    title = "ticket with corret ticket id testme#{rand(999_999_999)}"
    ticket = Ticket.create!(
      title: title,
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-customer1@example.com', 'customer1pw')
    get "/api/v1/tickets/#{ticket.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert_equal(title, result['title'])
    assert_equal(ticket.customer_id, result['customer_id'])
    assert_equal(1, result['updated_by_id'])
    assert_equal(1, result['created_by_id'])

    params = {
      title: "#{title} - 2",
      customer_id: @agent.id,
    }
    put "/api/v1/tickets/#{ticket.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert_equal("#{title} - 2", result['title'])
    assert_equal(ticket.customer_id, result['customer_id'])
    assert_equal(@customer_without_org.id, result['updated_by_id'])
    assert_equal(1, result['created_by_id'])

    params = {
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
    }
    post '/api/v1/ticket_articles', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    article_result = JSON.parse(@response.body)
    assert_equal(Hash, article_result.class)
    assert_equal(ticket.id, article_result['ticket_id'])
    assert_equal('Tickets Customer1', article_result['from'])
    assert_equal('some subject', article_result['subject'])
    assert_equal('some body', article_result['body'])
    assert_equal('text/plain', article_result['content_type'])
    assert_equal(@customer_without_org.id, article_result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Customer').id, article_result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'note').id, article_result['type_id'])

    Scheduler.worker(true)
    get "/api/v1/tickets/search?query=#{CGI.escape(title)}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['tickets'][0])
    assert_equal(1, result['tickets_count'])

    params = {
      condition: {
        'ticket.title' => {
          operator: 'contains',
          value: title,
        },
      },
    }
    post '/api/v1/tickets/search', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['tickets'][0])
    assert_equal(1, result['tickets_count'])

    delete "/api/v1/ticket_articles/#{article_result['id']}", params: {}.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (admin permission required)!', result['error'])

    params = {
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
      type: 'email',
      sender: 'Agent',
    }
    post '/api/v1/ticket_articles', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['ticket_id'])
    assert_equal('Tickets Customer1', result['from'])
    assert_equal('some subject', result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(@customer_without_org.id, result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Customer').id, result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'note').id, result['type_id'])

    delete "/api/v1/ticket_articles/#{result['id']}", params: {}.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (admin permission required)!', result['error'])

    params = {
      from: 'something which should not be changed on server side',
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
      type: 'web',
      sender: 'Agent',
      internal: true,
    }

    post '/api/v1/ticket_articles', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['ticket_id'])
    assert_equal('Tickets Customer1 <tickets-customer1@example.com>', result['from'])
    assert_equal('some subject', result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(false, result['internal'])
    assert_equal(@customer_without_org.id, result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Customer').id, result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'web').id, result['type_id'])

    params = {
      subject: 'new subject',
    }
    put "/api/v1/ticket_articles/#{result['id']}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (ticket.agent or admin permission required)!', result['error'])

    delete "/api/v1/tickets/#{ticket.id}", params: {}.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (admin permission required)!', result['error'])
  end

  test '03.6 ticket create with agent - minimal article with customer hash with article.origin_by' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-customer1@example.com', 'customer1pw')
    params = {
      title: 'a new ticket #3.6',
      group: 'Users',
      customer: {
        firstname: 'some firstname',
        lastname: 'some lastname',
        email: 'some_new_customer@example.com',
      },
      article: {
        body: 'some test 123',
        origin_by: @agent.login,
      },
    }

    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #3.6', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@customer_without_org.id, result['updated_by_id'])
    assert_equal(@customer_without_org.id, result['created_by_id'])
    ticket = Ticket.find(result['id'])
    article = ticket.articles.first
    assert_equal(@customer_without_org.id, article.updated_by_id)
    assert_equal(@customer_without_org.id, article.created_by_id)
    assert_equal(@customer_without_org.id, article.origin_by_id)
    assert_equal('Customer', article.sender.name)
    assert_equal('note', article.type.name)
    assert_equal('Tickets Customer1', article.from)
  end

  test '03.6.1 ticket create with agent - minimal article with customer hash with article.origin_by' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-customer1@example.com', 'customer1pw')
    params = {
      title: 'a new ticket #3.6.1',
      group: 'Users',
      customer: {
        firstname: 'some firstname',
        lastname: 'some lastname',
        email: 'some_new_customer@example.com',
      },
      article: {
        sender: 'Agent',
        body: 'some test 123',
        origin_by_id: @agent.id,
      },
    }

    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #3.6.1', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@customer_without_org.id, result['updated_by_id'])
    assert_equal(@customer_without_org.id, result['created_by_id'])
    ticket = Ticket.find(result['id'])
    article = ticket.articles.first
    assert_equal(@customer_without_org.id, article.updated_by_id)
    assert_equal(@customer_without_org.id, article.created_by_id)
    assert_equal(@customer_without_org.id, article.origin_by_id)
    assert_equal('Customer', article.sender.name)
    assert_equal('note', article.type.name)
    assert_equal('Tickets Customer1', article.from)
  end

  test '04.01 ticket show and response format' do
    title = "ticket testagent#{rand(999_999_999)}"
    ticket = Ticket.create!(
      title: title,
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent.id,
      created_by_id: @agent.id,
    )
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    get "/api/v1/tickets/#{ticket.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert_equal(ticket.title, result['title'])
    assert_not(result['group'])
    assert_not(result['priority'])
    assert_not(result['owner'])
    assert_equal(ticket.customer_id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    get "/api/v1/tickets/#{ticket.id}?expand=true", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert_equal(ticket.title, result['title'])
    assert_equal(ticket.customer_id, result['customer_id'])
    assert_equal(ticket.group.name, result['group'])
    assert_equal(ticket.priority.name, result['priority'])
    assert_equal(ticket.owner.login, result['owner'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    get "/api/v1/tickets/#{ticket.id}?expand=false", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert_equal(ticket.title, result['title'])
    assert_not(result['group'])
    assert_not(result['priority'])
    assert_not(result['owner'])
    assert_equal(ticket.customer_id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    get "/api/v1/tickets/#{ticket.id}?full=true", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)

    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert(result['assets'])
    assert(result['assets']['Ticket'])
    assert(result['assets']['Ticket'][ticket.id.to_s])
    assert_equal(ticket.id, result['assets']['Ticket'][ticket.id.to_s]['id'])
    assert_equal(ticket.title, result['assets']['Ticket'][ticket.id.to_s]['title'])
    assert_equal(ticket.customer_id, result['assets']['Ticket'][ticket.id.to_s]['customer_id'])

    assert(result['assets']['User'])
    assert(result['assets']['User'][@agent.id.to_s])
    assert_equal(@agent.id, result['assets']['User'][@agent.id.to_s]['id'])
    assert_equal(@agent.firstname, result['assets']['User'][@agent.id.to_s]['firstname'])
    assert_equal(@agent.lastname, result['assets']['User'][@agent.id.to_s]['lastname'])

    assert(result['assets']['User'])
    assert(result['assets']['User'][@customer_without_org.id.to_s])
    assert_equal(@customer_without_org.id, result['assets']['User'][@customer_without_org.id.to_s]['id'])
    assert_equal(@customer_without_org.firstname, result['assets']['User'][@customer_without_org.id.to_s]['firstname'])
    assert_equal(@customer_without_org.lastname, result['assets']['User'][@customer_without_org.id.to_s]['lastname'])

    get "/api/v1/tickets/#{ticket.id}?full=false", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['id'])
    assert_equal(ticket.title, result['title'])
    assert_not(result['group'])
    assert_not(result['priority'])
    assert_not(result['owner'])
    assert_equal(ticket.customer_id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
  end

  test '04.02 ticket index and response format' do
    title = "ticket testagent#{rand(999_999_999)}"
    ticket = Ticket.create!(
      title: title,
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent.id,
      created_by_id: @agent.id,
    )
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    get '/api/v1/tickets', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)

    assert_equal(Array, result.class)
    assert_equal(Hash, result[0].class)
    assert_equal(1, result[0]['id'])
    assert_equal(ticket.id, result[1]['id'])
    assert_equal(ticket.title, result[1]['title'])
    assert_not(result[1]['group'])
    assert_not(result[1]['priority'])
    assert_not(result[1]['owner'])
    assert_equal(ticket.customer_id, result[1]['customer_id'])
    assert_equal(@agent.id, result[1]['updated_by_id'])
    assert_equal(@agent.id, result[1]['created_by_id'])

    get '/api/v1/tickets?expand=true', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(Hash, result[0].class)
    assert_equal(1, result[0]['id'])
    assert_equal(ticket.id, result[1]['id'])
    assert_equal(ticket.title, result[1]['title'])
    assert_equal(ticket.customer_id, result[1]['customer_id'])
    assert_equal(ticket.group.name, result[1]['group'])
    assert_equal(ticket.priority.name, result[1]['priority'])
    assert_equal(ticket.owner.login, result[1]['owner'])
    assert_equal(@agent.id, result[1]['updated_by_id'])
    assert_equal(@agent.id, result[1]['created_by_id'])

    get '/api/v1/tickets?expand=false', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(Hash, result[0].class)
    assert_equal(1, result[0]['id'])
    assert_equal(ticket.id, result[1]['id'])
    assert_equal(ticket.title, result[1]['title'])
    assert_not(result[1]['group'])
    assert_not(result[1]['priority'])
    assert_not(result[1]['owner'])
    assert_equal(ticket.customer_id, result[1]['customer_id'])
    assert_equal(@agent.id, result[1]['updated_by_id'])
    assert_equal(@agent.id, result[1]['created_by_id'])

    get '/api/v1/tickets?full=true', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)

    assert_equal(Hash, result.class)
    assert_equal(Array, result['record_ids'].class)
    assert_equal(1, result['record_ids'][0])
    assert_equal(ticket.id, result['record_ids'][1])
    assert(result['assets'])
    assert(result['assets']['Ticket'])
    assert(result['assets']['Ticket'][ticket.id.to_s])
    assert_equal(ticket.id, result['assets']['Ticket'][ticket.id.to_s]['id'])
    assert_equal(ticket.title, result['assets']['Ticket'][ticket.id.to_s]['title'])
    assert_equal(ticket.customer_id, result['assets']['Ticket'][ticket.id.to_s]['customer_id'])

    assert(result['assets']['User'])
    assert(result['assets']['User'][@agent.id.to_s])
    assert_equal(@agent.id, result['assets']['User'][@agent.id.to_s]['id'])
    assert_equal(@agent.firstname, result['assets']['User'][@agent.id.to_s]['firstname'])
    assert_equal(@agent.lastname, result['assets']['User'][@agent.id.to_s]['lastname'])

    assert(result['assets']['User'])
    assert(result['assets']['User'][@customer_without_org.id.to_s])
    assert_equal(@customer_without_org.id, result['assets']['User'][@customer_without_org.id.to_s]['id'])
    assert_equal(@customer_without_org.firstname, result['assets']['User'][@customer_without_org.id.to_s]['firstname'])
    assert_equal(@customer_without_org.lastname, result['assets']['User'][@customer_without_org.id.to_s]['lastname'])

    get '/api/v1/tickets?full=false', params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    assert_equal(Hash, result[0].class)
    assert_equal(1, result[0]['id'])
    assert_equal(ticket.id, result[1]['id'])
    assert_equal(ticket.title, result[1]['title'])
    assert_not(result[1]['group'])
    assert_not(result[1]['priority'])
    assert_not(result[1]['owner'])
    assert_equal(ticket.customer_id, result[1]['customer_id'])
    assert_equal(@agent.id, result[1]['updated_by_id'])
    assert_equal(@agent.id, result[1]['created_by_id'])
  end

  test '04.03 ticket create and response format' do
    title = "ticket testagent#{rand(999_999_999)}"
    params = {
      title: title,
      group: 'Users',
      customer_id: @customer_without_org.id,
      state: 'new',
      priority: '2 normal',
      article: {
        body: 'some test 123',
      },
    }
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')

    post '/api/v1/tickets', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    ticket = Ticket.find(result['id'])
    assert_equal(ticket.state_id, result['state_id'])
    assert_not(result['state'])
    assert_equal(ticket.priority_id, result['priority_id'])
    assert_not(result['priority'])
    assert_equal(ticket.group_id, result['group_id'])
    assert_not(result['group'])
    assert_equal(title, result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    post '/api/v1/tickets?expand=true', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    ticket = Ticket.find(result['id'])
    assert_equal(ticket.state_id, result['state_id'])
    assert_equal(ticket.state.name, result['state'])
    assert_equal(ticket.priority_id, result['priority_id'])
    assert_equal(ticket.priority.name, result['priority'])
    assert_equal(ticket.group_id, result['group_id'])
    assert_equal(ticket.group.name, result['group'])
    assert_equal(title, result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    post '/api/v1/tickets?full=true', params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    ticket = Ticket.find(result['id'])
    assert(result['assets'])
    assert(result['assets']['Ticket'])
    assert(result['assets']['Ticket'][ticket.id.to_s])
    assert_equal(ticket.id, result['assets']['Ticket'][ticket.id.to_s]['id'])
    assert_equal(title, result['assets']['Ticket'][ticket.id.to_s]['title'])
    assert_equal(ticket.customer_id, result['assets']['Ticket'][ticket.id.to_s]['customer_id'])

    assert(result['assets']['User'])
    assert(result['assets']['User'][@agent.id.to_s])
    assert_equal(@agent.id, result['assets']['User'][@agent.id.to_s]['id'])
    assert_equal(@agent.firstname, result['assets']['User'][@agent.id.to_s]['firstname'])
    assert_equal(@agent.lastname, result['assets']['User'][@agent.id.to_s]['lastname'])

    assert(result['assets']['User'])
    assert(result['assets']['User'][@customer_without_org.id.to_s])
    assert_equal(@customer_without_org.id, result['assets']['User'][@customer_without_org.id.to_s]['id'])
    assert_equal(@customer_without_org.firstname, result['assets']['User'][@customer_without_org.id.to_s]['firstname'])
    assert_equal(@customer_without_org.lastname, result['assets']['User'][@customer_without_org.id.to_s]['lastname'])

  end

  test '04.04 ticket update and response formats' do
    title = "ticket testagent#{rand(999_999_999)}"
    ticket = Ticket.create!(
      title: title,
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent.id,
      created_by_id: @agent.id,
    )
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')

    params = {
      title: 'a update ticket #1',
    }
    put "/api/v1/tickets/#{ticket.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    ticket = Ticket.find(result['id'])
    assert_equal(ticket.state_id, result['state_id'])
    assert_not(result['state'])
    assert_equal(ticket.priority_id, result['priority_id'])
    assert_not(result['priority'])
    assert_equal(ticket.group_id, result['group_id'])
    assert_not(result['group'])
    assert_equal('a update ticket #1', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    params = {
      title: 'a update ticket #2',
    }
    put "/api/v1/tickets/#{ticket.id}?expand=true", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    ticket = Ticket.find(result['id'])
    assert_equal(ticket.state_id, result['state_id'])
    assert_equal(ticket.state.name, result['state'])
    assert_equal(ticket.priority_id, result['priority_id'])
    assert_equal(ticket.priority.name, result['priority'])
    assert_equal(ticket.group_id, result['group_id'])
    assert_equal(ticket.group.name, result['group'])
    assert_equal('a update ticket #2', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])

    params = {
      title: 'a update ticket #3',
    }
    put "/api/v1/tickets/#{ticket.id}?full=true", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)

    ticket = Ticket.find(result['id'])
    assert(result['assets'])
    assert(result['assets']['Ticket'])
    assert(result['assets']['Ticket'][ticket.id.to_s])
    assert_equal(ticket.id, result['assets']['Ticket'][ticket.id.to_s]['id'])
    assert_equal('a update ticket #3', result['assets']['Ticket'][ticket.id.to_s]['title'])
    assert_equal(ticket.customer_id, result['assets']['Ticket'][ticket.id.to_s]['customer_id'])

    assert(result['assets']['User'])
    assert(result['assets']['User'][@agent.id.to_s])
    assert_equal(@agent.id, result['assets']['User'][@agent.id.to_s]['id'])
    assert_equal(@agent.firstname, result['assets']['User'][@agent.id.to_s]['firstname'])
    assert_equal(@agent.lastname, result['assets']['User'][@agent.id.to_s]['lastname'])

    assert(result['assets']['User'])
    assert(result['assets']['User'][@customer_without_org.id.to_s])
    assert_equal(@customer_without_org.id, result['assets']['User'][@customer_without_org.id.to_s]['id'])
    assert_equal(@customer_without_org.firstname, result['assets']['User'][@customer_without_org.id.to_s]['firstname'])
    assert_equal(@customer_without_org.lastname, result['assets']['User'][@customer_without_org.id.to_s]['lastname'])

  end

  test '05.01 ticket split with html - check attachments' do
    ticket = Ticket.create!(
      title: 'some title',
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent.id,
      created_by_id: @agent.id,
    )
    article = Ticket::Article.create!(
      type: Ticket::Article::Type.lookup(name: 'note'),
      sender: Ticket::Article::Sender.lookup(name: 'Customer'),
      from: 'sender',
      subject: 'subject',
      body: '<b>test</b> <img src="cid:15.274327094.140938@ZAMMAD.example.com"/> test <img src="cid:15.274327094.140938.3@ZAMMAD.example.com"/>',
      content_type: 'text/html',
      ticket_id: ticket.id,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Store.add(
      object: 'Ticket::Article',
      o_id: article.id,
      data: 'content_file1_normally_should_be_an_image',
      filename: 'some_file1.jpg',
      preferences: {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140938@zammad.example.com',
        'Content-Disposition' => 'inline',
      },
      created_by_id: 1,
    )
    Store.add(
      object: 'Ticket::Article',
      o_id: article.id,
      data: 'content_file2_normally_should_be_an_image',
      filename: 'some_file2.jpg',
      preferences: {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140938.2@zammad.example.com',
        'Content-Disposition' => 'inline',
      },
      created_by_id: 1,
    )
    Store.add(
      object: 'Ticket::Article',
      o_id: article.id,
      data: 'content_file3_normally_should_be_an_image',
      filename: 'some_file3.jpg',
      preferences: {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140938.3@zammad.example.com',
      },
      created_by_id: 1,
    )
    Store.add(
      object: 'Ticket::Article',
      o_id: article.id,
      data: 'content_file4_normally_should_be_an_image',
      filename: 'some_file4.jpg',
      preferences: {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140938.4@zammad.example.com',
      },
      created_by_id: 1,
    )
    Store.add(
      object: 'Ticket::Article',
      o_id: article.id,
      data: 'content_file1_normally_should_be_an_pdf',
      filename: 'Rechnung_RE-2018-200.pdf',
      preferences: {
        'Content-Type'        => 'application/octet-stream; name="Rechnung_RE-2018-200.pdf"',
        'Mime-Type'           => 'application/octet-stream',
        'Content-ID'          => '8AB0BEC88984EE4EBEF643C79C8E0346@zammad.example.com',
        'Content-Description' => 'Rechnung_RE-2018-200.pdf',
        'Content-Disposition' => 'attachment',
      },
      created_by_id: 1,
    )

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')

    get "/api/v1/ticket_split?ticket_id=#{ticket.id}&article_id=#{article.id}&form_id=new_form_id123", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['assets'])
    assert(result['assets']['Ticket'])
    assert(result['assets']['Ticket'][ticket.id.to_s])
    assert(result['assets']['TicketArticle'][article.id.to_s])
    assert(result['attachments'])
    assert_equal(result['attachments'].count, 3)

    get "/api/v1/ticket_split?ticket_id=#{ticket.id}&article_id=#{article.id}&form_id=new_form_id123", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['assets'])
    assert(result['assets']['Ticket'])
    assert(result['assets']['Ticket'][ticket.id.to_s])
    assert(result['assets']['TicketArticle'][article.id.to_s])
    assert(result['attachments'])
    assert_equal(result['attachments'].count, 0)

  end

  test '05.02 ticket split with plain - check attachments' do
    ticket = Ticket.create!(
      title: 'some title',
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent.id,
      created_by_id: @agent.id,
    )
    article = Ticket::Article.create!(
      type: Ticket::Article::Type.lookup(name: 'note'),
      sender: Ticket::Article::Sender.lookup(name: 'Customer'),
      from: 'sender',
      subject: 'subject',
      body: '<b>test</b> <img src="cid:15.274327094.140938@zammad.example.com"/>',
      content_type: 'text/plain',
      ticket_id: ticket.id,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Store.add(
      object: 'Ticket::Article',
      o_id: article.id,
      data: 'content_file1_normally_should_be_an_image',
      filename: 'some_file1.jpg',
      preferences: {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140938@zammad.example.com',
        'Content-Disposition' => 'inline',
      },
      created_by_id: 1,
    )
    Store.add(
      object: 'Ticket::Article',
      o_id: article.id,
      data: 'content_file1_normally_should_be_an_image',
      filename: 'some_file2.jpg',
      preferences: {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140938.2@zammad.example.com',
        'Content-Disposition' => 'inline',
      },
      created_by_id: 1,
    )
    Store.add(
      object: 'Ticket::Article',
      o_id: article.id,
      data: 'content_file1_normally_should_be_an_pdf',
      filename: 'Rechnung_RE-2018-200.pdf',
      preferences: {
        'Content-Type'        => 'application/octet-stream; name="Rechnung_RE-2018-200.pdf"',
        'Mime-Type'           => 'application/octet-stream',
        'Content-ID'          => '8AB0BEC88984EE4EBEF643C79C8E0346@zammad.example.com',
        'Content-Description' => 'Rechnung_RE-2018-200.pdf',
        'Content-Disposition' => 'attachment',
      },
      created_by_id: 1,
    )

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')

    get "/api/v1/ticket_split?ticket_id=#{ticket.id}&article_id=#{article.id}&form_id=new_form_id123", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['assets'])
    assert(result['assets']['Ticket'])
    assert(result['assets']['Ticket'][ticket.id.to_s])
    assert(result['assets']['TicketArticle'][article.id.to_s])
    assert(result['attachments'])
    assert_equal(result['attachments'].count, 3)

    get "/api/v1/ticket_split?ticket_id=#{ticket.id}&article_id=#{article.id}&form_id=new_form_id123", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert(result['assets'])
    assert(result['assets']['Ticket'])
    assert(result['assets']['Ticket'][ticket.id.to_s])
    assert(result['assets']['TicketArticle'][article.id.to_s])
    assert(result['attachments'])
    assert_equal(result['attachments'].count, 0)

  end

  test '06.01 - ticket with follow up possible set to new_ticket' do
    group = Group.create!(
      name: "GroupWithNoFollowUp-#{rand(9_999_999_999)}",
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
      follow_up_possible: 'new_ticket' # disable follow up possible
    )

    ticket = Ticket.create!(
      title: 'ticket with wrong ticket id',
      group_id: group.id,
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'closed'), # set the ticket to closed
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    state = Ticket::State.find_by(name: 'open') # try to open a ticket from a closed state

    # customer
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-customer1@example.com', 'customer1pw')
    params = {
      state_id: state.id, # set the state id
    }

    put "/api/v1/tickets/#{ticket.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Cannot follow up on a closed ticket. Please create a new ticket.', result['error'])

    ticket = Ticket.create!(
      title: 'ticket with wrong ticket id',
      group_id: group.id,
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'closed'), # set the ticket to closed
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    # admin
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin@example.com', 'adminpw')

    put "/api/v1/tickets/#{ticket.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Cannot follow up on a closed ticket. Please create a new ticket.', result['error'])

    ticket = Ticket.create!(
      title: 'ticket with wrong ticket id',
      group_id: group.id,
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'closed'), # set the ticket to closed
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    # agent
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')

    put "/api/v1/tickets/#{ticket.id}", params: params.to_json, headers: @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Cannot follow up on a closed ticket. Please create a new ticket.', result['error'])
  end

  test '07.01 ticket merge' do
    group_no_permission = Group.create!(
      name: 'GroupWithNoPermission',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket1 = Ticket.create!(
      title: 'ticket merge1',
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket2 = Ticket.create!(
      title: 'ticket merge2',
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket3 = Ticket.create!(
      title: 'ticket merge2',
      group: group_no_permission,
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')

    get "/api/v1/ticket_merge/#{ticket2.id}/#{ticket1.id}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('failed', result['result'])
    assert_equal('No such master ticket number!', result['message'])

    get "/api/v1/ticket_merge/#{ticket3.id}/#{ticket1.number}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])
    assert_equal('Not authorized', result['error_human'])

    get "/api/v1/ticket_merge/#{ticket1.id}/#{ticket3.number}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])
    assert_equal('Not authorized', result['error_human'])

    get "/api/v1/ticket_merge/#{ticket1.id}/#{ticket2.number}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('success', result['result'])
    assert_equal(ticket2.id, result['master_ticket']['id'])
  end

  test '07.02 ticket merge - change permission' do
    group_change_permission = Group.create!(
      name: 'GroupWithChangePermission',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket1 = Ticket.create!(
      title: 'ticket merge1',
      group: group_change_permission,
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket2 = Ticket.create!(
      title: 'ticket merge2',
      group: group_change_permission,
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    @agent.group_names_access_map = { group_change_permission.name => %w[read change] }

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')

    get "/api/v1/ticket_merge/#{ticket1.id}/#{ticket2.number}", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('success', result['result'])
    assert_equal(ticket2.id, result['master_ticket']['id'])
  end

  test '08.01 ticket search sorted' do
    title = "ticket pagination #{rand(999_999_999)}"
    tickets = []

    ticket1 = Ticket.create!(
      title: "#{title} A",
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      type: Ticket::Article::Type.lookup(name: 'note'),
      sender: Ticket::Article::Sender.lookup(name: 'Customer'),
      from: 'sender',
      subject: 'subject',
      body: 'some body',
      ticket_id: ticket1.id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    travel 2.seconds

    ticket2 = Ticket.create!(
      title: "#{title} B",
      group: Group.lookup(name: 'Users'),
      customer_id: @customer_without_org.id,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '3 hoch'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    Ticket::Article.create!(
      type: Ticket::Article::Type.lookup(name: 'note'),
      sender: Ticket::Article::Sender.lookup(name: 'Customer'),
      from: 'sender',
      subject: 'subject',
      body: 'some body',
      ticket_id: ticket2.id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')
    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40", params: {}, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal([ticket2.id, ticket1.id], result['tickets'])

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')
    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40", params: { sort_by: 'created_at', order_by: 'asc' }, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal([ticket1.id, ticket2.id], result['tickets'])

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')
    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40", params: { sort_by: 'title', order_by: 'asc' }, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal([ticket1.id, ticket2.id], result['tickets'])

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')
    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40", params: { sort_by: 'title', order_by: 'desc' }, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal([ticket2.id, ticket1.id], result['tickets'])

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')
    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40", params: { sort_by: %w[created_at updated_at], order_by: %w[asc asc] }, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal([ticket1.id, ticket2.id], result['tickets'])

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')
    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40", params: { sort_by: %w[created_at updated_at], order_by: %w[desc asc]  }, headers: @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal([ticket2.id, ticket1.id], result['tickets'])
  end

end
