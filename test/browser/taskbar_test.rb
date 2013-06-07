# encoding: utf-8
require 'browser_test_helper'

class TaskbarTest < TestCase
  def test_current_session_a_same_agent
    tests = [
      {
        :name     => 'start',
        :instance1 => browser_instance,
        :instance2 => browser_instance,
        :instance1_username => 'master@example.com',
        :instance1_password => 'test',
        :instance2_username => 'master@example.com',
        :instance2_password => 'test',
        :url      => browser_url,
        :action   => [
          {
            :where   => :instance1,
            :execute => 'check',
            :css     => '#login',
            :result  => false,
          },
          {
            :where   => :instance2,
            :execute => 'check',
            :css     => '#login',
            :result  => false,
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => 'body',
            :value        => 'Reload application',
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => 'body',
            :value        => 'Reload application',
            :match_result => false,
          },
#          {
#            :execute => 'wait',
#            :value   => 1,
#          },
        ],
      },
    ]
    browser_double_test(tests)
  end

  def test_current_session_b_different_agent
    tests = [
      {
        :name     => 'start',
        :instance1 => browser_instance,
        :instance2 => browser_instance,
        :instance1_username => 'master@example.com',
        :instance1_password => 'test',
        :instance2_username => 'agent1@example.com',
        :instance2_password => 'test',
        :url      => browser_url,
        :action   => [
          {
            :where   => :instance1,
            :execute => 'check',
            :css     => '#login',
            :result  => false,
          },
          {
            :where   => :instance2,
            :execute => 'check',
            :css     => '#login',
            :result  => false,
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => 'body',
            :value        => 'Reload application',
            :match_result => false,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => 'body',
            :value        => 'Reload application',
            :match_result => false,
          },
#          {
#            :execute => 'wait',
#            :value   => 1,
#          },
        ],
      },
    ]
    browser_double_test(tests)
  end

  def test_persistant_task_a
    tests = [
      {
        :name     => 'persistant task',
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
            :value   => 6,
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
