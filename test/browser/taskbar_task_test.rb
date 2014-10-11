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
            :css     => 'a[href="#ticket/create"]',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :execute => 'check',
            :css     => '.active .newTicket',
            :result  => true,
          },
          {
            :execute => 'set',
            :css     => '.active .newTicket input[name="title"]',
            :value   => 'some test AAA',
          },
          {
            :execute => 'wait',
            :value   => 12,
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
            :execute => 'close_all_tasks',
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
            :css     => 'a[href="#ticket/create"]',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'set',
            :css     => '.active .newTicket input[name="title"]',
            :value   => 'INBOUND TEST#1',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :execute => 'set',
            :css     => '.active .newTicket [data-name="body"]',
            :value   => 'INBOUND BODY TEST#1',
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
            :execute => 'set',
            :css     => '.active .newTicket input[name="title"]',
            :value   => 'OUTBOUND TEST#1',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'set',
            :css     => '.active .newTicket [data-name="body"]',
            :value   => 'OUTBOUND BODY TEST#1',
          },
          {
            :execute => 'wait',
            :value   => 12,
          },
          {
            :execute => 'logout',
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
            :execute  => 'login',
            :username => 'master@example.com',
            :password => 'test',
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
            :execute => 'logout',
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
            :execute  => 'login',
            :username => 'agent1@example.com',
            :password => 'test',
          },
          {
            :execute => 'wait',
            :value   => 3,
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
