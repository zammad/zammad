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
            :css     => 'a[href="#manage"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#manage/users"]',
          },
          {
            :execute    => 'create_user',
            :login      => 'some login' + random,
            :firstname  => 'Manage Firstname' + random,
            :lastname   => 'Manage Lastname' + random,
            :email      => user_email,
            :password   => 'some-pass',
          },
          {
            :execute  => 'watch_for',
            :area     => 'body',
            :value    => random,
          },
          {
            :execute => 'click',
            :css     => '.table-overview tr:last-child td',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'set',
            :css     => '.modal input[name="lastname"]',
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
            :css     => 'a[href="#manage"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#manage/slas"]',
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
            :css     => '.modal input[name=name]',
            :value   => 'some sla' + random,
          },
          {
            :execute => 'set',
            :css     => '.modal input[name="first_response_time"]',
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
            :execute => 'wait',
            :value   => 3,
          },
          {
            :execute => 'click',
            :css     => '.table-overview tr:last-child td',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'set',
            :css     => '.modal input[name=name]',
            :value   => 'some sla update ' + random,
          },
          {
            :execute => 'set',
            :css     => '.modal input[name="first_response_time"]',
            :value   => 121,
          },
          {
            :execute => 'click',
            :css     => '.modal button.submit',
          },
          {
            :execute  => 'watch_for',
            :area     => 'body table',
            :value    => 'some sla update ' + random,
          },
          {
            :execute => 'wait',
            :value   => 4,
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
            :value   => 3,
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
            :css     => 'a[href="#manage"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#manage/slas"]',
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
            :css     => 'a[href="#manage"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#manage/slas"]',
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
