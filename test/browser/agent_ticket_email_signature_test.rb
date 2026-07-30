# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'browser_test_helper'

class AgentTicketEmailSignatureTest < TestCase
  def test_agent_signature_check

    suffix          = SecureRandom.uuid
    signature_name1 = "sig name 1 äöüß #{suffix}"
    signature_body1 = "--\nsig body 1 äöüß #{suffix}"
    signature_name2 = "sig name 2 äöüß #{suffix}"
    signature_body2 = "--\nsig body 2 äöüß #{suffix}"
    group_name1     = "group name 1 #{suffix}"
    group_name2     = "group name 2 #{suffix}"
    group_name3     = "group name 3 #{suffix}"

    @browser = browser_instance
    login(
      username: 'admin@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all

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
            login:  'admin@example.com',
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
            login:  'admin@example.com',
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
            login:  'admin@example.com',
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
    reload

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

    # Wait until the unsaved group change reached the task state (autosave runs
    #   debounced in the background) - the following reply click picks the
    #   signature based on it and would re-apply the signature of the previous
    #   group when it is still stale.
    # Returns true when settled, otherwise a string naming the first unmet
    #   precondition for the failure output.
    task_state_updated_js = <<~JS
      var task = App.TaskManager.all().filter(function(t) { return t.active; })[0];
      if (!task) return 'no active task';

      var group = App.Group.findByAttribute('name', '#{group_name2}');
      if (!group) return 'group #{group_name2} not present in the frontend collection';

      if (!task.state || !task.state.ticket) return 'no ticket state on active task ' + task.key;

      if (task.state.ticket.group_id != group.id) return 'task state group_id is ' + task.state.ticket.group_id + ', expected ' + group.id;

      return true;
    JS

    task_state_updated = false
    60.times do
      task_state_updated = execute(js: task_state_updated_js)
      break if task_state_updated == true

      sleep 0.5
    end
    raise "Unsaved group change did not reach the task state: #{task_state_updated}" if task_state_updated != true

    # execute reply
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
