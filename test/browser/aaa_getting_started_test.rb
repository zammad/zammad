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
            :css     => '.setup.wizard',
            :result  => true,
          },
        ],
      },
      {
        :name     => 'getting started - master agent',
        :action   => [
          {
            :execute => 'click',
            :css     => '.js-start .btn--primary',
          },

          {
            :execute => 'set',
            :css     => '.js-admin input[name="firstname"]',
            :value   => 'Test Master',
          },
          {
            :execute => 'set',
            :css     => '.js-admin input[name="lastname"]',
            :value   => 'Agent',
          },
          {
            :execute => 'set',
            :css     => '.js-admin input[name="email"]',
            :value   => 'master@example.com',
          },
          {
            :execute => 'set',
            :css     => '.js-admin input[name="password"]',
            :value   => 'test1234äöüß',
          },
          {
            :execute => 'set',
            :css     => '.js-admin input[name="password_confirm"]',
            :value   => 'test1234äöüß',
          },
          {
            :execute => 'click',
            :css     => '.js-admin .btn--success',
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

      # set base
      {
        :name     => 'getting started - base',
        :action   => [
          {
            :execute      => 'match',
            :css          => '.js-base h2',
            :value        => 'Organization',
            :match_result => true,
          },
          {
            :execute => 'set',
            :css     => '.js-base input[name="organization"]',
            :value   => 'Some Organization',
          },
          {
            :execute => 'set',
            :css     => '.js-base input[name="url"]',
            :value   => 'some host',
          },
          {
            :execute => 'click',
            :css     => '.js-base .btn--primary',
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'A URL looks like',
          },
          {
            :execute => 'set',
            :css     => '.js-base input[name="url"]',
            :value   => 'http://localhost:3333',
          },
          {
            :execute => 'click',
            :css     => '.js-base .btn--primary',
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'channel',
          },
          {
            :execute => 'check',
            :element => :url,
            :result  => '#getting_started/channel',
          },
        ],
      },

      # create email account
      {
        :name     => 'getting started - base',
        :action   => [
          {
            :execute      => 'match',
            :css          => '.js-channel h2',
            :value        => 'Connect Channels',
            :match_result => true,
          },
          {
            :execute => 'click',
            :css     => '.js-channel .email .provider_name',
          },
          {
            :execute => 'set',
            :css     => '.js-intro input[name="realname"]',
            :value   => 'Some Realname',
          },
          {
            :execute => 'set',
            :css     => '.js-intro input[name="email"]',
            :value   => 'otest01@znuny.com',
          },
          {
            :execute => 'set',
            :css     => '.js-intro input[name="password"]',
            :value   => 'otest0142',
          },
          {
            :execute => 'click',
            :css     => '.js-intro .btn--primary',
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'testing',
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'verify',
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'invite',
          },
          {
            :execute => 'check',
            :element => :url,
            :result  => '#getting_started/agents',
          },
        ],
      },

      # invite agent1
      {
        :name     => 'getting started - agent 1',
        :action   => [
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'Invite',
            :match_result => true,
          },
          {
            :execute => 'set',
            :css     => '.js-agent input[name="firstname"]',
            :value   => 'Agent 1',
          },
          {
            :execute => 'set',
            :css     => '.js-agent input[name="lastname"]',
            :value   => 'Test',
          },
          {
            :execute => 'set',
            :css     => '.js-agent input[name="email"]',
            :value   => 'agent1@example.com',
          },
          {
            :execute => 'click',
            :css     => '.js-agent input[name="group_ids"][value="1"]',
          },
          {
            :execute => 'click',
            :css     => '.js-agent .btn--success',
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'Invitation sent',
          },
          {
            :execute => 'check',
            :element => :url,
            :result  => '#getting_started/agents',
          },
          {
            :execute => 'click',
            :css     => '.js-agent .btn--primary',
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'Activity Stream',
          },
          {
            :execute => 'check',
            :element => :url,
            :result  => '#dashboard',
          },
        ],
      },
    ]
    browser_single_test(tests)
  end
end
