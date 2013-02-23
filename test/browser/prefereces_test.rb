# encoding: utf-8
require 'browser_test_helper'

class PreferencesTest < TestCase
  def test_preferences
    tests = [
      {
        :name     => 'preferences',
        :action   => [
          {
            :execute => 'click',
            :css     => 'a[href="#current_user"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#profile"]',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'click',
            :css     => 'a[href="#profile/language"]',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'check',
            :css     => '#language',
            :result  => true,
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'select',
            :css     => '#language select[name="locale"]',
            :value   => 'Deutsch',
          },
          {
            :execute => 'click',
            :css     => '#language button',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :execute => 'check',
            :css     => '#login',
            :result  => false,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'Sprache',
            :match_result => true,
          },
          {
            :execute => 'select',
            :css     => '#language select[name="locale"]',
            :value   => 'English (United States)',
          },
          {
            :execute => 'click',
            :css     => '#language button',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'Language',
            :match_result => true,
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests)
  end
end
