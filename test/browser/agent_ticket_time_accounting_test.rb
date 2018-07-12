
require 'browser_test_helper'

class AgentTicketTimeAccountingTest < TestCase
  def test_macro
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    # enable time accounting
    click(
      css: 'a[href="#manage"]',
    )
    click(
      css: '.content.active a[href="#manage/time_accounting"]',
    )
    switch(
      css: '.content.active .js-timeAccountingSetting',
      type: 'on',
    )

    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'some subject - time accounting#1',
        body: 'some body - time accounting#1',
      },
    )

    ticket_update(
      data: {
        body: 'some note',
      },
      do_not_submit: true,
    )
    click(
      css: '.active .js-submit',
    )

    watch_for(
      css: '.content.active .modal',
      value: 'Time Accounting',
    )
    set(
      css: '.content.active .modal [name=time_unit]',
      value: '4',
    )
    click(
      css: '.content.active .modal .js-submit',
    )
    watch_for_disappear(
      css: '.content.active .modal',
      value: 'Time Accounting',
    )
    watch_for(
      css: '.content.active .js-timeUnit',
      value: '4',
    )

    ticket2 = ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'some subject - time accounting#2',
        body: 'some body - time accounting#2',
      },
    )

    ticket_update(
      data: {
        body: 'some note',
      },
      do_not_submit: true,
    )
    click(
      css: '.active .js-submit',
    )

    watch_for(
      css: '.content.active .modal',
      value: 'Time Accounting',
    )
    set(
      css: '.content.active .modal [name=time_unit]',
      value: '4,6',
    )
    click(
      css: '.content.active .modal .js-submit',
    )
    watch_for_disappear(
      css: '.content.active .modal',
      value: 'Time Accounting',
    )
    watch_for(
      css: '.content.active .js-timeUnit',
      value: '4.6',
    )

    ticket_update(
      data: {
        body: 'some note2',
      },
      do_not_submit: true,
    )
    click(
      css: '.active .js-submit',
    )

    watch_for(
      css: '.content.active .modal',
      value: 'Time Accounting',
    )
    set(
      css: '.content.active .modal [name=time_unit]',
      value: '4abc',
    )
    click(
      css: '.content.active .modal .js-submit',
    )
    watch_for(
      css: '.content.active .modal [name=time_unit].has-error',
    )
    set(
      css: '.content.active .modal [name=time_unit]',
      value: '4 ',
    )
    click(
      css: '.content.active .modal .js-submit',
    )
    watch_for_disappear(
      css: '.content.active .modal',
      value: 'Time Accounting',
    )
    watch_for(
      css: '.content.active .js-timeUnit',
      value: '8.6',
    )

    # disable time accounting
    click(
      css: 'a[href="#manage"]',
    )
    click(
      css: '.content.active a[href="#manage/time_accounting"]',
    )
    switch(
      css: '.content.active .js-timeAccountingSetting',
      type: 'off',
    )

    # make sure "off" AJAX request gets completed
    # otherwise following tests might fail because
    # off still active timeaccounting
    logout()
  end

  def test_closing_time_accounting_modal_by_clicking_background
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    # enable time accounting
    click(
      css: 'a[href="#manage"]',
    )
    click(
      css: '.content.active a[href="#manage/time_accounting"]',
    )
    switch(
      css: '.content.active .js-timeAccountingSetting',
      type: 'on',
    )

    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'some subject - time accounting#3',
        body: 'some body - time accounting#3',
      },
    )

    ticket_update(
      data: {
        body: 'some note',
      },
      do_not_submit: true,
    )
    click(
      css: '.active .js-submit',
    )

    watch_for(
      css: '.content.active .modal',
      value: 'Time Accounting',
    )

    # Click outside the modal to make it disappear
    execute(
      js: 'document.elementFromPoint(300, 100).click();',
    )
    watch_for_disappear(
      css: '.content.active .modal',
      value: 'Time Accounting',
    )

    click(
      css: '.active .js-submit',
    )
    watch_for(
      css: '.content.active .modal',
      value: 'Time Accounting',
    )

    set(
      css: '.content.active .modal [name=time_unit]',
      value: '4',
    )
    click(
      css: '.content.active .modal .js-submit',
    )
    watch_for_disappear(
      css: '.content.active .modal',
      value: 'Time Accounting',
    )

    # disable time accounting
    click(
      css: 'a[href="#manage"]',
    )
    click(
      css: '.content.active a[href="#manage/time_accounting"]',
    )
    switch(
      css: '.content.active .js-timeAccountingSetting',
      type: 'off',
    )

    # make sure "off" AJAX request gets completed
    # otherwise following tests might fail because
    # off still active timeaccounting
    logout()
  end
end
