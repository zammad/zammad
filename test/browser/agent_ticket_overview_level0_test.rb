# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketOverviewLevel0Test < TestCase
  def test_bulk_close
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # test bulk action

    # create new ticket
    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'overview count test #1',
        body:     'overview count test #1',
      }
    )
    ticket2 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'overview count test #2',
        body:     'overview count test #2',
      }
    )
    click(text: 'Overviews')

    # enable full overviews
    execute(
      js: '$(".content.active .sidebar").css("display", "block")',
    )

    click(text: 'Unassigned & Open')
    watch_for(
      css:   '.content.active',
      value: 'overview count test #2',
    )

    # select both via bulk action
    click(
      css:  %(.content.active table tr td input[value="#{ticket1[:id]}"] + .icon-checkbox.icon-unchecked),
      fast: true,
    )

    # scroll to reply - needed for chrome
    scroll_to(
      position: 'top',
      css:      %(.content.active table tr td input[value="#{ticket2[:id]}"] + .icon-checkbox.icon-unchecked),
    )
    click(
      css:  %(.content.active table tr td input[value="#{ticket2[:id]}"] + .icon-checkbox.icon-unchecked),
      fast: true,
    )

    exists(
      css: %(.content.active table tr td input[value="#{ticket1[:id]}"][type="checkbox"]:checked),
    )
    exists(
      css: %(.content.active table tr td input[value="#{ticket2[:id]}"][type="checkbox"]:checked),
    )

    # select close state & submit
    select(
      css:   '.content.active .bulkAction [name="state_id"]',
      value: 'closed',
    )
    click(
      css: '.content.active .bulkAction .js-confirm',
    )
    click(
      css: '.content.active .bulkAction .js-submit',
    )

    watch_for_disappear(
      css:     %(.content.active table tr td input[value="#{ticket2[:id]}"]),
      timeout: 6,
    )

    exists_not(
      css: %(.content.active table tr td input[value="#{ticket1[:id]}"]),
    )
    exists_not(
      css: %(.content.active table tr td input[value="#{ticket2[:id]}"]),
    )

    # remember current overview count
    overview_counter_before = overview_counter()

    # click options and enable number and article count
    click(css: '.content.active [data-type="settings"]')

    modal_ready()

    check(
      css: '.modal input[value="number"]',
    )
    check(
      css: '.modal input[value="title"]',
    )
    check(
      css: '.modal input[value="customer"]',
    )
    check(
      css: '.modal input[value="group"]',
    )
    check(
      css: '.modal input[value="created_at"]',
    )
    check(
      css: '.modal input[value="article_count"]',
    )
    click(css: '.modal .js-submit')
    modal_disappear

    # check if number and article count is shown
    match(
      css:   '.content.active table th:nth-child(3)',
      value: '#',
    )
    match(
      css:   '.content.active table th:nth-child(4)',
      value: 'Title',
    )
    match(
      css:   '.content.active table th:nth-child(7)',
      value: 'Article#',
    )

    # reload browser
    reload()
    sleep 4

    # check if number and article count is shown
    match(
      css:   '.content.active table th:nth-child(3)',
      value: '#',
    )
    match(
      css:   '.content.active table th:nth-child(4)',
      value: 'Title',
    )
    match(
      css:   '.content.active table th:nth-child(7)',
      value: 'Article#',
    )

    # disable number and article count
    click(css: '.content.active [data-type="settings"]')

    modal_ready()

    uncheck(
      css: '.modal input[value="number"]',
    )
    uncheck(
      css: '.modal input[value="article_count"]',
    )
    click(css: '.modal .js-submit')
    modal_disappear

    # check if number and article count is gone
    match_not(
      css:   '.content.active table th:nth-child(3)',
      value: '#',
    )
    match(
      css:   '.content.active table th:nth-child(3)',
      value: 'Title',
    )
    exists_not(
      css: '.content.active table th:nth-child(8)',
    )

    # create new ticket
    ticket3 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'overview count test #3',
        body:     'overview count test #3',
      }
    )
    sleep 6

    # get new overview count
    overview_counter_new = overview_counter()
    assert_equal(overview_counter_before['#ticket/view/all_unassigned'] + 1, overview_counter_new['#ticket/view/all_unassigned'])

    # open ticket by search
    ticket_open_by_search(
      number: ticket3[:number],
    )
    sleep 1

    # close ticket
    ticket_update(
      data: {
        state: 'closed',
      }
    )
    sleep 6

    # get current overview count
    overview_counter_after = overview_counter()
    assert_equal(overview_counter_before['#ticket/view/all_unassigned'], overview_counter_after['#ticket/view/all_unassigned'])

    # cleanup
    tasks_close_all()
  end

  def test_bulk_pending
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # test bulk action

    # create new ticket
    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'overview count test #3',
        body:     'overview count test #3',
      }
    )
    ticket2 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'overview count test #4',
        body:     'overview count test #4',
      }
    )
    click(text: 'Overviews')

    # enable full overviews
    execute(
      js: '$(".content.active .sidebar").css("display", "block")',
    )

    click(text: 'Unassigned & Open')
    watch_for(
      css:     '.content.active',
      value:   'overview count test #4',
      timeout: 8,
    )

    # remember current overview count
    overview_counter_before = overview_counter()

    # select both via bulk action
    click(
      css:  %(.content.active table tr td input[value="#{ticket1[:id]}"] + .icon-checkbox.icon-unchecked),
      fast: true,
    )

    # scroll to reply - needed for chrome
    scroll_to(
      position: 'top',
      css:      %(.content.active table tr td input[value="#{ticket2[:id]}"] + .icon-checkbox.icon-unchecked),
    )
    click(
      css:  %(.content.active table tr td input[value="#{ticket2[:id]}"] + .icon-checkbox.icon-unchecked),
      fast: true,
    )

    exists(
      css: %(.content.active table tr td input[value="#{ticket1[:id]}"][type="checkbox"]:checked),
    )
    exists(
      css: %(.content.active table tr td input[value="#{ticket2[:id]}"][type="checkbox"]:checked),
    )

    exists(
      displayed: false,
      css:       '.content.active .bulkAction [data-name="pending_time"]',
    )

    select(
      css:   '.content.active .bulkAction [name="state_id"]',
      value: 'pending close',
    )

    exists(
      displayed: true,
      css:       '.content.active .bulkAction [data-name="pending_time"]',
    )

    set(
      css:   '.content.active .bulkAction [data-item="date"]',
      value: '05/23/2037',
    )

    select(
      css:   '.content.active .bulkAction [name="group_id"]',
      value: 'Users',
    )

    select(
      css:   '.content.active .bulkAction [name="owner_id"]',
      value: 'Test Master Agent',
    )

    click(
      css: '.content.active .bulkAction .js-confirm',
    )
    click(
      css: '.content.active .bulkAction .js-submit',
    )

    watch_for_disappear(
      css:     %(.content.active table tr td input[value="#{ticket2[:id]}"]),
      timeout: 12,
    )

    exists_not(
      css: %(.content.active table tr td input[value="#{ticket1[:id]}"]),
    )
    exists_not(
      css: %(.content.active table tr td input[value="#{ticket2[:id]}"]),
    )

    # get new overview count
    overview_counter_new = overview_counter()
    assert_equal(overview_counter_before['#ticket/view/all_unassigned'] - 2, overview_counter_new['#ticket/view/all_unassigned'])

    # open ticket by search
    ticket_open_by_search(
      number: ticket1[:number],
    )
    sleep 1

    # close ticket
    ticket_update(
      data: {
        state: 'closed',
      }
    )

    # open ticket by search
    ticket_open_by_search(
      number: ticket2[:number],
    )
    sleep 1

    # close ticket
    ticket_update(
      data: {
        state: 'closed',
      }
    )

    # cleanup
    tasks_close_all()
  end

  # verify correct behaviour for issue #1864 - Bulk-Action: Not possible to change owner
  def test_bulk_owner_change
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # test bulk action

    # create new ticket
    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'overview owner change test #1',
        body:     'overview owner change #1',
      }
    )
    ticket2 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'overview owner change #2',
        body:     'overview owner change #2',
      }
    )

    overview_open(
      link:    '#ticket/view/all_unassigned',
    )

    watch_for(
      css:     '.content.active',
      value:   'overview owner change #2',
      timeout: 8,
    )

    # remember current overview count
    overview_counter_before = overview_counter()

    # select both via bulk action
    click(
      css:  %(.content.active table tr td input[value="#{ticket1[:id]}"] + .icon-checkbox.icon-unchecked),
      fast: true,
    )

    # scroll to reply - needed for chrome
    scroll_to(
      position: 'top',
      css:      %(.content.active table tr td input[value="#{ticket2[:id]}"] + .icon-checkbox.icon-unchecked),
    )
    click(
      css:  %(.content.active table tr td input[value="#{ticket2[:id]}"] + .icon-checkbox.icon-unchecked),
      fast: true,
    )

    exists(
      css: %(.content.active table tr td input[value="#{ticket1[:id]}"][type="checkbox"]:checked),
    )
    exists(
      css: %(.content.active table tr td input[value="#{ticket2[:id]}"][type="checkbox"]:checked),
    )

    select(
      css:   '.content.active .bulkAction [name="owner_id"]',
      value: 'Test Master Agent',
    )

    select(
      css:   '.content.active .bulkAction [name="state_id"]',
      value: 'closed',
    )

    click(
      css: '.content.active .bulkAction .js-confirm',
    )
    click(
      css: '.content.active .bulkAction .js-submit',
    )

    watch_for_disappear(
      css:     %(.content.active table tr td input[value="#{ticket2[:id]}"]),
      timeout: 12,
    )

    exists_not(
      css: %(.content.active table tr td input[value="#{ticket1[:id]}"]),
    )
    exists_not(
      css: %(.content.active table tr td input[value="#{ticket2[:id]}"]),
    )

    # get new overview count
    overview_counter_new = overview_counter()
    assert_equal(overview_counter_before['#ticket/view/all_unassigned'] - 2, overview_counter_new['#ticket/view/all_unassigned'])

    # cleanup
    tasks_close_all()
  end

  # verify fix for issue #2026 - Bulk action should not be shown if user has no change permissions
  def test_no_bulk_action_when_missing_change_permission
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # create new group
    group_create(
      data: {
        name: 'some group2',
      },
    )

    role_edit(
      data: {
        name:              'Agent',
        group_permissions: { 2 => ['full'],
                             3 => ['full'], }
      },
    )

    user_edit(
      data: {
        login:       'master@example.com',
        permissions: { 1 => ['full'],
                       2 => ['full'],
                       3 => ['full'], }
      },
    )

    user_create(
      data: {
        firstname:   'Tester',
        lastname:    'Agent 2',
        email:       'agent2@example.com',
        password:    'test',
        role:        'Agent',
        permissions: { 1 => %w[read create overview] }
      },
    )

    # create new tickets
    can_change_ticket = ticket_create(
      data: {
        customer: 'nico',
        group:    'some group2',
        title:    'overview test #5',
        body:     'overview test #5',
      }
    )
    cannot_change_ticket = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'overview test #6',
        body:     'overview test #6',
      }
    )

    logout() # logout as master@example.com then login as agent2@example.com
    login(
      username: 'agent2@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # open Overview menu tab
    click(
      css: '.js-menu .js-overviewsMenuItem',
    )

    # enable full overviews
    execute(
      js: '$(".content.active .sidebar").css("display", "block")',
    )

    # click Unassigned & Open tab
    click(
      css: '.content.active [href="#ticket/view/all_unassigned"]',
    )

    watch_for(
      css:     '.content.active',
      value:   'overview test #6',
      timeout: 8,
    )

    # first select the ticket that we have change rights to
    check(
      css: %(.content.active table tr td input[value="#{can_change_ticket[:id]}"]),
    )

    # check that the bulk action form appears
    exists(
      displayed: true,
      css:       '.content.active .bulkAction',
    )

    # then select the ticket that we do not have change rights to
    scroll_to(
      position: 'top',
      css:      %(.content.active table tr td input[value="#{cannot_change_ticket[:id]}"] + .icon-checkbox.icon-unchecked),
    )
    check(
      css: %(.content.active table tr td input[value="#{cannot_change_ticket[:id]}"]),
    )

    # check that the bulk action form disappears
    exists(
      displayed: false,
      css:       '.content.active .bulkAction',
    )

    # de-select the ticket that we do not have change rights to
    uncheck(
      css:  %(.content.active table tr td input[value="#{cannot_change_ticket[:id]}"]),
      fast: true,
    )

    # check that the bulk action form appears again
    exists(
      displayed: true,
      css:       '.content.active .bulkAction',
    )

    # de-select the ticket that we have change rights to
    uncheck(
      css:  %(.content.active table tr td input[value="#{can_change_ticket[:id]}"]),
      fast: true,
    )

    # check that the bulk action form disappears again
    exists(
      displayed: false,
      css:       '.content.active .bulkAction',
    )

    # cleanup
    tasks_close_all()
    logout() # logout as agent2@example.com and then login as master@example.com to clean up tickets
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # open ticket by search
    ticket_open_by_search(
      number: cannot_change_ticket[:number],
    )
    sleep 1

    # close ticket
    ticket_update(
      data: {
        state: 'closed',
      }
    )

    # open ticket by search
    ticket_open_by_search(
      number: can_change_ticket[:number],
    )
    sleep 1

    # close ticket
    ticket_update(
      data: {
        state: 'closed',
      }
    )
  end
end
