# encoding: utf-8
require 'browser_test_helper'

class AgentTicketOverviewLevel0Test < TestCase
  def test_i
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    # test bulk action

    # create new ticket
    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'overview count test #1',
        body: 'overview count test #1',
      }
    )
    ticket2 = ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'overview count test #2',
        body: 'overview count test #2',
      }
    )
    click(text: 'Overviews')

    # enable full overviews
    execute(
      js: '$(".content.active .sidebar").css("display", "block")',
    )

    click(text: 'Unassigned & Open')
    sleep 8 # till overview is rendered

    # select both via bulk action
    click(
      css: '.active table tr td input[value="' + ticket1[:id] + '"] + .icon-checkbox.icon-unchecked',
      fast: true,
    )

    # scroll to reply - needed for chrome
    scroll_to(
      position: 'top',
      css:      '.active table tr td input[value="' + ticket2[:id] + '"] + .icon-checkbox.icon-unchecked',
    )
    click(
      css: '.active table tr td input[value="' + ticket2[:id] + '"] + .icon-checkbox.icon-unchecked',
      fast: true,
    )

    exists(
      css: '.active table tr td input[value="' + ticket1[:id] + '"][type="checkbox"]:checked',
    )
    exists(
      css: '.active table tr td input[value="' + ticket2[:id] + '"][type="checkbox"]:checked',
    )

    # select close state & submit
    select(
      css: '.active .bulkAction [name="state_id"]',
      value: 'closed',
    )
    click(
      css: '.active .bulkAction .js-confirm',
    )
    click(
      css: '.active .bulkAction .js-submit',
    )
    sleep 6

    exists_not(
      css: '.active table tr td input[value="' + ticket1[:id] + '"]',
    )
    exists_not(
      css: '.active table tr td input[value="' + ticket2[:id] + '"]',
    )

    # remember current overview count
    overview_counter_before = overview_counter()

    # click options and enable number and article count
    click(css: '.active [data-type="settings"]')

    watch_for(
      css: '.modal h1',
      value: 'Edit',
    )
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
      css: '.active table th:nth-child(3)',
      value: '#',
    )
    match(
      css: '.active table th:nth-child(4)',
      value: 'Title',
    )
    match(
      css: '.active table th:nth-child(7)',
      value: 'Article#',
    )

    # reload browser
    reload()
    sleep 4

    # check if number and article count is shown
    match(
      css: '.active table th:nth-child(3)',
      value: '#',
    )
    match(
      css: '.active table th:nth-child(4)',
      value: 'Title',
    )
    match(
      css: '.active table th:nth-child(7)',
      value: 'Article#',
    )

    # disable number and article count
    click(css: '.active [data-type="settings"]')

    watch_for(
      css: '.modal h1',
      value: 'Edit',
    )
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
      css: '.active table th:nth-child(3)',
      value: '#',
    )
    match(
      css: '.active table th:nth-child(3)',
      value: 'Title',
    )
    exists_not(
      css: '.active table th:nth-child(8)',
    )

    # create new ticket
    ticket3 = ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'overview count test #3',
        body: 'overview count test #3',
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
end
