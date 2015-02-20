# encoding: utf-8
require 'browser_test_helper'

class AgentTicketOverviewLevel0Test < TestCase
  def test_I
    tests = [
      {
        :name     => 'verify overview count',
        :action   => [
          {
            :execute => 'close_all_tasks',
          },

          # remember it ticket count in overview
          {
            :execute => 'overview_count_remember',
          },

          # create new open ticket
          {
            :execute => 'create_ticket',
            :group   => 'Users',
            :subject => 'some subject 123äöü',
            :body    => 'some body 123äöü - with closed tab',
          },

          # remember ticket for later
          {
            :execute      => 'match',
            :css          => '.active .page-header .ticket-number',
            :value        => '^(.*)$',
            :no_quote     => true,
            :match_result => true,
          },
          {
            :execute => 'wait',
            :value   => 5,
          },

          # check new ticket count of open tickets in overview
          {
            :execute => 'overview_count_verify',
            :data    => {
              '#ticket/view/all_unassigned' => 1,
            },
          },

          # close ticket
          {
            :execute => 'search_ticket',
            :number  => '###stack###',
          },
          {
            :execute => 'update_ticket',
            :state   => 'closed',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },

          # verify new open tickets in overview
          {
            :execute => 'overview_count_verify',
            :data    => {
              '#ticket/view/all_unassigned' => 0,
            },
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests, { :username => 'master@example.com' })
  end
end
