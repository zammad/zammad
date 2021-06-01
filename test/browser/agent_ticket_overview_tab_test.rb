# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketOverviewTabTest < TestCase
  def test_i
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    title = "test #{rand(9_999_999)}"

    # create new ticket
    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    "overview tab test #1 - #{title}",
        body:     "overview tab test #1 - #{title}",
      }
    )
    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    "overview tab test #2 - #{title}",
        body:     "overview tab test #2 - #{title}",
      }
    )
    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    "overview tab test #3 - #{title}",
        body:     "overview tab test #3 - #{title}",
      }
    )
    tasks_close_all()

    #click(text: 'Overviews')
    # enable full overviews
    #execute(
    #  js: '$(".content.active .sidebar").css("display", "block")',
    #)
    #click(text: 'Unassigned & Open')

    ticket_open_by_overview(
      number: ticket1[:number],
      title:  "overview tab test #1 - #{title}",
      link:   '#ticket/view/all_unassigned',
    )

    assert_equal(1, @browser.find_elements(css: '.tasks .task').count)

    ticket_update(
      data:      {
        body:  'some body',
        state: 'closed',
      },
      task_type: 'closeNextInOverview', # default: stayOnTab / possible: closeTab, closeNextInOverview, stayOnTab
    )

    watch_for(
      css:     '.tasks .task.is-active',
      value:   "overview tab test #2 - #{title}",
      timeout: 8,
    )

    assert_equal(1, @browser.find_elements(css: '.tasks .task').count)

    ticket_update(
      data:      {
        body:  'some body',
        state: 'closed',
      },
      task_type: 'closeTab', # default: stayOnTab / possible: closeTab, closeNextInOverview, stayOnTab
    )

    assert_equal(0, @browser.find_elements(css: '.tasks .task').count)

    # cleanup
    tasks_close_all()
  end
end
