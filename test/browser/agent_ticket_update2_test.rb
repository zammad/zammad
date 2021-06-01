# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketUpdate2Test < TestCase
  def test_work_with_two_browser_on_same_ticket_edit
    browser1 = browser_instance
    login(
      browser:  browser1,
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all(browser: browser1)

    browser2 = browser_instance
    login(
      browser:  browser2,
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all(browser: browser2)

    # create ticket
    ticket1 = ticket_create(
      browser: browser1,
      data:    {
        group:    'Users',
        customer: 'nicole',
        title:    'some level 3 <b>subject</b> 123äöü',
        body:     'some level 3 <b>body</b> 123äöü',
      }
    )

    # open ticket in second browser
    ticket_open_by_search(
      browser: browser2,
      number:  ticket1[:number],
    )
    watch_for(
      browser: browser2,
      css:     '.active div.ticket-article',
      value:   'some level 3 <b>body</b> 123äöü',
    )

    watch_for(
      browser: browser1,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--not-changed',
      value:   'AT', # agent1
    )
    watch_for(
      browser: browser2,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--not-changed',
      value:   'TA', # master
    )

    # change edit screen in instance 1
    ticket_update(
      browser:       browser1,
      data:          {
        body: 'some level 3 <b>body</b> in instance 1',
      },
      do_not_submit: true,
    )
    watch_for(
      browser:  browser1,
      css:      '.content.active .js-reset',
      value:    '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    watch_for(
      browser: browser1,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--not-changed',
      value:   'AT', # agent1
    )
    watch_for(
      browser: browser2,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--changed',
      value:   'TA', # master
    )

    # update ticket in instance 2
    ticket_update(
      browser:       browser2,
      data:          {
        body: 'some level 3 <b>body</b> in instance 2',
      },
      do_not_submit: true,
    )
    watch_for(
      browser:  browser2,
      css:      '.content.active .js-reset',
      value:    '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )
    watch_for(
      browser: browser1,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--changed',
      value:   'AT', # agent1
    )
    watch_for(
      browser: browser2,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--changed',
      value:   'TA', # master
    )

    click(
      browser: browser2,
      css:     '.active .js-submit',
    )

    # discard changes should gone away
    watch_for_disappear(
      browser:  browser2,
      css:      '.content.active .js-reset',
      value:    '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )
    ticket_verify(
      browser: browser2,
      data:    {
        body: '',
      },
    )

    watch_for(
      browser: browser1,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--not-changed',
      value:   'AT', # agent1
    )
    watch_for(
      browser: browser2,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--changed',
      value:   'TA', # master
    )

    # check content and edit screen in instance 1
    watch_for(
      browser: browser2,
      css:     '.active div.ticket-article',
      value:   'some level 3 <b>body</b> in instance 2',
      timeout: 1,
    )

    ticket_verify(
      browser: browser1,
      data:    {
        body: 'some level 3 <b>body</b> in instance 1',
      },
    )

    # update ticket in instance 1
    click(
      browser: browser1,
      css:     '.active .js-submit',
    )

    watch_for(
      browser: browser1,
      css:     '.active div.ticket-article',
      value:   'some level 3 <b>body</b> in instance 2',
    )
    sleep 2
    match_not(
      browser:  browser1,
      css:      '.content.active .js-reset',
      value:    '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    watch_for(
      browser: browser1,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--not-changed',
      value:   'AT', # agent1
    )
    watch_for(
      browser: browser2,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--not-changed',
      value:   'TA', # master
    )

    # check content in instance 2
    watch_for(
      browser: browser2,
      css:     '.active div.ticket-article',
      value:   'some level 3 <b>body</b> in instance 1',
    )

    # check content and edit screen in instance 1+2
    ticket_verify(
      browser: browser1,
      data:    {
        body: '',
      },
    )
    match_not(
      browser:  browser1,
      css:      '.content.active .js-reset',
      value:    '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    ticket_verify(
      browser: browser2,
      data:    {
        body: '',
      },
    )
    match_not(
      browser:  browser2,
      css:      '.content.active .js-reset',
      value:    '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    watch_for(
      browser: browser1,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--not-changed',
      value:   'AT', # agent1
    )
    watch_for(
      browser: browser2,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--not-changed',
      value:   'TA', # master
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
      data:    {
        body: '',
      },
    )
    match_not(
      browser:  browser1,
      css:      '.content.active .js-reset',
      value:    '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    ticket_verify(
      browser: browser2,
      data:    {
        body: '',
      },
    )
    match_not(
      browser:  browser2,
      css:      '.content.active .js-reset',
      value:    '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    watch_for(
      browser: browser1,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--not-changed',
      value:   'AT', # agent1
    )
    watch_for(
      browser: browser2,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--not-changed',
      value:   'TA', # master
    )

    # change form of ticket, reset, reload and verify in instance 2
    ticket_update(
      browser:       browser2,
      data:          {
        body: '22 some level 3 <b>body</b> in instance 2',
      },
      do_not_submit: true,
    )

    watch_for(
      browser:  browser2,
      css:      '.content.active .js-reset',
      value:    '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )
    sleep 3
    reload(
      browser: browser2,
    )
    sleep 3
    click(
      css:     '.content.active .js-reset',
      browser: browser2,
    )
    sleep 4
    ticket_verify(
      browser: browser2,
      data:    {
        body: '',
      },
    )

    # change form of ticket in instance 2
    ticket_update(
      browser:       browser2,
      data:          {
        body: '22 some level 3 <b>body</b> in instance 2',
      },
      do_not_submit: true,
    )

    watch_for(
      browser:  browser2,
      css:      '.content.active .js-reset',
      value:    '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )
    sleep 2

    watch_for(
      browser: browser1,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--changed',
      value:   'AT', # agent1
    )
    watch_for(
      browser: browser2,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--not-changed',
      value:   'TA', # master
    )

    reload(
      browser: browser2,
    )
    ticket_verify(
      browser: browser2,
      data:    {
        body: '22 some level 3 <b>body</b> in instance 2',
      },
    )
    watch_for(
      browser:  browser2,
      css:      '.content.active .js-reset',
      value:    '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    watch_for(
      browser: browser1,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--changed',
      value:   'AT', # agent1
    )
    watch_for(
      browser: browser2,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--not-changed',
      value:   'TA', # master
    )

    task_type(
      browser: browser2,
      type:    'stayOnTab',
    )

    click(
      browser: browser2,
      css:     '.active .js-submit',
    )

    # discard changes should gone away
    watch_for_disappear(
      browser:  browser2,
      css:      '.content.active .js-reset',
      value:    '(Discard your unsaved changes.|Verwerfen der)',
      no_quote: true,
    )

    watch_for(
      browser: browser1,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--not-changed',
      value:   'AT', # agent1
    )
    watch_for(
      browser: browser2,
      css:     '.content.active .js-attributeBar .js-avatar .avatar--not-changed',
      value:   'TA', # master
    )

    # check if new article is empty
    ticket_verify(
      browser: browser2,
      data:    {
        body: '',
      },
    )
    watch_for(
      browser: browser2,
      css:     '.active div.ticket-article',
      value:   '22 some level 3 <b>body</b> in instance 2',
    )
  end
end
