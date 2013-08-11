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
            :execute => 'click',
            :css     => 'a[href="#profile/language"]',
          },
          {
            :execute => 'check',
            :css     => '#language',
            :result  => true,
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
            :value   => 6,
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
            :value   => 4,
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
