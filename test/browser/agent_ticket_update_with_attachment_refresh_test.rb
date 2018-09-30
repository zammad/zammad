require 'browser_test_helper'

# https://github.com/zammad/zammad/issues/1123
# Make sure attachment is shown after reloading an in-progress ticket update

class AgentTicketUpdateWithAttachmentRefreshTest < TestCase
  def test_attachment_after_refresh
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )

    #
    # attachment checks - existing ticket
    #

    # create new ticket with no attachment, attachment check should pop up
    ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'test 6 - ticket 1',
        body: 'test 6 - ticket 1 body',
      },
    )
    sleep 1

    # fill body
    ticket_update(
      data: {
        body: 'keep me',
      },
      do_not_submit: true,
    )

    # since selenium webdriver with firefox is not able to upload files, skipp here
    # https://github.com/w3c/webdriver/issues/1230
    return if browser == 'firefox'

    # add attachment, attachment check should quiet
    file_upload(
      css:   '.content.active .attachmentPlaceholder-inputHolder input',
      files: ['test/data/upload/upload1.txt'],
    )

    sleep 2

    # check if attachment is shown
    match(
      css: '.content.active .ticketZoom .attachments .attachment:nth-child(1) .attachment-name',
      value: 'upload1.txt'
    )

    @browser.navigate.refresh

    sleep 1

    # check if attachment is shown
    match(
      css: '.content.active .ticketZoom .attachments .attachment:nth-child(1) .attachment-name',
      value: 'upload1.txt'
    )
  end
end
