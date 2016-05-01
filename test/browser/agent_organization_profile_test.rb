# encoding: utf-8
require 'browser_test_helper'

class AgentOrganizationProfileTest < TestCase
  def test_org_profile
    # work in one browser window
    message = '1 ' + rand(99_999_999).to_s
    note    = 'some note ' + rand(99_999_999).to_s

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    # search and open org
    organization_open_by_search(
      value: 'Zammad Foundation',
    )

    verify_task(
      data: {
        title: 'Zammad Foundation',
      }
    )

    watch_for(
      css: '.active .profile-window',
      value: 'note',
    )
    watch_for(
      css: '.active .profile-window',
      value: 'member',
    )

    # update note
    set(
      css: '.active .profile [data-name="note"]',
      value: note,
    )
    empty_search()
    sleep 2

    # check and change note again in edit screen
    click(css: '.active .js-action .icon-arrow-down', fast: true)
    click(css: '.active .js-action [data-type="edit"]')

    watch_for(
      css: '.active .modal',
      value: 'note',
    )
    watch_for(
      css: '.active .modal',
      value: note,
    )

    set(
      css: '.modal [name="name"]',
      value: 'Z2',
    )
    set(
      css: '.active .modal [data-name="note"]',
      value: 'some note abc',
    )
    click(css: '.active .modal button.js-submit')

    watch_for(
      css: '.active .profile-window',
      value: 'some note abc',
    )

    verify_task(
      data: {
        title: 'Z2',
      }
    )

    # change lastname back
    click(css: '.active .js-action .icon-arrow-down', fast: true)
    click(css: '.active .js-action [data-type="edit"]')
    watch_for(
      css: '.active .modal',
      value: 'note',
    )
    set(
      css: '.modal [name="name"]',
      value: 'Zammad Foundation',
    )
    click(css: '.active .modal button.js-submit')

    verify_task(
      data: {
        title: 'Zammad Foundation',
      }
    )

    # create new ticket
    ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'org profile check ' + message,
        body: 'org profile check ' + message,
      },
    )

    # switch to org tab, verify if ticket is shown
    organization_open_by_search(
      value: 'Zammad Foundation',
    )
    watch_for(
      css: '.active .profile-window',
      value: 'org profile check ' + message,
    )
    tasks_close_all()

    # work with two browser windows
    message = 'comment 1 ' + rand(99_999_999_999_999_999).to_s

    # use current session
    browser1 = @browser

    browser2 = browser_instance
    login(
      browser: browser2,
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all(
      browser: browser2,
    )

    organization_open_by_search(
      browser: browser1,
      value: 'Zammad Foundation',
    )
    organization_open_by_search(
      browser: browser2,
      value: 'Zammad Foundation',
    )

    # update note
    set(
      browser: browser1,
      css: '.active .profile [data-name="note"]',
      value: message,
    )
    empty_search(
      browser: browser1,
    )

    # verify
    watch_for(
      browser: browser2,
      css: '.active .profile-window',
      value: message,
    )
  end
end
