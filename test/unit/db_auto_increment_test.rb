require 'test_helper'

class DbAutoIncrementTest < ActiveSupport::TestCase

  test 'id overwrite' do

    setting_backup = Setting.get('system_init_done')

    Setting.set('system_init_done', false)

    Ticket::StateType.create_if_not_exists( id: 200, name: 'unit test 1', updated_by_id: 1, created_by_id: 1  )
    state_type = Ticket::StateType.where( name: 'unit test 1' ).first
    assert_equal( Ticket::StateType.to_s, state_type.class.to_s )
    assert_equal( 'unit test 1', state_type.name )

    Ticket::StateType.create_if_not_exists( id: 200, name: 'unit test 1 _ should not be created', updated_by_id: 1, created_by_id: 1  )
    state_type = Ticket::StateType.where( id: 200 ).first
    assert_equal( Ticket::StateType.to_s, state_type.class.to_s )
    assert_equal( 'unit test 1', state_type.name )

    Ticket::StateType.create_or_update( id: 200, name: 'unit test 1 _ should be updated', updated_by_id: 1, created_by_id: 1  )
    state_type = Ticket::StateType.where( name: 'unit test 1 _ should be updated' ).first
    assert_equal( Ticket::StateType.to_s, state_type.class.to_s )
    assert_equal( 'unit test 1 _ should be updated', state_type.name )

    state_type = Ticket::StateType.where( id: 200 ).first
    assert_equal( Ticket::StateType.to_s, state_type.class.to_s )
    assert_equal( 'unit test 1 _ should be updated', state_type.name )

    Ticket::State.create_if_not_exists( id: 210, name: 'unit test 1', state_type_id: Ticket::StateType.where(name: 'unit test 1 _ should be updated').first.id, updated_by_id: 1, created_by_id: 1  )
    state = Ticket::State.where( name: 'unit test 1' ).first
    assert_equal( Ticket::State.to_s, state.class.to_s )
    assert_equal( 'unit test 1', state.name )

    Ticket::State.create_if_not_exists( id: 210, name: 'unit test 1 _ should not be created', state_type_id: Ticket::StateType.where(name: 'unit test 1 _ should be updated').first.id, updated_by_id: 1, created_by_id: 1  )
    state = Ticket::State.where( id: 210 ).first
    assert_equal( Ticket::State.to_s, state.class.to_s )
    assert_equal( 'unit test 1', state.name )

    Ticket::State.create_or_update( id: 210, name: 'unit test 1 _ should be updated', state_type_id: Ticket::StateType.where(name: 'unit test 1 _ should be updated').first.id, updated_by_id: 1, created_by_id: 1  )
    state = Ticket::State.where( name: 'unit test 1 _ should be updated' ).first
    assert_equal( Ticket::State.to_s, state.class.to_s )
    assert_equal( 'unit test 1 _ should be updated', state.name )

    state = Ticket::State.where( id: 210 ).first
    assert_equal( Ticket::State.to_s, state.class.to_s )
    assert_equal( 'unit test 1 _ should be updated', state.name )

    Setting.set('system_init_done', setting_backup)

  end
end
