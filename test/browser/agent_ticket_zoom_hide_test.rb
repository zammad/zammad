# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketZoomHideTest < TestCase

  def setup
    # Enable attachment image preview
    set_setting('ui_ticket_zoom_attachments_preview', true)
  end

  def test_ticket_zoom_hide_closes_all_modals
    # since selenium webdriver with firefox is not able to upload files, skip here
    # https://github.com/w3c/webdriver/issues/1230
    return if browser == 'firefox'

    @browser = browser_instance

    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )

    # create two tickets
    ticket_create(
      data: {
        customer: 'Nico',
        group:    'Users',
        title:    'Ticket 1',
        body:     'some body 123äöü - changes',
      }
    )

    ticket_create(
      data: {
        customer: 'Nico',
        group:    'Users',
        title:    'Ticket 2',
        body:     'some body 123äöü - changes',
      }
    )

    # Upload attachment and submit update
    ticket_update(
      data: {
        body:  'added image attachment',
        files: [Rails.root.join('test/data/upload/upload2.jpg')],
      },
    )

    # Open the attachment preview modal
    click(
      css: '.attachment-icon img',
    )

    modal_ready()

    # Now go to a previous ticket and confirm that the modal disappears
    location(
      url: "#{browser_url}/#ticket/zoom/1",
    )
    sleep 2
    modal_disappear()
  end

  def teardown
    # Disable attachment image preview
    set_setting('ui_ticket_zoom_attachments_preview', false)
  end
end
