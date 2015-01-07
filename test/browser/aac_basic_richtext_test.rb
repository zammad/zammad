# encoding: utf-8
require 'browser_test_helper'

class AACBasicRichtextTest < TestCase
  def test_preferences
    tests = [
      {
        :name     => 'richtext single line',
        :action   => [
          {
            :execute => 'click',
            :css     => 'a[href="#current_user"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#layout_ref"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#layout_ref/richtext"]',
          },
          {
            :execute => 'set',
            :css     => '#content .text-1',
            :value   => 'some test for browser ',
            :slow  => true,
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :execute => 'sendkey',
            :value   => :enter,
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'sendkey',
            :value   => 'and some other for browser',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute      => 'match',
            :css          => '#content .text-1',
            :value        => 'some test for browser and some other for browser',
            :match_result => true,
          },
        ],
      },
      {
        :name     => 'richtext multi line',
        :action   => [
          {
            :execute => 'set',
            :css     => '#content .text-3',
            :value   => 'some test for browser ',
            :slow  => true,
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :execute => 'sendkey',
            :value   => :enter,
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'sendkey',
            :value   => 'and some other for browser',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute      => 'match',
            :css          => '#content .text-3',
            :value        => "some test for browser\nand some other for browser",
            :match_result => true,
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests, { :username => 'master@example.com' })
  end
end