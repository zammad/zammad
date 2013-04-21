# encoding: utf-8
require 'browser_test_helper'

class AgentTicketCreateTest < TestCase
  def test_customer_ticket_create
    tests = [
      {
        :name     => 'agent ticket create',
        :action   => [
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
            :css     => '.ticket_create',
            :result  => true,
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'set',
            :css     => '.ticket_create input[name="customer_id_autocompletion"]',
            :value   => 'ma',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :execute => 'sendkey',
            :css     => '.ticket_create input[name="customer_id_autocompletion"]',
            :value   => :arrow_down,
          },
          {
            :execute => 'sendkey',
            :css     => '.ticket_create input[name="customer_id_autocompletion"]',
            :value   => :tab,
          },
          {
            :execute => 'select',
            :css     => '.ticket_create select[name="group_id"]',
            :value   => 'Users',
          },
          {
            :execute => 'set',
            :css     => '.ticket_create input[name="subject"]',
            :value   => 'some subject 123äöü',
          },
          {
            :execute => 'set',
            :css     => '.ticket_create textarea[name="body"]',
            :value   => 'some body 123äöü',
          },
          {
            :execute => 'click',
            :css     => '.form-actions button[type="submit"]',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :execute => 'check',
            :css     => '#login',
            :result  => false,
          },
          {
            :execute => 'check',
            :element => :url,
            :result  => '#ticket/zoom/',
          },

          # check ticket
          {
            :execute      => 'match',
            :css          => 'div.article',
            :value        => 'some body 123äöü',
            :match_result => true,
          },

          # update ticket
          {
            :execute => 'check',
            :css     => 'textarea[name="body"]',
            :result  => true,
          },
          {
            :execute => 'set',
            :css     => 'textarea[name="body"]',
            :value   => 'some body 1234 äöüß',
          },
          {
            :execute => 'click',
            :css     => 'button',
            :type    => 'submit',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'some body 1234 äöüß',
            :match_result => true,
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests, { :username => 'agent1@example.com' })
  end
end
