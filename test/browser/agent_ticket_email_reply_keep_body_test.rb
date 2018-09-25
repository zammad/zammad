
require 'browser_test_helper'

class AgentTicketEmailReplyKeepBodyTest < TestCase
  def test_reply_message_keep_body

    # merge ticket with closed tab
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    # create new ticket
    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'some subject 123äöü - reply test',
        body: 'some body 123äöü - reply test',
      },
    )
    sleep 1

    # fill body
    ticket_update(
      data: {
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
      css: '.content.active .js-reset',
      value: '(Discard your unsaved changes.|Verwerfen der)',
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
      css: '.content.active .js-reset',
      value: '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    # check body
    ticket_verify(
      data: {
        body: 'keep me',
      },
    )

  end

  def test_full_quote
    @browser = instance = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    ticket_open_by_title(
      title: 'Welcome to Zammad',
    )
    watch_for(
      css:      '.content.active .js-settingContainer .js-setting .dropdown-icon',
    )

    # enable email full quote in the ticket zoom config page
    scroll_to(
      position: 'botton',
      css:      '.content.active .js-settingContainer .js-setting .dropdown-icon',
    )
    click(css: '.content.active .js-settingContainer .js-setting .dropdown-icon')
    modal_ready()
    select(
      css: '.modal #ui_ticket_zoom_article_email_full_quote select[name="ui_ticket_zoom_article_email_full_quote"]',
      value: 'yes'
    )
    click(
      css: '.modal #ui_ticket_zoom_article_email_full_quote .btn[type="submit"]',
    )
    modal_close()
    modal_disappear()

    exists(css: '.content.active .ticket-article [data-type="emailReply"]')

    # scroll to reply - needed for chrome
    scroll_to(
      position: 'botton',
      css:      '.content.active .ticket-article [data-type="emailReply"]',
    )

    click(css: '.content.active .ticket-article [data-type="emailReply"]')

    full_text = @browser.find_element(css: '.content.active .article-new .articleNewEdit-body').text

    match = full_text.match(/\nOn (.*?) Nicole Braun wrote:/)
    assert match
    assert match[1]
    assert Time.zone.parse(match[1])
  end
end
