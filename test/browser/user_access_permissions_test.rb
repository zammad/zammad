require 'browser_test_helper'

class AgentProfilePermissionsTest < TestCase
  def test_agent_to_edit_customer_profile
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    user_open_by_search(value: 'Braun')

    verify_task(
      data: {
        title: 'Nicole Braun',
      }
    )

    watch_for(
      css: '.content.active .profile-window',
      value: 'note',
    )

    watch_for(
      css: '.content.active .profile-window',
      value: 'email',
    )

    set(
      css: '.content.active [data-name="note"]',
      value: 'some note 123',
    )
    empty_search()

    # check and change note again in edit screen
    click(css: '.content.active .js-action .icon-arrow-down', fast: true)
    click(css: '.content.active .js-action [data-type="edit"]')

    watch_for(
      css: '.content.active .modal',
      value: 'note',
    )
    watch_for(
      css: '.content.active .modal',
      value: 'some note 123',
    )

    set(
      css: '.modal [name="lastname"]',
      value: 'B2',
    )
    set(
      css: '.modal [data-name="note"]',
      value: 'some note abc',
    )
    click(css: '.content.active .modal button.js-submit')

    watch_for(
      css: '.content.active .profile-window',
      value: 'some note abc',
    )

    verify_task(
      data: {
        title: 'Nicole B2',
      }
    )

    # change lastname back
    click(css: '.content.active .js-action .icon-arrow-down', fast: true)
    click(css: '.content.active .js-action [data-type="edit"]')
    watch_for(
      css: '.content.active .modal',
      value: 'note',
    )
    set(
      css: '.modal [name="lastname"]',
      value: 'Braun',
    )
    click(css: '.content.active .modal button.js-submit')

    verify_task(
      data: {
        title: 'Nicole Braun',
      }
    )
  end

  def test_agent_edit_admin_profile
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    user_open_by_search(value: 'Test Master')

    verify_task(
      data: {
        title: 'Test Master Agent',
      }
    )

    watch_for(
      css: '.content.active .profile-window',
      value: 'note',
    )
    watch_for(
      css: '.content.active .profile-window',
      value: 'email',
    )

    empty_search()
    sleep 2

    click(css: '.content.active .js-action .icon-arrow-down', fast: true)
    exists_not(css: '.content.active .js-action [data-type="edit"]')
  end

  def test_agent_to_edit_admin_ticket_user_details
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    ticket1 = ticket_create(
      data: {
        customer: 'master',
        group:    'Users',
        title:    'test_user_access_permissions - ticket 1',
        body:     'test_user_access_permissions - ticket 1',
      },
    )

    tasks_close_all()

    logout()

    login(
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    ticket_open_by_search(
      number: ticket1[:number],
    )

    watch_for(
      css: '.content.active .tabsSidebar-holder',
      value: ticket1[:title],
    )

    click(css: '.content.active .tabsSidebar .tabsSidebar-tab[data-tab="customer"]')
    click(css: '.content.active .sidebar[data-tab="customer"] .js-actions .dropdown-toggle')
    exists_not(css: '.content.active .sidebar[data-tab="customer"] .js-actions [data-type="customer-edit"]')
  end

  def test_agent_to_edit_customer_ticket
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
        group:    'Users',
        title:    'test_user_access_permissions - ticket 2',
        body:     'test_user_access_permissions - ticket 2',
      },
    )
    ticket_open_by_search(
      number: ticket1[:number],
    )

    click(css: '.content.active .tabsSidebar .tabsSidebar-tab[data-tab="customer"]')
    click(css: '.content.active .sidebar[data-tab="customer"] .js-actions .dropdown-toggle')
    click(css: '.content.active .sidebar[data-tab="customer"] .js-actions [data-type="customer-edit"]')

    set(
      css: '.modal [name="lastname"]',
      value: 'B2',
    )

    set(
      css: '.modal [data-name="note"]',
      value: 'some note abc',
    )

    click(css: '.content.active .modal button.js-submit')

    watch_for(
      css: '.content.active .sidebar[data-tab="customer"] .sidebar-block [data-name="note"]',
      value: 'some note abc',
    )

    watch_for(
      css: '.content.active .sidebar[data-tab="customer"] .sidebar-block h3[title="Name"]',
      value: 'Nicole B2',
    )

    sleep 2
    # change lastname back
    click(css: '.content.active .sidebar[data-tab="customer"] .js-actions')
    click(css: 'li[data-type="customer-edit"]')

    watch_for(
      css: '.content.active .modal',
      value: 'note',
    )

    set(
      css: '.modal [name="lastname"]',
      value: 'Braun',
    )
    set(
      css: '.modal [data-name="note"]',
      value: 'some note abc',
    )
    click(css: '.content.active .modal button.js-submit')

    watch_for(
      css: '.content.active .sidebar[data-tab="customer"] .sidebar-block [data-name="note"]',
      value: 'some note abc',
    )

    watch_for(
      css: '.content.active .sidebar[data-tab="customer"] .sidebar-block [title="Name"]',
      value: 'Nicole Braun',
    )
  end

  def test_agent_to_edit_customer_ticket_details
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
        group:    'Users',
        title:    'test_user_access_permissions - ticket 3',
        body:     'test_user_access_permissions - ticket 3',
      },
    )
    ticket_open_by_search(
      number: ticket1[:number],
    )

    exists(css: '.content.active .tabsSidebar .tabsSidebar-tab[data-tab="customer"]')
    exists(css: '.content.active .sidebar[data-tab="customer"] .js-actions .dropdown-toggle')
    exists(css: '.content.active .sidebar[data-tab="customer"] .js-actions [data-type="customer-edit"]')

    # scroll to the Avatar at the top of the zoom view and click it
    # scrolling is needed because the browser might have scrolled down
    # caused by a undeliverable email (of the created ticket)
    zoom_top_avatar_selector = '.content.active .tabsSidebar-holder .js-avatar'
    scroll_to(
      position: 'botton',
      css:      zoom_top_avatar_selector,
    )
    click(css: zoom_top_avatar_selector)

    # check and change note again in edit screen
    click(css: '.content.active .js-action .dropdown-toggle')
    click(css: '.content.active .js-action [data-type="edit"]')

    watch_for(
      css: '.content.active .modal',
      value: 'note',
    )

    set(
      css: '.modal [name="lastname"]',
      value: 'B2',
    )
    set(
      css: '.modal [data-name="note"]',
      value: 'some note abc',
    )
    click(css: '.content.active .modal button.js-submit')

    watch_for(
      css: '.content.active .profile-window',
      value: 'some note abc',
    )

    verify_task(
      data: {
        title: 'Nicole B2',
      }
    )

    # change lastname back
    click(css: '.content.active .js-action .dropdown-toggle')
    click(css: '.content.active .js-action [data-type="edit"]')

    watch_for(
      css: '.content.active .modal',
      value: 'note',
    )
    set(
      css: '.modal [name="lastname"]',
      value: 'Braun',
    )
    set(
      css: '.modal [data-name="note"]',
      value: 'note',
    )
    click(css: '.content.active .modal button.js-submit')

    verify_task(
      data: {
        title: 'Nicole Braun',
      }
    )
  end

  def test_agent_to_edit_admin_ticket_details
    @browser = browser_instance

    login(
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    ticket1 = ticket_create(
      data: {
        customer: 'master',
        group:    'Users',
        title:    'test_user_access_permissions - ticket 4',
        body:     'test_user_access_permissions - ticket 4',
      },
    )

    ticket_open_by_search(
      number: ticket1[:number],
    )

    exists(css: '.content.active .tabsSidebar .tabsSidebar-tab[data-tab="customer"]')
    exists(css: '.content.active .sidebar[data-tab="customer"] .js-actions .dropdown-toggle')
    exists_not(css: '.content.active .sidebar[data-tab="customer"] .js-actions [data-type="customer-edit"]')

    # scroll to the Avatar at the top of the zoom view and click it
    # scrolling is needed because the browser might have scrolled down
    # caused by a undeliverable email (of the created ticket)
    zoom_top_avatar_selector = '.content.active .tabsSidebar-holder .js-avatar'
    scroll_to(
      position: 'botton',
      css:      zoom_top_avatar_selector,
    )
    click(css: zoom_top_avatar_selector)

    click(css: '.content.active .js-action .icon-arrow-down', fast: true)
    exists_not(css: '.content.active .js-action [data-type="edit"]')
  end
end
