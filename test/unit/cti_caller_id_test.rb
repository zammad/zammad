
require 'test_helper'

class CtiCallerIdTest < ActiveSupport::TestCase

  setup do

    Ticket.destroy_all
    Cti::CallerId.destroy_all
    @agent1 = User.create_or_update(
      login: 'ticket-caller_id-agent1@example.com',
      firstname: 'CallerId',
      lastname: 'Agent1',
      email: 'ticket-caller_id-agent1@example.com',
      active: true,
      phone: '+49 1111 222222',
      fax: '+49 1111 222223',
      mobile: '+49 1111 222223',
      note: 'Phone at home: +49 1111 222224',
      updated_by_id: 1,
      created_by_id: 1,
    )
    @agent2 = User.create_or_update(
      login: 'ticket-caller_id-agent2@example.com',
      firstname: 'CallerId',
      lastname: 'Agent2',
      email: 'ticket-caller_id-agent2@example.com',
      phone: '+49 2222 222222',
      note: 'Phone at home: <b>+49 2222 222224</b>',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    @agent3 = User.create_or_update(
      login: 'ticket-caller_id-agent3@example.com',
      firstname: 'CallerId',
      lastname: 'Agent3',
      email: 'ticket-caller_id-agent3@example.com',
      phone: '+49 2222 222222',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    @customer1 = User.create_or_update(
      login: 'ticket-caller_id-customer1@example.com',
      firstname: 'CallerId',
      lastname: 'Customer1',
      email: 'ticket-caller_id-customer1@example.com',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    Observer::Transaction.commit
    Scheduler.worker(true)
  end

  test '1 lookups' do

    Cti::CallerId.rebuild

    caller_ids = Cti::CallerId.lookup('491111222277')
    assert_equal(0, caller_ids.length)

    caller_ids = Cti::CallerId.lookup('491111222223')
    assert_equal(1, caller_ids.length)
    assert_equal(@agent1.id, caller_ids[0].user_id)
    assert_equal('known', caller_ids[0].level)

    caller_ids = Cti::CallerId.lookup('492222222222')
    assert_equal(2, caller_ids.length)
    assert_equal(@agent3.id, caller_ids[0].user_id)
    assert_equal('known', caller_ids[0].level)
    assert_equal(@agent2.id, caller_ids[1].user_id)
    assert_equal('known', caller_ids[1].level)

    # create ticket in group
    ticket1 = Ticket.create!(
      title: 'some caller id test 1',
      group: Group.lookup(name: 'Users'),
      customer: @customer1,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )
    article1 = Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message\nFon (GEL): +49 111 366-1111 Mi-Fr
Fon (LIN): +49 222 6112222 Mo-Di
Mob: +49 333 8362222",
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer1.id,
      created_by_id: @customer1.id,
    )
    assert(ticket1)

    # create ticket in group
    ticket2 = Ticket.create!(
      title: 'some caller id test 2',
      group: Group.lookup(name: 'Users'),
      customer: @customer1,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )
    article2 = Ticket::Article.create!(
      ticket_id: ticket2.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message\nFon (GEL): +49 111 111-1111 Mi-Fr
Fon (LIN): +49 222 1112222 Mo-Di
Mob: +49 333 1112222",
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )
    assert(ticket2)

    Observer::Transaction.commit
    Scheduler.worker(true)

    caller_ids = Cti::CallerId.lookup('491111222277')
    assert_equal(0, caller_ids.length)

    caller_ids = Cti::CallerId.lookup('491111222223')
    assert_equal(1, caller_ids.length)
    assert_equal(@agent1.id, caller_ids[0].user_id)
    assert_equal('known', caller_ids[0].level)

    caller_ids = Cti::CallerId.lookup('492222222222')
    assert_equal(2, caller_ids.length)
    assert_equal(@agent3.id, caller_ids[0].user_id)
    assert_equal('known', caller_ids[0].level)
    assert_equal(@agent2.id, caller_ids[1].user_id)
    assert_equal('known', caller_ids[1].level)

    caller_ids = Cti::CallerId.lookup('492226112222')
    assert_equal(1, caller_ids.length)
    assert_equal(@customer1.id, caller_ids[0].user_id)
    assert_equal('maybe', caller_ids[0].level)

    caller_ids = Cti::CallerId.lookup('492221112222')
    assert_equal(0, caller_ids.length)

  end

  test '2 lookups' do

    Cti::CallerId.destroy_all

    Cti::CallerId.maybe_add(
      caller_id: '4999999999',
      level: 'maybe',
      user_id: 2,
      object: 'Ticket',
      o_id: 2,
    )

    Cti::CallerId.maybe_add(
      caller_id: '4912345678901',
      comment: 'Hairdresser Bob Smith, San Francisco',
      level: 'public',
      user_id: 2,
      object: 'GoYello',
      o_id: 1,
    )

    caller_ids = Cti::CallerId.lookup('4912345678901')
    assert_equal(1, caller_ids.length)
    assert_equal('public', caller_ids[0].level)
    assert_equal(2, caller_ids[0].user_id)
    assert_equal('Hairdresser Bob Smith, San Francisco', caller_ids[0].comment)

    Cti::CallerId.maybe_add(
      caller_id: '4912345678901',
      level: 'maybe',
      user_id: 2,
      object: 'Ticket',
      o_id: 2,
    )

    caller_ids = Cti::CallerId.lookup('4912345678901')
    assert_equal(1, caller_ids.length)
    assert_equal('maybe', caller_ids[0].level)
    assert_equal(2, caller_ids[0].user_id)
    assert_nil(caller_ids[0].comment)

    Cti::CallerId.maybe_add(
      caller_id: '4912345678901',
      level: 'maybe',
      user_id: 2,
      object: 'Ticket',
      o_id: 2,
    )

    caller_ids = Cti::CallerId.lookup('4912345678901')
    assert_equal(1, caller_ids.length)
    assert_equal('maybe', caller_ids[0].level)
    assert_equal(2, caller_ids[0].user_id)
    assert_nil(caller_ids[0].comment)

    user_id = User.find_by(login: 'ticket-caller_id-customer1@example.com').id

    Cti::CallerId.maybe_add(
      caller_id: '4912345678901',
      level: 'maybe',
      user_id: user_id,
      object: 'Ticket',
      o_id: 2,
    )

    caller_ids = Cti::CallerId.lookup('4912345678901')
    assert_equal(2, caller_ids.length)
    assert_equal('maybe', caller_ids[0].level)
    assert_equal(user_id, caller_ids[0].user_id)
    assert_nil(caller_ids[0].comment)
    assert_equal('maybe', caller_ids[1].level)
    assert_equal(2, caller_ids[1].user_id)
    assert_nil(caller_ids[1].comment)

    Cti::CallerId.maybe_add(
      caller_id: '4912345678901',
      level: 'known',
      user_id: user_id,
      object: 'User',
      o_id: 2,
    )

    caller_ids = Cti::CallerId.lookup('4912345678901')
    assert_equal(1, caller_ids.length)
    assert_equal('known', caller_ids[0].level)
    assert_equal(user_id, caller_ids[0].user_id)
    assert_nil(caller_ids[0].comment)

  end

  test '3 process - log' do

    ticket1 = Ticket.create!(
      title: 'some caller id test 1',
      group: Group.lookup(name: 'Users'),
      customer: @customer1,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )
    article1 = Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message\nFon (GEL): +49 111 366-1111 Mi-Fr
Fon (LIN): +49 222 6112222 Mo-Di
Mob: +49 333 8362222",
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer1.id,
      created_by_id: @customer1.id,
    )
    assert(ticket1)
    ticket2 = Ticket.create!(
      title: 'some caller id test 2',
      group: Group.lookup(name: 'Users'),
      customer: @customer1,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @agent1.id,
      created_by_id: @agent1.id,
    )
    article2 = Ticket::Article.create!(
      ticket_id: ticket2.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message\nFon (GEL): +49 111 366-1111 Mi-Fr
Fon (LIN): +49 222 6112222 Mo-Di
Mob: +49 333 8362222",
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer1.id,
      created_by_id: @customer1.id,
    )
    assert(ticket2)

    Cti::CallerId.rebuild

    Cti::Log.process(
      'cause' => '',
      'event' => 'newCall',
      'user' => 'user 1',
      'from' => '491113661111',
      'to' => '4930600000000',
      'callId' => '4991155921769858278-1',
      'direction' => 'in',
    )

    log = Cti::Log.log
    assert(log[:list])
    assert(log[:assets])
    assert(log[:list][0])
    assert_not(log[:list][1])
    assert(log[:list][0].preferences)
    assert(log[:list][0].preferences[:from])
    assert_equal(1, log[:list][0].preferences[:from].count)
    assert_equal(@customer1.id, log[:list][0].preferences[:from][0][:user_id])
    assert_equal('maybe', log[:list][0].preferences[:from][0][:level])

  end

  test '4 touch caller log / don\'t touch caller log' do
    5.times do |count|
      travel 2.seconds
      Cti::Log.process(
        'cause' => '',
        'event' => 'newCall',
        'user' => 'user 1',
        'from' => '491111222222',
        'to' => '4930600000000',
        'callId' => "touch-loop-#{count}",
        'direction' => 'in',
      )
    end

    # do not update Cti::Log on user touch
    last_updated_at = Cti::Log.order(updated_at: :desc).first.updated_at
    travel 10.minutes
    @agent1.reload
    @agent1.touch
    Observer::Transaction.commit
    Scheduler.worker(true)
    assert_equal(last_updated_at, Cti::Log.order(updated_at: :desc).first.updated_at)

    # do update old Cti::Log on phone update of user
    @agent1.reload
    @agent1.phone = '+49 1111 222222 999'
    @agent1.save!
    Observer::Transaction.commit
    Scheduler.worker(true)
    assert_not_equal(last_updated_at, Cti::Log.order(updated_at: :desc).first.updated_at)

    # new call with not known number
    travel 10.minutes
    Cti::Log.process(
      'cause' => '',
      'event' => 'newCall',
      'user' => 'user 1',
      'from' => '49111122222277',
      'to' => '4930600000000',
      'callId' => 'touch-loop-20',
      'direction' => 'in',
    )

    # set not known number for agent1
    last_updated_at = Cti::Log.order(updated_at: :desc).first.updated_at
    travel 10.minutes
    @agent1.reload
    @agent1.phone = '+49 1111 222222 77'
    @agent1.save!
    Observer::Transaction.commit
    Scheduler.worker(true)
    assert_not_equal(last_updated_at, Cti::Log.order(updated_at: :desc).first.updated_at)

    # verify last updated entry
    last = Cti::Log.order(updated_at: :desc).first
    assert_equal('49111122222277', last.preferences[:from][0][:caller_id])
    assert_nil(last.preferences[:from][0][:comment])
    assert_equal('known', last.preferences[:from][0][:level])
    assert_equal('User', last.preferences[:from][0][:object])
    assert_equal(@agent1.id, last.preferences[:from][0][:o_id])

    # create new user with no phone number
    last_updated_at = Cti::Log.order(updated_at: :desc).first.updated_at
    travel 30.minutes
    agent4 = User.create!(
      login: 'ticket-caller_id-agent4@example.com',
      firstname: 'CallerId',
      lastname: 'Agent4',
      email: 'ticket-caller_id-agent4@example.com',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Observer::Transaction.commit
    Scheduler.worker(true)
    assert_equal(last_updated_at, Cti::Log.order(updated_at: :desc).first.updated_at)

    # verify if caller log is updated with '' value for phone
    agent4.reload
    agent4.phone = ''
    agent4.save!
    Observer::Transaction.commit
    Scheduler.worker(true)
    assert_equal(last_updated_at, Cti::Log.order(updated_at: :desc).first.updated_at)

    # verify if caller log is updated with nil value for phone
    agent4.reload
    agent4.phone = nil
    agent4.save!
    Observer::Transaction.commit
    Scheduler.worker(true)

    # verify if caller log is updated with existing caller log value for phone
    assert_equal(last_updated_at, Cti::Log.order(updated_at: :desc).first.updated_at)
    agent4.reload
    agent4.phone = '+49 1111 222222'
    agent4.save!
    Observer::Transaction.commit
    Scheduler.worker(true)
    assert_not_equal(last_updated_at, Cti::Log.order(updated_at: :desc).first.updated_at)

    # verify if caller log is no value change for phone
    last_updated_at = Cti::Log.order(updated_at: :desc).first.updated_at
    travel 30.minutes
    agent4.save!
    Observer::Transaction.commit
    Scheduler.worker(true)
    assert_equal(last_updated_at, Cti::Log.order(updated_at: :desc).first.updated_at)

    # verify if caller log is updated with '' value for phone
    last_updated_at = Cti::Log.order(updated_at: :desc).first.updated_at
    travel 30.minutes
    agent4.reload
    agent4.phone = ''
    agent4.save!
    Observer::Transaction.commit
    Scheduler.worker(true)
    assert_not_equal(last_updated_at, Cti::Log.order(updated_at: :desc).first.updated_at)

    # verify if caller log is updated if new ticket with existing caller id is created
    last_updated_at = Cti::Log.order(updated_at: :desc).first.updated_at
    travel 30.minutes
    last_caller_id_count = Cti::CallerId.count
    ticket1 = Ticket.create!(
      title: 'some caller id test 1',
      group: Group.lookup(name: 'Users'),
      customer: @customer1,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: @customer1.id,
      created_by_id: @customer1.id,
    )
    article1 = Ticket::Article.create!(
      ticket_id: ticket1.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject',
      message_id: 'some@id',
      body: "some message\n+49 1111 222222",
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Customer').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: @customer1.id,
      created_by_id: @customer1.id,
    )
    Observer::Transaction.commit
    Scheduler.worker(true)
    assert_equal(last_caller_id_count + 2, Cti::CallerId.count)
    assert_equal(last_updated_at, Cti::Log.order(updated_at: :desc).first.updated_at)

  end

  test '5 probe if caller log need to be pushed' do

    Cti::Log.process(
      'cause' => '',
      'event' => 'newCall',
      'user' => 'user 1',
      'from' => '491111222222',
      'to' => '4930600000000',
      'callId' => 'touch-loop-0',
      'direction' => 'in',
    )
    assert(Cti::Log.push_caller_list_update?(Cti::Log.last))

    65.times do |count|
      travel 1.hour
      Cti::Log.process(
        'cause' => '',
        'event' => 'newCall',
        'user' => 'user 1',
        'from' => '491111222222',
        'to' => '4930600000000',
        'callId' => "touch-loop-1-#{count}",
        'direction' => 'in',
      )
    end
    assert(Cti::Log.push_caller_list_update?(Cti::Log.last))
    assert_not(Cti::Log.push_caller_list_update?(Cti::Log.first))

    65.times do |count|
      travel 1.minute
      Cti::Log.process(
        'cause' => '',
        'event' => 'newCall',
        'user' => 'user 1',
        'from' => '491111222222',
        'to' => '4930600000000',
        'callId' => "touch-loop-2-#{count}",
        'direction' => 'in',
      )
    end
    assert(Cti::Log.push_caller_list_update?(Cti::Log.last))
    assert_not(Cti::Log.push_caller_list_update?(Cti::Log.first))

    travel 2.seconds
    Cti::Log.process(
      'cause' => '',
      'event' => 'newCall',
      'user' => 'user 1',
      'from' => '491111222222',
      'to' => '4930600000000',
      'callId' => 'touch-loop-3-1',
      'direction' => 'in',
    )
    assert(Cti::Log.push_caller_list_update?(Cti::Log.last))

  end

  test 'user delete with caller log rebuild' do
    assert_equal(2, Cti::CallerId.where(user_id: @agent2.id).count)

    @agent2.destroy!

    assert_equal(0, Cti::CallerId.where(user_id: @agent2.id).count)

    Observer::Transaction.commit
    Scheduler.worker(true)

    assert_equal(0, Cti::CallerId.where(user_id: @agent2.id).count)
  end

  test 'order of events' do
    Cti::Log.process(
      'cause' => '',
      'event' => 'newCall',
      'user' => 'user 1',
      'from' => '491111222222',
      'to' => '4930600000000',
      'callId' => 'touch-loop-1',
      'direction' => 'in',
    )

    last = Cti::Log.last
    assert_equal(last.state, 'newCall')
    assert_equal(last.done, false)

    travel 2.seconds
    Cti::Log.process(
      'cause' => '',
      'event' => 'hangup',
      'user' => 'user 1',
      'from' => '491111222222',
      'to' => '4930600000000',
      'callId' => 'touch-loop-1',
      'direction' => 'in',
    )
    last.reload
    assert_equal(last.state, 'hangup')
    assert_equal(last.done, false)

    travel 2.seconds
    Cti::Log.process(
      'cause' => '',
      'event' => 'answer',
      'user' => 'user 1',
      'from' => '491111222222',
      'to' => '4930600000000',
      'callId' => 'touch-loop-1',
      'direction' => 'in',
    )
    last.reload
    assert_equal(last.state, 'hangup')
    assert_equal(last.done, false)

  end

  test 'not answered should be not marked as done' do

    Cti::Log.process(
      'cause' => '',
      'event' => 'newCall',
      'user' => 'user 1',
      'from' => '491111222222',
      'to' => '4930600000000',
      'callId' => 'touch-loop-1',
      'direction' => 'in',
    )

    last = Cti::Log.last
    assert_equal(last.state, 'newCall')
    assert_equal(last.done, false)

    travel 2.seconds
    Cti::Log.process(
      'cause' => '',
      'event' => 'hangup',
      'user' => 'user 1',
      'from' => '491111222222',
      'to' => '4930600000000',
      'callId' => 'touch-loop-1',
      'direction' => 'in',
    )
    last.reload
    assert_equal(last.state, 'hangup')
    assert_equal(last.done, false)
  end

  test 'answered should be marked as done' do

    Cti::Log.process(
      'cause' => '',
      'event' => 'newCall',
      'user' => 'user 1',
      'from' => '491111222222',
      'to' => '4930600000000',
      'callId' => 'touch-loop-1',
      'direction' => 'in',
    )

    last = Cti::Log.last
    assert_equal(last.state, 'newCall')
    assert_equal(last.done, false)

    travel 2.seconds
    Cti::Log.process(
      'cause' => '',
      'event' => 'answer',
      'user' => 'user 1',
      'from' => '491111222222',
      'to' => '4930600000000',
      'callId' => 'touch-loop-1',
      'direction' => 'in',
    )
    last = Cti::Log.last
    assert_equal(last.state, 'answer')
    assert_equal(last.done, true)

    travel 2.seconds
    Cti::Log.process(
      'cause' => '',
      'event' => 'hangup',
      'user' => 'user 1',
      'from' => '491111222222',
      'to' => '4930600000000',
      'callId' => 'touch-loop-1',
      'direction' => 'in',
    )
    last.reload
    assert_equal(last.state, 'hangup')
    assert_equal(last.done, true)
  end

  test 'voicemail should not be marked as done' do

    Cti::Log.process(
      'cause' => '',
      'event' => 'newCall',
      'user' => 'user 1',
      'from' => '491111222222',
      'to' => '4930600000000',
      'callId' => 'touch-loop-1',
      'direction' => 'in',
    )

    last = Cti::Log.last
    assert_equal(last.state, 'newCall')
    assert_equal(last.done, false)

    Cti::Log.process(
      'cause' => '',
      'event' => 'answer',
      'user' => 'voicemail',
      'from' => '491111222222',
      'to' => '4930600000000',
      'callId' => 'touch-loop-1',
      'direction' => 'in',
    )
    last = Cti::Log.last
    assert_equal(last.state, 'answer')
    assert_equal(last.done, true)

    travel 2.seconds
    Cti::Log.process(
      'cause' => '',
      'event' => 'hangup',
      'user' => 'user 1',
      'from' => '491111222222',
      'to' => '4930600000000',
      'callId' => 'touch-loop-1',
      'direction' => 'in',
    )
    last.reload
    assert_equal(last.state, 'hangup')
    assert_equal(last.done, false)
  end

  test 'forwarded should be marked as done' do

    Cti::Log.process(
      'cause' => '',
      'event' => 'newCall',
      'user' => 'user 1',
      'from' => '491111222222',
      'to' => '4930600000000',
      'callId' => 'touch-loop-1',
      'direction' => 'in',
    )

    last = Cti::Log.last
    assert_equal(last.state, 'newCall')
    assert_equal(last.done, false)

    travel 2.seconds
    Cti::Log.process(
      'cause' => 'forwarded',
      'event' => 'hangup',
      'user' => 'user 1',
      'from' => '491111222222',
      'to' => '4930600000000',
      'callId' => 'touch-loop-1',
      'direction' => 'in',
    )
    last.reload
    assert_equal(last.state, 'hangup')
    assert_equal(last.done, true)
  end

end
