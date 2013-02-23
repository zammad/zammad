# encoding: utf-8
require 'browser_test_helper'
 
class AuthTest < TestCase
  def test_authentication
    tests = [
      {
        :name     => 'start',
        :instance => browser_instance,
        :url      => browser_url,
        :action   => [
          {
            :execute => 'check',
            :css     => '#login',
            :result  => true,
          },
          {
            :execute => 'check',
            :css     => '#login button',
            :result  => true,
          },
          {
            :execute => 'click',
            :css     => '#login button',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :execute => 'check',
            :css     => '#login',
            :result  => true,
          },
        ],
      },
      {
        :name     => 'login',
        :action   => [
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'check',
            :css     => '#login',
            :result  => true,
          },
          {
            :execute => 'set',
            :css     => 'input[name="username"]',
            :value   => 'nicole.braun@zammad.org',
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
            :value   => 3,
          },

          # check action
          {
            :execute => 'check',
            :css     => '#login',
            :result  => false,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'nicole.braun@zammad.org',
            :match_result => true,
          },
        ],
      },
    ]
    browser_single_test(tests)
  end
end