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
          {
            :execute => 'click',
            :css     => 'a[href="#new"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#ticket_create/call_inbound"]',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :execute => 'check',
            :css     => '.active .ticket_create',
            :result  => true,
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'set',
            :css     => '.active .ticket_create input[name="customer_id_autocompletion"]',
            :value   => 'ma',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :execute => 'sendkey',
            :css     => '.active .ticket_create input[name="customer_id_autocompletion"]',
            :value   => :arrow_down,
          },
          {
            :execute => 'sendkey',
            :css     => '.active .ticket_create input[name="customer_id_autocompletion"]',
            :value   => :tab,
          },
          {
            :execute => 'select',
            :css     => '.active .ticket_create select[name="group_id"]',
            :value   => 'Users',
          },
          {
            :execute => 'set',
            :css     => '.active .ticket_create input[name="subject"]',
            :value   => 'some subject 4 -  123äöü',
          },
          {
            :execute => 'set',
            :css     => '.active .ticket_create textarea[name="body"]',
            :value   => 'some body 4 -  123äöü',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },

          # reload instances, verify again
          {
            :execute      => 'reload',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },

          {
            :execute => 'click',
            :css     => '.active .form-actions button[type="submit"]',
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
            :css          => '.active div.article',
            :value        => 'some body 4 -  123äöü',
            :match_result => true,
          },

          # close task/cleanup
          {
            :execute => 'click',
            :css     => '#task [data-type="close"]',
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests, { :username => 'agent1@example.com' })
  end
end
