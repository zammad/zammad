# encoding: utf-8
require 'browser_test_helper'
 
class Auth < ActiveSupport::TestCase
  test 'authentication' do
    tests = [
      {
        :name     => 'start',
        :instance => Watir::Browser.new,
        :url      => 'http://localhost:3000',
        :action   => [
          {
            :execute => 'check',
            :element => :form,
            :id      => 'login',
            :result  => true,
          },
          {
            :execute => 'check',
            :element => :button,
            :type    => 'submit',
            :result  => true,
          },
          {
            :execute => 'click',
            :element => :button,
            :type    => 'submit',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :execute => 'check',
            :element => :form,
            :id      => 'login',
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
            :element => :form,
            :id      => 'login',
            :result  => true,
          },
          {
            :execute => 'set',
            :element => :text_field,
            :name    => 'username',
            :value   => 'nicole.braun@zammad.org',
          },
          {
            :execute => 'set',
            :element => :text_field,
            :name    => 'password',
            :value   => 'test'
          },
          {
            :execute => 'click',
            :element => :button,
            :type    => 'submit',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :execute => 'check',
            :element => :form,
            :id      => 'login',
            :result  => false,
          },
        ],
      },
    ]
    browser_single_test(tests)
  end
end