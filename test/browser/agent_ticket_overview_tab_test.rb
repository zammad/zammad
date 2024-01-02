# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketOverviewTabTest < TestCase
  def task_count_equals(count)

    retries ||= 0
    assert_equal(count, @browser.find_elements(css: '.tasks .task').count)
  rescue
    retries += 1
    if retries < 5
      sleep 1
      retry
    end
    raise e

  end

  def test_i
    @browser = browser_instance
    login(
      username: 'admin@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all

    title = "test #{SecureRandom.uuid}"

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
    tasks_close_all

    # click(text: 'Overviews')
    # enable full overviews
    # execute(
    #  js: '$(".content.active .sidebar").css("display", "block")',
    # )
    # click(text: 'Unassigned & Open')

    ticket_open_by_overview(
      number: ticket1[:number],
      title:  "overview tab test #1 - #{title}",
      link:   '#ticket/view/all_unassigned',
    )

    task_count_equals(1)

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

    task_count_equals(1)

    ticket_update(
      data:      {
        body:  'some body',
        state: 'closed',
      },
      task_type: 'closeTab', # default: stayOnTab / possible: closeTab, closeNextInOverview, stayOnTab
    )

    task_count_equals(0)

    # cleanup
    tasks_close_all
  end
end
