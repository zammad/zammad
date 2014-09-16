# encoding: utf-8
require 'browser_test_helper'

class AgentUserManageTest < TestCase
  def test_agent_user
    customer_user_email = 'customer-test-' + rand(999999).to_s + '@example.com'
    firstname           = 'Customer Firstname'
    lastname            = 'Customer Lastname'
    fullname            = "#{ firstname } #{ lastname } <#{ customer_user_email }>"
    tests = [
      {
        :name     => 'create customer',
        :action   => [
          {
            :execute => 'close_all_tasks',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'click',
            :css     => 'a[href="#new"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#ticket/create"]',
          },
          {
            :execute => 'click',
            :css     => '.active .customer_new',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'set',
            :css     => '.modal input[name="firstname"]',
            :value   => firstname,
          },
          {
            :execute => 'set',
            :css     => '.modal input[name="lastname"]',
            :value   => lastname,
          },
          {
            :execute => 'set',
            :css     => '.modal input[name="email"]',
            :value   => customer_user_email,
          },
          {
            :execute => 'click',
            :css     => '.modal button.js-submit',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },

          # check is used is selected
          {
            :execute      => 'match',
            :css          => '.active input[name="customer_id"]',
            :value        => '^[0-9].?$',
            :no_quote     => true,
            :match_result => true,
          },
          {
            :execute      => 'match',
            :css          => '.active input[name="customer_id_autocompletion"]',
            :value        => firstname,
            :no_quote     => true,
            :match_result => true,
          },
          {
            :execute      => 'match',
            :css          => '.active input[name="customer_id_autocompletion"]',
            :value        => lastname,
            :no_quote     => true,
            :match_result => true,
          },
          {
            :execute      => 'match',
            :css          => '.active input[name="customer_id_autocompletion"]',
            :value        => customer_user_email,
            :no_quote     => true,
            :match_result => true,
          },
          {
            :execute      => 'match',
            :css          => '.active input[name="customer_id_autocompletion"]',
            :value        => fullname,
            :no_quote     => true,
            :match_result => true,
          },

          # call new ticket screen again
          {
            :execute => 'close_all_tasks',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },

          # accept task close warning
          {
            :execute => 'click',
            :css     => '.modal button.js-submit',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'click',
            :css     => 'a[href="#new"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#ticket/create"]',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute      => 'match',
            :css          => '.active input[name="customer_id"]',
            :value        => '^[0-9].?$',
            :no_quote     => true,
            :match_result => false,
          },
          {
            :execute      => 'match',
            :css          => '.active input[name="customer_id_autocompletion"]',
            :value        => firstname,
            :no_quote     => true,
            :match_result => false,
          },
          {
            :execute => 'set',
            :css     => '.active .ticket-create input[name="customer_id_autocompletion"]',
            :value   => customer_user_email,
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :execute => 'sendkey',
            :css     => '.active .ticket-create input[name="customer_id_autocompletion"]',
            :value   => :arrow_down,
          },
          {
            :execute => 'sendkey',
            :css     => '.active .ticket-create input[name="customer_id_autocompletion"]',
            :value   => :tab,
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute      => 'match',
            :css          => '.active input[name="customer_id"]',
            :value        => '^[0-9].?$',
            :no_quote     => true,
            :match_result => true,
          },
          {
            :execute      => 'match',
            :css          => '.active input[name="customer_id_autocompletion"]',
            :value        => firstname,
            :no_quote     => true,
            :match_result => true,
          },
          {
            :execute      => 'match',
            :css          => '.active input[name="customer_id_autocompletion"]',
            :value        => lastname,
            :no_quote     => true,
            :match_result => true,
          },
          {
            :execute      => 'match',
            :css          => '.active input[name="customer_id_autocompletion"]',
            :value        => fullname,
            :no_quote     => true,
            :match_result => true,
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests, { :username => 'agent1@example.com' })
  end
end
