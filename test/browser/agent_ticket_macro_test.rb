
require 'browser_test_helper'

class AgentTicketMacroTest < TestCase
  # def test_macro
  #   @browser = browser_instance
  #   login(
  #     username: 'agent1@example.com',
  #     password: 'test',
  #     url: browser_url,
  #   )
  #   tasks_close_all()

  #   ticket1 = ticket_create(
  #     data: {
  #       customer: 'nico',
  #       group: 'Users',
  #       title: 'some subject - macro#1',
  #       body: 'some body - macro#1',
  #     },
  #   )

  #   click(css: '.active.content .js-submitDropdown .js-openDropdownMacro')
  #   click(css: '.active.content .js-submitDropdown .js-dropdownActionMacro')

  #   # verify tags
  #   tags_verify(
  #     tags: {
  #       'spam' => true,
  #       'tag1' => false,
  #     }
  #   )
  # end

  def test_macro_ux_flow_next_up
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    # Setup: Create two tickets
    ticket_create(
      data: {
        customer: 'nicole.braun',
        group: 'Users',
        title: 'Sample Ticket 1',
        body: 'Lorem ipsum dolor sit amet consectetur adipisicing elit.',
      },
    )

    ticket_create(
      data: {
        customer: 'nicole.braun',
        group: 'Users',
        title: 'Sample Ticket 2',
        body: 'Suspendisse volutpat lectus sem, in fermentum orci semper sit amet.',
      },
    )

    # Setup: Create three macros (one for each ux_flow_next_up option)
    click(css: 'a[href="#manage"]')
    click(css: '.sidebar a[href="#manage/macros"]')
    macro_options = ['Stay on tab', 'Close tab', 'Advance to next ticket from overview']
    macro_options.each.with_index do |o, i|
      click(css: '.page-header-meta > a[data-type="new"]')
      sendkey(css: '.modal-body input[name="name"]', value: "Test Macro #{i + 1}")
      select(css: '.modal-body select[name="ux_flow_next_up"]', value: o)
      click(css: '.modal-footer button[type="submit"]')
    end

    click(css: 'a[title$="Sample Ticket 1"]')

    # Assert: Run the first macro and verify the tab is still open
    click(css: '.active.content .js-submitDropdown .js-openDropdownMacro')
    click(css: '.active.content .js-submitDropdown .js-dropdownActionMacro[data-id="2"]')
    match(css: '.tasks > a.is-active > .nav-tab-name', value: 'Sample Ticket 1',)

    # Setup: Close all tabs and reopen only the first ticket
    tasks_close_all()
    click(css: 'a[href="#ticket/view"]')
    begin
      remaining_retries = 1
      click(css: 'a[href="#ticket/view/all_unassigned"]')
    # responsive design means some elements are un-clickable at certain viewport sizes
    rescue Selenium::WebDriver::Error::WebDriverError => e
      raise e if remaining_retries.zero?
      (remaining_retries -= 1) && click(css: 'a.tab.js-tab[href="#ticket/view/all_unassigned"]')
    end
    click(css: 'td[title="Sample Ticket 1"]')

    # Assert: Run the second macro and verify the tab is closed
    click(css: '.active.content .js-submitDropdown .js-openDropdownMacro')
    click(css: '.active.content .js-submitDropdown .js-dropdownActionMacro[data-id="3"]')
    exists_not(css: '.tasks > a')

    # Setup: Reopen the first ticket via a Ticket Overview
    click(css: 'a[href="#ticket/view"]')
    begin
      remaining_retries = 1
      click(css: 'a[href="#ticket/view/all_unassigned"]')
    # responsive design means some elements are un-clickable at certain viewport sizes
    rescue Selenium::WebDriver::Error::WebDriverError => e
      raise e if remaining_retries.zero?
      (remaining_retries -= 1) && click(css: 'a.tab.js-tab[href="#ticket/view/all_unassigned"]')
    end
    click(css: 'td[title="Sample Ticket 1"]')

    # Assert: Run the third macro and verify the second ticket opens
    click(css: '.active.content .js-submitDropdown .js-openDropdownMacro')
    click(css: '.active.content .js-submitDropdown .js-dropdownActionMacro[data-id="4"]')
    match_not(css: '.tasks > a.task > .nav-tab-name', value: 'Sample Ticket 1',)
    match(css: '.tasks > a.is-active > .nav-tab-name', value: 'Sample Ticket 2',)
  end
end
