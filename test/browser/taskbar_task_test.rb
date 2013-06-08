# encoding: utf-8
require 'browser_test_helper'

class TaskbarTaskTest < TestCase
  def test_persistant_task_a
    tests = [
      {
        :name     => 'persistant task',
        :action   => [
          {
            :execute => 'wait',
            :value   => 2,
          },
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
            :css     => 'a[href="#ticket_create/call_inbound"]',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :execute => 'check',
            :css     => '.active .ticket_create',
            :result  => true,
          },
          {
            :execute => 'set',
            :css     => '.active .ticket_create input[name="subject"]',
            :value   => 'some test AAA',
          },
          {
            :execute => 'wait',
            :value   => 20,
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests, { :username => 'agent1@example.com' })
  end
  def test_persistant_task_b
    tests = [
      {
        :name     => 'persistant task',
        :action   => [
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :execute => 'click',
            :css     => '.task',
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'some test AAA',
            :match_result => true,
          },
          {
            :execute => 'click',
            :css     => '.taskbar [data-type="close"]',
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'some test AAA',
            :match_result => false,
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests, { :username => 'agent1@example.com' })
  end
end
