# encoding: utf-8
require 'browser_test_helper'

class PreferencesTest < TestCase
  def test_preferences
    @browser = browser_instance
    login(
      :username => 'master@example.com',
      :password => 'test',
      :url      => browser_url,
    )
    tasks_close_all()

    # start ticket create
    ticket_create(
      :data => {
        :customer => 'nicole',
        :group    => 'Users',
        :title    => 'preferences lang check #1',
        :body     => 'preferences lang check #1',
      },
      :do_not_submit => true,
    )

    # start ticket zoom
    ticket = ticket_create(
      :data => {
        :customer => 'nicole',
        :group    => 'Users',
        :title    => 'preferences lang check #2',
        :body     => 'preferences lang check #2',
      },
    )

    # start user profile
    user_open_by_search(
      :value => 'Nicole',
    )

    # start organization profile
    organization_open_by_search(
      :value => 'Zammad Foundation',
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

    # check language in navbar
    watch_for(
      :css   => '#navigation',
      :value => 'Übersicht'
    )

    # check language in dashboard
    click( :css => '#navigation a[href="#dashboard"]' )
    watch_for(
      :css   => '.content.active',
      :value => 'Meine zugewiesenen'
    )

    # check language in overview
    click( :css => '#navigation a[href="#ticket/view"]' )
    watch_for(
      :css   => '.content.active',
      :value => 'Meine'
    )
    verify_title(
      :value => 'Meine zugewiesenen',
    )

    # check language in ticket create
    verify_task(
      :data => {
        :title => 'anruf',
      }
    )
    open_task(
      :data    => {
        :title => 'preferences lang check #1',
      }
    )
    watch_for(
      :css   => '.content.active',
      :value => 'kunde'
    )
    watch_for(
      :css   => '.content.active',
      :value => 'priorität'
    )
    watch_for(
      :css   => '.content.active [data-name="body"]',
      :value => 'preferences lang check #1'
    )
    verify_title(
      :value => 'anruf',
    )

    # check language in ticket zoom
    ticket_open_by_search(
      :number => ticket[:number],
    )
    watch_for(
      :css   => '.content.active',
      :value => 'erstellt'
    )
    watch_for(
      :css   => '.content.active',
      :value => 'priorität'
    )

    # check language in user profile
    open_task(
      :data    => {
        :title => 'Nicole',
      }
    )
    watch_for(
      :css   => '.content.active',
      :value => 'notiz'
    )
    watch_for(
      :css   => '.content.active',
      :value => 'e-mail'
    )
    watch_for(
      :css   => '.content.active',
      :value => 'aktion'
    )

    # check language in organization profile
    open_task(
      :data    => {
        :title => 'Zammad',
      }
    )
    watch_for(
      :css   => '.content.active',
      :value => 'notiz'
    )

    click( :css => 'a[href="#current_user"]' )
    click( :css => 'a[href="#profile"]' )
    click( :css => 'a[href="#profile/language"]' )
    select(
      :css   => '.language_item select[name="locale"]',
      :value => 'English (United States)',
    )
    click( :css => '.content button[type="submit"]' )
    sleep 2
    watch_for(
      :css   => 'body',
      :value => 'Language',
    )

    # check language in navbar
    watch_for(
      :css   => '#navigation',
      :value => 'Overview'
    )

    # check language in dashboard
    click( :css => '#navigation a[href="#dashboard"]' )
    watch_for(
      :css   => '.content.active',
      :value => 'My assig'
    )

    # check language in overview
    click( :css => '#navigation a[href="#ticket/view"]' )
    watch_for(
      :css   => '.content.active',
      :value => 'My'
    )
    verify_title(
      :value => 'My assig',
    )

    # check language in ticket create
    verify_task(
      :data => {
        :title => 'call',
      }
    )
    open_task(
      :data    => {
        :title => 'preferences lang check #1',
      }
    )
    watch_for(
      :css   => '.content.active',
      :value => 'customer'
    )
    watch_for(
      :css   => '.content.active',
      :value => 'priority'
    )
    watch_for(
      :css   => '.content.active [data-name="body"]',
      :value => 'preferences lang check #1'
    )
    verify_title(
      :value => 'call',
    )

    # check language in ticket zoom
    ticket_open_by_search(
      :number => ticket[:number],
    )
    watch_for(
      :css   => '.content.active',
      :value => 'create'
    )
    watch_for(
      :css   => '.content.active',
      :value => 'priority'
    )

    # check language in user profile
    open_task(
      :data    => {
        :title => 'Nicole',
      }
    )
    watch_for(
      :css   => '.content.active',
      :value => 'note'
    )
    watch_for(
      :css   => '.content.active',
      :value => 'email'
    )

    # check language in organization profile
    open_task(
      :data    => {
        :title => 'Zammad',
      }
    )
    watch_for(
      :css   => '.content.active',
      :value => 'note'
    )
    watch_for(
      :css   => '.content.active',
      :value => 'action'
    )

    # switch to de again
    click( :css => 'a[href="#current_user"]' )
    click( :css => 'a[href="#profile"]' )
    click( :css => 'a[href="#profile/language"]' )
    select(
      :css   => '.language_item select[name="locale"]',
      :value => 'Deutsch',
    )
    click( :css => '.content button[type="submit"]' )
    sleep 2
    watch_for(
      :css   => 'body',
      :value => 'Sprache',
    )
    sleep 4

    # check if language is still used after reload
    reload()
    watch_for(
      :css   => 'body',
      :value => 'Sprache',
    )

    # check language in navbar
    watch_for(
      :css   => '#navigation',
      :value => 'Übersicht'
    )

    # check language in dashboard
    click( :css => '#navigation a[href="#dashboard"]' )
    watch_for(
      :css   => '.content.active',
      :value => 'Meine'
    )

    # check language in overview
    click( :css => '#navigation a[href="#ticket/view"]' )
    watch_for(
      :css   => '.content.active',
      :value => 'Meine'
    )
  end
end