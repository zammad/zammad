# encoding: utf-8
require 'browser_test_helper'
 
class AuthMaster < ActiveSupport::TestCase
  test 'authentication' do
    tests = [
      {
        :name     => 'start',
        :instance => Watir::Browser.new,
        :url      => 'http://localhost:3000',
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
            :value        => 'master@example',
            :match_result => true,
          },
        ],
      },
    ]
    browser_single_test(tests)
  end
end