
require 'test_helper'

class EmailProcessCustomerSelectionBasedOnSenderRecipient < ActiveSupport::TestCase

  setup do
    groups = Group.all
    roles = Role.where(name: 'Agent')
    @agent1 = User.create_or_update(
      login: 'user-customer-selection-agent1@example.com',
      firstname: 'UserOutOfOffice',
      lastname: 'Agent1',
      email: 'user-customer-selection-agent1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Customer')
    @customer1 = User.create_or_update(
      login: 'user-customer-selection-customer1@example.com',
      firstname: 'UserOutOfOffice',
      lastname: 'customer1',
      email: 'user-customer-selection-customer1@example.com',
      password: 'customerpw',
      active: true,
      roles: roles,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  test 'customer need to be customer' do

    email_raw_string = "From: #{@agent1.email}
To: #{@customer1.email}
Subject: test

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)
    article = Ticket::Article.find(article_p.id)
    assert_equal('test', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Agent', ticket.create_article_sender.name)
    assert_equal('Agent', article.sender.name)
    assert_equal(@customer1.email, ticket.customer.email)
    assert_equal(@customer1.firstname, ticket.customer.firstname)
    assert_equal(@customer1.lastname, ticket.customer.lastname)

  end

  test 'agent need to be customer' do

    Setting.set('postmaster_sender_is_agent_search_for_customer', false)

    email_raw_string = "From: #{@agent1.email}
To: #{@customer1.email}
Subject: test

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket_p.id)
    article = Ticket::Article.find(article_p.id)
    assert_equal('test', ticket.title)
    assert_equal('new', ticket.state.name)
    assert_equal('Agent', ticket.create_article_sender.name)
    assert_equal('Agent', article.sender.name)
    assert_equal(@agent1.email, ticket.customer.email)
    assert_equal(@agent1.firstname, ticket.customer.firstname)
    assert_equal(@agent1.lastname, ticket.customer.lastname)

  end

end
