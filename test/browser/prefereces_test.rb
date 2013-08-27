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
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'Sprache',
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
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'Language',
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests)
  end
end
