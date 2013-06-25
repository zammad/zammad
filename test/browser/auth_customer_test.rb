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
          {
            :execute => 'reload',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'nicole.braun@zammad.org',
            :match_result => true,
          },
          {
            :execute      => 'match',
            :element      => :cookie,
            :value        => 'expires=>nil',
          },
        ],
      },
    ]
    browser_single_test(tests)
  end

  def test_authentication_new_browser_without_permanent_cookie_no_session_should_be
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
        ],
      },
    ]
    browser_single_test(tests)
  end

  def test_new_browser_with_permanent_cookie_login
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
            :css     => '#login [name="remember_me"]',
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
          {
            :execute      => 'match',
            :element      => :cookie,
            :value        => 'expires=>.+?\d{4}.+?,',
          },
        ],
      },
    ]
    browser_single_test(tests)
  end

end
