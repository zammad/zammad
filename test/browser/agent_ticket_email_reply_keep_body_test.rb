# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketEmailReplyKeepBodyTest < TestCase
  def test_reply_message_keep_body

    # merge ticket with closed tab
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # create new ticket
    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'some subject 123äöü - reply test',
        body:     'some body 123äöü - reply test',
      },
    )
    sleep 1

    # fill body
    ticket_update(
      data:          {
        body: 'keep me',
      },
      do_not_submit: true,
    )

    # scroll to reply - needed for chrome
    scroll_to(
      position: 'botton',
      css:      '.content.active [data-type="emailReply"]',
    )

    # click reply
    click(css: '.content.active [data-type="emailReply"]')

    # check body
    watch_for(
      css:      '.content.active .js-reset',
      value:    '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    # check body
    ticket_verify(
      data: {
        body: 'keep me',
      },
    )

    # scroll to reply - needed for chrome
    sleep 5
    scroll_to(
      position: 'botton',
      css:      '.content.active [data-type="emailReply"]',
    )
    # click reply
    click(css: '.content.active [data-type="emailReply"]')

    # check body
    watch_for(
      css:      '.content.active .js-reset',
      value:    '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    # check body
    ticket_verify(
      data: {
        body: 'keep me',
      },
    )

  end

  def change_quote_config(params = {})
    scroll_to(
      position: 'botton',
      css:      '.content.active .js-settingContainer .js-setting',
    )
    click(css: '.content.active .js-settingContainer .js-setting')
    modal_ready()
    select(
      css:   params[:css],
      value: params[:value]
    )
    click(
      css: params[:submit_css],
    )
    modal_close()
    modal_disappear()
  end

  def test_full_quote
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    ticket_open_by_title(
      title: 'Welcome to Zammad',
    )
    watch_for(
      css: '.content.active .js-settingContainer .js-setting .dropdown-icon',
    )

    # enable email full quote in the ticket zoom config page
    change_quote_config(
      css:        '.modal #ui_ticket_zoom_article_email_full_quote select[name="ui_ticket_zoom_article_email_full_quote"]',
      value:      'yes',
      submit_css: '.modal #ui_ticket_zoom_article_email_full_quote .btn[type="submit"]',
    )
    change_quote_config(
      css:        '.modal #ui_ticket_zoom_article_email_full_quote_header select[name="ui_ticket_zoom_article_email_full_quote_header"]',
      value:      'yes',
      submit_css: '.modal #ui_ticket_zoom_article_email_full_quote_header .btn[type="submit"]',
    )

    scroll_to(
      position: 'botton',
      css:      '.content.active .ticket-article [data-type="emailReply"]',
    )
    click(css: '.content.active .ticket-article [data-type="emailReply"]')

    full_text = @browser.find_element(css: '.content.active .article-new .articleNewEdit-body').text

    match = full_text.match(%r{\nOn (.*?) Nicole Braun wrote:})
    assert match
    assert match[1]
    assert Time.zone.parse(match[1])

    # try again, but with the full quote header disabled
    tasks_close_all()
    ticket_open_by_title(
      title: 'Welcome to Zammad',
    )
    change_quote_config(
      css:        '.modal #ui_ticket_zoom_article_email_full_quote_header select[name="ui_ticket_zoom_article_email_full_quote_header"]',
      value:      'no',
      submit_css: '.modal #ui_ticket_zoom_article_email_full_quote_header .btn[type="submit"]',
    )

    scroll_to(
      position: 'botton',
      css:      '.content.active .ticket-article [data-type="emailReply"]',
    )
    click(css: '.content.active .ticket-article [data-type="emailReply"]')

    full_text = @browser.find_element(css: '.content.active .article-new .articleNewEdit-body').text

    match = full_text.match(%r{\nOn (.*?) Nicole Braun wrote:})
    assert_nil match

    # after test, turn full quote header back on again
    tasks_close_all()
    ticket_open_by_title(
      title: 'Welcome to Zammad',
    )
    change_quote_config(
      css:        '.modal #ui_ticket_zoom_article_email_full_quote_header select[name="ui_ticket_zoom_article_email_full_quote_header"]',
      value:      'yes',
      submit_css: '.modal #ui_ticket_zoom_article_email_full_quote_header .btn[type="submit"]',
    )
  end

  # Regression test for issue #2344 - Missing translation for Full-Quote-Text "on xy wrote"
  def test_full_quote_german_locale
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    ticket_open_by_title(
      title: 'Welcome to Zammad',
    )
    watch_for(
      css: '.content.active .js-settingContainer .js-setting .dropdown-icon',
    )

    # enable email full quote in the ticket zoom config page
    change_quote_config(
      css:        '.modal #ui_ticket_zoom_article_email_full_quote select[name="ui_ticket_zoom_article_email_full_quote"]',
      value:      'yes',
      submit_css: '.modal #ui_ticket_zoom_article_email_full_quote .btn[type="submit"]',
    )

    # switch user profile language to German
    switch_language(
      data: {
        language: 'Deutsch'
      },
    )

    ticket_open_by_title(
      title: 'Welcome to Zammad',
    )

    scroll_to(
      position: 'botton',
      css:      '.content.active .ticket-article [data-type="emailReply"]',
    )
    click(css: '.content.active .ticket-article [data-type="emailReply"]')

    full_text = @browser.find_element(css: '.content.active .article-new .articleNewEdit-body').text

    match = full_text.match(%r{\nAm (.*?), schrieb Nicole Braun:})
    assert match

    datestamp = match[1]
    assert datestamp
    assert Time.zone.parse(datestamp)
    day_of_week = datestamp.split(',').first
    assert %w[Montag Dienstag Mittwoch Donnerstag Freitag Samstag Sonntag].include? day_of_week

    # switch user profile language to English again for other tests
    switch_language(
      data: {
        language: 'English (United States)'
      },
    )
  end
end
