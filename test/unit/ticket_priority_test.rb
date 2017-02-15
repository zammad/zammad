# encoding: utf-8
require 'test_helper'

class TicketPriorityTest < ActiveSupport::TestCase

  test 'base' do

    # check current state
    assert_equal(1, Ticket::Priority.where(default_create: true).count)
    priority_create = Ticket::Priority.find_by(default_create: true)

    # add new state
    priority_new2 = Ticket::Priority.create_if_not_exists(
      name: 'priority 2',
      updated_by_id: 1,
      created_by_id: 1,
    )

    # verify states
    assert_equal(1, Ticket::Priority.where(default_create: true).count)
    assert_equal(priority_create.id, Ticket::Priority.find_by(default_create: true).id)

    # cleanup
    priority_new2.destroy

    # verify states
    assert_equal(1, Ticket::Priority.where(default_create: true).count)
    assert_equal(priority_create.id, Ticket::Priority.find_by(default_create: true).id)

    # add new state
    priority_new3 = Ticket::Priority.create_if_not_exists(
      name: 'priority 3',
      default_create: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    # verify states
    assert_equal(1, Ticket::Priority.where(default_create: true).count)
    assert_equal(priority_new3.id, Ticket::Priority.find_by(default_create: true).id)
    assert_not_equal(priority_create.id, Ticket::Priority.find_by(default_create: true).id)

    # cleanup
    priority_new3.destroy

    # verify states
    assert_equal(1, Ticket::Priority.where(default_create: true).count)
    assert_equal(Ticket::Priority.first, Ticket::Priority.find_by(default_create: true))

    # cleanup
    priority_create.reload
    priority_create.default_create = true
    priority_create.save!

    # verify states
    assert_equal(1, Ticket::Priority.where(default_create: true).count)
    assert_equal(priority_create.id, Ticket::Priority.find_by(default_create: true).id)

  end

end
