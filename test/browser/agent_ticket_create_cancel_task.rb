require 'browser_test_helper'

# Regression test for UI bugfix
# https://github.com/zammad/zammad/issues/2669
#
# In case the ticket create screen is explicitly canceled, the task should be closed automatically.
class AgentTicketCreateCancelTaskTest < TestCase
  def test_ticket_cancel_task
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    click(
      css: 'a[href="#ticket/create"]'
    )
    watch_for(
      css: '.tasks .task.is-active',
    )

    task_key = @browser.find_element(css: '.tasks .task.is-active').attribute('data-key')

    click(
      css: 'a.btn.js-cancel'
    )
    watch_for_disappear(
      css: '.tasks .task.is-active'
    )

    exists_not(
      css: ".tasks .task[data-key='#{task_key}']"
    )
  end
end
