# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'integration_test_helper'

class ObjectManagerTest < ActiveSupport::TestCase

  test 'a object manager' do

    list_objects = ObjectManager.list_objects
    assert_equal(%w[Ticket TicketArticle User Organization Group], list_objects)

    list_objects = ObjectManager.list_frontend_objects
    assert_equal(%w[Ticket User Organization Group], list_objects)

    assert_equal(false, ObjectManager::Attribute.pending_migration?)

    # create simple attribute
    attribute1 = ObjectManager::Attribute.add(
      object:        'Ticket',
      name:          'test1',
      display:       'Test 1',
      data_type:     'input',
      data_option:   {
        maxlength: 200,
        type:      'text',
        null:      false,
      },
      active:        true,
      screens:       {},
      position:      20,
      created_by_id: 1,
      updated_by_id: 1,
      editable:      false,
      to_migrate:    false,
    )
    assert(attribute1)
    assert_equal('test1', attribute1.name)
    assert_equal(true, attribute1.editable)
    assert_equal(true, attribute1.to_create)
    assert_equal(true, attribute1.to_migrate)
    assert_equal(false, attribute1.to_delete)
    assert_equal(true, ObjectManager::Attribute.pending_migration?)

    attribute1 = ObjectManager::Attribute.get(
      object: 'Ticket',
      name:   'test1',
    )
    assert(attribute1)
    assert_equal('test1', attribute1.name)
    assert_equal(true, attribute1.editable)
    assert_equal(true, attribute1.to_create)
    assert_equal(true, attribute1.to_migrate)
    assert_equal(false, attribute1.to_delete)
    assert_equal(true, ObjectManager::Attribute.pending_migration?)

    # delete attribute without execute migrations
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name:   'test1',
    )

    attribute1 = ObjectManager::Attribute.get(
      object: 'Ticket',
      name:   'test1',
    )
    assert_not(attribute1)

    assert_equal(false, ObjectManager::Attribute.pending_migration?)
    assert(ObjectManager::Attribute.migration_execute)

    attribute1 = ObjectManager::Attribute.get(
      object: 'Ticket',
      name:   'test1',
    )
    assert_not(attribute1)

    # create invalid attributes
    assert_raises(ActiveRecord::RecordInvalid) do
      ObjectManager::Attribute.add(
        object:        'Ticket',
        name:          'test2_id',
        display:       'Test 2 with id',
        data_type:     'input',
        data_option:   {
          maxlength: 200,
          type:      'text',
          null:      false,
        },
        active:        true,
        screens:       {},
        position:      20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end
    assert_raises(ActiveRecord::RecordInvalid) do
      ObjectManager::Attribute.add(
        object:        'Ticket',
        name:          'test3_ids',
        display:       'Test 3 with id',
        data_type:     'input',
        data_option:   {
          maxlength: 200,
          type:      'text',
          null:      false,
        },
        active:        true,
        screens:       {},
        position:      20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end
    assert_raises(ActiveRecord::RecordInvalid) do
      ObjectManager::Attribute.add(
        object:        'Ticket',
        name:          'test4',
        display:       'Test 4 with missing data_option[:type]',
        data_type:     'input',
        data_option:   {
          maxlength: 200,
          null:      false,
        },
        active:        true,
        screens:       {},
        position:      20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end

    attribute5 = ObjectManager::Attribute.add(
      object:        'Ticket',
      name:          'test5',
      display:       'Test 5',
      data_type:     'boolean',
      data_option:   {
        default: true,
        options: {
          true:  'Yes',
          false: 'No',
        },
        null:    false,
      },
      active:        true,
      screens:       {},
      position:      20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    assert(attribute5)
    assert_equal('test5', attribute5.name)
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name:   'test5',
    )

    assert_raises(ActiveRecord::RecordInvalid) do
      ObjectManager::Attribute.add(
        object:        'Ticket',
        name:          'test6',
        display:       'Test 6',
        data_type:     'boolean',
        data_option:   {
          options: {
            true:  'Yes',
            false: 'No',
          },
          null:    false,
        },
        active:        true,
        screens:       {},
        position:      20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end

    attribute7 = ObjectManager::Attribute.add(
      object:        'Ticket',
      name:          'test7',
      display:       'Test 7',
      data_type:     'select',
      data_option:   {
        default: 1,
        options: {
          '1' => 'aa',
          '2' => 'bb',
        },
        null:    false,
      },
      active:        true,
      screens:       {},
      position:      20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    assert(attribute7)
    assert_equal('test7', attribute7.name)
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name:   'test7',
    )

    assert_raises(ActiveRecord::RecordInvalid) do
      ObjectManager::Attribute.add(
        object:        'Ticket',
        name:          'test8',
        display:       'Test 8',
        data_type:     'select',
        data_option:   {
          default: 1,
          null:    false,
        },
        active:        true,
        screens:       {},
        position:      20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end

    attribute9 = ObjectManager::Attribute.add(
      object:        'Ticket',
      name:          'test9',
      display:       'Test 9',
      data_type:     'datetime',
      data_option:   {
        future: true,
        past:   false,
        diff:   24,
        null:   true,
      },
      active:        true,
      screens:       {},
      position:      20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    assert(attribute9)
    assert_equal('test9', attribute9.name)
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name:   'test9',
    )

    assert_raises(ActiveRecord::RecordInvalid) do
      ObjectManager::Attribute.add(
        object:        'Ticket',
        name:          'test10',
        display:       'Test 10',
        data_type:     'datetime',
        data_option:   {
          past: false,
          diff: 24,
          null: true,
        },
        active:        true,
        screens:       {},
        position:      20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end

    attribute11 = ObjectManager::Attribute.add(
      object:        'Ticket',
      name:          'test11',
      display:       'Test 11',
      data_type:     'date',
      data_option:   {
        future: true,
        past:   false,
        diff:   24,
        null:   true,
      },
      active:        true,
      screens:       {},
      position:      20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    assert(attribute11)
    assert_equal('test11', attribute11.name)
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name:   'test11',
    )
    assert_equal(false, ObjectManager::Attribute.pending_migration?)

    assert_raises(ActiveRecord::RecordInvalid) do
      ObjectManager::Attribute.add(
        object:        'Ticket',
        name:          'test13|',
        display:       'Test 13',
        data_type:     'date',
        data_option:   {
          future: true,
          past:   false,
          diff:   24,
          null:   true,
        },
        active:        true,
        screens:       {},
        position:      20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end
    assert_equal(false, ObjectManager::Attribute.pending_migration?)

    assert_raises(ActiveRecord::RecordInvalid) do
      ObjectManager::Attribute.add(
        object:        'Ticket',
        name:          'test14!',
        display:       'Test 14',
        data_type:     'date',
        data_option:   {
          future: true,
          past:   false,
          diff:   24,
          null:   true,
        },
        active:        true,
        screens:       {},
        position:      20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end
    assert_equal(false, ObjectManager::Attribute.pending_migration?)

    assert_raises(ActiveRecord::RecordInvalid) do
      ObjectManager::Attribute.add(
        object:        'Ticket',
        name:          'test15ä',
        display:       'Test 15',
        data_type:     'date',
        data_option:   {
          future: true,
          past:   false,
          diff:   24,
          null:   true,
        },
        active:        true,
        screens:       {},
        position:      20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end
    assert_equal(false, ObjectManager::Attribute.pending_migration?)

    # Test case #16 invalidated after callback added to set default #data_option[:null] value

    assert_raises(ActiveRecord::RecordInvalid) do
      ObjectManager::Attribute.add(
        object:        'Ticket',
        name:          'test17',
        display:       'Test 17',
        data_type:     'integer',
        data_option:   {
          default: 2,
          min:     1,
        },
        active:        true,
        screens:       {},
        position:      20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end
    assert_equal(false, ObjectManager::Attribute.pending_migration?)

    assert_raises(ActiveRecord::RecordInvalid) do
      ObjectManager::Attribute.add(
        object:        'Ticket',
        name:          'delete',
        display:       'Test 18',
        data_type:     'input',
        data_option:   {
          maxlength: 200,
          type:      'text',
          null:      false,
        },
        active:        true,
        screens:       {},
        position:      20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end
    assert_equal(false, ObjectManager::Attribute.pending_migration?)

    attribute_count = ObjectManager::Attribute.count
    assert_raises(ActiveRecord::RecordInvalid) do
      ObjectManager::Attribute.add(
        object:        'Ticket',
        name:          'updated_at',
        display:       'Update Time',
        data_type:     'datetime',
        data_option:   {
          future: true,
          past:   true,
          diff:   24,
          null:   true,
        },
        active:        true,
        screens:       {},
        position:      20,
        created_by_id: 1,
        updated_by_id: 1,
      )
      assert_equal(false, ObjectManager::Attribute.pending_migration?)
    end
    assert_equal(attribute_count, ObjectManager::Attribute.count)

    assert_raises(ActiveRecord::RecordInvalid) do
      ObjectManager::Attribute.add(
        object:        'Ticket',
        name:          'updated_AT',
        display:       'Update Time',
        data_type:     'datetime',
        data_option:   {
          future: true,
          past:   true,
          diff:   24,
          null:   true,
        },
        active:        true,
        screens:       {},
        position:      20,
        created_by_id: 1,
        updated_by_id: 1,
      )
      assert_equal(false, ObjectManager::Attribute.pending_migration?)
    end

    assert_equal(attribute_count, ObjectManager::Attribute.count)

  end

  test 'b object manager attribute' do

    assert_equal(false, ObjectManager::Attribute.pending_migration?)
    assert_equal(0, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(0, ObjectManager::Attribute.migrations.count)

    attribute1 = ObjectManager::Attribute.add(
      object:        'Ticket',
      name:          'attribute1',
      display:       'Attribute 1',
      data_type:     'input',
      data_option:   {
        maxlength: 200,
        type:      'text',
        null:      true,
      },
      active:        true,
      screens:       {},
      position:      20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    assert(attribute1)

    assert_equal(true, ObjectManager::Attribute.pending_migration?)
    assert_equal(1, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(1, ObjectManager::Attribute.migrations.count)

    # execute migrations
    assert(ObjectManager::Attribute.migration_execute)

    assert_equal(false, ObjectManager::Attribute.pending_migration?)
    assert_equal(0, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(0, ObjectManager::Attribute.migrations.count)

    # create example ticket
    ticket1 = Ticket.create(
      title:         'some attribute test1',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      attribute1:    'some attribute text',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert('ticket1 created', ticket1)

    assert_equal('some attribute test1', ticket1.title)
    assert_equal('Users', ticket1.group.name)
    assert_equal('new', ticket1.state.name)
    assert_equal('some attribute text', ticket1.attribute1)

    # add additional attributes
    ObjectManager::Attribute.add(
      object:        'Ticket',
      name:          'attribute2',
      display:       'Attribute 2',
      data_type:     'select',
      data_option:   {
        default: '2',
        options: {
          '1' => 'aa',
          '2' => 'bb',
        },
        null:    true,
      },
      active:        true,
      screens:       {},
      position:      20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ObjectManager::Attribute.add(
      object:        'Ticket',
      name:          'attribute3',
      display:       'Attribute 3',
      data_type:     'datetime',
      data_option:   {
        future: true,
        past:   false,
        diff:   24,
        null:   true,
      },
      active:        true,
      screens:       {},
      position:      20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ObjectManager::Attribute.add(
      object:        'Ticket',
      name:          'attribute4',
      display:       'Attribute 4',
      data_type:     'datetime',
      data_option:   {
        future: true,
        past:   false,
        diff:   24,
        null:   true,
      },
      active:        true,
      screens:       {},
      position:      20,
      created_by_id: 1,
      updated_by_id: 1,
    )

    # execute migrations
    assert_equal(true, ObjectManager::Attribute.pending_migration?)
    assert(ObjectManager::Attribute.migration_execute)
    assert_equal(false, ObjectManager::Attribute.pending_migration?)

    # create example ticket
    ticket2 = Ticket.create(
      title:         'some attribute test2',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      attribute1:    'some attribute text',
      attribute2:    '1',
      attribute3:    Time.zone.parse('2016-05-12 00:59:59 UTC'),
      attribute4:    Date.parse('2016-05-11'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert('ticket2 created', ticket2)

    assert_equal('some attribute test2', ticket2.title)
    assert_equal('Users', ticket2.group.name)
    assert_equal('new', ticket2.state.name)
    assert_equal('some attribute text', ticket2.attribute1)
    assert_equal('1', ticket2.attribute2)
    assert_equal(Time.zone.parse('2016-05-12 00:59:59 UTC'), ticket2.attribute3)
    assert_equal(Date.parse('2016-05-11'), ticket2.attribute4)

    # update data_option null -> to_config
    attribute1 = ObjectManager::Attribute.add(
      object:        'Ticket',
      name:          'attribute1',
      display:       'Attribute 1',
      data_type:     'input',
      data_option:   {
        maxlength: 200,
        type:      'text',
        null:      false,
      },
      active:        true,
      screens:       {},
      position:      20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    assert(attribute1)

    assert_equal(true, ObjectManager::Attribute.pending_migration?)
    assert_equal(0, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(1, ObjectManager::Attribute.where(to_config: true).count)
    assert_equal(1, ObjectManager::Attribute.migrations.count)

    # execute migrations
    assert(ObjectManager::Attribute.migration_execute)

    assert_equal(false, ObjectManager::Attribute.pending_migration?)
    assert_equal(0, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(0, ObjectManager::Attribute.where(to_config: true).count)
    assert_equal(0, ObjectManager::Attribute.migrations.count)

    # update data_option maxlength -> to_config && to_migrate
    attribute1 = ObjectManager::Attribute.add(
      object:        'Ticket',
      name:          'attribute1',
      display:       'Attribute 1',
      data_type:     'input',
      data_option:   {
        maxlength: 250,
        type:      'text',
        null:      false,
      },
      active:        true,
      screens:       {},
      position:      20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    assert(attribute1)

    assert_equal(true, ObjectManager::Attribute.pending_migration?)
    assert_equal(1, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(1, ObjectManager::Attribute.where(to_config: true).count)
    assert_equal(1, ObjectManager::Attribute.migrations.count)

    # execute migrations
    assert(ObjectManager::Attribute.migration_execute)

    assert_equal(false, ObjectManager::Attribute.pending_migration?)
    assert_equal(0, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(0, ObjectManager::Attribute.where(to_config: true).count)
    assert_equal(0, ObjectManager::Attribute.migrations.count)

    # remove attribute
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name:   'attribute1',
    )
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name:   'attribute2',
    )
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name:   'attribute3',
    )
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name:   'attribute4',
    )
    assert(ObjectManager::Attribute.migration_execute)

    ticket2 = Ticket.find(ticket2.id)
    assert('ticket2 created', ticket2)

    assert_equal('some attribute test2', ticket2.title)
    assert_equal('Users', ticket2.group.name)
    assert_equal('new', ticket2.state.name)
    assert_nil(ticket2[:attribute1])
    assert_nil(ticket2[:attribute2])
    assert_nil(ticket2[:attribute3])
    assert_nil(ticket2[:attribute4])

  end

  test 'c object manager attribute - certain names' do

    assert_equal(false, ObjectManager::Attribute.pending_migration?)
    assert_equal(0, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(0, ObjectManager::Attribute.migrations.count)

    attribute1 = ObjectManager::Attribute.add(
      object:        'Ticket',
      name:          '1_a_anfrage_status',
      display:       '1_a_anfrage_status',
      data_type:     'input',
      data_option:   {
        maxlength: 200,
        type:      'text',
        null:      true,
      },
      active:        true,
      screens:       {},
      position:      20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    assert(attribute1)

    assert_equal(true, ObjectManager::Attribute.pending_migration?)
    assert_equal(1, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(1, ObjectManager::Attribute.migrations.count)

    # execute migrations
    assert(ObjectManager::Attribute.migration_execute)

    assert_equal(false, ObjectManager::Attribute.pending_migration?)
    assert_equal(0, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(0, ObjectManager::Attribute.migrations.count)

    # create example ticket
    ticket1 = Ticket.create!(
      title:                'some attribute test3',
      group:                Group.lookup(name: 'Users'),
      customer_id:          2,
      state:                Ticket::State.lookup(name: 'new'),
      priority:             Ticket::Priority.lookup(name: '2 normal'),
      '1_a_anfrage_status': 'some attribute text',
      updated_by_id:        1,
      created_by_id:        1,
    )
    assert('ticket1 created', ticket1)

    assert_equal('some attribute test3', ticket1.title)
    assert_equal('Users', ticket1.group.name)
    assert_equal('new', ticket1.state.name)
    assert_equal('some attribute text', ticket1['1_a_anfrage_status'])

    condition = {
      'ticket.title' => {
        operator: 'is',
        value:    'some attribute test3',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10)
    assert_equal(ticket_count, 1)
    assert_equal(tickets[0].id, ticket1.id)

    condition = {
      'ticket.1_a_anfrage_status' => {
        operator: 'is',
        value:    'some attribute text',
      },
    }
    ticket_count, tickets = Ticket.selectors(condition, limit: 10)
    assert_equal(ticket_count, 1)
    assert_equal(tickets[0].id, ticket1.id)

    agent1 = User.create_or_update(
      login:         'agent1@example.com',
      firstname:     'Notification',
      lastname:      'Agent1',
      email:         'agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         Role.where(name: 'Agent'),
      groups:        Group.all,
      updated_by_id: 1,
      created_by_id: 1,
    )

    Overview.create!(
      name:          'Overview1',
      link:          'my_overview',
      roles:         Role.all,
      condition:     {
        'ticket.1_a_anfrage_status' => {
          operator: 'is',
          value:    'some attribute text',
        },
      },
      order:         {
        by:        '1_a_anfrage_status',
        direction: 'DESC',
      },
      group_by:      '1_a_anfrage_status',
      view:          {
        d:                 %w[title customer state created_at],
        s:                 %w[number title customer state created_at],
        m:                 %w[number title customer state created_at],
        view_mode_default: 's',
      },
      prio:          1,
      updated_by_id: 1,
      created_by_id: 1,
    )

    result = Ticket::Overviews.index(agent1)

    overview = nil
    result.each do |local_overview|
      next if local_overview[:overview][:name] != 'Overview1'

      overview = local_overview
      break
    end
    assert(overview)

    assert_equal(1, overview[:tickets].count)
    assert_equal(1, overview[:count])
    assert_equal(ticket1.id, overview[:tickets][0][:id])
  end

  test 'd object manager attribute - update attribute type' do

    attribute1 = ObjectManager::Attribute.add(
      object:        'Ticket',
      name:          'example_1',
      display:       'example_1',
      data_type:     'input',
      data_option:   {
        default:   '',
        maxlength: 200,
        type:      'text',
        null:      true,
        options:   {},
      },
      active:        true,
      screens:       {},
      position:      20,
      created_by_id: 1,
      updated_by_id: 1,
    )

    assert_equal(true, ObjectManager::Attribute.pending_migration?)
    assert_equal(1, ObjectManager::Attribute.migrations.count)

    assert(ObjectManager::Attribute.migration_execute)

    assert_raises(ActiveRecord::RecordInvalid) do
      ObjectManager::Attribute.add(
        object:        'Ticket',
        name:          'example_1',
        display:       'example_1',
        data_type:     'boolean',
        data_option:   {
          default: true,
          options: {
            true:  'Yes',
            false: 'No',
          },
          null:    false,
        },
        active:        true,
        screens:       {},
        position:      200,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end

    attribute2 = ObjectManager::Attribute.add(
      object:        'Ticket',
      name:          'example_1',
      display:       'example_1',
      data_type:     'select',
      data_option:   {
        default:   '',
        maxlength: 200,
        type:      'text',
        null:      true,
        options:   {
          aa: 'aa',
          bb: 'bb',
        },
      },
      active:        true,
      screens:       {},
      position:      20,
      created_by_id: 1,
      updated_by_id: 1,
    )

    assert_equal(attribute1.id, attribute2.id)
    assert_equal(true, ObjectManager::Attribute.pending_migration?)
    assert_equal(1, ObjectManager::Attribute.migrations.count)

    assert(ObjectManager::Attribute.migration_execute)

  end

  test 'overview any owner / no owner is set' do

    group = Group.create!(
      name:          'OverviewTest',
      updated_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Agent')
    agent1 = User.create!(
      login:         'ticket-overview-agent1@example.com',
      firstname:     'Overview',
      lastname:      'Agent1',
      email:         'ticket-overview-agent1@example.com',
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        [group],
      updated_at:    '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object:        'Ticket',
      name:          'watcher',
      display:       'watcher',
      data_type:     'select',
      data_option:   {
        default:   '',
        maxlength: 200,
        type:      'text',
        null:      true,
        options:   {
          aa: 'agent a',
          bb: 'agent b',
          cc: 'agent c',
        },
      },
      active:        true,
      screens:       {},
      position:      20,
      created_by_id: 1,
      updated_by_id: 1,
    )

    assert_equal(true, ObjectManager::Attribute.pending_migration?)
    assert_equal(1, ObjectManager::Attribute.migrations.count)

    assert(ObjectManager::Attribute.migration_execute)

    Ticket.destroy_all
    Overview.destroy_all

    UserInfo.current_user_id = 1
    overview_role = Role.find_by(name: 'Agent')
    overview1 = Overview.create!(
      name:      'not watched',
      prio:      1000,
      role_ids:  [overview_role.id],
      condition: {
        'ticket.watcher' => {
          operator: 'is',
          value:    '',
        },
      },
      order:     {
        by:        'created_at',
        direction: 'ASC',
      },
      view:      {
        d:                 %w[title customer group created_at],
        s:                 %w[title customer group created_at],
        m:                 %w[number title customer group created_at],
        view_mode_default: 's',
      },
    )

    overview2 = Overview.create!(
      name:      'not watched by somebody',
      prio:      2000,
      role_ids:  [overview_role.id],
      condition: {
        'ticket.watcher' => {
          operator: 'is not',
          value:    '',
        },
      },
      order:     {
        by:        'created_at',
        direction: 'ASC',
      },
      view:      {
        d:                 %w[title customer group created_at],
        s:                 %w[title customer group created_at],
        m:                 %w[number title customer group created_at],
        view_mode_default: 's',
      },
    )

    overview3 = Overview.create!(
      name:      'not watched as array',
      prio:      3000,
      role_ids:  [overview_role.id],
      condition: {
        'ticket.watcher' => {
          operator: 'is',
          value:    [''],
        },
      },
      order:     {
        by:        'created_at',
        direction: 'ASC',
      },
      view:      {
        d:                 %w[title customer group created_at],
        s:                 %w[title customer group created_at],
        m:                 %w[number title customer group created_at],
        view_mode_default: 's',
      },
    )

    overview4 = Overview.create!(
      name:      'not watched by somebody as array',
      prio:      4000,
      role_ids:  [overview_role.id],
      condition: {
        'ticket.watcher' => {
          operator: 'is not',
          value:    [''],
        },
      },
      order:     {
        by:        'created_at',
        direction: 'ASC',
      },
      view:      {
        d:                 %w[title customer group created_at],
        s:                 %w[title customer group created_at],
        m:                 %w[number title customer group created_at],
        view_mode_default: 's',
      },
    )

    overview5 = Overview.create!(
      name:      'watched by aa',
      prio:      5000,
      role_ids:  [overview_role.id],
      condition: {
        'ticket.watcher' => {
          operator: 'is',
          value:    'aa',
        },
      },
      order:     {
        by:        'created_at',
        direction: 'ASC',
      },
      view:      {
        d:                 %w[title customer group created_at],
        s:                 %w[title customer group created_at],
        m:                 %w[number title customer group created_at],
        view_mode_default: 's',
      },
    )

    overview6 = Overview.create!(
      name:      'not watched by aa',
      prio:      6000,
      role_ids:  [overview_role.id],
      condition: {
        'ticket.watcher' => {
          operator: 'is not',
          value:    'aa',
        },
      },
      order:     {
        by:        'created_at',
        direction: 'ASC',
      },
      view:      {
        d:                 %w[title customer group created_at],
        s:                 %w[title customer group created_at],
        m:                 %w[number title customer group created_at],
        view_mode_default: 's',
      },
    )

    overview7 = Overview.create!(
      name:      'watched by aa array',
      prio:      7000,
      role_ids:  [overview_role.id],
      condition: {
        'ticket.watcher' => {
          operator: 'is',
          value:    ['aa'],
        },
      },
      order:     {
        by:        'created_at',
        direction: 'ASC',
      },
      view:      {
        d:                 %w[title customer group created_at],
        s:                 %w[title customer group created_at],
        m:                 %w[number title customer group created_at],
        view_mode_default: 's',
      },
    )

    overview8 = Overview.create!(
      name:      'not watched by aa array',
      prio:      8000,
      role_ids:  [overview_role.id],
      condition: {
        'ticket.watcher' => {
          operator: 'is not',
          value:    ['aa'],
        },
      },
      order:     {
        by:        'created_at',
        direction: 'ASC',
      },
      view:      {
        d:                 %w[title customer group created_at],
        s:                 %w[title customer group created_at],
        m:                 %w[number title customer group created_at],
        view_mode_default: 's',
      },
    )

    ticket1 = Ticket.create!(
      title:       'overview test 1',
      group:       Group.lookup(name: 'OverviewTest'),
      customer_id: 2,
      owner_id:    1,
      watcher:     '',
      state:       Ticket::State.lookup(name: 'new'),
      priority:    Ticket::Priority.lookup(name: '2 normal'),
    )

    travel 2.seconds
    ticket2 = Ticket.create!(
      title:       'overview test 2',
      group:       Group.lookup(name: 'OverviewTest'),
      customer_id: 2,
      owner_id:    nil,
      watcher:     nil,
      state:       Ticket::State.lookup(name: 'new'),
      priority:    Ticket::Priority.lookup(name: '2 normal'),
    )

    travel 2.seconds
    ticket3 = Ticket.create!(
      title:       'overview test 3',
      group:       Group.lookup(name: 'OverviewTest'),
      customer_id: 2,
      owner_id:    agent1.id,
      watcher:     'aa',
      state:       Ticket::State.lookup(name: 'new'),
      priority:    Ticket::Priority.lookup(name: '2 normal'),
    )

    result = Ticket::Overviews.index(agent1)
    assert_equal(result[0][:overview][:id], overview1.id)
    assert_equal(result[0][:overview][:name], 'not watched')
    assert_equal(result[0][:overview][:view], 'not_watched')
    assert_equal(result[0][:tickets].class, Array)
    assert_equal(result[0][:tickets][0][:id], ticket1.id)
    assert_equal(result[0][:tickets][1][:id], ticket2.id)
    assert_equal(result[0][:count], 2)

    assert_equal(result[1][:overview][:id], overview2.id)
    assert_equal(result[1][:overview][:name], 'not watched by somebody')
    assert_equal(result[1][:overview][:view], 'not_watched_by_somebody')
    assert_equal(result[1][:tickets].class, Array)
    assert_equal(result[1][:tickets][0][:id], ticket3.id)
    assert_equal(result[1][:count], 1)

    assert_equal(result[2][:overview][:id], overview3.id)
    assert_equal(result[2][:overview][:name], 'not watched as array')
    assert_equal(result[2][:overview][:view], 'not_watched_as_array')
    assert_equal(result[2][:tickets].class, Array)
    assert_equal(result[2][:tickets][0][:id], ticket1.id)
    assert_equal(result[2][:tickets][1][:id], ticket2.id)
    assert_equal(result[2][:count], 2)

    assert_equal(result[3][:overview][:id], overview4.id)
    assert_equal(result[3][:overview][:name], 'not watched by somebody as array')
    assert_equal(result[3][:overview][:view], 'not_watched_by_somebody_as_array')
    assert_equal(result[3][:tickets].class, Array)
    assert_equal(result[3][:tickets][0][:id], ticket3.id)
    assert_equal(result[3][:count], 1)

    assert_equal(result[4][:overview][:id], overview5.id)
    assert_equal(result[4][:overview][:name], 'watched by aa')
    assert_equal(result[4][:overview][:view], 'watched_by_aa')
    assert_equal(result[4][:tickets].class, Array)
    assert_equal(result[4][:tickets][0][:id], ticket3.id)
    assert_equal(result[4][:count], 1)

    assert_equal(result[5][:overview][:id], overview6.id)
    assert_equal(result[5][:overview][:name], 'not watched by aa')
    assert_equal(result[5][:overview][:view], 'not_watched_by_aa')
    assert_equal(result[5][:tickets].class, Array)
    assert_equal(result[5][:tickets][0][:id], ticket1.id)
    assert_equal(result[5][:tickets][1][:id], ticket2.id)
    assert_equal(result[5][:count], 2)

    assert_equal(result[6][:overview][:id], overview7.id)
    assert_equal(result[6][:overview][:name], 'watched by aa array')
    assert_equal(result[6][:overview][:view], 'watched_by_aa_array')
    assert_equal(result[6][:tickets].class, Array)
    assert_equal(result[6][:tickets][0][:id], ticket3.id)
    assert_equal(result[6][:count], 1)

    assert_equal(result[7][:overview][:id], overview8.id)
    assert_equal(result[7][:overview][:name], 'not watched by aa array')
    assert_equal(result[7][:overview][:view], 'not_watched_by_aa_array')
    assert_equal(result[7][:tickets].class, Array)
    assert_equal(result[7][:tickets][0][:id], ticket1.id)
    assert_equal(result[7][:tickets][1][:id], ticket2.id)
    assert_equal(result[7][:count], 2)

  end

end
