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
    assert_response(500)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal('Attribute \'group_id\' required!', result['error_human'])
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
    assert_response(500)
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
    assert_response(500)
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
    ticket = Ticket.create!(
      title: 'ticket with corret ticket id',
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
    assert_equal(@agent.id, result['updated_by_id'])
    assert_equal(1, result['created_by_id'])

    params = {
      ticket_id: ticket.id,
      subject: 'some subject',
      body: 'some body',
    }
    post '/api/v1/ticket_articles', params.to_json, @headers.merge('Authorization' => credentials)
    assert_response(201)
    result = JSON.parse(@response.body)
    assert_equal(Hash, result.class)
    assert_equal(ticket.id, result['ticket_id'])
    assert_equal('Tickets Agent', result['from'])
    assert_equal('some subject', result['subject'])
    assert_equal('some body', result['body'])
    assert_equal('text/plain', result['content_type'])
    assert_equal(false, result['internal'])
    assert_equal(@agent.id, result['created_by_id'])
    assert_equal(Ticket::Article::Sender.lookup(name: 'Agent').id, result['sender_id'])
    assert_equal(Ticket::Article::Type.lookup(name: 'note').id, result['type_id'])

    delete "/api/v1/ticket_articles/#{result['id']}", {}.to_json, @headers.merge('Authorization' => credentials)
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
    assert_equal('Tickets Agent via Zammad <zammad@localhost>', result['from'])
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
    assert_equal('Tickets Agent via Zammad <zammad@localhost>', result['from'])
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
    assert_equal('Tickets Admin via Zammad <zammad@localhost>', result['from'])
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
    ticket = Ticket.create!(
      title: 'ticket with corret ticket id',
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
    assert_equal('Tickets Customer1', result['from'])
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
