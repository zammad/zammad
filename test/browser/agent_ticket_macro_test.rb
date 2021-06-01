# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketMacroTest < TestCase

  def test_close_and_tag_as_spam_default
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    ticket = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'macro "Close & Tag as Spam" default',
        body:     'some body - macro "Close & Tag as Spam" default',
      },
    )

    perform_macro(name: 'Close & Tag as Spam')

    # check redirect after perfoming macro
    location_check(
      url: "#{browser_url}/#dashboard",
    )

    # reopen ticket and verify tags
    ticket_open_by_search(
      number: ticket[:number],
    )

    tags_verify(
      tags: {
        'spam' => true,
        'tag1' => false,
      }
    )
  end

  def test_ux_flow_next_up_stay_on_tab
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    ux_flow_next_up = 'Stay on tab'
    macro_name      = "Test #{ux_flow_next_up}"
    macro_create(
      name:            macro_name,
      ux_flow_next_up: ux_flow_next_up,
      actions:         {
        'Tags' => {
          operator: 'add',
          value:    'spam',
        }
      }
    )

    ticket = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    "macro #{macro_name}",
        body:     "some body - macro #{macro_name}",
      },
    )

    perform_macro(name: macro_name)

    location_check(
      url: "#{browser_url}/#ticket/zoom/#{ticket[:id]}",
    )

    tags_verify(
      tags: {
        'spam' => true,
        'tag1' => false,
      }
    )
  end

  def test_ux_flow_next_up_close_tab
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    ux_flow_next_up = 'Close tab'
    macro_name      = "Test #{ux_flow_next_up}"
    macro_create(
      name:            macro_name,
      ux_flow_next_up: ux_flow_next_up,
    )

    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    "macro #{macro_name}",
        body:     "some body - macro #{macro_name}",
      },
    )

    perform_macro(name: macro_name)

    watch_for_disappear(
      css:     '.tasks > a',
      timeout: 5,
    )
  end

  def test_ux_flow_next_up_advance_to_next_ticket_from_overview
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    ux_flow_next_up = 'Advance to next ticket from overview'
    macro_name      = "Test #{ux_flow_next_up}"
    macro_create(
      name:            macro_name,
      ux_flow_next_up: ux_flow_next_up,
    )

    title_prefix = "macro #{macro_name}"
    ticket1      = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    "#{title_prefix} - 1",
        body:     "some body - macro #{macro_name}",
      },
    )

    ticket2 = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    "#{title_prefix} - 2",
        body:     "some body - macro #{macro_name}",
      },
    )

    # we need to close all open ticket tasks because
    # otherwise the Zoom view won't change in "Overview"-mode
    # when we re-enter the Zoom view for a ticket via the overview
    tasks_close_all()

    sleep 8 # to update overview list to open correct/next ticket in overview

    ticket_open_by_overview(
      title: ticket1[:title],
      link:  '#ticket/view/all_unassigned',
    )

    verify_task(
      data: {
        title: ticket1[:title],
      }
    )

    perform_macro(name: macro_name)

    verify_task(
      data: {
        title: ticket2[:title],
      }
    )
  end
end
