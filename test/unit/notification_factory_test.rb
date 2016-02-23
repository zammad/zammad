# encoding: utf-8
require 'test_helper'

class NotificationFactoryTest < ActiveSupport::TestCase

  Translation.load('de-de')

  test 'notifications send' do
    result = NotificationFactory.send(
      recipient: User.find(2),
      subject: 'sime subject',
      body: 'some body',
      content_type: '',
    )
    assert_match('some body', result.to_s)
    assert_match('text/plain', result.to_s)
    assert_no_match('text/html', result.to_s)

    result = NotificationFactory.send(
      recipient: User.find(2),
      subject: 'sime subject',
      body: 'some body',
      content_type: 'text/plain',
    )
    assert_match('some body', result.to_s)
    assert_match('text/plain', result.to_s)
    assert_no_match('text/html', result.to_s)

    result = NotificationFactory.send(
      recipient: User.find(2),
      subject: 'sime subject',
      body: 'some <span>body</span>',
      content_type: 'text/html',
    )
    assert_match('some body', result.to_s)
    assert_match('text/plain', result.to_s)
    assert_match('<span>body</span>', result.to_s)
    assert_match('text/html', result.to_s)
  end

  test 'notifications base' do
    ticket = Ticket.create(
      title: 'some title äöüß',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 2,
      created_by_id: 2,
    )
    article_plain = Ticket::Article.create(
      ticket_id: ticket.id,
      type_id: Ticket::Article::Type.where(name: 'phone' ).first.id,
      sender_id: Ticket::Article::Sender.where(name: 'Customer' ).first.id,
      from: 'Zammad Feedback <feedback@example.org>',
      body: 'some text',
      internal: false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    tests = [
      {
        locale: 'en',
        string: 'Hi #{recipient.firstname},',
        result: 'Hi Nicole,',
      },
      {
        locale: 'de-de',
        string: 'Hi #{recipient.firstname},',
        result: 'Hi Nicole,',
      },
      {
        locale: 'de-de',
        string: 'Hi #{recipient.firstname}, Group: #{ticket.group.name}',
        result: 'Hi Nicole, Group: Users',
      },
      {
        locale: 'de-de',
        string: '#{config.http_type} some text',
        result: 'http some text',
      },
      {
        locale: 'de-de',
        string: 'i18n(New) some text',
        result: 'Neu some text',
      },
      {
        locale: 'de-de',
        string: '\'i18n(#{ticket.state.name})\' ticket state',
        result: '\'neu\' ticket state',
      },
      {
        locale: 'de-de',
        string: 'a #{not_existing_object.test}',
        result: 'a #{not_existing_object / no such object}',
      },
      {
        locale: 'de-de',
        string: 'a #{ticket.level1}',
        result: 'a #{ticket.level1 / no such method}',
      },
      {
        locale: 'de-de',
        string: 'a #{ticket.level1.level2}',
        result: 'a #{ticket.level1 / no such method}',
      },
      {
        locale: 'de-de',
        string: 'a #{ticket.title.level2}',
        result: 'a #{ticket.title.level2 / no such method}',
      },
      {
        locale: 'de-de',
        string: 'by #{ticket.updated_by.fullname}',
        result: 'by Nicole Braun',
      },
      {
        locale: 'de-de',
        string: 'Subject #{article.from}, Group: #{ticket.group.name}',
        result: 'Subject Zammad Feedback <feedback@example.org>, Group: Users',
      },
      {
        locale: 'de-de',
        string: 'Body #{article.body}, Group: #{ticket.group.name}',
        result: 'Body some text, Group: Users',
      },
      {
        locale: 'de-de',
        string: '\#{puts `ls`}',
        result: '\#{puts `ls`} (not allowed)',
      },
      {
        locale: 'de-de',
        string: 'test i18n(new)',
        result: 'test neu',
      },
      {
        locale: 'de-de',
        string: 'test i18n()',
        result: 'test ',
      },
      {
        locale: 'de-de',
        string: 'test i18n(new) i18n(open)',
        result: 'test neu offen',
      },
    ]
    tests.each { |test|
      result = NotificationFactory.build(
        string: test[:string],
        objects: {
          ticket: ticket,
          article: article_plain,
          recipient: User.find(2),
        },
        locale: test[:locale]
      )
      assert_equal( test[:result], result, 'verify result' )
    }

    ticket.destroy
  end

  test 'notifications html' do
    ticket = Ticket.create(
      title: 'some title <b>äöüß</b> 2',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article_html = Ticket::Article.create(
      ticket_id: ticket.id,
      type_id: Ticket::Article::Type.where(name: 'phone' ).first.id,
      sender_id: Ticket::Article::Sender.where(name: 'Customer' ).first.id,
      from: 'Zammad Feedback <feedback@example.org>',
      body: 'some <b>text</b><br>next line',
      content_type: 'text/html',
      internal: false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    tests = [
      {
        locale: 'de-de',
        string: 'Subject #{ticket.title}',
        result: 'Subject some title <b>äöüß</b> 2',
      },
      {
        locale: 'de-de',
        string: 'Subject #{article.from}, Group: #{ticket.group.name}',
        result: 'Subject Zammad Feedback <feedback@example.org>, Group: Users',
      },
      {
        locale: 'de-de',
        string: 'Body #{article.body}, Group: #{ticket.group.name}',
        result: 'Body some text
next line, Group: Users',
      },
    ]
    tests.each { |test|
      result = NotificationFactory.build(
        string: test[:string],
        objects: {
          ticket: ticket,
          article: article_html,
          recipient: User.find(2),
        },
        locale: test[:locale]
      )
      assert_equal( test[:result], result, 'verify result' )
    }

    ticket.destroy
  end

  test 'notifications attack' do
    ticket = Ticket.create(
      title: 'some title <b>äöüß</b> 3',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article_html = Ticket::Article.create(
      ticket_id: ticket.id,
      type_id: Ticket::Article::Type.where(name: 'phone' ).first.id,
      sender_id: Ticket::Article::Sender.where(name: 'Customer' ).first.id,
      from: 'Zammad Feedback <feedback@example.org>',
      body: 'some <b>text</b><br>next line',
      content_type: 'text/html',
      internal: false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    tests = [
      {
        locale: 'de-de',
        string: '\#{puts `ls`}',
        result: '\#{puts `ls`} (not allowed)',
      },
      {
        locale: 'de-de',
        string: 'attack#1 #{article.destroy}',
        result: 'attack#1 #{article.destroy} (not allowed)',
      },
      {
        locale: 'de-de',
        string: 'attack#2 #{Article.where}',
        result: 'attack#2 #{Article.where} (not allowed)',
      },
      {
        locale: 'de-de',
        string: 'attack#1 #{article.
        destroy}',
        result: 'attack#1 #{article.
        destroy} (not allowed)',
      },
      {
        locale: 'de-de',
        string: 'attack#1 #{article.find}',
        result: 'attack#1 #{article.find} (not allowed)',
      },
      {
        locale: 'de-de',
        string: 'attack#1 #{article.update(:name => "test")}',
        result: 'attack#1 #{article.update(:name => "test")} (not allowed)',
      },
      {
        locale: 'de-de',
        string: 'attack#1 #{article.all}',
        result: 'attack#1 #{article.all} (not allowed)',
      },
      {
        locale: 'de-de',
        string: 'attack#1 #{article.delete}',
        result: 'attack#1 #{article.delete} (not allowed)',
      },
    ]
    tests.each { |test|
      result = NotificationFactory.build(
        string: test[:string],
        objects: {
          ticket: ticket,
          article: article_html,
          recipient: User.find(2),
        },
        locale: test[:locale]
      )
      assert_equal( test[:result], result, 'verify result' )
    }

    ticket.destroy
  end

  test 'notifications template' do
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

    result = NotificationFactory.template(
      template: 'password_reset',
      locale: 'de-de',
      objects:  {
        user: agent1,
      },
    )
    assert_match('Zurücksetzen Deines', result[:subject])
    assert_match('wir haben eine Anfrage zum Zurücksetzen', result[:body])
    assert_match('Dein', result[:body])
    assert_match('Dein', result[:body])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_no_match('Your', result[:body])

    result = NotificationFactory.template(
      template: 'password_reset',
      locale: 'de',
      objects:  {
        user: agent1,
      },
    )
    assert_match('Zurücksetzen Deines', result[:subject])
    assert_match('wir haben eine Anfrage zum Zurücksetzen', result[:body])
    assert_match('Dein', result[:body])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_no_match('Your', result[:body])

    result = NotificationFactory.template(
      template: 'password_reset',
      locale: 'es-us',
      objects:  {
        user: agent1,
      },
    )
    assert_match('Reset your', result[:subject])
    assert_match('We received a request to reset the password', result[:body])
    assert_match('Your', result[:body])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_no_match('Dein', result[:body])

    ticket = Ticket.create(
      group_id: Group.lookup(name: 'Users').id,
      customer_id: User.lookup(email: 'nicole.braun@zammad.org').id,
      owner_id: User.lookup(login: '-' ).id,
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
    result = NotificationFactory.template(
      template: 'ticket_create',
      locale: 'es-us',
      objects:  {
        ticket: ticket,
        article: article,
        recipient: agent1,
        changes: changes,
      },
    )
    assert_match('New Ticket', result[:subject])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_match('has been created by', result[:body])
    assert_match('&lt;b&gt;test123&lt;/b&gt;', result[:body])
    assert_match('Manage your notifications settings', result[:body])
    assert_no_match('Dein', result[:body])

    result = NotificationFactory.template(
      template: 'ticket_create',
      locale: 'de-de',
      objects:  {
        ticket: ticket,
        article: article,
        recipient: agent1,
        changes: changes,
      },
    )
    assert_match('Neues Ticket', result[:subject])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_match('es wurde ein neues Ticket', result[:body])
    assert_match('&lt;b&gt;test123&lt;/b&gt;', result[:body])
    assert_match('Benachrichtigungseinstellungen Verwalten', result[:body])
    assert_no_match('Your', result[:body])

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
    result = NotificationFactory.template(
      template: 'ticket_update',
      locale: 'es-us',
      objects:  {
        ticket: ticket,
        article: article,
        recipient: agent1,
        changes: changes,
      },
    )
    assert_match('Updated Ticket', result[:subject])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_match('has been updated by', result[:body])
    assert_match('<b>test123</b>', result[:body])
    assert_match('Manage your notifications settings', result[:body])
    assert_no_match('Dein', result[:body])

    result = NotificationFactory.template(
      template: 'ticket_update',
      locale: 'de-de',
      objects:  {
        ticket: ticket,
        article: article,
        recipient: agent1,
        changes: changes,
      },
    )
    assert_match('Ticket aktualisiert', result[:subject])
    assert_match('Notification&lt;b&gt;xxx&lt;/b&gt;', result[:body])
    assert_match('wurde von', result[:body])
    assert_match('<b>test123</b>', result[:body])
    assert_match('Benachrichtigungseinstellungen Verwalten', result[:body])
    assert_no_match('Your', result[:body])

  end

end
