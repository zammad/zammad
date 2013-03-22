# encoding: utf-8
require 'test_helper'
 
class TicketTest < ActiveSupport::TestCase
  test 'ticket create' do
    ticket = Ticket.create(
      :title           => 'some title äöüß',
      :group           => Group.lookup( :name => 'Users'),
      :customer_id     => 2,
      :ticket_state    => Ticket::State.lookup( :name => 'new' ),
      :ticket_priority => Ticket::Priority.lookup( :name => '2 normal' ),
      :updated_by_id   => 1,
      :created_by_id   => 1,
    )
    assert( ticket, "ticket created" )

    assert_equal( ticket.title, 'some title äöüß', 'ticket.title verify' )
    assert_equal( ticket.group.name, 'Users', 'ticket.group verify' )
    assert_equal( ticket.ticket_state.name, 'new', 'ticket.state verify' )

    delete = ticket.destroy
    assert( delete, "ticket destroy" )
  end

  test 'ticket sla' do
    ticket = Ticket.create(
      :title           => 'some title äöüß',
      :group           => Group.lookup( :name => 'Users'),
      :customer_id     => 2,
      :ticket_state    => Ticket::State.lookup( :name => 'new' ),
      :ticket_priority => Ticket::Priority.lookup( :name => '2 normal' ),
      :created_at      => '2013-03-21 09:30:00 UTC',
      :updated_at      => '2013-03-21 09:30:00 UTC',
      :updated_by_id   => 1,
      :created_by_id   => 1,
    )
    assert( ticket, "ticket created" )
    assert_equal( ticket.escalation_time, nil, 'ticket.escalation_time verify' )

    sla = Sla.create(
      :name => 'test sla 1',
      :condition => {},
      :data => {
        "Mon"=>"Mon", "Tue"=>"Tue", "Wed"=>"Wed", "Thu"=>"Thu", "Fri"=>"Fri", "Sat"=>"Sat", "Sun"=>"Sun",
        "beginning_of_workday" => "8:00",
        "end_of_workday"       => "18:00",
      },
      :first_response_time => 120,
      :update_time   => 180,
      :close_time    => 240,
      :active        => true,
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.escalation_time verify 1' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.first_response_escal_date verify 1' )
    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.update_time_escal_date verify 1' )
    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 13:30:00 UTC', 'ticket.close_time_escal_date verify 1' )
    delete = sla.destroy
    assert( delete, "sla destroy 1" )

    sla = Sla.create(
      :name => 'test sla 2',
      :condition => { "tickets.ticket_priority_id" =>["1", "2", "3"] },
      :data => {
        "Mon"=>"Mon", "Tue"=>"Tue", "Wed"=>"Wed", "Thu"=>"Thu", "Fri"=>"Fri", "Sat"=>"Sat", "Sun"=>"Sun",
        "beginning_of_workday" => "8:00",
        "end_of_workday"       => "18:00",
      },
      :first_response_time => 60,
      :update_time   => 120,
      :close_time    => 180,
      :active        => true,
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    ticket = Ticket.find(ticket.id)
    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.escalation_time verify 2' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 2' )
    assert_equal( ticket.first_response, nil, 'ticket.first_response verify 2' )
    assert_equal( ticket.first_response_in_min, nil, 'ticket.first_response_in_min verify 2' )
    assert_equal( ticket.first_response_diff_in_min, nil, 'ticket.first_response_diff_in_min verify 2' )
    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.update_time_escal_date verify 2' )
    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 2' )

    ticket.update_attributes(
#      :first_response_escal_date => '2013-03-26 09:30:00 UTC',
      :first_response            => '2013-03-21 10:00:00 UTC',
    )
    ticket.escalation_calculation
    puts ticket.inspect

    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.escalation_time verify 3' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 3' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 10:00:00 UTC', 'ticket.first_response verify 3' )
    assert_equal( ticket.first_response_in_min, 30, 'ticket.first_response_in_min verify 3' )
    assert_equal( ticket.first_response_diff_in_min, 30, 'ticket.first_response_diff_in_min verify 3' )
    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.update_time_escal_date verify 3' )
    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 3' )
 
     ticket.update_attributes(
#      :first_response_escal_date => '2013-03-26 09:30:00 UTC',
      :first_response            => '2013-03-21 14:00:00 UTC',
    )
    ticket.escalation_calculation
    puts ticket.inspect

    assert_equal( ticket.escalation_time.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.escalation_time verify 4' )
    assert_equal( ticket.first_response_escal_date.gmtime.to_s, '2013-03-21 10:30:00 UTC', 'ticket.first_response_escal_date verify 4' )
    assert_equal( ticket.first_response.gmtime.to_s, '2013-03-21 14:00:00 UTC', 'ticket.first_response verify 4' )
    assert_equal( ticket.first_response_in_min, 270, 'ticket.first_response_in_min verify 4' )
    assert_equal( ticket.first_response_diff_in_min, -210, 'ticket.first_response_diff_in_min verify 4' )
    assert_equal( ticket.update_time_escal_date.gmtime.to_s, '2013-03-21 11:30:00 UTC', 'ticket.update_time_escal_date verify 4' )
    assert_equal( ticket.close_time_escal_date.gmtime.to_s, '2013-03-21 12:30:00 UTC', 'ticket.close_time_escal_date verify 4' )
 


    delete = sla.destroy
    assert( delete, "sla destroy 2" )

    delete = ticket.destroy
    assert( delete, "ticket destroy" )
    delete = sla.destroy
    assert( delete, "sla destroy" )
  end
end