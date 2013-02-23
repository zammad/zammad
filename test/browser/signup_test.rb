# encoding: utf-8
require 'browser_test_helper'
 
class SignupTest < TestCase
  def test_signup
    signup_user_email = 'signup-test-' + rand(999999).to_s + '@example.com'
    tests = [
      {
        :name     => 'start',
        :instance => browser_instance,
        :url      => browser_url,
        :action   => [
          {
            :execute => 'click',
            :css     => 'a[href="#signup"]',
          },
          {
            :execute => 'check',
            :css     => '#form-signup',
            :result  => true,
          },
        ],
      },
      {
        :name     => 'signup',
        :action   => [
          {
            :execute => 'set',
            :css     => 'input[name="firstname"]',
            :value   => 'Signup Firstname',
          },
          {
            :execute => 'set',
            :css     => 'input[name="lastname"]',
            :value   => 'Signup Lastname',
          },
          {
            :execute => 'set',
            :css     => 'input[name="email"]',
            :value   => signup_user_email,
          },
          {
            :execute => 'set',
            :css     => 'input[name="password"]',
            :value   => 'some-pass',
          },
          {
            :execute => 'set',
            :css     => 'input[name="password_confirm"]',
            :value   => 'some-pass',
          },
          {
            :execute => 'click',
            :css     => 'button.submit',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },

          # check action
          {
            :execute => 'check',
            :css     => '#login',
            :result  => false,
          },
          {
            :execute => 'check',
            :css     => '#form-signup',
            :result  => false,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => signup_user_email,
            :match_result => true,
          },
        ],
      },
    ]
    browser_single_test(tests)
  end
end