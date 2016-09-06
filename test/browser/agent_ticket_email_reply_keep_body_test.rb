# encoding: utf-8
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
end
