# encoding: utf-8
require 'browser_test_helper'

class AuthCustomerTest < TestCase
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
            :execute => 'login',
            :username => 'nicole.braun@zammad.org',
            :password => 'test',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :execute  => 'reload',
          },
          {
            :execute  => 'watch_for',
            :area     => 'body',
            :value    => 'Overviews',
          },
          {
            :execute  => 'match',
            :element  => :cookie,
            :value    => 'expires=>nil',
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
            :execute     => 'login',
            :username    => 'nicole.braun@zammad.org',
            :password    => 'test',
            :remember_me => true,
          },
          {
            :execute  => 'match',
            :element  => :cookie,
            :value    => 'expires=>.+?\d{4}.+?,',
          },
          {
            :execute  => 'logout',
          },
        ],
      },
    ]
    browser_single_test(tests)
  end

end
