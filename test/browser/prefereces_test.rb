# encoding: utf-8
require 'browser_test_helper'

class PreferencesTest < TestCase
  def test_preferences
    @browser = browser_instance
    login(
      :username => 'nicole.braun@zammad.org',
      :password => 'test',
      :url      => browser_url,
    )
    click( :css => 'a[href="#current_user"]' )
    click( :css => 'a[href="#profile"]' )
    click( :css => 'a[href="#profile/language"]' )
    select(
      :css   => '.language_item select[name="locale"]',
      :value => 'Deutsch',
    )
    click( :css => '.content button[type="submit"]' )
    watch_for(
      :css   => 'body',
      :value => 'Sprache',
    )
    select(
      :css   => '.language_item select[name="locale"]',
      :value => 'English (United States)',
    )
    click( :css => '.content button[type="submit"]' )
    watch_for(
      :css   => 'body',
      :value => 'Language',
    )
    select(
      :css   => '.language_item select[name="locale"]',
      :value => 'Deutsch',
    )
    click( :css => '.content button[type="submit"]' )
    watch_for(
      :css   => 'body',
      :value => 'Sprache',
    )
    reload()
    watch_for(
      :css   => 'body',
      :value => 'Sprache',
    )
  end
end