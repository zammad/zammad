# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class TranslationTest < TestCase

  def test_preferences
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    click(css: 'a[href="#current_user"]')
    click(css: 'a[href="#profile"]')
    click(css: 'a[href="#profile/language"]')
    select(
      css:   '.js-language [name="locale"]',
      value: 'English (United States)',
    )
    click(css: '.content.active button[type="submit"]')
    sleep 2
    watch_for(
      css:   'body',
      value: 'Language',
    )

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/translation"]')

    watch_for(
      css:   '.content.active',
      value: 'English is the source language, so we have nothing to translate',
    )

    click(css: 'a[href="#current_user"]')
    click(css: 'a[href="#profile"]')
    click(css: 'a[href="#profile/language"]')
    select(
      css:   '.js-language [name="locale"]',
      value: 'Deutsch',
    )
    click(css: '.content.active button[type="submit"]')
    watch_for(
      css:   'body',
      value: 'Sprache',
    )

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/translation"]')

    notify_close(optional: true) # to be not in click area
    set(
      css:   '.content.active input.js-Item[data-source="Translations"]',
      value: 'Übersetzung2',
    )
    sleep 5 # wait until nofify is gone
    click(css: '#global-search')
    sleep 4 # wait till rerender

    click(css: 'a[href="#dashboard"]')
    sleep 2 # wait till nav is rendered

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/translation"]')

    match(
      css:   '.content.active .sidebar',
      value: 'Übersetzung2',
    )
    match(
      css:   '.content.active input.js-Item[data-source="Translations"]',
      value: 'Übersetzung2',
    )

    execute(
      js: "$('.js-Item[data-source=Translations]').parents('tr').find('.js-Reset:visible').click()",
    )
    sleep 5

    match(
      css:   '.content.active .sidebar',
      value: 'Übersetzung2',
    )
    match_not(
      css:   '.content.active input.js-Item[data-source="Translations"]',
      value: 'Übersetzung2',
    )

    click(css: 'a[href="#dashboard"]')
    sleep 4 # wait till rerender

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/translation"]')
    sleep 2

    match_not(
      css:   '.content.active .sidebar',
      value: 'Übersetzung2',
    )
    match_not(
      css:   '.content.active input.js-Item[data-source="Translations"]',
      value: 'Übersetzung2',
    )
    match_not(
      css:   '.content.active .sidebar',
      value: 'Übersetzung2',
    )

    @browser.action.key_down(:control)
            .key_down(:shift)
            .send_keys('t')
            .key_up(:shift)
            .key_up(:control)
            .perform

    watch_for(
      css:   'span.translation[title="Overviews"]',
      value: 'Übersichten',
    )
    set(
      css:   'span.translation[title="Overviews"]',
      value: 'Übersichten123',
    )
    sleep 1
    click(css: 'a[href="#dashboard"]')
    sleep 5

    @browser.action.key_down(:control)
            .key_down(:shift)
            .send_keys('t')
            .key_up(:shift)
            .key_up(:control)
            .perform

    sleep 5
    exists_not(
      css: 'span.translation[title="Overviews"]',
    )
    match(
      css:   '.js-menu',
      value: 'Übersichten123',
    )

    reload()
    exists_not(
      css: 'span.translation[title="Overviews"]',
    )
    match(
      css:   '.js-menu',
      value: 'Übersichten123',
    )

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/translation"]')
    sleep 4

    match(
      css:   '.content.active input.js-Item[data-source="Overviews"]',
      value: 'Übersichten123',
    )

    execute(
      js: "$('.js-Item[data-source=Overviews]').parents('tr').find('.js-Reset:visible').click()",
    )
    sleep 5

    click(css: 'a[href="#dashboard"]')
    sleep 5

    match_not(
      css:   '.js-menu',
      value: 'Übersichten123',
    )
    match(
      css:   '.js-menu',
      value: 'Übersichten',
    )

    click(css: 'a[href="#current_user"]')
    click(css: 'a[href="#profile"]')
    click(css: 'a[href="#profile/language"]')
    select(
      css:   '.js-language [name="locale"]',
      value: 'English (United States)',
    )
    click(css: '.content.active button[type="submit"]')
    sleep 2
    watch_for(
      css:   'body',
      value: 'Language',
    )
    sleep 5

    @browser.action.key_down(:control)
            .key_down(:shift)
            .send_keys('t')
            .key_up(:shift)
            .key_up(:control)
            .perform

    watch_for(
      css:   'span.translation[title="Overviews"]',
      value: 'Overviews',
    )
    set(
      css:   'span.translation[title="Overviews"]',
      value: 'Overviews123',
    )
    sleep 1
    click(css: 'a[href="#dashboard"]')
    sleep 5

    @browser.action.key_down(:control)
            .key_down(:shift)
            .send_keys('t')
            .key_up(:shift)
            .key_up(:control)
            .perform

    sleep 5
    exists_not(
      css: 'span.translation[title="Overviews"]',
    )
    match(
      css:   '.js-menu',
      value: 'Overviews123',
    )

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/translation"]')
    sleep 4

    match(
      css:   '.content.active input.js-Item[data-source="Overviews"]',
      value: 'Overviews123',
    )
    match_not(
      css:   '.content.active',
      value: 'English is the source language, so we have nothing to translate',
    )

    execute(
      js: "$('.js-Item[data-source=Overviews]').parents('tr').find('.js-Reset:visible').click()",
    )

    watch_for(
      css:   '.content.active',
      value: 'English is the source language, so we have nothing to translate',
    )

  end

  def test_admin_sync
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    click(css: 'a[href="#current_user"]')
    click(css: 'a[href="#profile"]')
    click(css: 'a[href="#profile/language"]')
    select(
      css:   '.js-language [name="locale"]',
      value: 'Deutsch',
    )
    click(css: '.content.active button[type="submit"]')
    watch_for(
      css:   'body',
      value: 'Sprache',
    )

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/translation"]')

    watch_for(
      css:   '.content.active',
      value: 'Inline Übersetzung',
    )

    click(css: '.content.active .js-syncChanges')

    modal_ready()
    watch_for(
      css:   '.content.active .modal',
      value: 'Letzte Übersetzung laden',
    )
    modal_disappear(
      timeout: 6.minutes,
    )

    click(css: 'a[href="#current_user"]')
    click(css: 'a[href="#profile"]')
    click(css: 'a[href="#profile/language"]')
    select(
      css:   '.js-language [name="locale"]',
      value: 'English (United States)',
    )
    click(css: '.content.active button[type="submit"]')
    watch_for(
      css:   'body',
      value: 'Language',
    )

  end

  # see https://github.com/zammad/zammad/issues/2056
  #
  # The purpose of this test is to verify that
  # the Translation admin panel automatically re-renders
  # under certain edge cases:
  #
  # Clicking into the Translation panel from another admin panel ALWAYS causes a rerender,
  # but clicking into it from, e.g., a Ticket or the Dashboard does not.
  #
  # We want to ensure that in the latter case,
  # the Translation panel rerenders automatically if there are new phrases to translate.
  def test_rerender_when_new_phrases_detected
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    click(css: 'a[href="#current_user"]')
    click(css: 'a[href="#profile"]')
    click(css: 'a[href="#profile/language"]')
    select(
      css:   '.js-language [name="locale"]',
      value: 'Deutsch',
    )
    click(css: '.content.active button[type="submit"]')
    watch_for(
      css:   'body',
      value: 'Sprache',
    )

    # The only way to test the edge case describe above
    # (i.e., visiting the Translation panel directly from a Ticket or the Dashboard)
    # is to first click into the admin settings and visit the Translation panel,
    # then leave, then come back.
    #
    # (/#manage remembers the most-recent admin panel.)
    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#system/translation"]')

    watch_for(
      css:   '.content.active',
      value: 'Inline Übersetzung',
    )

    click(css: 'a[href="#dashboard"]')

    new_ui_phrase = 'Charlie bit me!'
    @browser.execute_script("App.i18n.translateContent('#{new_ui_phrase}')")

    click(css: 'a[href="#manage"]')

    watch_for(
      css:     %(td[title="#{new_ui_phrase}"]),
      value:   new_ui_phrase,
      timeout: 3
    )

  end

end
