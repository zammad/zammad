# encoding: utf-8
require 'test_helper'

class EmailProcessStateOpenSet < ActiveSupport::TestCase

  setup do
    groups = Group.all
    roles = Role.where(name: 'Agent')
    @agent1 = User.create_or_update(
      login: 'agent-ticket-state-open-set@example.com',
      firstname: 'StateOpenSet',
      lastname: 'Agent1',
      email: 'agent-ticket-state-open-set@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Customer')
    @customer1 = User.create_or_update(
      login: 'customer-ticket-state-open-set@example.com',
      firstname: 'StateOpenSet',
      lastname: 'Customer',
      email: 'customer-ticket-state-open-set@example.com',
      password: 'customerpw',
      active: true,
      roles: roles,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  test 'new as agent' do
    email_raw_string = "From: agent-ticket-state-open-set@example.com
To: customer-ticket-state-open-set@example.com
Subject: test sender is agent

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)

    article = Ticket::Article.find(article_p.id)
    assert_equal('test sender is agent', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Agent', ticket.create_article_sender.name)
    assert_equal('Agent', article.sender.name)
    assert_equal('customer-ticket-state-open-set@example.com', ticket.customer.email)
    assert_equal('StateOpenSet', ticket.customer.firstname)
    assert_equal('Customer', ticket.customer.lastname)

    article = Ticket::Article.create!(
      ticket_id: ticket.id,
      type_id: Ticket::Article::Type.find_by(name: 'email').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
      body: 'test',
      internal: false,
      updated_by_id: @customer1.id,
      created_by_id: @customer1.id,
    )

    ticket.reload
    assert_equal('test sender is agent', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Agent', ticket.create_article_sender.name)
    assert_equal('Customer', article.sender.name)
    assert_equal('customer-ticket-state-open-set@example.com', ticket.customer.email)
    assert_equal('StateOpenSet', ticket.customer.firstname)
    assert_equal('Customer', ticket.customer.lastname)

    article = Ticket::Article.create!(
      ticket_id: ticket.id,
      type_id: Ticket::Article::Type.find_by(name: 'email').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Agent').id,
      body: 'test',
      internal: false,
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )

    ticket.reload
    assert_equal('test sender is agent', ticket.title)
    assert_equal('open', ticket.state.name)
    assert_equal('Agent', ticket.create_article_sender.name)
    assert_equal('Agent', article.sender.name)
    assert_equal('customer-ticket-state-open-set@example.com', ticket.customer.email)
    assert_equal('StateOpenSet', ticket.customer.firstname)
    assert_equal('Customer', ticket.customer.lastname)

  end

  test 'new as customer' do
    email_raw_string = "From: customer-ticket-state-open-set@example.com
To: agent-ticket-state-open-set@example.com
Subject: test sender is customer

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)

    article = Ticket::Article.find(article_p.id)
    assert_equal('test sender is customer', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Customer', ticket.create_article_sender.name)
    assert_equal('Customer', article.sender.name)
    assert_equal('customer-ticket-state-open-set@example.com', ticket.customer.email)
    assert_equal('StateOpenSet', ticket.customer.firstname)
    assert_equal('Customer', ticket.customer.lastname)

    article = Ticket::Article.create!(
      ticket_id: ticket.id,
      type_id: Ticket::Article::Type.find_by(name: 'email').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
      body: 'test',
      internal: false,
      updated_by_id: @customer1.id,
      created_by_id: @customer1.id,
    )

    ticket.reload
    assert_equal('test sender is customer', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Customer', ticket.create_article_sender.name)
    assert_equal('Customer', article.sender.name)
    assert_equal('customer-ticket-state-open-set@example.com', ticket.customer.email)
    assert_equal('StateOpenSet', ticket.customer.firstname)
    assert_equal('Customer', ticket.customer.lastname)

    article = Ticket::Article.create!(
      ticket_id: ticket.id,
      type_id: Ticket::Article::Type.find_by(name: 'email').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Agent').id,
      body: 'test',
      internal: false,
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )

    ticket.reload
    assert_equal('test sender is customer', ticket.title)
    assert_equal('open', ticket.state.name)
    assert_equal('Customer', ticket.create_article_sender.name)
    assert_equal('Agent', article.sender.name)
    assert_equal('customer-ticket-state-open-set@example.com', ticket.customer.email)
    assert_equal('StateOpenSet', ticket.customer.firstname)
    assert_equal('Customer', ticket.customer.lastname)
  end

end
