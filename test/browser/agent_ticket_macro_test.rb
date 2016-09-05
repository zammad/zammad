# encoding: utf-8
require 'browser_test_helper'

class AgentTicketMacroTest < TestCase
  def test_macro
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'some subject - macro#1',
        body: 'some body - macro#1',
      },
    )

    click(css: '.active.content .js-submitDropdown .js-openDropdownMacro')
    click(css: '.active.content .js-submitDropdown .js-dropdownActionMacro')

    # verify tags
    tags_verify(
      tags: {
        'spam' => true,
        'tag1' => false,
      }
    )
  end
end
