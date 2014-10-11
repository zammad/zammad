# encoding: utf-8
require 'browser_test_helper'

class AgentTicketActionLevel4Test < TestCase
  def test_agent_ticket_create_with_reload
    tests = [
      {
        :name     => 'agent ticket create with reload',
        :action   => [
          {
            :execute => 'close_all_tasks',
          },

          # create ticket
          {
            :execute       => 'create_ticket',
            :group         => 'Users',
            :subject       => 'some subject 4 -  123äöü',
            :body          => 'some body 4 -  123äöü',
            :do_not_submit => true,
          },
          {
            :execute => 'wait',
            :value   => 6,
          },

          # reload instances, verify autosave
          {
            :execute => 'reload',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },

          {
            :execute => 'click',
            :css     => '.content.active button.submit',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :execute => 'check',
            :element => :url,
            :result  => '#ticket/zoom/',
          },

          # check ticket
          {
            :execute      => 'match',
            :css          => '.active div.ticket-article',
            :value        => 'some body 4 -  123äöü',
            :match_result => true,
          },

          # close task/cleanup
          {
            :execute => 'close_all_tasks',
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests, { :username => 'agent1@example.com' })
  end
end
