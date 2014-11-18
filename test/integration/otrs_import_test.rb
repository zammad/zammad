# encoding: utf-8
require 'integration_test_helper'

class OtrsImportTest < ActiveSupport::TestCase

  # check count of imported items
  test 'check counts' do
    #agent_count = User.where()
    assert_equal( 600, Ticket.count, 'tickets' )
    assert_equal( 10, Ticket::State.count, 'ticket states' )
    assert_equal( 24, Group.count, 'groups' )

  end

  # check imported users and permission
  test 'check users' do
    role_admin    = Role.where( :name => 'Admin' ).first
    role_agent    = Role.where( :name => 'Agent' ).first
    role_customer = Role.where( :name => 'Customer' ).first
    #role_report   = Role.where( :name => 'Report' ).first

    user1 = User.find(2)
    assert_equal( 'agent-1 firstname', user1.firstname )
    assert_equal( 'agent-1 lastname', user1.lastname )
    assert_equal( 'agent-1', user1.login )
    assert_equal( 'agent-1@example.com', user1.email )
    assert_equal( true, user1.active )


    assert( user1.roles.include?( role_agent ) )
    assert( !user1.roles.include?( role_admin ) )
    assert( !user1.roles.include?( role_customer ) )
    #assert( !user1.roles.include?( role_report ) )

    group_dasa = Group.where( :name => 'dasa' ).first
    group_raw  = Group.where( :name => 'Raw' ).first

    assert( !user1.groups.include?( group_dasa ) )
    assert( user1.groups.include?( group_raw ) )


    user2 = User.find(3)
    assert_equal( 'agent-2 firstname äöüß', user2.firstname )
    assert_equal( 'agent-2 lastname äöüß', user2.lastname )
    assert_equal( 'agent-2', user2.login )
    assert_equal( 'agent-2@example.com', user2.email )
    assert_equal( true, user2.active )

    assert( user2.roles.include?( role_agent ) )
    assert( user2.roles.include?( role_admin ) )
    assert( !user2.roles.include?( role_customer ) )
    #assert( user2.roles.include?( role_report ) )

    assert( user2.groups.include?( group_dasa ) )
    assert( user2.groups.include?( group_raw ) )

    user3 = User.find(7)
    assert_equal( 'invalid', user3.firstname )
    assert_equal( 'invalid', user3.lastname )
    assert_equal( 'invalid', user3.login )
    assert_equal( 'invalid@example.com', user3.email )
    assert_equal( false, user3.active )

    assert( user3.roles.include?( role_agent ) )
    assert( !user3.roles.include?( role_admin ) )
    assert( !user3.roles.include?( role_customer ) )
    #assert( user3.roles.include?( role_report ) )

    assert( !user3.groups.include?( group_dasa ) )
    assert( !user3.groups.include?( group_raw ) )

    user4 = User.find(8)
    assert_equal( 'invalid-temp', user4.firstname )
    assert_equal( 'invalid-temp', user4.lastname )
    assert_equal( 'invalid-temp', user4.login )
    assert_equal( 'invalid-temp@example.com', user4.email )
    assert_equal( false, user4.active )

    assert( user4.roles.include?( role_agent ) )
    assert( !user4.roles.include?( role_admin ) )
    assert( !user4.roles.include?( role_customer ) )
    #assert( user4.roles.include?( role_report ) )

    assert( !user4.groups.include?( group_dasa ) )
    assert( !user4.groups.include?( group_raw ) )

  end

  # check all synced states and state types
  test 'check ticket stats' do
    state_new = Ticket::State.find(1)
    assert_equal( 'new', state_new.name )
    assert_equal( 'new', state_new.state_type.name )
  end

  # check groups/queues
  test 'check groups' do
    group1 = Group.find(1)
    assert_equal( 'Postmaster', group1.name )
    assert_equal( true, group1.active )

    group2 = Group.find(19)
    assert_equal( 'UnitTestQueue20668', group2.name )
    assert_equal( false, group2.active )
  end

  # check imported customers and organization relation
  test 'check customers / organizations' do
    user1 = User.where( :login => 'jn' ).first
    assert_equal( 'Johannes', user1.firstname )
    assert_equal( 'Nickel', user1.lastname )
    assert_equal( 'jn', user1.login )
    assert_equal( 'jn@example.com', user1.email )
    organization1 = user1.organization
    assert_equal( 'Znuny GmbH Berlin', organization1.name )
    assert_equal( 'äöüß', organization1.note )

    user2 = User.where( :login => 'test90133' ).first
    assert_equal( 'test90133', user2.firstname )
    assert_equal( 'test90133', user2.lastname )
    assert_equal( 'test90133', user2.login )
    assert_equal( 'qa4711@t-online.de', user2.email )
    organization2 = user2.organization
    assert( organization2, nil )
  end
end