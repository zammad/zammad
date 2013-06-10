# encoding: utf-8
require 'browser_test_helper'

class TaskbarSessionTest < TestCase
  def test_current_session_a_same_agent
    tests = [
      {
        :name     => 'start',
        :instance1 => browser_instance,
        :instance2 => browser_instance,
        :instance1_username => 'agent1@example.com',
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
            :value   => 10,
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
            :value   => 10,
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

end
