require 'browser_test_helper'

class AgentTicketUpdate1Test < TestCase
  def test_check_changes
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # confirm on create
    ticket_create(
      data:          {
        customer: 'nico',
        group:    'Users',
        title:    'some changes',
        body:     'some body 123äöü - changes',
      },
      do_not_submit: true,
    )
    close_task(
      data:            {
        title: 'some changes',
      },
      discard_changes: true,
    )
    sleep 1

    # confirm on zoom
    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'some changes',
        body:     'some body 123äöü - changes',
      },
    )
    ticket_update(
      data:          {
        body: 'some note',
      },
      do_not_submit: true,
    )
    close_task(
      data:            {
        title: 'some changes',
      },
      discard_changes: true,
    )
  end
end
