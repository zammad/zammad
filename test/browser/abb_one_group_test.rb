# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketActionLevel0Test < TestCase

  def test_aaa_agent_ticket_create_with_one_group
    agent = "bob.smith_one_group#{SecureRandom.uuid}"

    @browser = browser_instance
    login(
      username: 'admin@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all

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

    tasks_close_all

    # invite agent (with one group)
    click(css: '#navigation a[href="#dashboard"]')
    click(css: '.active.content .tab[data-area="first-steps-widgets"]')
    watch_for(
      css:   '.active.content',
      value: 'Configuration',
    )
    click(css: '.active.content .js-inviteAgent')
    modal_ready
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
    check(css: '.modal [data-attribute-name="role_ids"] input[value="2"]')
    click(
      css: '.modal .js-groupListNewItemRow .js-groupListItemAddNew .js-input'
    )
    click(
      css: '.modal .js-groupListNewItemRow .js-optionsList .js-option'
    )
    check(css: '.modal .js-groupListItem[value=full]')
    click(
      css: '.modal .js-groupListNewItemRow .js-add'
    )
    click(
      css:  '.modal button.btn.btn--primary',
      fast: true,
      ajax: false,
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
    modal_ready
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

    check(css: '.modal .js-groupListItem[value=full]')

    click(
      css:  '.modal button.btn.btn--primary',
      fast: true,
      ajax: false,
    )
    watch_for_disappear(
      css:   'body div.modal',
      value: 'Sending',
    )

    tasks_close_all

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
    exists(css: '.newTicket .form-group.hide input[name="group_id"]+.js-input')

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

    tasks_close_all

  end

  def test_ccc_agent_ticket_create_with_more_groups

    @browser = browser_instance
    login(
      username: 'admin@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all

    group_create(
      data: {
        name:   "some group #{SecureRandom.uuid}",
        member: [
          {
            login:  'admin@example.com',
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

    tasks_close_all

  end

end
