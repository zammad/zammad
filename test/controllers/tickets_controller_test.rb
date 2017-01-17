# encoding: utf-8
require 'test_helper'

class TicketsControllerTest < ActionDispatch::IntegrationTest
  setup do

    # set accept header
    @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    # create agent
    roles  = Role.where(name: %w(Admin Agent))
    groups = Group.all

    UserInfo.current_user_id = 1
    @admin = User.create_or_update(
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
    @agent = User.create_or_update(
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
    @customer_without_org = User.create_or_update(
      login: 'tickets-customer1@example.com',
      firstname: 'Tickets',
      lastname: 'Customer1',
      email: 'tickets-customer1@example.com',
      password: 'customer1pw',
      active: true,
      roles: roles,
    )

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
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
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
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
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
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
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
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #3', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
  end

  test '01.04 ticket create with agent - wrong owner_id - 0' do
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
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Invalid value for param \'owner_id\': 0', result['error'])
  end

  test '01.05 ticket create with agent - wrong owner_id - ""' do
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
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
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

  test '01.06 ticket create with agent - wrong owner_id - 99999' do
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
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(422)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Invalid value for param \'owner_id\': 99999', result['error'])
  end

  test '01.07 ticket create with agent - wrong owner_id - nil' do
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
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #7', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
  end

  test '01.08 ticket create with agent - minimal article with guess customer' do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-agent@example.com', 'agentpw')
    params = {
      title: 'a new ticket #8',
      group: 'Users',
      priority: '2 normal',
      state: 'new',
      customer_id: 'guess:some_new_customer@example.com',
      article: {
        body: 'some test 123',
      },
    }
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #8', result['title'])
    assert_equal(User.lookup(email: 'some_new_customer@example.com').id, result['customer_id'])
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(@agent.id, result['created_by_id'])
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
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
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
    group = Group.create_or_update(
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
    get "/api/v1/tickets/#{ticket.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])

    params = {
      title: 'ticket with wrong ticket id - 2',
    }
    put "/api/v1/tickets/#{ticket.id}", params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])

    delete "/api/v1/tickets/#{ticket.id}", {}.to_json, @headers.merge('Authorization' => credentials)
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
    get "/api/v1/tickets/#{ticket.id}", {}, @headers.merge('Authorization' => credentials)
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
    put "/api/v1/tickets/#{ticket.id}", params.to_json, @headers.merge('Authorization' => credentials)
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
    post '/api/v1/ticket_articles', params.to_json, @headers.merge('Authorization' => credentials)
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
    get "/api/v1/tickets/search?query=#{CGI.escape(title)}", {}, @headers.merge('Authorization' => credentials)
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
    post '/api/v1/tickets/search', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['tickets'][0])
    assert_equal(1, result['tickets_count'])

    delete "/api/v1/ticket_articles/#{article_result['id']}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)

    params = {
      from: 'something which should not be changed on server side',
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
      type: 'email',
      internal: true,
    }
    post '/api/v1/ticket_articles', params.to_json, @headers.merge('Authorization' => credentials)
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
    put "/api/v1/ticket_articles/#{result['id']}", params.to_json, @headers.merge('Authorization' => credentials)
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

    delete "/api/v1/ticket_articles/#{result['id']}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (admin permission required)!', result['error'])

    delete "/api/v1/tickets/#{ticket.id}", {}.to_json, @headers.merge('Authorization' => credentials)
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
    get "/api/v1/tickets/#{ticket.id}", {}, @headers.merge('Authorization' => credentials)
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
    put "/api/v1/tickets/#{ticket.id}", params.to_json, @headers.merge('Authorization' => credentials)
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
    post '/api/v1/ticket_articles', params.to_json, @headers.merge('Authorization' => credentials)
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
    put "/api/v1/ticket_articles/#{result['id']}", params.to_json, @headers.merge('Authorization' => credentials)
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

    delete "/api/v1/ticket_articles/#{result['id']}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)

    params = {
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
      type: 'email',
    }
    post '/api/v1/ticket_articles', params.to_json, @headers.merge('Authorization' => credentials)
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

    delete "/api/v1/ticket_articles/#{result['id']}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)

    delete "/api/v1/tickets/#{ticket.id}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
  end

  test '02.05 ticket pagination' do
    title = "ticket pagination #{rand(999_999_999)}"
    tickets = []
    (1..20).each { |count|
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
      sleep 1
    }

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('tickets-admin', 'adminpw')
    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(tickets[19].id, result['tickets'][0])
    assert_equal(tickets[0].id, result['tickets'][19])
    assert_equal(20, result['tickets_count'])

    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=10", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(tickets[19].id, result['tickets'][0])
    assert_equal(tickets[10].id, result['tickets'][9])
    assert_equal(10, result['tickets_count'])

    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40&page=1&per_page=5", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(tickets[19].id, result['tickets'][0])
    assert_equal(tickets[15].id, result['tickets'][4])
    assert_equal(5, result['tickets_count'])

    get "/api/v1/tickets/search?query=#{CGI.escape(title)}&limit=40&page=2&per_page=5", {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(tickets[14].id, result['tickets'][0])
    assert_equal(tickets[10].id, result['tickets'][4])
    assert_equal(5, result['tickets_count'])

    get '/api/v1/tickets?limit=40&page=1&per_page=5', {}, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Array, result.class)
    tickets = Ticket.order(:id).limit(5)
    assert_equal(tickets[0].id, result[0]['id'])
    assert_equal(tickets[4].id, result[4]['id'])
    assert_equal(5, result.count)

    get '/api/v1/tickets?limit=40&page=2&per_page=5', {}, @headers.merge('Authorization' => credentials)
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
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
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
    post '/api/v1/tickets', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(Ticket::State.lookup(name: 'new').id, result['state_id'])
    assert_equal('a new ticket #c2', result['title'])
    assert_equal(@customer_without_org.id, result['customer_id'])
    assert_equal(@customer_without_org.id, result['updated_by_id'])
    assert_equal(@customer_without_org.id, result['created_by_id'])
  end

  test '03.03 ticket with wrong ticket id' do
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
    get "/api/v1/tickets/#{ticket.id}", {}, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])

    params = {
      title: 'ticket with wrong ticket id - 2',
    }
    put "/api/v1/tickets/#{ticket.id}", params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])

    delete "/api/v1/tickets/#{ticket.id}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized', result['error'])
  end

  test '03.04 ticket with correct ticket id' do
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
    get "/api/v1/tickets/#{ticket.id}", {}, @headers.merge('Authorization' => credentials)
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
    put "/api/v1/tickets/#{ticket.id}", params.to_json, @headers.merge('Authorization' => credentials)
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
    post '/api/v1/ticket_articles', params.to_json, @headers.merge('Authorization' => credentials)
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
    get "/api/v1/tickets/search?query=#{CGI.escape(title)}", {}, @headers.merge('Authorization' => credentials)
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
    post '/api/v1/tickets/search', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(200)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['tickets'][0])
    assert_equal(1, result['tickets_count'])

    delete "/api/v1/ticket_articles/#{article_result['id']}", {}.to_json, @headers.merge('Authorization' => credentials)
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
    post '/api/v1/ticket_articles', params.to_json, @headers.merge('Authorization' => credentials)
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

    delete "/api/v1/ticket_articles/#{result['id']}", {}.to_json, @headers.merge('Authorization' => credentials)
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

    post '/api/v1/ticket_articles', params.to_json, @headers.merge('Authorization' => credentials)
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
    put "/api/v1/ticket_articles/#{result['id']}", params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (ticket.agent or admin permission required)!', result['error'])

    delete "/api/v1/tickets/#{ticket.id}", {}.to_json, @headers.merge('Authorization' => credentials)
    assert_response(401)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Not authorized (admin permission required)!', result['error'])
  end

end
