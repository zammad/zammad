# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketUpdate5Test < TestCase
  def test_check_changes
    @browser = browser_instance

    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )

    # create ticket

    ticket_create(
      data: {
        customer: 'Nico',
        group:    'Users',
        title:    'some changes',
        body:     'some body 123äöü - changes',
      }
    )

    select(
      css:   '.content.active .sidebar select[name="owner_id"]',
      value: 'Agent 1 Test',
    )

    click(css: '.content.active .js-attributeBar .js-submit', wait: 2)

    select(
      css:   '.content.active .sidebar select[name="group_id"]',
      value: '-',
    )

    select(
      css:   '.content.active .sidebar select[name="group_id"]',
      value: 'Users',
    )

    sleep 1

    match(
      css:   '.content.active .sidebar select[name="owner_id"]',
      value: '-'
    )

  end
end
