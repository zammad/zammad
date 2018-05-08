require 'browser_test_helper'

# Regression test for UI bugfix
# https://github.com/zammad/zammad/issues/1990
#
# Ensure that CC field when creating a new ticket is autocompleting user emails

class AgentTicketCreateResetCustomerSelectionTest < TestCase
  def test_tokenizer
    @browser = browser_instance

    login(
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    click(
      css: 'a[href="#ticket/create"]'
    )

    @browser.find_element(:css, 'li[data-type=email-out]').click

    elem = @browser.find_element(:name, 'cc')
    elem.send_keys 'test@example.com'
    elem.send_keys :enter

    exists(
      css: '.token-label',
      value: 'test@example.com'
    )
  end
end
