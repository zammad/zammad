# encoding: utf-8
require 'browser_test_helper'

class AaaGettingStartedTest < TestCase
  def test_getting_started
    tests = [
      {
        :name     => 'start',
        :instance => browser_instance,
        :url      => browser_url + '/',
        :action   => [
          {
            :execute => 'check',
            :css     => '#form-master',
            :result  => true,
          },
        ],
      },
      {
        :name     => 'getting started - master agent',
        :action   => [
          {
            :execute => 'set',
            :css     => '#form-master input[name="firstname"]',
            :value   => 'Test Master',
          },
          {
            :execute => 'set',
            :css     => '#form-master input[name="lastname"]',
            :value   => 'Agent',
          },
          {
            :execute => 'set',
            :css     => '#form-master input[name="email"]',
            :value   => 'master@example.com',
          },
          {
            :execute => 'set',
            :css     => '#form-master input[name="password"]',
            :value   => 'test1234äöüß',
          },
          {
            :execute => 'set',
            :css     => '#form-master input[name="password_confirm"]',
            :value   => 'test1234äöüß',
          },
          {
            :execute => 'click',
            :css     => '#form-master button[type="submit"]',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :execute => 'check',
            :element => :url,
            :result  => '#getting_started',
          },
        ],
      },

      # create agent1
      {
        :name     => 'getting started - agent 1',
        :action   => [
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'Invite Agents',
            :match_result => true,
          },
          {
            :execute => 'set',
            :css     => '#form-agent input[name="firstname"]',
            :value   => 'Agent 1',
          },
          {
            :execute => 'set',
            :css     => '#form-agent input[name="lastname"]',
            :value   => 'Test',
          },
          {
            :execute => 'set',
            :css     => '#form-agent input[name="email"]',
            :value   => 'agent1@example.com',
          },
          {
            :execute => 'click',
            :css     => '#form-agent input[name="group_ids"][value="1"]',
          },
          {
            :execute => 'click',
            :css     => '#form-agent button[type="submit"]',
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'Invitation sent',
          },
          {
            :execute => 'check',
            :element => :url,
            :result  => '#getting_started',
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'Invite Agents',
            :match_result => true,
          },

        ],
      },
    ]
    browser_single_test(tests)
  end
end
