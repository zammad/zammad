require 'test_helper'

class TicketOwnerResetOnFollowUpTest < ActiveSupport::TestCase

  setup do
    UserInfo.current_user_id = 1
    Group.create_or_update(
      name: 'Disabled Group',
      follow_up_possible: 'yes',
      follow_up_assignment: true,
      active: false,
    )
    groups = Group.where(name: 'Users')
    roles = Role.where(name: 'Agent')
    @agent1 = User.create_or_update(
      login: 'ticket-customer-organization-update-agent1@example.com',
      firstname: 'FollowUpCheck',
      lastname: 'Agent1',
      email: 'ticket-customer-organization-update-agent1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )
    roles = Role.where(name: 'Customer')
    @organization1 = Organization.create_if_not_exists(
      name: 'Customer Organization Update',
    )
    @customer1 = User.create_or_update(
      login: 'ticket-customer-organization-update-customer1@example.com',
      firstname: 'FollowUpCheck',
      lastname: 'Customer1',
      email: 'ticket-customer-organization-update-customer1@example.com',
      password: 'customerpw',
      active: true,
      organization_id: @organization1.id,
      roles: roles,
    )
    UserInfo.current_user_id = nil
  end

  test 'create ticket, update owner to user with disabled group' do

    ticket = Ticket.create!(
      title: "some title1\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer_id: @customer1.id,
      owner_id: @agent1.id,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket, 'ticket created')
    assert_equal(@customer1.id, ticket.customer.id)
    assert_equal(@organization1.id, ticket.organization.id)

    @agent1.groups = Group.where(name: 'Disabled Group')
    @agent1.save!

    ticket.owner = @agent1
    ticket.save!

    ticket.reload
    assert_equal('-', ticket.owner.login) # reassigned to default agent
  end

  test 'create ticket, update owner to user which is inactive' do

    ticket = Ticket.create!(
      title: "some title1\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer_id: @customer1.id,
      owner_id: @agent1.id,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket, 'ticket created')
    assert_equal(@customer1.id, ticket.customer.id)
    assert_equal(@organization1.id, ticket.organization.id)

    @agent1.active = false
    @agent1.save!

    ticket.owner = @agent1
    ticket.save!

    ticket.reload
    assert_equal('-', ticket.owner.login) # reassigned to default agent
  end

  test 'create ticket, update owner to user which active and is in active group' do

    ticket = Ticket.create!(
      title: "some title1\n äöüß",
      group: Group.lookup(name: 'Users'),
      customer_id: @customer1.id,
      owner_id: @agent1.id,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket, 'ticket created')
    assert_equal(@customer1.id, ticket.customer.id)
    assert_equal(@organization1.id, ticket.organization.id)

    ticket.owner = @agent1
    ticket.save!

    ticket.reload
    assert_equal(ticket.owner.login, 'ticket-customer-organization-update-agent1@example.com') # should not be reassigned
  end

  test 'check if ticket is unassigned on follow up via model if owner in a group is inactive' do
    ticket = Ticket.create!(
      title: 'follow up check for invalid owner',
      group: Group.lookup(name: 'Users'),
      customer: @customer1,
      owner: @agent1,
      state: Ticket::State.lookup(name: 'closed'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article = Ticket::Article.create!(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'follow up check',
      body: 'some message article',
      internal: false,
      sender: Ticket::Article::Sender.lookup(name: 'Agent'),
      type: Ticket::Article::Type.lookup(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    @agent1.groups = Group.where(name: 'Disabled Group')
    @agent1.save!

    email_raw = "From: me@example.com
To: customer@example.com
Subject: #{ticket.subject_build('some new subject')}

Some Text"

    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw)
    assert_equal(ticket.id, ticket_p.id)

    assert_equal('open', ticket_p.state.name)
    assert_equal('-', ticket_p.owner.login)

  end

  test 'check if ticket is unassigned on follow up via email if current owner is inactive' do

    ticket = Ticket.create!(
      title: 'follow up check for invalid owner',
      group: Group.lookup(name: 'Users'),
      customer: @customer1,
      owner: @agent1,
      state: Ticket::State.lookup(name: 'closed'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article = Ticket::Article.create!(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'follow up check',
      body: 'some message article',
      internal: false,
      sender: Ticket::Article::Sender.lookup(name: 'Agent'),
      type: Ticket::Article::Type.lookup(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    @agent1.active = false
    @agent1.save!

    email_raw = "From: me@example.com
To: customer@example.com
Subject: #{ticket.subject_build('some new subject')}

Some Text"

    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw)
    assert_equal(ticket.id, ticket_p.id)

    assert_equal('open', ticket_p.state.name)
    assert_equal('-', ticket_p.owner.login)
  end

  test 'check if ticket is unassigned on follow up via email if current owner is customer now' do

    ticket = Ticket.create!(
      title: 'follow up check for invalid owner is customer now',
      group: Group.lookup(name: 'Users'),
      customer: @customer1,
      owner: @agent1,
      state: Ticket::State.lookup(name: 'closed'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article = Ticket::Article.create!(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'follow up check',
      body: 'some message article',
      internal: false,
      sender: Ticket::Article::Sender.lookup(name: 'Agent'),
      type: Ticket::Article::Type.lookup(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    @agent1.roles = Role.where(name: 'Customer')
    @agent1.save!

    email_raw = "From: me@example.com
To: customer@example.com
Subject: #{ticket.subject_build('some new subject')}

Some Text"

    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw)
    assert_equal(ticket.id, ticket_p.id)

    assert_equal('open', ticket_p.state.name)
    assert_equal('-', ticket_p.owner.login)
  end

end
