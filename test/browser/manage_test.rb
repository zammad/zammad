# encoding: utf-8
require 'browser_test_helper'

class ManageTest < TestCase
  def test_user
    random = 'manage-test-' + rand(999999).to_s
    user_email = random + '@example.com'

    # user
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
            :value   => 'some login' + random,
          },
          {
            :execute => 'set',
            :css     => 'input[name="firstname"]',
            :value   => 'Manage Firstname' + random,
          },
          {
            :execute => 'set',
            :css     => 'input[name="lastname"]',
            :value   => 'Manage Lastname' + random,
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
            :css     => '.modal button.submit',
          },
          {
            :execute  => 'watch_for',
            :area     => 'body',
            :value    => random,
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
            :value   => '2Manage Lastname' + random,
          },
          {
            :execute => 'click',
            :css     => '.modal button.submit',
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => '2Manage Lastname' + random,
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
        ],
      },
      {
        :name     => 'sla',
        :action   => [
          {
            :execute => 'click',
            :css     => 'a[href="#admin"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#slas"]',
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
            :css     => 'input[name=name]',
            :value   => 'some sla' + random,
          },
          {
            :execute => 'set',
            :css     => 'input[name="first_response_time"]',
            :value   => 61,
          },
          {
            :execute => 'click',
            :css     => '.modal button.submit',
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => random,
          },
          {
            :execute => 'click',
            :css     => 'a[data-type="edit"]:last-child',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'set',
            :css     => 'input[name=name]',
            :value   => 'some sla update ' + random,
          },
          {
            :execute => 'set',
            :css     => 'input[name="first_response_time"]',
            :value   => 121,
          },
          {
            :execute => 'click',
            :css     => '.modal button.submit',
          },
          {
            :execute  => 'watch_for',
            :area     => 'body',
            :value    => 'some sla update ' + random,
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'click',
            :css     => 'a[data-type="destroy"]:last-child',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'click',
            :css     => '.modal .submit',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'some sla update ' + random,
            :match_result => false,
          },
          {
            :execute => 'click',
            :css     => 'a[href="#/"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#admin"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#slas"]',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'some sla update ' + random,
            :match_result => false,
          },
          {
            :execute => 'reload',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'click',
            :css     => 'a[href="#/"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#admin"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#slas"]',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'some sla update ' + random,
            :match_result => false,
          },

        ],

      },
    ]
    browser_signle_test_with_login(tests, { :username => 'master@example.com' })
  end
end
