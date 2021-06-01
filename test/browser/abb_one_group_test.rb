# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketActionLevel0Test < TestCase

  def test_aaa_agent_ticket_create_with_one_group
    agent = "bob.smith_one_group#{rand(99_999_999)}"

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # create new ticket
    ticket_create(
      data: {
        customer: 'nico',
        group:    '-NONE-',
        title:    'some subject 123äöü - one group 1',
        body:     'some body 123äöü - one group 1',
      },
    )
    sleep 1

    # update ticket
    ticket_update(
      data: {
        state: 'closed',
        group: '-NONE-',
        body:  'some body 1234 äöüß - one group 1 - update',
      },
    )

    tasks_close_all()

    # invite agent (with one group)
    click(css: '#navigation a[href="#dashboard"]')
    click(css: '.active.content .tab[data-area="first-steps-widgets"]')
    watch_for(
      css:   '.active.content',
      value: 'Configuration',
    )
    click(css: '.active.content .js-inviteAgent')
    modal_ready()
    set(
      css:   '.modal [name="firstname"]',
      value: 'Bob',
    )
    set(
      css:   '.modal [name="lastname"]',
      value: 'Smith',
    )
    set(
      css:   '.modal [name="email"]',
      value: "#{agent}@example.com",
    )
    exists(
      displayed: false,
      css:       '.modal .js-groupList',
    )
    exists(
      css: '.modal .js-groupListItem[value=full]:checked',
    )
    click(
      css:  '.modal button.btn.btn--primary',
      fast: true,
    )
    watch_for(
      css:   'body div.modal',
      value: 'Sending',
    )
    watch_for_disappear(
      css:   'body div.modal',
      value: 'Sending',
    )

    click(css: '#navigation a[href="#dashboard"]')
    click(css: '.active.content .tab[data-area="first-steps-widgets"]')
    watch_for(
      css:   '.active.content',
      value: 'Configuration',
    )
    click(css: '.active.content .js-inviteAgent')
    modal_ready()
    set(
      css:   '.modal [name="firstname"]',
      value: 'Bob2',
    )
    set(
      css:   '.modal [name="lastname"]',
      value: 'Smith2',
    )
    set(
      css:   '.modal [name="email"]',
      value: "#{agent}2@example.com",
    )

    # disable agent role
    uncheck(
      css: '.modal [name="role_ids"][value=2]',
    )

    exists(
      displayed: false,
      css:       '.modal .js-groupList',
    )
    exists_not(
      css: '.modal .js-groupListItem[value=full]:checked',
    )

    # enable agent role
    check(
      css: '.modal [name="role_ids"][value=2]',
    )

    exists(
      displayed: false,
      css:       '.modal .js-groupList',
    )
    exists(
      css: '.modal .js-groupListItem[value=full]:checked',
    )

    click(
      css:  '.modal button.btn.btn--primary',
      fast: true,
    )
    watch_for(
      css:   'body div.modal',
      value: 'Sending',
    )
    watch_for_disappear(
      css:   'body div.modal',
      value: 'Sending',
    )

    tasks_close_all()

  end

  def test_bbb_customer_ticket_create_with_one_group

    @browser = browser_instance
    login(
      username: 'nicole.braun@zammad.org',
      password: 'test',
      url:      browser_url,
    )

    # customer ticket create
    click(css: 'a[href="#new"]', only_if_exists: true)
    click(css: 'a[href="#customer_ticket_new"]')

    watch_for(
      css:   '.newTicket',
      value: 'New Ticket',
    )
    exists_not(css: '.newTicket select[name="group_id"]')

    set(
      css:   '.newTicket input[name="title"]',
      value: 'one group',
    )
    set(
      css:   '.newTicket [data-name="body"]',
      value: 'one group body',
    )
    click(css: '.newTicket button.js-submit', wait: 5)

    # check if ticket is shown
    location_check(url: '#ticket/zoom/')

    match(
      css:      '.active div.ticket-article',
      value:    'one group body',
      no_quote: true,
    )

    # update ticket
    set(
      css:      '.active [data-name="body"]',
      value:    'one group - some body 1234 äöüß',
      no_click: true,
    )

    task_type(
      type: 'stayOnTab',
    )

    click(css: '.active .js-submit')

    watch_for(
      css:   '.active div.ticket-article',
      value: 'one group - some body 1234 äöüß',
    )

    tasks_close_all()

  end

  def test_ccc_agent_ticket_create_with_more_groups

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    group_create(
      data: {
        name:   "some group #{rand(999_999_999)}",
        member: [
          {
            login:  'master@example.com',
            access: 'full',
          },
          {
            login:  'agent1@example.com',
            access: 'full',
          },
        ],
      },
    )

    # wait to push new group dependencies to browser (to show group selection)
    sleep 12

    # create new ticket
    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'some subject 123äöü - one group 2',
        body:     'some body 123äöü - one group 2',
      },
    )
    sleep 1

    # update ticket
    ticket_update(
      data: {
        body:  'some body 1234 äöüß - one group 2 - update',
        group: 'Users',
      },
    )

    tasks_close_all()

  end

end
