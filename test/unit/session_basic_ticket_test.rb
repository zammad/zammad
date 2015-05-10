# encoding: utf-8
# rubocop:disable UselessAssignment
require 'test_helper'

class SessionBasicTicketTest < ActiveSupport::TestCase

  test 'b ticket_overview_index' do
    UserInfo.current_user_id = 1

    # create users
    roles  = Role.where( name: [ 'Agent' ] )
    groups = Group.all

    agent1 = User.create_or_update(
      login: 'session-basic-ticket-agent-1',
      firstname: 'Session',
      lastname: 'session basic ' + rand(99_999).to_s,
      email: 'session-basic-ticket-agent-1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    agent1.roles = roles
    assert( agent1.save, 'create/update agent1' )

    Ticket.create( title: 'default overview test', group_id: 1, priority_id: 1, state_id: 1, customer_id: 1 )

    user = User.lookup( id: agent1.id )
    client1 = Sessions::Backend::TicketOverviewIndex.new(user, false, '123-1', 5)

    # get as stream
    result1 = client1.push
    if !result1
      Rails.logger.error "FAILD Sessions::Backend::TicketOverviewIndex push"
    end
    assert( result1, 'check ticket_overview_index' )

    # next check should be empty / no changes
    result1 = client1.push
    assert( !result1, 'check ticket_overview_index - recall' )

    # next check should be empty / no changes
    sleep 6
    result1 = client1.push
    assert( !result1, 'check ticket_overview_index - recall 2' )

    # create ticket
    ticket = Ticket.create( title: '12323', group_id: 1, priority_id: 1, state_id: 1, customer_id: 1 )
    sleep 6

    # get as stream
    result1 = client1.push
    assert( result1, 'check ticket_overview_index - recall 3' )
  end

  test 'b ticket_overview_list' do
    UserInfo.current_user_id = 1

    # create users
    roles  = Role.where( name: [ 'Agent' ] )
    groups = Group.all

    agent1 = User.create_or_update(
      login: 'session-basic-ticket-agent-1',
      firstname: 'Session',
      lastname: 'session basic ' + rand(99_999).to_s,
      email: 'session-basic-ticket-agent-1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
    )

    agent1.roles = roles
    assert( agent1.save, 'create/update agent1' )

    Ticket.create( title: 'default overview test', group_id: 1, priority_id: 1, state_id: 1, customer_id: 1 )

    user = User.lookup( id: agent1.id )

    client1 = Sessions::Backend::TicketOverviewList.new(user, false, '123-1', 5)

    # get as stream
    result1 = client1.push
    if !result1
      Rails.logger.error "FAILD Sessions::Backend::TicketOverviewList push"
    end
    assert( result1, 'check ticket_overview_list' )

    # next check should be empty / no changes
    result1 = client1.push
    assert( !result1, 'check ticket_overview_list - recall' )

    # next check should be empty / no changes
    sleep 6
    result1 = client1.push
    assert( !result1, 'check ticket_overview_list - recall 2' )

    # create ticket
    ticket = Ticket.create( title: '12323', group_id: 1, priority_id: 1, state_id: 1, customer_id: 1 )
    sleep 6

    # get as stream
    result1 = client1.push
    assert( result1, 'check ticket_overview_list - recall 3' )
  end
end
