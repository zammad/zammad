# encoding: utf-8
require 'browser_test_helper'

class Preferences < ActiveSupport::TestCase
  test 'preferences' do
    tests = [
      {
        :name     => 'preferences',
        :action   => [
          {
            :execute => 'click',
            :element => :link,
            :href    => '#current_user',
          },
          {
            :execute => 'click',
            :element => :link,
            :href    => '#profile',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'click',
            :element => :link,
            :href    => '#profile/language',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'check',
            :element => :div,
            :id      => 'language',
            :result  => true,
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'select',
            :element => :select_list,
            :name    => 'locale',
            :value   => 'Deutsch',
          },
          {
            :execute => 'click',
            :element => :button,
            :type    => 'submit',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :execute => 'check',
            :element => :form,
            :id      => 'login',
            :result  => false,
          },
          {
            :execute      => 'match',
            :element      => :body,
            :value        => 'Sprache',
            :match_result => true,
          },
          {
            :execute => 'select',
            :element => :select_list,
            :name    => 'locale',
            :value   => 'English (United States)',
          },
          {
            :execute => 'click',
            :element => :button,
            :type    => 'submit',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :execute      => 'match',
            :element      => :body,
            :value        => 'Language',
            :match_result => true,
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests)
  end
end
