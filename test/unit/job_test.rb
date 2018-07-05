
require 'test_helper'

class JobTest < ActiveSupport::TestCase
  test 'case 1' do

    # create ticket
    group1 = Group.lookup(name: 'Users')
    group2 = Group.create_or_update(
      name: 'JobTest2',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket1 = Ticket.create!(
      title: 'job test 1',
      group: group1,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      created_at: Time.zone.now - 3.days,
      updated_at: Time.zone.now - 3.days,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ticket2 = Ticket.create!(
      title: 'job test 2',
      group: group1,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      created_at: Time.zone.now - 1.day,
      created_by_id: 1,
      updated_at: Time.zone.now - 1.day,
      updated_by_id: 1,
    )
    ticket3 = Ticket.create!(
      title: 'job test 3',
      group: group2,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'open'),
      priority: Ticket::Priority.lookup(name: '3 high'),
      created_at: Time.zone.now - 1.day,
      created_by_id: 1,
      updated_at: Time.zone.now - 1.day,
      updated_by_id: 1,
    )
    ticket4 = Ticket.create!(
      title: 'job test 4',
      group: group2,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'closed'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      created_at: Time.zone.now - 3.days,
      created_by_id: 1,
      updated_at: Time.zone.now - 3.days,
      updated_by_id: 1,
    )
    ticket5 = Ticket.create!(
      title: 'job test 5',
      group: group2,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'open'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      created_at: Time.zone.now - 3.days,
      created_by_id: 1,
      updated_by_id: 1,
      updated_at: Time.zone.now - 3.days,
    )

    # create jobs
    job1 = Job.create_or_update(
      name: 'Test Job1',
      timeplan: {
        days: {
          Mon: false,
          Tue: false,
          Wed: false,
          Thu: false,
          Fri: false,
          Sat: false,
          Sun: false,
        },
        hours: {
          0 => false,
          1 => false,
          2 => false,
          3 => false,
          4 => false,
          5 => false,
          6 => false,
          7 => false,
          8 => false,
          9 => false,
          10 => false,
          11 => false,
          12 => false,
          13 => false,
          14 => false,
          15 => false,
          16 => false,
          17 => false,
          18 => false,
          19 => false,
          20 => false,
          21 => false,
          22 => false,
          23 => false,
        },
        minutes: {
          0 => false,
          10 => false,
          20 => false,
          30 => false,
          40 => false,
          50 => false,
        },
      },
      condition: {
        'ticket.state_id' => { 'operator' => 'is', 'value' => [Ticket::State.lookup(name: 'new').id.to_s, Ticket::State.lookup(name: 'open').id.to_s] },
        'ticket.created_at' => { 'operator' => 'before (relative)', 'value' => '2', 'range' => 'day' },
      },
      perform: {
        'ticket.state_id' => { 'value' => Ticket::State.lookup(name: 'closed').id.to_s }
      },
      disable_notification: true,
      last_run_at: nil,
      active: true,
      created_by_id: 1,
      created_at: Time.zone.now,
      updated_by_id: 1,
      updated_at: Time.zone.now,
    )
    assert_not(job1.next_run_at)
    assert_not(job1.executable?)

    job1.last_run_at = Time.zone.now - 15.minutes
    job1.save!
    assert_not(job1.executable?)

    job1.updated_at = Time.zone.now - 15.minutes
    job1.save!
    assert(job1.executable?)

    job1.active = false
    job1.save!
    assert_not(job1.executable?)

    job1.active = true
    job1.save!
    assert_not(job1.executable?)

    assert_not(job1.in_timeplan?)

    time = Time.zone.now
    # "freeze" time to avoid timing issues
    travel_to(time)

    day_map = {
      0 => 'Sun',
      1 => 'Mon',
      2 => 'Tue',
      3 => 'Wed',
      4 => 'Thu',
      5 => 'Fri',
      6 => 'Sat',
    }
    job1.timeplan['days'][day_map[time.wday]] = true
    job1.save!
    assert_not(job1.in_timeplan?(time))
    job1.timeplan['hours'][time.hour.to_s] = true
    job1.save!
    assert_not(job1.in_timeplan?(time))
    min = time.min
    if min < 9
      min = 0
    elsif min < 20
      min = 10
    elsif min < 30
      min = 20
    elsif min < 40
      min = 30
    elsif min < 50
      min = 40
    elsif min < 60
      min = 50
    end
    job1.timeplan['minutes'][min.to_s] = true
    job1.save!
    assert(job1.in_timeplan?(time))

    job1.timeplan['hours'][time.hour] = true
    job1.save!

    job1.timeplan['minutes'][min] = true
    job1.save!
    assert(job1.in_timeplan?(time))

    # execute jobs
    job1.updated_at = Time.zone.now - 15.minutes
    job1.save!
    Job.run

    assert(job1.next_run_at)
    assert(job1.executable?)
    assert(job1.in_timeplan?)

    # verify changes on tickets
    ticket1_later = Ticket.find(ticket1.id)
    assert_equal('closed', ticket1_later.state.name)
    assert_not_equal(ticket1.updated_at.to_s, ticket1_later.updated_at.to_s)

    ticket2_later = Ticket.find(ticket2.id)
    assert_equal('new', ticket2_later.state.name)
    assert_equal(ticket2.updated_at.to_s, ticket2_later.updated_at.to_s)

    ticket3_later = Ticket.find(ticket3.id)
    assert_equal('open', ticket3_later.state.name)
    assert_equal(ticket3.updated_at.to_s, ticket3_later.updated_at.to_s)

    ticket4_later = Ticket.find(ticket4.id)
    assert_equal('closed', ticket4_later.state.name)
    assert_equal(ticket4.updated_at.to_s, ticket4_later.updated_at.to_s)

    ticket5_later = Ticket.find(ticket5.id)
    assert_equal('closed', ticket5_later.state.name)
    assert_not_equal(ticket5.updated_at.to_s, ticket5_later.updated_at.to_s)

    # execute jobs again
    job1.updated_at = Time.zone.now - 15.minutes
    job1.save!
    Job.run

    # verify changes on tickets
    ticket1_later_next = Ticket.find(ticket1.id)
    assert_equal('closed', ticket1_later_next.state.name)
    assert_equal(ticket1_later.updated_at.to_s, ticket1_later_next.updated_at.to_s)

    ticket2_later_next = Ticket.find(ticket2.id)
    assert_equal('new', ticket2_later_next.state.name)
    assert_equal(ticket2_later.updated_at.to_s, ticket2_later_next.updated_at.to_s)

    ticket3_later_next = Ticket.find(ticket3.id)
    assert_equal('open', ticket3_later_next.state.name)
    assert_equal(ticket3_later.updated_at.to_s, ticket3_later_next.updated_at.to_s)

    ticket4_later_next = Ticket.find(ticket4.id)
    assert_equal('closed', ticket4_later_next.state.name)
    assert_equal(ticket4_later.updated_at.to_s, ticket4_later_next.updated_at.to_s)

    ticket5_later_next = Ticket.find(ticket5.id)
    assert_equal('closed', ticket5_later_next.state.name)
    assert_equal(ticket5_later.updated_at.to_s, ticket5_later_next.updated_at.to_s)

  end

  test 'with invalid state_id' do

    # create ticket
    group1 = Group.lookup(name: 'Users')
    group2 = Group.create_or_update(
      name: 'JobTest2',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket1 = Ticket.create!(
      title: 'job test 1',
      group: group1,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      created_at: Time.zone.now - 3.days,
      updated_at: Time.zone.now - 3.days,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ticket2 = Ticket.create!(
      title: 'job test 2',
      group: group1,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      created_at: Time.zone.now - 1.day,
      created_by_id: 1,
      updated_at: Time.zone.now - 1.day,
      updated_by_id: 1,
    )

    # create jobs
    job1 = Job.create_or_update(
      name: 'Test Job1',
      timeplan: {
        days: {
          Mon: true,
          Tue: true,
          Wed: true,
          Thu: true,
          Fri: true,
          Sat: true,
          Sun: true,
        },
        hours: {
          0 => true,
          1 => true,
          2 => true,
          3 => true,
          4 => true,
          5 => true,
          6 => true,
          7 => true,
          8 => true,
          9 => true,
          10 => true,
          11 => true,
          12 => true,
          13 => true,
          14 => true,
          15 => true,
          16 => true,
          17 => true,
          18 => true,
          19 => true,
          20 => true,
          21 => true,
          22 => true,
          23 => true,
        },
        minutes: {
          0 => true,
          10 => true,
          20 => true,
          30 => true,
          40 => true,
          50 => true,
        },
      },
      condition: {
        'ticket.state_id' => { 'operator' => 'is', 'value' => '9999' },
        'ticket.created_at' => { 'operator' => 'before (relative)', 'value' => '2', 'range' => 'day' },
      },
      perform: {
        'ticket.state_id' => { 'value' => Ticket::State.lookup(name: 'closed').id.to_s }
      },
      disable_notification: true,
      last_run_at: nil,
      updated_at: Time.zone.now - 15.minutes,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(job1.executable?)
    assert(job1.in_timeplan?)
    Job.run

    # verify changes on tickets
    ticket1_later = Ticket.find(ticket1.id)
    assert_equal('new', ticket1_later.state.name)
    assert_equal(ticket1.updated_at.to_s, ticket1_later.updated_at.to_s)

    ticket2_later = Ticket.find(ticket2.id)
    assert_equal('new', ticket2_later.state.name)
    assert_equal(ticket2.updated_at.to_s, ticket2_later.updated_at.to_s)
  end

  test 'case 3' do

    # create jobs
    job1 = Job.create_or_update(
      name: 'Test Job1',
      timeplan: {
        days: {
          Mon: true,
          Tue: false,
          Wed: false,
          Thu: false,
          Fri: true,
          Sat: false,
          Sun: false,
        },
        hours: {
          0 => false,
          1 => true,
          2 => false,
          3 => false,
          4 => false,
          5 => false,
          6 => false,
          7 => false,
          8 => false,
          9 => false,
          10 => true,
          11 => false,
          12 => false,
          13 => false,
          14 => false,
          15 => false,
          16 => false,
          17 => false,
          18 => false,
          19 => false,
          20 => false,
          21 => false,
          22 => false,
          23 => false,
        },
        minutes: {
          0 => true,
          10 => false,
          20 => false,
          30 => false,
          40 => true,
          50 => false,
        },
      },
      condition: {
        'ticket.state_id' => { 'operator' => 'is', 'value' => [Ticket::State.lookup(name: 'new').id.to_s, Ticket::State.lookup(name: 'open').id.to_s] },
        'ticket.created_at' => { 'operator' => 'before (relative)', 'value' => '2', 'range' => 'day' },
      },
      perform: {
        'ticket.state_id' => { 'value' => Ticket::State.lookup(name: 'closed').id.to_s }
      },
      disable_notification: true,
      last_run_at: nil,
      active: true,
      created_by_id: 1,
      created_at: Time.zone.now,
      updated_by_id: 1,
      updated_at: Time.zone.now,
    )

    time_now = Time.zone.parse('2016-03-18 09:17:13 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-18 10:00:00 UTC', next_run_at.to_s)

    time_now = Time.zone.parse('2016-03-18 10:37:13 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-18 10:40:00 UTC', next_run_at.to_s)

    time_now = Time.zone.parse('2016-03-17 09:17:13 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-18 01:00:00 UTC', next_run_at.to_s)

    time_now = Time.zone.parse('2016-03-17 11:17:13 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-18 01:00:00 UTC', next_run_at.to_s)

    time_now = Time.zone.parse('2016-03-19 11:17:13 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-21 01:00:00 UTC', next_run_at.to_s)

    time_now = Time.zone.parse('2016-03-22 00:59:59 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-25 01:00:00 UTC', next_run_at.to_s)

    time_now = Time.zone.parse('2016-03-25 00:59:59 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-25 01:00:00 UTC', next_run_at.to_s)

    time_now = Time.zone.parse('2016-03-24 00:59:59 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-25 01:00:00 UTC', next_run_at.to_s)

    time_now = Time.zone.parse('2016-03-24 23:59:59 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-25 01:00:00 UTC', next_run_at.to_s)

    time_now = Time.zone.parse('2016-03-25 01:00:01 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-25 01:00:00 UTC', next_run_at.to_s)

    time_now = Time.zone.parse('2016-03-25 01:09:01 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-25 01:40:00 UTC', next_run_at.to_s)

    time_now = Time.zone.parse('2016-03-25 01:09:59 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-25 01:40:00 UTC', next_run_at.to_s)

    job1.last_run_at = Time.zone.parse('2016-03-18 10:00:01 UTC')
    job1.save!
    time_now = Time.zone.parse('2016-03-18 10:00:02 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-18 10:40:00 UTC', next_run_at.to_s)

    job1.last_run_at = Time.zone.parse('2016-03-18 10:40:01 UTC')
    job1.save!
    time_now = Time.zone.parse('2016-03-18 10:40:02 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-21 01:00:00 UTC', next_run_at.to_s)

  end

  test 'case 4' do

    # create jobs
    job1 = Job.create_or_update(
      name: 'Test Job1',
      timeplan: {
        days: {
          Mon: true,
          Tue: false,
          Wed: false,
          Thu: false,
          Fri: true,
          Sat: false,
          Sun: false,
        },
        hours: {
          0 => true,
          1 => false,
          2 => false,
          3 => false,
          4 => false,
          5 => false,
          6 => false,
          7 => false,
          8 => false,
          9 => false,
          10 => true,
          11 => false,
          12 => false,
          13 => false,
          14 => false,
          15 => false,
          16 => false,
          17 => false,
          18 => false,
          19 => false,
          20 => false,
          21 => false,
          22 => false,
          23 => false,
        },
        minutes: {
          0 => true,
          10 => false,
          20 => false,
          30 => false,
          40 => true,
          50 => false,
        },
      },
      condition: {
        'ticket.state_id' => { 'operator' => 'is', 'value' => [Ticket::State.lookup(name: 'new').id.to_s, Ticket::State.lookup(name: 'open').id.to_s] },
        'ticket.created_at' => { 'operator' => 'before (relative)', 'value' => '2', 'range' => 'day' },
      },
      perform: {
        'ticket.state_id' => { 'value' => Ticket::State.lookup(name: 'closed').id.to_s }
      },
      disable_notification: true,
      last_run_at: nil,
      active: true,
      created_by_id: 1,
      created_at: Time.zone.now,
      updated_by_id: 1,
      updated_at: Time.zone.now,
    )

    time_now = Time.zone.parse('2016-03-17 23:51:23 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-18 00:00:00 UTC', next_run_at.to_s)

    job1.last_run_at = Time.zone.parse('2016-03-17 23:45:01 UTC')
    job1.save!
    time_now = Time.zone.parse('2016-03-17 23:51:23 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-18 00:00:00 UTC', next_run_at.to_s)

    job1.last_run_at = Time.zone.parse('2016-03-17 23:59:01 UTC')
    job1.save!
    time_now = Time.zone.parse('2016-03-17 23:59:23 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-18 00:40:00 UTC', next_run_at.to_s)

    time_now = Time.zone.parse('2016-03-17 23:59:23 UTC')
    assert_not(job1.in_timeplan?(time_now))

    time_now = Time.zone.parse('2016-03-18 00:01:23 UTC')
    assert(job1.in_timeplan?(time_now))

  end

  test 'check next_run_at' do

    job1 = Job.create_or_update(
      name: 'Test Job1',
      timeplan: {
        days: {
          Mon: true,
          Tue: false,
          Wed: false,
          Thu: false,
          Fri: false,
          Sat: false,
          Sun: false,
        },
        hours: {
          '0' => true,
          '1' => false,
          '2' => false,
          '3' => false,
          '4' => false,
          '5' => false,
          '6' => false,
          '7' => false,
          '8' => false,
          '9' => false,
          '10' => false,
          '11' => false,
          '12' => false,
          '13' => false,
          '14' => false,
          '15' => false,
          '16' => false,
          '17' => false,
          '18' => false,
          '19' => false,
          '20' => false,
          '21' => false,
          '22' => false,
          '23' => false,
        },
        minutes: {
          '0' => true,
          '10' => false,
          '20' => false,
          '30' => false,
          '40' => false,
          '50' => false,
        },
      },
      condition: {
        'ticket.state_id' => { 'operator' => 'is', 'value' => [Ticket::State.lookup(name: 'new').id.to_s, Ticket::State.lookup(name: 'open').id.to_s] },
        'ticket.created_at' => { 'operator' => 'before (relative)', 'value' => '2', 'range' => 'day' },
      },
      perform: {
        'ticket.state_id' => { 'value' => Ticket::State.lookup(name: 'closed').id.to_s }
      },
      disable_notification: true,
      last_run_at: nil,
      active: true,
      created_by_id: 1,
      created_at: Time.zone.now,
      updated_by_id: 1,
      updated_at: Time.zone.now,
    )

    time_now = Time.zone.parse('2016-03-17 23:51:23 UTC')
    next_run_at = job1.next_run_at_calculate(time_now)
    assert_equal('2016-03-21 00:00:00 UTC', next_run_at.to_s)
  end

  test 'update next run at' do

    travel_to Time.zone.local(2017, 11, 10, 22, 0o4, 44)

    job1 = Job.create_or_update(
      name: 'Test Job1',
      timeplan: {
        days: {
          Mon: false,
          Tue: false,
          Wed: false,
          Thu: false,
          Fri: false,
          Sat: true,
          Sun: false,
        },
        hours: {
          '0' => false,
          '1' => false,
          '2' => false,
          '3' => false,
          '4' => false,
          '5' => false,
          '6' => false,
          '7' => false,
          '8' => false,
          '9' => false,
          '10' => false,
          '11' => false,
          '12' => false,
          '13' => false,
          '14' => false,
          '15' => false,
          '16' => false,
          '17' => false,
          '18' => false,
          '19' => false,
          '20' => false,
          '21' => false,
          '22' => false,
          '23' => true,
        },
        minutes: {
          '0' => true,
          '10' => false,
          '20' => false,
          '30' => false,
          '40' => false,
          '50' => false,
        },
      },
      condition: {
        'ticket.state_id' => { 'operator' => 'is', 'value' => [Ticket::State.lookup(name: 'new').id.to_s, Ticket::State.lookup(name: 'open').id.to_s] },
      },
      perform: {
        'ticket.action' => { 'value' => 'delete' },
      },
      disable_notification: true,
      last_run_at: nil,
      active: true,
      created_by_id: 1,
      created_at: Time.zone.now,
      updated_by_id: 1,
      updated_at: Time.zone.now,
    )

    assert_equal('2017-11-11 23:00:00 UTC', job1.next_run_at.to_s)
    assert_not(job1.last_run_at)

    travel_to Time.zone.local(2017, 11, 16, 22, 0o4, 44)

    Job.run

    job1.reload

    assert_equal('2017-11-18 23:00:00 UTC', job1.next_run_at.to_s)
    assert_not(job1.last_run_at)

    travel_back

  end

  test 'execute on certain time' do

    travel_to Time.zone.local(2017, 11, 16, 22, 0o4, 44)

    group1 = Group.lookup(name: 'Users')
    ticket1 = Ticket.create!(
      title: 'job test 1',
      group: group1,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      created_by_id: 1,
      updated_by_id: 1,
    )
    ticket2 = Ticket.create!(
      title: 'job test 2',
      group: group1,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      created_by_id: 1,
      updated_by_id: 1,
    )

    job1 = Job.create_or_update(
      name: 'Test Job1',
      timeplan: {
        days: {
          Mon: false,
          Tue: false,
          Wed: false,
          Thu: true,
          Fri: false,
          Sat: false,
          Sun: false,
        },
        hours: {
          '0' => false,
          '1' => false,
          '2' => false,
          '3' => false,
          '4' => false,
          '5' => false,
          '6' => false,
          '7' => false,
          '8' => false,
          '9' => false,
          '10' => false,
          '11' => false,
          '12' => false,
          '13' => false,
          '14' => false,
          '15' => false,
          '16' => false,
          '17' => false,
          '18' => false,
          '19' => false,
          '20' => false,
          '21' => false,
          '22' => false,
          '23' => true,
        },
        minutes: {
          '0' => true,
          '10' => false,
          '20' => false,
          '30' => false,
          '40' => false,
          '50' => false,
        },
      },
      condition: {
        'ticket.state_id' => { 'operator' => 'is', 'value' => [Ticket::State.lookup(name: 'new').id.to_s, Ticket::State.lookup(name: 'open').id.to_s] },
      },
      perform: {
        'ticket.action' => { 'value' => 'delete' },
      },
      disable_notification: true,
      last_run_at: nil,
      active: true,
      created_by_id: 1,
      created_at: Time.zone.now,
      updated_by_id: 1,
      updated_at: Time.zone.now,
    )
    Job.run

    assert(Ticket.find_by(id: ticket1.id))
    assert(Ticket.find_by(id: ticket2.id))

    travel_to Time.zone.local(2017, 11, 16, 23, 0o4, 44)

    Job.run

    assert_not(Ticket.find_by(id: ticket1.id))
    assert_not(Ticket.find_by(id: ticket2.id))

    travel_back
  end

  test 'delete based on tag' do

    # create ticket
    group1 = Group.lookup(name: 'Users')
    group2 = Group.create_or_update(
      name: 'JobTest2',
      updated_by_id: 1,
      created_by_id: 1,
    )
    ticket1 = Ticket.create!(
      title: 'job test 1',
      group: group1,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      created_at: Time.zone.now - 3.days,
      updated_at: Time.zone.now - 3.days,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ticket1.tag_add('spam', 1)
    ticket1.tag_add('test1 ', 1)
    ticket2 = Ticket.create!(
      title: 'job test 2',
      group: group1,
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      created_at: Time.zone.now - 1.day,
      created_by_id: 1,
      updated_at: Time.zone.now - 1.day,
      updated_by_id: 1,
    )

    job1 = Job.create_or_update(
      name: 'Test Job1',
      timeplan: {
        days: {
          Mon: true,
          Tue: true,
          Wed: true,
          Thu: true,
          Fri: true,
          Sat: true,
          Sun: true,
        },
        hours: {
          0 => true,
          1 => true,
          2 => true,
          3 => true,
          4 => true,
          5 => true,
          6 => true,
          7 => true,
          8 => true,
          9 => true,
          10 => true,
          11 => true,
          12 => true,
          13 => true,
          14 => true,
          15 => true,
          16 => true,
          17 => true,
          18 => true,
          19 => true,
          20 => true,
          21 => true,
          22 => true,
          23 => true,
        },
        minutes: {
          0 => true,
          10 => true,
          20 => true,
          30 => true,
          40 => true,
          50 => true,
        },
      },
      condition: {
        'ticket.tags' => { 'operator' => 'contains one', 'value' => 'spam' },
      },
      perform: {
        'ticket.action' => { 'value' => 'delete' },
      },
      disable_notification: true,
      last_run_at: nil,
      updated_at: Time.zone.now - 15.minutes,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(job1.executable?)
    assert(job1.in_timeplan?)
    Job.run

    assert_not(Ticket.find_by(id: ticket1.id))
    assert(Ticket.find_by(id: ticket2.id))

  end

end
