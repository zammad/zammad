# encoding: utf-8
require 'test_helper'

class TicketStateTest < ActiveSupport::TestCase

  test 'base' do

    # check current state
    assert_equal(1, Ticket::State.where(default_create: true).count)
    assert_equal(1, Ticket::State.where(default_follow_up: true).count)
    state_create = Ticket::State.find_by(default_create: true)
    state_follow_up = Ticket::State.find_by(default_follow_up: true)

    # add new state
    state_new2 = Ticket::State.create_if_not_exists(
      name: 'new 2',
      state_type_id: Ticket::StateType.find_by(name: 'new').id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    state_follow_up2 = Ticket::State.create_if_not_exists(
      name: 'open 2',
      state_type_id: Ticket::StateType.find_by(name: 'open').id,
      updated_by_id: 1,
      created_by_id: 1,
    )

    # verify states
    assert_equal(1, Ticket::State.where(default_create: true).count)
    assert_equal(1, Ticket::State.where(default_follow_up: true).count)
    assert_equal(state_create.id, Ticket::State.find_by(default_create: true).id)
    assert_equal(state_follow_up.id, Ticket::State.find_by(default_follow_up: true).id)

    # cleanup
    state_new2.destroy
    state_follow_up2.destroy

    # verify states
    assert_equal(1, Ticket::State.where(default_create: true).count)
    assert_equal(1, Ticket::State.where(default_follow_up: true).count)
    assert_equal(state_create.id, Ticket::State.find_by(default_create: true).id)
    assert_equal(state_follow_up.id, Ticket::State.find_by(default_follow_up: true).id)

    # add new state
    state_new3 = Ticket::State.create_if_not_exists(
      name: 'new 3',
      state_type_id: Ticket::StateType.find_by(name: 'new').id,
      default_create: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    state_follow_up3 = Ticket::State.create_if_not_exists(
      name: 'open 3',
      state_type_id: Ticket::StateType.find_by(name: 'open').id,
      default_follow_up: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    # verify states
    assert_equal(1, Ticket::State.where(default_create: true).count)
    assert_equal(1, Ticket::State.where(default_follow_up: true).count)
    assert_not_equal(state_create.id, Ticket::State.find_by(default_create: true).id)
    assert_equal(state_new3.id, Ticket::State.find_by(default_create: true).id)
    assert_not_equal(state_follow_up.id, Ticket::State.find_by(default_follow_up: true).id)
    assert_equal(state_follow_up3.id, Ticket::State.find_by(default_follow_up: true).id)

    # cleanup
    state_new3.destroy
    state_follow_up3.destroy

    # verify states
    assert_equal(1, Ticket::State.where(default_create: true).count)
    assert_equal(1, Ticket::State.where(default_follow_up: true).count)
    assert_equal(state_create.id, Ticket::State.find_by(default_create: true).id)
    assert_not_equal(state_follow_up.id, Ticket::State.find_by(default_follow_up: true).id)

    # cleanup
    state_create.reload
    state_create.default_create = true
    state_create.save!

    state_follow_up.reload
    state_follow_up.default_follow_up = true
    state_follow_up.save!

    # verify states
    assert_equal(1, Ticket::State.where(default_create: true).count)
    assert_equal(1, Ticket::State.where(default_follow_up: true).count)
    assert_equal(state_create.id, Ticket::State.find_by(default_create: true).id)
    assert_equal(state_follow_up.id, Ticket::State.find_by(default_follow_up: true).id)

  end

end
