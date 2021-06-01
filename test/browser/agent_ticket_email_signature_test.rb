# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketEmailSignatureTest < TestCase
  def test_agent_signature_check

    suffix          = rand(99_999_999_999_999_999).to_s
    signature_name1 = "sig name 1 äöüß #{suffix}"
    signature_body1 = "--\nsig body 1 äöüß #{suffix}"
    signature_name2 = "sig name 2 äöüß #{suffix}"
    signature_body2 = "--\nsig body 2 äöüß #{suffix}"
    group_name1     = "group name 1 #{suffix}"
    group_name2     = "group name 2 #{suffix}"
    group_name3     = "group name 3 #{suffix}"

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    #
    # create groups and signatures
    #

    # create signatures
    signature_create(
      data: {
        name: signature_name1,
        body: signature_body1,
      },
    )
    signature_create(
      data: {
        name: signature_name2,
        body: signature_body2,
      },
    )

    # create groups
    group_create(
      data: {
        name:      group_name1,
        signature: signature_name1,
        member:    [
          {
            login:  'master@example.com',
            access: 'full',
          },
        ],
      }
    )
    group_create(
      data: {
        name:      group_name2,
        signature: signature_name2,
        member:    [
          {
            login:  'master@example.com',
            access: 'full',
          },
        ],
      }
    )
    group_create(
      data: {
        name:   group_name3,
        member: [
          {
            login:  'master@example.com',
            access: 'full',
          },
        ],
      }
    )
    sleep 10 # wait until background job is processed

    #
    # check signature in new ticket
    #

    # reload instances to get new group permissions
    reload()

    # create ticket
    ticket_create(
      data:          {
        customer: 'nicole',
        group:    'Users',
        title:    'some subject 5 - 123äöü',
        body:     'some body 5 - 123äöü',
      },
      do_not_submit: true,
    )

    # select group
    select(
      css:   '.active [name="group_id"]',
      value: group_name1,
    )

    # check content
    match(
      css:   '.active [data-name="body"]',
      value: 'some body 5',
    )

    # check signature
    match_not(
      css:      '.active [data-name="body"]',
      value:    signature_body1,
      no_quote: true,
    )
    match_not(
      css:      '.active [data-name="body"]',
      value:    signature_body2,
      no_quote: true,
    )

    # select create channel
    click(
      css: '.active [data-type="email-out"]',
    )

    # group 1 is still selected

    # check content
    match(
      css:   '.active [data-name="body"]',
      value: 'some body 5',
    )

    # check signature
    match(
      css:      '.active [data-name="body"]',
      value:    signature_body1,
      no_quote: true,
    )
    match_not(
      css:      '.active [data-name="body"]',
      value:    signature_body2,
      no_quote: true,
    )

    # select group
    select(
      css:   '.active [name="group_id"]',
      value: group_name2,
    )

    # check content
    match(
      css:   '.active [data-name="body"]',
      value: 'some body 5',
    )

    # check signature
    match_not(
      css:      '.active [data-name="body"]',
      value:    signature_body1,
      no_quote: true,
    )
    match(
      css:      '.active [data-name="body"]',
      value:    signature_body2,
      no_quote: true,
    )

    # select group
    select(
      css:   '.active [name="group_id"]',
      value: group_name3,
    )

    # check content
    match(
      css:   '.active [data-name="body"]',
      value: 'some body 5',
    )

    # check signature
    match_not(
      css:      '.active [data-name="body"]',
      value:    signature_body1,
      no_quote: true,
    )
    match_not(
      css:      '.active [data-name="body"]',
      value:    signature_body2,
      no_quote: true,
    )

    # select group
    select(
      css:   '.active [name="group_id"]',
      value: group_name1,
    )

    # check content
    match(
      css:   '.active [data-name="body"]',
      value: 'some body 5',
    )

    # check signature
    match(
      css:      '.active [data-name="body"]',
      value:    signature_body1,
      no_quote: true,
    )
    match_not(
      css:      '.active [data-name="body"]',
      value:    signature_body2,
      no_quote: true,
    )

    # select create channel
    click(
      css: '.active [data-type="phone-out"]',
    )

    # check content
    match(
      css:   '.active [data-name="body"]',
      value: 'some body 5',
    )

    # check signature
    match_not(
      css:      '.active [data-name="body"]',
      value:    signature_body1,
      no_quote: true,
    )
    match_not(
      css:      '.active [data-name="body"]',
      value:    signature_body2,
      no_quote: true,
    )

    #
    # check signature in zoom ticket
    #
    ticket_create(
      data: {
        customer: 'nicole',
        group:    group_name1,
        title:    'some subject 5/2 - 123äöü',
        body:     'some body 5/2 - 123äöü',
      },
    )

    # execute reply
    click(
      css: '.active [data-type="emailReply"]',
    )

    # check if signature exists
    match(
      css:      '.active [data-name="body"]',
      value:    signature_body1,
      no_quote: true,
    )
    match_not(
      css:      '.active [data-name="body"]',
      value:    signature_body2,
      no_quote: true,
    )

    # update group2
    select(
      css:   '.active [name="group_id"]',
      value: group_name2,
    )

    # execute reply
    sleep 5 # time to recognice form changes
    scroll_to(
      position: 'botton',
      css:      '.active [data-type="emailReply"]',
    )
    click(
      css: '.active [data-type="emailReply"]',
    )

    # check if signature exists
    match_not(
      css:      '.active [data-name="body"]',
      value:    signature_body1,
      no_quote: true,
    )
    match(
      css:      '.active [data-name="body"]',
      value:    signature_body2,
      no_quote: true,
    )

    # discard changes
    sleep 2
    click(
      css: '.active .js-reset',
    )
    sleep 3

    # check if signature exists
    match_not(
      css:      '.active [data-name="body"]',
      value:    signature_body1,
      no_quote: true,
    )
    match_not(
      css:      '.active [data-name="body"]',
      value:    signature_body2,
      no_quote: true,
    )

  end
end
