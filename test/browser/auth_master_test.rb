# encoding: utf-8
require 'browser_test_helper'

class AuthMasterTest < TestCase
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
            :value   => 5,
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
            :execute => 'check',
            :css     => '#login',
            :result  => true,
          },
          {
            :execute => 'set',
            :css     => 'input[name="username"]',
            :value   => 'master@example.com',
          },
          {
            :execute => 'set',
            :css     => 'input[name="password"]',
            :value   => 'test1234äöüß'
          },
          {
            :execute => 'click',
            :css     => '#login button',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },

          # check action
          {
            :execute  => 'check',
            :css      => '#login',
            :result   => false,
          },
          {
            :execute  => 'watch_for',
            :area     => 'body',
            :value    => 'master@example',
          },
        ],
      },
    ]
    browser_single_test(tests)
  end
end
