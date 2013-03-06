# encoding: utf-8
require 'browser_test_helper'

class ManageTest < TestCase
  def test_user
    user = 'manage-test-' + rand(999999).to_s
    user_email = user + '@example.com'
    tests = [
      {
        :name     => 'user',
        :action   => [
          {
            :execute => 'click',
            :css     => 'a[href="#admin"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#users"]',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'click',
            :css     => 'a[data-type="new"]',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'set',
            :css     => 'input[name=login]',
            :value   => 'some login' + user,
          },
          {
            :execute => 'set',
            :css     => 'input[name="firstname"]',
            :value   => 'Manage Firstname' + user,
          },
          {
            :execute => 'set',
            :css     => 'input[name="lastname"]',
            :value   => 'Manage Lastname' + user,
          },
          {
            :execute => 'set',
            :css     => 'input[name="email"]',
            :value   => user_email,
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
            :css     => 'input[name="role_ids"][value="3"]',
          },
          {
            :execute => 'click',
            :css     => 'button.submit',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => user,
            :match_result => true,
          },
          {
            :execute => 'click',
            :css     => 'a[data-type="edit"]:last-child',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'set',
            :css     => 'input[name="lastname"]',
            :value   => '2Manage Lastname' + user,
          },
          {
            :execute => 'click',
            :css     => 'button.submit',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => '2Manage Lastname' + user,
            :match_result => true,
          },
          {
            :execute => 'wait',
            :value   => 1,
          },

        ],
      },
    ]
    browser_signle_test_with_login(tests, { :username => 'master@example.com' })
  end
end
