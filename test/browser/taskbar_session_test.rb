# encoding: utf-8
require 'browser_test_helper'

class TaskbarSessionTest < TestCase
  def test_current_session_a_same_agent
    tests = [
      {
        :name                => 'check taken over session block screen with same user',
        :instance1           => browser_instance,
        :instance2           => browser_instance,
        :instance1_username  => 'agent1@example.com',
        :instance1_password  => 'test',
        :instance2_username  => 'agent1@example.com',
        :instance2_password  => 'test',
        :url      => browser_url,
        :action   => [
          {
            :execute => 'wait',
            :value   => 12,
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
        ],
      },
    ]
    browser_double_test(tests)
  end

  def test_current_session_b_different_agent
    tests = [
      {
        :name                => 'check taken over session block screen with same user',
        :instance1           => browser_instance,
        :instance2           => browser_instance,
        :instance1_username  => 'master@example.com',
        :instance1_password  => 'test',
        :instance2_username  => 'agent1@example.com',
        :instance2_password  => 'test',
        :url                 => browser_url,
        :action   => [
          {
            :execute => 'wait',
            :value   => 12,
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
        ],
      },
    ]
    browser_double_test(tests)
  end

end
