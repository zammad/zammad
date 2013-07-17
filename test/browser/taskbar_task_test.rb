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
            :execute => 'wait',
            :value   => 1,
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
  def test_persistant_task_with_relogin
    tests = [
      {
        :name     => 'agent1 - create persistant task',
        :action   => [
          {
            :execute => 'wait',
            :value   => 2,
          },
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
            :value   => 3,
          },
          {
            :execute => 'set',
            :css     => '.active .ticket_create input[name="subject"]',
            :value   => 'INBOUND TEST#1',
          },
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
            :value   => 1,
          },
          {
            :execute => 'set',
            :css     => '.active .ticket_create input[name="subject"]',
            :value   => 'OUTBOUND TEST#1',
          },
          {
            :execute => 'wait',
            :value   => 20,
          },
          {
            :execute => 'click',
            :css     => 'a[href="#current_user"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#logout"]',
          },
          {
            :execute => 'check',
            :css     => '#login',
            :result  => true,
          },
          {
            :execute => 'wait',
            :value   => 10,
          },
        ],
      },
      {
        :name     => 'relogin with master - task are not viewable',
        :action   => [
          {
            :execute => 'set',
            :css     => 'input[name="username"]',
            :value   => 'master@example.com',
          },
          {
            :execute => 'set',
            :css     => 'input[name="password"]',
            :value   => 'test'
          },
          {
            :execute => 'click',
            :css     => '#login button',
          },
          {
            :execute => 'wait',
            :value   => 6,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'INBOUND TEST#1',
            :match_result => false,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'OUTBOUND TEST#1',
            :match_result => false,
          },
          {
            :execute => 'click',
            :css     => 'a[href="#current_user"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#logout"]',
          },
          {
            :execute => 'check',
            :css     => '#login',
            :result  => true,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'INBOUND TEST#1',
            :match_result => false,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'OUTBOUND TEST#1',
            :match_result => false,
          },
        ],
      },
      {
        :name     => 'relogin with agent - task are viewable',
        :action   => [
          {
            :execute => 'set',
            :css     => 'input[name="username"]',
            :value   => 'agent1@example.com',
          },
          {
            :execute => 'set',
            :css     => 'input[name="password"]',
            :value   => 'test'
          },
          {
            :execute => 'click',
            :css     => '#login button',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'INBOUND TEST#1',
            :match_result => true,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'OUTBOUND TEST#1',
            :match_result => true,
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests, { :username => 'agent1@example.com' })
  end
end
