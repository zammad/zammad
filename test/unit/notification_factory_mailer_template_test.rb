# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class NotificationFactoryMailerTemplateTest < ActiveSupport::TestCase

  test 'notifications template' do

    Translation.load('de-de')

    groups = Group.where(name: 'Users')
    roles  = Role.where(name: 'Agent')
    agent1 = User.create!(
      login:         'notification-template-agent1@example.com',
      firstname:     'Notification<b>xxx</b>',
      lastname:      'Agent1<b>yyy</b>',
      email:         'notification-template-agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      preferences:   {
        locale: 'de-de',
      },
      updated_by_id: 1,
      created_by_id: 1,
    )

    agent_current_user = User.create!(
      login:         'notification-template-current_user@example.com',
      firstname:     'Notification Current',
      lastname:      'User',
      email:         'notification-template-current_user@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      preferences:   {
        locale: 'de-de',
      },
      updated_by_id: 1,
      created_by_id: 1,
    )

    result = NotificationFactory::Mailer.template(
      template: 'password_reset',
      locale:   'de-de',
      objects:  {
        user: agent1,
      },
    )
    assert_match('Zurücksetzen Ihres', result[:subject])
    assert_match('wir haben eine Anfrage zum Zurücksetzen', result[:body])
    assert_match('Ihr', result[:body])
    assert_match('Ihr', result[:body])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_no_match('Your', result[:body])

    result = NotificationFactory::Mailer.template(
      template: 'password_reset',
      locale:   'de',
      objects:  {
        user: agent1,
      },
    )
    assert_match('Zurücksetzen Ihres', result[:subject])
    assert_match('wir haben eine Anfrage zum Zurücksetzen', result[:body])
    assert_match('Ihr', result[:body])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_no_match('Your', result[:body])

    result = NotificationFactory::Mailer.template(
      template: 'password_reset',
      locale:   'xx-us',
      objects:  {
        user: agent1,
      },
    )
    assert_match('Reset your', result[:subject])
    assert_match('We received a request to reset the password', result[:body])
    assert_match('Your', result[:body])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_no_match('Ihr', result[:body])

    ticket = Ticket.create(
      group_id:      Group.lookup(name: 'Users').id,
      customer_id:   User.lookup(email: 'nicole.braun@zammad.org').id,
      owner_id:      User.lookup(login: '-').id,
      title:         'Welcome to Zammad!',
      state_id:      Ticket::State.lookup(name: 'new').id,
      priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: 1,
      created_by_id: 1,
    )
    article = Ticket::Article.create(
      ticket_id:     ticket.id,
      type_id:       Ticket::Article::Type.lookup(name: 'phone').id,
      sender_id:     Ticket::Article::Sender.lookup(name: 'Customer').id,
      from:          'Zammad Feedback <feedback@zammad.org>',
      content_type:  'text/plain',
      body:          'Welcome!
<b>test123</b>',
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )

    changes = {}
    result = NotificationFactory::Mailer.template(
      template: 'ticket_create',
      locale:   'xx-us',
      objects:  {
        ticket:       ticket,
        article:      article,
        recipient:    agent1,
        current_user: agent_current_user,
        changes:      changes,
      },
    )
    assert_match('New Ticket', result[:subject])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_match('has been created by', result[:body])
    assert_match('&lt;b&gt;test123&lt;/b&gt;', result[:body])
    assert_match('Manage your notifications settings', result[:body])
    assert_no_match('Dein', result[:body])
    assert_no_match('longname', result[:body])
    assert_match('Current User', result[:body])

    result = NotificationFactory::Mailer.template(
      template: 'ticket_create',
      locale:   'de-de',
      objects:  {
        ticket:       ticket,
        article:      article,
        recipient:    agent1,
        current_user: agent_current_user,
        changes:      changes,
      },
    )
    assert_match('Neues Ticket', result[:subject])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_match('es wurde ein neues Ticket', result[:body])
    assert_match('&lt;b&gt;test123&lt;/b&gt;', result[:body])
    assert_match('Benachrichtigungseinstellungen Verwalten', result[:body])
    assert_no_match('Your', result[:body])
    assert_no_match('longname', result[:body])
    assert_match('Current User', result[:body])

    article = Ticket::Article.create(
      ticket_id:     ticket.id,
      type_id:       Ticket::Article::Type.lookup(name: 'phone').id,
      sender_id:     Ticket::Article::Sender.lookup(name: 'Customer').id,
      from:          'Zammad Feedback <feedback@zammad.org>',
      content_type:  'text/html',
      body:          'Welcome!
<b>test123</b>',
      internal:      false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    changes = {
      state: %w[aaa bbb],
      group: %w[xxx yyy],
    }
    result = NotificationFactory::Mailer.template(
      template: 'ticket_update',
      locale:   'xx-us',
      objects:  {
        ticket:       ticket,
        article:      article,
        recipient:    agent1,
        current_user: agent_current_user,
        changes:      changes,
      },
    )
    assert_match('Updated Ticket', result[:subject])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_match('has been updated by', result[:body])
    assert_match('<b>test123</b>', result[:body])
    assert_match('Manage your notifications settings', result[:body])
    assert_no_match('Dein', result[:body])
    assert_no_match('longname', result[:body])
    assert_match('Current User', result[:body])

    result = NotificationFactory::Mailer.template(
      template: 'ticket_update',
      locale:   'de-de',
      objects:  {
        ticket:       ticket,
        article:      article,
        recipient:    agent1,
        current_user: agent_current_user,
        changes:      changes,
      },
    )
    assert_match('Ticket aktualisiert', result[:subject])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_match('wurde von', result[:body])
    assert_match('<b>test123</b>', result[:body])
    assert_match('Benachrichtigungseinstellungen Verwalten', result[:body])
    assert_no_match('Your', result[:body])
    assert_no_match('longname', result[:body])
    assert_match('Current User', result[:body])

    Setting.set('locale_default', 'de-de')
    result = NotificationFactory::Mailer.template(
      template: 'ticket_update',
      objects:  {
        ticket:       ticket,
        article:      article,
        recipient:    agent1,
        current_user: agent_current_user,
        changes:      changes,
      },
    )
    assert_match('Ticket aktualisiert', result[:subject])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_match('wurde von', result[:body])
    assert_match('<b>test123</b>', result[:body])
    assert_match('Benachrichtigungseinstellungen Verwalten', result[:body])
    assert_no_match('Your', result[:body])
    assert_no_match('longname', result[:body])
    assert_match('Current User', result[:body])

    Setting.set('locale_default', 'not_existing')
    result = NotificationFactory::Mailer.template(
      template: 'ticket_update',
      objects:  {
        ticket:       ticket,
        article:      article,
        recipient:    agent1,
        current_user: agent_current_user,
        changes:      changes,
      },
    )
    assert_match('Updated Ticket', result[:subject])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_match('has been updated by', result[:body])
    assert_match('<b>test123</b>', result[:body])
    assert_match('Manage your notifications settings', result[:body])
    assert_no_match('Dein', result[:body])
    assert_no_match('longname', result[:body])
    assert_match('Current User', result[:body])

    Setting.set('locale_default', 'pt-br')
    result = NotificationFactory::Mailer.template(
      template: 'ticket_update',
      objects:  {
        ticket:       ticket,
        article:      article,
        recipient:    agent1,
        current_user: agent_current_user,
        changes:      changes,
      },
    )
    assert_match('Chamado atualizado', result[:subject])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_match('foi atualizado por', result[:body])
    assert_match('<b>test123</b>', result[:body])
    assert_match('Manage your notifications settings', result[:body])
    assert_no_match('Dein', result[:body])
    assert_no_match('longname', result[:body])
    assert_match('Current User', result[:body])

  end

end
