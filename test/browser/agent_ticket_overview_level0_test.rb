# encoding: utf-8
require 'browser_test_helper'

class AgentTicketOverviewLevel0Test < TestCase
  def test_I
    @browser = browser_instance
    login(
      :username => 'master@example.com',
      :password => 'test',
      :url      => browser_url,
    )
    tasks_close_all()

    # remember current overview count
    overview_counter_before = overview_counter()

    # create new ticket
    ticket1 = ticket_create(
      :data    => {
        :customer => 'nico*',
        :group    => 'Users',
        :title    => 'overview count test #1',
        :body     => 'overview count test #1',
      }
    )
    sleep 8

    # get new overview count
    overview_counter_new = overview_counter()
    assert_equal( overview_counter_before['#ticket/view/all_unassigned'] + 1, overview_counter_new['#ticket/view/all_unassigned'] )

    # open ticket by search
    ticket_open_by_search(
      :number  => ticket1[:number],
    )
    sleep 1

    # close ticket
    ticket_update(
      :data    => {
        :state => 'closed',
      }
    )
    sleep 8

    # get current overview count
    overview_counter_after = overview_counter()
    assert_equal( overview_counter_before['#ticket/view/all_unassigned'], overview_counter_after['#ticket/view/all_unassigned'] )
  end
end