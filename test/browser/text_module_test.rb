# encoding: utf-8
require 'browser_test_helper'

class TextModuleTest < TestCase
  def test_user
    random = 'text_module_test_' + rand(999999).to_s
    random2 = 'text_module_test_' + rand(999999).to_s
    user_email = random + '@example.com'

    # user
    tests = [
      {
        :name     => 'add #1',
        :action   => [
          {
            :execute => 'click',
            :css     => 'a[href="#admin"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#text_modules"]',
          },
          {
            :execute => 'wait',
            :value   => 1,
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
            :value   => 'some name' + random,
          },
          {
            :execute => 'set',
            :css     => 'input[name="keywords"]',
            :value   => random,
          },
          {
            :execute => 'set',
            :css     => 'textarea[name="content"]',
            :value   => 'some content' + random,
          },
          {
            :execute => 'click',
            :css     => '.modal button.submit',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => random,
            :match_result => true,
          },
        ],
      },
      {
        :name     => 'add #2',
        :action   => [
          {
            :execute => 'click',
            :css     => 'a[href="#admin"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#text_modules"]',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'click',
            :css     => 'a[data-type="new"]',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'set',
            :css     => 'input[name=name]',
            :value   => 'some name' + random2,
          },
          {
            :execute => 'set',
            :css     => 'input[name="keywords"]',
            :value   => random2,
          },
          {
            :execute => 'set',
            :css     => 'textarea[name="content"]',
            :value   => 'some content' + random2,
          },
          {
            :execute => 'click',
            :css     => '.modal button.submit',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => random2,
            :match_result => true,
          },
        ],
      },
      {
        :name     => 'verify usage',
        :action   => [
          {
            :execute => 'click',
            :css     => 'a[href="#new"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#ticket_create/call_outbound"]',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'set',
            :css     => '.active textarea[name=body]',
            :value   => '::' + random,
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => random,
            :match_result => true,
          },
          {
            :execute => 'sendkey',
            :css     => '.active textarea[name=body]',
            :value   => :enter,
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute      => 'match',
            :css          => '.active textarea[name=body]',
            :value        => random,
            :match_result => true,
          },
        ],

      },
    ]
    browser_signle_test_with_login(tests, { :username => 'master@example.com' })
  end
end
