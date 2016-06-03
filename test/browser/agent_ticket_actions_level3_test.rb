# encoding: utf-8
require 'browser_test_helper'

class AgentTicketActionsLevel3Test < TestCase
  def test_check_changes
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    # confirm on create
    ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'some changes',
        body: 'some body 123äöü - changes',
      },
      do_not_submit: true,
    )
    close_task(
      data: {
        title: 'some changes',
      },
      discard_changes: true,
    )
    sleep 1

    # confirm on zoom
    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'some changes',
        body: 'some body 123äöü - changes',
      },
    )
    ticket_update(
      data: {
        body: 'some note',
      },
      do_not_submit: true,
    )
    close_task(
      data: {
        title: 'some changes',
      },
      discard_changes: true,
    )

  end

  def test_work_with_two_browser_on_same_ticket_edit

    browser1 = browser_instance
    login(
      browser: browser1,
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all(browser: browser1)

    browser2 = browser_instance
    login(
      browser: browser2,
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all(browser: browser2)

    # create ticket
    ticket1 = ticket_create(
      browser: browser1,
      data: {
        group: 'Users',
        customer: 'nicole',
        title: 'some level 3 <b>subject</b> 123äöü',
        body: 'some level 3 <b>body</b> 123äöü',
      }
    )

    # open ticket in second browser
    ticket_open_by_search(
      browser: browser2,
      number: ticket1[:number],
    )
    watch_for(
      browser: browser2,
      css: '.active div.ticket-article',
      value: 'some level 3 <b>body</b> 123äöü',
    )

    # change edit screen in instance 1
    ticket_update(
      browser: browser1,
      data: {
        body: 'some level 3 <b>body</b> in instance 1',
      },
      do_not_submit: true,
    )
    watch_for(
      browser: browser1,
      css: '.content.active .js-reset',
      value: '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    # update ticket in instance 2
    ticket_update(
      browser: browser2,
      data: {
        body: 'some level 3 <b>body</b> in instance 2',
      },
      do_not_submit: true,
    )
    watch_for(
      browser: browser2,
      css: '.content.active .js-reset',
      value: '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    click(
      browser: browser2,
      css: '.active .js-submit',
    )

    # discard changes should gone away
    watch_for_disappear(
      browser: browser2,
      css: '.content.active .js-reset',
      value: '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )
    ticket_verify(
      browser: browser2,
      data: {
        body: '',
      },
    )

    # check content and edit screen in instance 1
    match(
      browser: browser2,
      css: '.active div.ticket-article',
      value: 'some level 3 <b>body</b> in instance 2',
    )

    ticket_verify(
      browser: browser1,
      data: {
        body: 'some level 3 <b>body</b> in instance 1',
      },
    )

    # update ticket in instance 1
    click(
      browser: browser1,
      css: '.active .js-submit',
    )

    watch_for(
      browser: browser1,
      css: '.active div.ticket-article',
      value: 'some level 3 <b>body</b> in instance 2',
    )
    sleep 1
    match_not(
      browser: browser1,
      css: '.content.active .js-reset',
      value: '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    # check content in instance 2
    watch_for(
      browser: browser2,
      css: '.active div.ticket-article',
      value: 'some level 3 <b>body</b> in instance 1',
    )

    # check content and edit screen in instance 1+2
    ticket_verify(
      browser: browser1,
      data: {
        body: '',
      },
    )
    match_not(
      browser: browser1,
      css: '.content.active .js-reset',
      value: '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    ticket_verify(
      browser: browser2,
      data: {
        body: '',
      },
    )
    match_not(
      browser: browser2,
      css: '.content.active .js-reset',
      value: '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    # reload instances, verify again
    reload(
      browser: browser1,
    )
    reload(
      browser: browser2,
    )

    # check content and edit screen in instance 1+2
    ticket_verify(
      browser: browser1,
      data: {
        body: '',
      },
    )
    match_not(
      browser: browser1,
      css: '.content.active .js-reset',
      value: '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    ticket_verify(
      browser: browser2,
      data: {
        body: '',
      },
    )
    match_not(
      browser: browser2,
      css: '.content.active .js-reset',
      value: '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    # change form of ticket, reset, reload and verify in instance 2
    ticket_update(
      browser: browser2,
      data: {
        body: '22 some level 3 <b>body</b> in instance 2',
      },
      do_not_submit: true,
    )

    watch_for(
      browser: browser2,
      css: '.content.active .js-reset',
      value: '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )
    sleep 3
    reload(
      browser: browser2,
    )
    sleep 3
    click(
      css: '.content.active .js-reset',
      browser: browser2,
    )
    sleep 4
    ticket_verify(
      browser: browser2,
      data: {
        body: '',
      },
    )

    # change form of ticket in instance 2
    ticket_update(
      browser: browser2,
      data: {
        body: '22 some level 3 <b>body</b> in instance 2',
      },
      do_not_submit: true,
    )

    watch_for(
      browser: browser2,
      css: '.content.active .js-reset',
      value: '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )
    sleep 2

    reload(
      browser: browser2,
    )
    ticket_verify(
      browser: browser2,
      data: {
        body: '22 some level 3 <b>body</b> in instance 2',
      },
    )
    watch_for(
      browser: browser2,
      css: '.content.active .js-reset',
      value: '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    task_type(
      browser: browser2,
      type:    'stayOnTab',
    )

    click(
      browser: browser2,
      css: '.active .js-submit',
    )

    # discard changes should gone away
    watch_for_disappear(
      browser: browser2,
      css: '.content.active .js-reset',
      value: '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    # check if new article is empty
    ticket_verify(
      browser: browser2,
      data: {
        body: '',
      },
    )
    watch_for(
      browser: browser2,
      css: '.active div.ticket-article',
      value: '22 some level 3 <b>body</b> in instance 2',
    )
  end
end
