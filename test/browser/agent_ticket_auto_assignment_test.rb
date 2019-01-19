require 'browser_test_helper'

class AgentTicketAutoAssignmentTest < TestCase
  def test_ticket

    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    #
    # attachment checks - new ticket
    #

    # create new ticket with no attachment, attachment check should pop up
    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'test_auto_assignment_1 - ticket 1',
        body:     'test_auto_assignment_1 - ticket 1 - no auto assignment',
      },
    )

    ticket2 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'test_auto_assignment_2 - ticket 2',
        body:     'test_auto_assignment_2 - ticket 2 - no auto assignment',
      },
    )

    ticket3 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'test_auto_assignment_3 - ticket 3',
        body:     'test_auto_assignment_3 - ticket 3 - no auto assignment',
      },
    )

    tasks_close_all()

    logout()

    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # open ticket#1
    ticket_open_by_search(
      number: ticket1[:number],
    )

    # verify if owner is set
    match(
      css:   '.content.active .sidebar select[name="owner_id"]',
      value: '-',
    )

    # open ticket#2
    ticket_open_by_search(
      number: ticket2[:number],
    )

    # verify if owner is set
    match(
      css:   '.content.active .sidebar select[name="owner_id"]',
      value: '-',
    )

    tasks_close_all()

    # enable auto assignment
    click(css: 'a[href="#manage"]')
    click(css: '.content.active a[href="#settings/ticket"]')
    click(css: '.content.active a[href="#auto_assignment"]')
    switch(
      css:  '.content.active .js-ticketAutoAssignment',
      type: 'on',
    )

    # open ticket#1
    ticket_open_by_search(
      number: ticket1[:number],
    )

    # verify if owner is set
    watch_for(
      css:     '.content.active .sidebar select[name="owner_id"]',
      value:   'Test Master',
      timeout: 2,
    )

    # open ticket#2
    ticket_open_by_search(
      number: ticket2[:number],
    )

    # verify if owner is set
    watch_for(
      css:     '.content.active .sidebar select[name="owner_id"]',
      value:   'Test Master',
      timeout: 2,
    )

    # define auto assignment exception
    click(css: 'a[href="#manage"]')
    # flanky
    click(css: '.content.active a[href="#settings/ticket"]')
    click(css: '.content.active a[href="#auto_assignment"]')
    click(css: '.content.active .js-select.js-option[title="master@example.com"]')
    click(css: '.content.active .js-timeAccountingFilter')

    watch_for_disappear(
      css:     '.content.active .sidebar select[name="owner_id"]',
      value:   'Test Master',
      timeout: 10,
    )

    # open ticket#3
    ticket_open_by_search(
      number: ticket3[:number],
    )

    # verify if owner is not set
    sleep 6
    match(
      css:   '.content.active .sidebar select[name="owner_id"]',
      value: '-',
    )

    tasks_close_all()

    # disable auto assignment
    click(css: 'a[href="#manage"]')
    click(css: '.content.active a[href="#settings/ticket"]')
    click(css: '.content.active a[href="#auto_assignment"]')
    switch(
      css:  '.content.active .js-ticketAutoAssignment',
      type: 'off',
    )

  end
end
