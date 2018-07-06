require 'browser_test_helper'

class AgentTicketUpdate4Test < TestCase

  def test_update_date_object_for_ticket

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    # date object
    object_manager_attribute_create(
      data: {
        name: 'date1',
        display: "Date-#{rand(999_999)}",
        data_type: 'Date',
      },
    )

    watch_for(
      css: '.content.active',
      value: 'Database Update required',
    )

    click(css: '.content.active .tab-pane.active div.js-execute')
    watch_for(
      css: '.modal',
      value: 'restart',
    )
    watch_for_disappear(
      css:     '.modal',
      timeout: 240,
    )
    sleep 5
    watch_for(
      css: '.content.active',
    )

    # create new ticket
    ticket = ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        priority: '2 normal',
        state:    'open',
        title:    'ticket attribute test #1',
        body:     'ticket attribute test #1',
      },
      custom_data_date: {
        date1: '02/28/2018',
      },
      disable_group_check: true,
    )

    ticket_open_by_search(
      browser: @browser,
      number: ticket[:number],
    )

    ticket_update(
      data: {},
      custom_data_date: {
        date1: '',
      },
    )
    click(css: '.content.active .js-submit')

    match_not(
      css: '.active .sidebar div[data-name="date1"] input[data-item="date"]',
      value: '02/28/2018',
    )
  end
end
