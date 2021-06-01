# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class NotificationFactoryMailerTest < ActiveSupport::TestCase

  test 'notifications send' do
    result = NotificationFactory::Mailer.send(
      recipient:    User.find(2),
      subject:      'some subject',
      body:         'some body',
      content_type: '',
    )
    assert_match('some body', result.to_s)
    assert_match('text/plain', result.to_s)
    assert_no_match('text/html', result.to_s)

    result = NotificationFactory::Mailer.send(
      recipient:    User.find(2),
      subject:      'some subject',
      body:         'some body',
      content_type: 'text/plain',
    )
    assert_match('some body', result.to_s)
    assert_match('text/plain', result.to_s)
    assert_no_match('text/html', result.to_s)

    result = NotificationFactory::Mailer.send(
      recipient:    User.find(2),
      subject:      'some subject',
      body:         'some <span>body</span>',
      content_type: 'text/html',
    )
    assert_match('some body', result.to_s)
    assert_match('text/plain', result.to_s)
    assert_match('<span>body</span>', result.to_s)
    assert_match('text/html', result.to_s)

    attachments = []
    attachments.push Store.add(
      object:        'TestMailer',
      o_id:          1,
      data:          'content_file1_normally_should_be_an_image',
      filename:      'some_file1.jpg',
      preferences:   {
        'Content-Type'        => 'image/jpeg',
        'Mime-Type'           => 'image/jpeg',
        'Content-ID'          => '15.274327094.140938@zammad.example.com',
        'Content-Disposition' => 'inline'
      },
      created_by_id: 1,
    )
    attachments.push Store.add(
      object:        'TestMailer',
      o_id:          1,
      data:          'content_file2',
      filename:      'some_file2.txt',
      preferences:   {
        'Content-Type' => 'text/stream',
        'Mime-Type'    => 'text/stream',
      },
      created_by_id: 1,
    )

    result = NotificationFactory::Mailer.send(
      recipient:    User.find(2),
      subject:      'some subject',
      body:         'some <span>body</span><img style="width: 85.5px; height: 49.5px" src="cid:15.274327094.140938@zammad.example.com">asdasd<br>',
      content_type: 'text/html',
      attachments:  attachments,
    )
    assert_match('some body', result.to_s)
    assert_match('text/plain', result.to_s)
    assert_match('<span>body</span>', result.to_s)
    assert_match('text/html', result.to_s)
    assert_match('Content-Type: image/jpeg', result.to_s)
    assert_match('Content-Disposition: inline', result.to_s)
    assert_match('Content-ID: <15.274327094.140938@zammad.example.com>', result.to_s)
    assert_match('text/stream', result.to_s)
    assert_match('some_file2.txt', result.to_s)

  end

  test 'notifications settings' do

    groups = Group.all
    roles  = Role.where(name: 'Agent')
    agent1 = User.create!(
      login:         'notification-settings-agent1@example.com',
      firstname:     'Notification<b>xxx</b>',
      lastname:      'Agent1',
      email:         'notification-settings-agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

    agent2 = User.create!(
      login:         'notification-settings-agent2@example.com',
      firstname:     'Notification<b>xxx</b>',
      lastname:      'Agent2',
      email:         'notification-settings-agent2@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_by_id: 1,
      created_by_id: 1,
    )

    group_notification_setting = Group.create!(
      name:          'NotificationSetting',
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket1 = Ticket.create(
      group_id:      Group.lookup(name: 'Users').id,
      customer_id:   User.lookup(email: 'nicole.braun@zammad.org').id,
      owner_id:      User.lookup(login: '-').id,
      title:         'Notification Settings Test 1!',
      state_id:      Ticket::State.lookup(name: 'new').id,
      priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket2 = Ticket.create(
      group_id:      Group.lookup(name: 'Users').id,
      customer_id:   User.lookup(email: 'nicole.braun@zammad.org').id,
      owner_id:      agent1.id,
      title:         'Notification Settings Test 2!',
      state_id:      Ticket::State.lookup(name: 'new').id,
      priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket3 = Ticket.create(
      group_id:      group_notification_setting.id,
      customer_id:   User.lookup(email: 'nicole.braun@zammad.org').id,
      owner_id:      User.lookup(login: '-').id,
      title:         'Notification Settings Test 1!',
      state_id:      Ticket::State.lookup(name: 'new').id,
      priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    ticket4 = Ticket.create(
      group_id:      group_notification_setting.id,
      customer_id:   User.lookup(email: 'nicole.braun@zammad.org').id,
      owner_id:      agent1.id,
      title:         'Notification Settings Test 2!',
      state_id:      Ticket::State.lookup(name: 'new').id,
      priority_id:   Ticket::Priority.lookup(name: '2 normal').id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    agent1.preferences[:notification_config][:group_ids] = nil
    agent1.save
    travel 30.seconds

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket1, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket2, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket3, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket4, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    agent2.preferences[:notification_config][:group_ids] = nil
    agent2.save
    travel 30.seconds

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket1, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket2, 'create')
    assert_nil(result)

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket3, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket4, 'create')
    assert_nil(result)

    # no group selection
    agent1.preferences[:notification_config][:group_ids] = []
    agent1.save
    travel 30.seconds

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket1, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket2, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket3, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket4, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    agent2.preferences[:notification_config][:group_ids] = []
    agent2.save
    travel 30.seconds

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket1, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket2, 'create')
    assert_nil(result)

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket3, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket4, 'create')
    assert_nil(result)

    agent1.preferences[:notification_config][:group_ids] = ['-']
    agent1.save
    travel 30.seconds

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket1, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket2, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket3, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket4, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    agent2.preferences[:notification_config][:group_ids] = ['-']
    agent2.save
    travel 30.seconds

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket1, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket2, 'create')
    assert_nil(result)

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket3, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket4, 'create')
    assert_nil(result)

    # dedecated group selection
    agent1.preferences[:notification_config][:group_ids] = [Group.lookup(name: 'Users').id]
    agent1.save
    travel 30.seconds

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket1, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket2, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket3, 'create')
    assert_nil(result)

    result = NotificationFactory::Mailer.notification_settings(agent1, ticket4, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    agent2.preferences[:notification_config][:group_ids] = [Group.lookup(name: 'Users').id]
    agent2.save
    travel 30.seconds

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket1, 'create')
    assert_equal(true, result[:channels][:online])
    assert_equal(true, result[:channels][:email])

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket2, 'create')
    assert_nil(result)

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket3, 'create')
    assert_nil(result)
    assert_nil(result)

    result = NotificationFactory::Mailer.notification_settings(agent2, ticket4, 'create')
    assert_nil(result)

  end

end
