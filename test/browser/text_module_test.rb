# encoding: utf-8
require 'browser_test_helper'

class TextModuleTest < TestCase
  def test_I
    random = 'text_module_test_' + rand(999999).to_s
    random2 = 'text_module_test_' + rand(999999).to_s

    # user
    tests = [
      {
        :name     => 'add #1',
        :action   => [
          {
            :execute => 'close_all_tasks',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#admin"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#text_modules"]',
          },
          {
            :execute => 'click',
            :css     => 'a[data-type="new"]',
          },
          {
            :execute => 'set',
            :css     => 'input[name=name]',
            :value   => 'some name' + random,
          },
          {
            :execute => 'set',
            :css     => 'input[name="keywords"]',
            :value   => random,
          },
          {
            :execute => 'set',
            :css     => 'textarea[name="content"]',
            :value   => 'some content' + random,
          },
          {
            :execute => 'click',
            :css     => '.modal button.submit',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => random,
            :match_result => true,
          },
        ],
      },
      {
        :name     => 'add #2',
        :action   => [
          {
            :execute => 'click',
            :css     => 'a[href="#admin"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#text_modules"]',
          },
          {
            :execute => 'click',
            :css     => 'a[data-type="new"]',
          },
          {
            :execute => 'set',
            :css     => 'input[name=name]',
            :value   => 'some name' + random2,
          },
          {
            :execute => 'set',
            :css     => 'input[name="keywords"]',
            :value   => random2,
          },
          {
            :execute => 'set',
            :css     => 'textarea[name="content"]',
            :value   => 'some content' + random2,
          },
          {
            :execute => 'click',
            :css     => '.modal button.submit',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => random2,
            :match_result => true,
          },
        ],
      },
      {
        :name     => 'verify usage',
        :action   => [
          {
            :execute => 'click',
            :css     => 'a[href="#new"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#ticket_create/call_outbound"]',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'set',
            :css     => '.active textarea[name=body]',
            :value   => '::' + random,
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => random,
            :match_result => true,
          },
          {
            :execute => 'click',
            :css     => '.-sew-list-item.selected',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute      => 'match',
            :css          => '.active textarea[name=body]',
            :value        => 'some content' + random,
            :match_result => true,
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests, { :username => 'master@example.com' })
  end
  def test_II
    random = 'text_II_module_test_' + rand(999999).to_s

    # user
    tests = [
      {
        :name     => 'start',
        :instance1 => browser_instance,
        :instance2 => browser_instance,
        :instance1_username => 'master@example.com',
        :instance1_password => 'test',
        :instance2_username => 'agent1@example.com',
        :instance2_password => 'test',
        :action   => [
          # create ticket
          {
            :where   => :instance2,
            :execute => 'close_all_tasks',
          },
          {
            :where   => :instance2,
            :execute => 'click',
            :css     => 'a[href="#new"]',
          },
          {
            :where   => :instance2,
            :execute => 'click',
            :css     => 'a[href="#ticket_create/call_inbound"]',
          },
          {
            :where   => :instance2,
            :execute => 'set',
            :css     => '.active input[name=subject]',
            :value   => 'A',
          },
          {
            :where   => :instance2,
            :execute => 'click',
            :css     => 'a[href="#new"]',
          },
          {
            :where   => :instance2,
            :execute => 'click',
            :css     => 'a[href="#ticket_create/call_outbound"]',
          },
          {
            :where   => :instance2,
            :execute => 'set',
            :css     => '.active input[name=subject]',
            :value   => 'B',
          },

          # create new text module
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => 'a[href="#admin"]',
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => 'a[href="#text_modules"]',
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => 'a[data-type="new"]',
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => 'input[name=name]',
            :value   => 'some name' + random,
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => 'input[name="keywords"]',
            :value   => random,
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => 'textarea[name="content"]',
            :value   => 'some content <%= @ticket.customer.lastname %>' + random,
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => '.modal button.submit',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :where   => :instance1,
            :execute      => 'match',
            :css          => 'body',
            :value        => random,
            :match_result => true,
          },


        ],
      },
      {
        :name     => 'check if text module exists in instance2, for ready to use',
        :action   => [
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :where   => :instance2,
            :execute => 'set',
            :css     => '.active textarea[name=body]',
            :value   => '::' + random,
          },
          {
            :where   => :instance2,
            :execute => 'wait',
            :value   => 1,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => 'body',
            :value        => random,
            :match_result => true,
          },
          {
            :where   => :instance2,
            :execute => 'click',
            :css     => '.-sew-list-item.selected',
          },
          {
            :where   => :instance2,
            :execute => 'wait',
            :value   => 1,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active textarea[name=body]',
            :value        => 'some content ' + random,
            :match_result => true,
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :where   => :instance2,
            :execute => 'set',
            :css     => '.active .ticket_create input[name="customer_id_autocompletion"]',
            :value   => 'nicole',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :where   => :instance2,
            :execute => 'sendkey',
            :css     => '.active .ticket_create input[name="customer_id_autocompletion"]',
            :value   => :arrow_down,
          },
          {
            :where   => :instance2,
            :execute => 'sendkey',
            :css     => '.active .ticket_create input[name="customer_id_autocompletion"]',
            :value   => :tab,
          },
          {
            :where   => :instance2,
            :execute => 'wait',
            :value   => 1,
          },
          {
            :where   => :instance2,
            :execute => 'set',
            :css     => '.active textarea[name=body]',
            :value   => '::' + random,
          },
          {
            :where   => :instance2,
            :execute => 'wait',
            :value   => 1,
          },
          {
            :where   => :instance2,
            :execute => 'click',
            :css     => '.-sew-list-item.selected',
          },
          {
            :where   => :instance2,
            :execute => 'wait',
            :value   => 1,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active textarea[name=body]',
            :value        => 'some content Braun' + random,
            :match_result => true,
          },
        ],
      },
    ]
    browser_double_test(tests)
  end
end
