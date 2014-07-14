# encoding: utf-8
require 'test_helper'

class SessionBasicTicketTest < ActiveSupport::TestCase
  test 'b ticket_overview_index' do

    UserInfo.current_user_id = 1
    user = User.lookup(:id => 1)
    client1 = Sessions::Backend::TicketOverviewIndex.new(user, false, '123-1')

    # get as stream
    result1 = client1.push
    assert( result1, "check ticket_overview_index" )
    sleep 1

    # next check should be empty
    result1 = client1.push
    assert( !result1, "check ticket_overview_index - recall" )

    # next check should be empty
    sleep 10
    result1 = client1.push
    assert( !result1, "check ticket_overview_index - recall 2" )

    ticket = Ticket.create( :title => '12323', :group_id => 1, :priority_id => 1, :state_id => 1, :customer_id => 1 )

    sleep 10

    # get as stream
    result1 = client1.push
    assert( result1, "check ticket_overview_index - recall 3" )
  end

  test 'b ticket_overview_list' do

    UserInfo.current_user_id = 1
    user = User.lookup(:id => 1)
    client1 = Sessions::Backend::TicketOverviewList.new(user, false, '123-1')

    # get as stream
    result1 = client1.push
    assert( result1, "check ticket_overview_list" )
    sleep 1

    # next check should be empty
    result1 = client1.push
    assert( !result1, "check ticket_overview_list - recall" )

    # next check should be empty
    sleep 10
    result1 = client1.push
    assert( !result1, "check ticket_overview_list - recall 2" )

    ticket = Ticket.create( :title => '12323', :group_id => 1, :priority_id => 1, :state_id => 1, :customer_id => 1 )

    sleep 10

    # get as stream
    result1 = client1.push
    assert( result1, "check ticket_overview_list - recall 3" )
  end
end