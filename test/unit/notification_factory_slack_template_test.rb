# encoding: utf-8
require 'test_helper'

class NotificationFactorySlackTemplateTest < ActiveSupport::TestCase

  test 'notifications template' do

    Translation.load('de-de')

    groups = Group.where(name: 'Users')
    roles  = Role.where(name: 'Agent')
    agent1 = User.create_or_update(
      login: 'notification-template-agent1@example.com',
      firstname: 'Notification<b>xxx</b>',
      lastname: 'Agent1<b>yyy</b>',
      email: 'notification-template-agent1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      preferences: {
        locale: 'de-de',
      },
      updated_by_id: 1,
      created_by_id: 1,
    )

    agent_current_user = User.create_or_update(
      login: 'notification-template-current_user@example.com',
      firstname: 'Notification Current',
      lastname: 'User<b>xxx</b>',
      email: 'notification-template-current_user@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      preferences: {
        locale: 'de-de',
      },
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket = Ticket.create(
      group_id: Group.lookup(name: 'Users').id,
      customer_id: User.lookup(email: 'nicole.braun@zammad.org').id,
      owner_id: User.lookup(login: '-').id,
      title: 'Welcome to Zammad!',
      state_id: Ticket::State.lookup(name: 'new').id,
      priority_id: Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: 1,
      created_by_id: 1,
    )
    article = Ticket::Article.create(
      ticket_id: ticket.id,
      type_id: Ticket::Article::Type.lookup(name: 'phone').id,
      sender_id: Ticket::Article::Sender.lookup(name: 'Customer').id,
      from: 'Zammad Feedback <feedback@zammad.org>',
      content_type: 'text/plain',
      body: 'Welcome!
<b>test123</b>',
      internal: false,
      updated_by_id: 1,
      created_by_id: 1,
    )

    changes = {}
    result = NotificationFactory::Slack.template(
      template: 'ticket_create',
      locale: 'es-us',
      objects:  {
        ticket: ticket,
        article: article,
        recipient: agent1,
        current_user: agent_current_user,
        changes: changes,
      },
    )

    assert_match('# Welcome to Zammad!', result[:subject])
    assert_match('User<b>xxx</b>', result[:body])
    assert_match('Created by', result[:body])
    assert_match('<b>test123</b>', result[:body])
    assert_no_match('Dein', result[:body])
    assert_no_match('longname', result[:body])
    assert_match('Current User', result[:body])

    article = Ticket::Article.create(
      ticket_id: ticket.id,
      type_id: Ticket::Article::Type.lookup(name: 'phone').id,
      sender_id: Ticket::Article::Sender.lookup(name: 'Customer').id,
      from: 'Zammad Feedback <feedback@zammad.org>',
      content_type: 'text/html',
      body: 'Welcome!
<b>test123</b>',
      internal: false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    changes = {
      state: %w(aaa bbb),
      group: %w(xxx yyy),
    }
    result = NotificationFactory::Slack.template(
      template: 'ticket_update',
      locale: 'es-us',
      objects:  {
        ticket: ticket,
        article: article,
        recipient: agent1,
        current_user: agent_current_user,
        changes: changes,
      },
    )
    assert_match('# Welcome to Zammad!', result[:subject])
    assert_match('User<b>xxx</b>', result[:body])
    assert_match('state: aaa -> bbb', result[:body])
    assert_match('group: xxx -> yyy', result[:body])
    assert_no_match('Dein', result[:body])
    assert_no_match('longname', result[:body])
    assert_match('Current User', result[:body])

  end

end
