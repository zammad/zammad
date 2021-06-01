# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class KarmaTest < ActiveSupport::TestCase

  test 'basic' do

    groups = Group.all
    roles  = Role.where(name: 'Agent')
    agent1 = User.create!(
      login:         'karma-agent1@example.com',
      firstname:     'Karma',
      lastname:      'Agent1',
      email:         'karma-agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_by_id: 1,
      created_by_id: 1,
    )
    agent2 = User.create!(
      login:         'karma-agent2@example.com',
      firstname:     'Karma',
      lastname:      'Agent2',
      email:         'karma-agent2@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_by_id: 1,
      created_by_id: 1,
    )
    customer1 = User.create!(
      login:         'karma-customer1@example.com',
      firstname:     'Karma',
      lastname:      'Customer1',
      email:         'karma-customer1@example.com',
      password:      'customerpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket1 = Ticket.create!(
      title:         'karma test 1',
      group:         Group.lookup(name: 'Users'),
      customer:      customer1,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
      updated_at:    Time.zone.now - 10.hours,
      created_at:    Time.zone.now - 10.hours,
    )
    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'agent phone 1 / init',
      internal:      false,
      sender:        Ticket::Article::Sender.lookup(name: 'Agent'),
      type:          Ticket::Article::Type.lookup(name: 'phone'),
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
      updated_at:    Time.zone.now - 10.hours,
      created_at:    Time.zone.now - 10.hours,
    )
    assert(ticket1)

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_equal(10, Karma.score_by_user(agent1))
    assert_equal(0, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    karma_user = Karma::User.by_user(agent1)
    assert_equal('Beginner', karma_user.level)
    assert_equal(10, karma_user.score)

    karma_user = Karma::User.by_user(agent2)
    assert_equal('Beginner', karma_user.level)
    assert_equal(0, karma_user.score)

    ticket1.state = Ticket::State.lookup(name: 'pending reminder')
    ticket1.updated_by_id = agent1.id
    ticket1.updated_at = Time.zone.now - 9.hours
    ticket1.created_at = Time.zone.now - 9.hours
    ticket1.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_equal(10 + 2, Karma.score_by_user(agent1))
    assert_equal(0, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    karma_user = Karma::User.by_user(agent1)
    assert_equal('Beginner', karma_user.level)
    assert_equal(12, karma_user.score)

    karma_user = Karma::User.by_user(agent2)
    assert_equal('Beginner', karma_user.level)
    assert_equal(0, karma_user.score)

    ticket1.state = Ticket::State.lookup(name: 'pending close')
    ticket1.updated_by_id = agent1.id
    ticket1.updated_at = Time.zone.now - 9.hours
    ticket1.created_at = Time.zone.now - 9.hours
    ticket1.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_equal(10 + 2, Karma.score_by_user(agent1))
    assert_equal(0, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    ticket1.state = Ticket::State.lookup(name: 'closed')
    ticket1.updated_by_id = agent2.id
    ticket1.updated_at = Time.zone.now - 9.hours
    ticket1.created_at = Time.zone.now - 9.hours
    ticket1.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_equal(10 + 2, Karma.score_by_user(agent1))
    assert_equal(0, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    ticket1.state = Ticket::State.lookup(name: 'open')
    ticket1.save!

    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'reply: some subject',
      message_id:    'some@id',
      body:          'agent phone 2',
      internal:      false,
      sender:        Ticket::Article::Sender.lookup(name: 'Agent'),
      type:          Ticket::Article::Type.lookup(name: 'phone'),
      updated_by_id: agent2.id,
      created_by_id: agent2.id,
      updated_at:    Time.zone.now - (9.hours + 15.minutes),
      created_at:    Time.zone.now - (9.hours + 15.minutes),
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_equal(10 + 2, Karma.score_by_user(agent1))
    assert_equal(0, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    ticket1.state = Ticket::State.lookup(name: 'closed')
    ticket1.save!

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_equal(10 + 2, Karma.score_by_user(agent1))
    assert_equal(5, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'customer phone',
      internal:      false,
      sender:        Ticket::Article::Sender.lookup(name: 'Customer'),
      type:          Ticket::Article::Type.lookup(name: 'phone'),
      updated_by_id: customer1.id,
      created_by_id: customer1.id,
      updated_at:    Time.zone.now - 8.hours,
      created_at:    Time.zone.now - 8.hours,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_equal(10 + 2, Karma.score_by_user(agent1))
    assert_equal(5, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'agent phone 3',
      internal:      false,
      sender:        Ticket::Article::Sender.lookup(name: 'Agent'),
      type:          Ticket::Article::Type.lookup(name: 'phone'),
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
      updated_at:    Time.zone.now - (7.hours + 30.minutes),
      created_at:    Time.zone.now - (7.hours + 30.minutes),
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_equal(10 + 2 + 25, Karma.score_by_user(agent1))
    assert_equal(5, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.lookup(name: 'Agent'),
      type:          Ticket::Article::Type.lookup(name: 'phone'),
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
      updated_at:    Time.zone.now - (7.hours + 15.minutes),
      created_at:    Time.zone.now - (7.hours + 15.minutes),
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_equal(10 + 2 + 25, Karma.score_by_user(agent1))
    assert_equal(5, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.lookup(name: 'Customer'),
      type:          Ticket::Article::Type.lookup(name: 'phone'),
      updated_by_id: customer1.id,
      created_by_id: customer1.id,
      updated_at:    Time.zone.now - 7.hours,
      created_at:    Time.zone.now - 7.hours,
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_equal(10 + 2 + 25, Karma.score_by_user(agent1))
    assert_equal(5, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.lookup(name: 'Agent'),
      type:          Ticket::Article::Type.lookup(name: 'phone'),
      updated_by_id: agent2.id,
      created_by_id: agent2.id,
      updated_at:    Time.zone.now - (2.hours + 30.minutes),
      created_at:    Time.zone.now - (2.hours + 30.minutes),
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_equal(10 + 2 + 25, Karma.score_by_user(agent1))
    assert_equal(5 + 10, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.lookup(name: 'Agent'),
      type:          Ticket::Article::Type.lookup(name: 'phone'),
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
      updated_at:    Time.zone.now - (2.hours + 45.minutes),
      created_at:    Time.zone.now - (2.hours + 45.minutes),
    )

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_equal(10 + 2 + 25, Karma.score_by_user(agent1))
    assert_equal(5 + 10, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    ticket1.tag_add('Tag1', agent1.id)
    #travel 5.seconds
    ticket1.tag_add('Tag2', agent1.id)

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_equal(10 + 2 + 25 + 4, Karma.score_by_user(agent1))
    assert_equal(5 + 10, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    ticket1.tag_add('Tag3', agent1.id)
    ticket1.tag_add('Tag4', agent2.id)

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_equal(10 + 2 + 25 + 4, Karma.score_by_user(agent1))
    assert_equal(5 + 10 + 4, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    ticket2 = Ticket.create!(
      title:         'karma test 1',
      group:         Group.lookup(name: 'Users'),
      customer:      customer1,
      state:         Ticket::State.lookup(name: 'new'),
      owner_id:      agent1.id,
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
      updated_at:    Time.zone.now - 10.hours,
      created_at:    Time.zone.now - 10.hours,
    )
    Ticket::Article.create!(
      ticket_id:     ticket2.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      body:          'some message',
      internal:      false,
      sender:        Ticket::Article::Sender.lookup(name: 'Agent'),
      type:          Ticket::Article::Type.lookup(name: 'phone'),
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
      updated_at:    Time.zone.now - 2.hours,
      created_at:    Time.zone.now - 2.hours,
    )
    assert(ticket2)

    # execute object transaction
    TransactionDispatcher.commit
    Scheduler.worker(true)

    assert_equal(10 + 2 + 25 + 4 + 10, Karma.score_by_user(agent1))
    assert_equal(5 + 10 + 4, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    ticket2.state = Ticket::State.lookup(name: 'pending reminder')
    ticket2.pending_time = Time.zone.now - 1.day
    ticket2.save!

    Ticket.process_pending

    assert_equal(10 + 2 + 25 + 4 + 10, Karma.score_by_user(agent1))
    assert_equal(5 + 10 + 4, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    ticket2.state = Ticket::State.lookup(name: 'pending reminder')
    ticket2.pending_time = Time.zone.now - 3.days
    ticket2.save!

    Ticket.process_pending

    assert_equal(10 + 2 + 25 + 4 + 10 - 5, Karma.score_by_user(agent1))
    assert_equal(5 + 10 + 4, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    Ticket.process_pending

    assert_equal(10 + 2 + 25 + 4 + 10 - 5, Karma.score_by_user(agent1))
    assert_equal(5 + 10 + 4, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    calendar1 = Calendar.create!(
      name:           'EU 1 - karma test',
      timezone:       'Europe/Berlin',
      business_hours: {
        mon: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        tue: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        wed: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        thu: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        fri: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        sat: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
        sun: {
          active:     true,
          timeframes: [ ['00:00', '23:59'] ]
        },
      },
      default:        true,
      ical_url:       nil,
      updated_by_id:  1,
      created_by_id:  1,
    )

    sla1 = Sla.create!(
      name:                'test sla 1',
      condition:           {},
      first_response_time: 20,
      update_time:         60,
      solution_time:       120,
      calendar_id:         calendar1.id,
      updated_by_id:       1,
      created_by_id:       1,
    )
    ticket2.state = Ticket::State.lookup(name: 'open')
    ticket2.save!

    TransactionDispatcher.commit
    Scheduler.worker(true)

    #Scheduler.worker(true)
    #Ticket::Escalation.rebuild_all
    Ticket.process_escalation

    assert_equal(10 + 2 + 25 + 4 + 10 - 5 - 5, Karma.score_by_user(agent1))
    assert_equal(5 + 10 + 4, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    Ticket.process_escalation

    assert_equal(10 + 2 + 25 + 4 + 10 - 5 - 5, Karma.score_by_user(agent1))
    assert_equal(5 + 10 + 4, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    # check min score
    Karma::ActivityLog.add('ticket escalated', ticket2.owner, 'Ticket', ticket2.id, true)
    Karma::ActivityLog.add('ticket escalated', ticket2.owner, 'Ticket', ticket2.id, true)
    Karma::ActivityLog.add('ticket escalated', ticket2.owner, 'Ticket', ticket2.id, true)
    Karma::ActivityLog.add('ticket escalated', ticket2.owner, 'Ticket', ticket2.id, true)
    Karma::ActivityLog.add('ticket escalated', ticket2.owner, 'Ticket', ticket2.id, true)
    Karma::ActivityLog.add('ticket escalated', ticket2.owner, 'Ticket', ticket2.id, true)
    Karma::ActivityLog.add('ticket escalated', ticket2.owner, 'Ticket', ticket2.id, true)
    Karma::ActivityLog.add('ticket escalated', ticket2.owner, 'Ticket', ticket2.id, true)
    Karma::ActivityLog.add('ticket escalated', ticket2.owner, 'Ticket', ticket2.id, true)
    assert_equal(0, Karma.score_by_user(agent1), 'block - score, min is 0')
    assert_equal(5 + 10 + 4, Karma.score_by_user(agent2))
    assert_equal(0, Karma.score_by_user(customer1))

    # test score/level
    assert_equal('Beginner', Karma::User.level_by_score(0))
    assert_equal('Beginner', Karma::User.level_by_score(400))
    assert_equal('Beginner', Karma::User.level_by_score(499))
    assert_equal('Newbie', Karma::User.level_by_score(500))
    assert_equal('Newbie', Karma::User.level_by_score(1999))
    assert_equal('Intermediate', Karma::User.level_by_score(2000))
    assert_equal('Intermediate', Karma::User.level_by_score(4999))
    assert_equal('Professional', Karma::User.level_by_score(5000))
    assert_equal('Professional', Karma::User.level_by_score(6999))
    assert_equal('Expert', Karma::User.level_by_score(7000))
    assert_equal('Expert', Karma::User.level_by_score(8999))
    assert_equal('Master', Karma::User.level_by_score(9000))
    assert_equal('Master', Karma::User.level_by_score(18_999))
    assert_equal('Evangelist', Karma::User.level_by_score(19_000))
    assert_equal('Evangelist', Karma::User.level_by_score(49_999))
    assert_equal('Hero', Karma::User.level_by_score(50_000))

    # cleanup
    ticket1.destroy!
    ticket2.destroy!
    calendar1.destroy!
    sla1.destroy!

  end

end
