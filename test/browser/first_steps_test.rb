# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class FirstStepsTest < TestCase

  def test_basic
    agent    = "bob.smith_#{rand(99_999_999)}"
    customer = "customer.smith_#{rand(99_999_999)}"

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    click(css: '.active.content .tab[data-area="first-steps-widgets"]')
    watch_for(
      css:   '.active.content',
      value: 'Configuration',
    )

    # invite agent (with more then one group)
    click(css: '.active.content .js-inviteAgent')

    modal_ready()

    set(
      css:   '.modal [name="firstname"]',
      value: 'Bob',
    )
    set(
      css:   '.modal [name="lastname"]',
      value: 'Smith',
    )
    set(
      css:   '.modal [name="email"]',
      value: "#{agent}@example.com",
    )
    check(css: '.modal .js-groupListItem[value=full]')
    click(
      css:  '.modal button.btn.btn--primary',
      fast: true,
    )
    watch_for(
      css:   'body div.modal',
      value: 'Sending',
    )
    watch_for_disappear(
      css:   'body div.modal',
      value: 'Sending',
    )
    modal_disappear()

    # invite customer
    click(css: '.active.content .js-inviteCustomer')
    modal_ready()
    set(
      css:   '.modal [name="firstname"]',
      value: 'Client',
    )
    set(
      css:   '.modal [name="lastname"]',
      value: 'Smith',
    )
    set(
      css:   '.modal [name="email"]',
      value: "#{customer}@example.com",
    )
    set(
      css:   '.modal [data-name="note"]',
      value: 'some note',
    )
    click(
      css:  '.modal button.btn.btn--primary',
      fast: true,
    )
    watch_for(
      css:   'body div.modal',
      value: 'Sending',
    )
    watch_for_disappear(
      css:   'body div.modal',
      value: 'Sending',
    )
    modal_disappear()

    # test ticket
    click(
      css:  '.active.content .js-testTicket',
      fast: true,
    )
    modal_ready()
    watch_for(
      css:   'body div.modal',
      value: 'A Test Ticket has been created',
    )
    click(
      css:  '.modal .modal-body',
      fast: true,
    )
    watch_for_disappear(
      css:   'body div.modal',
      value: 'Test Ticket',
    )
    modal_disappear()

    execute(
      js: '$(".active.content .sidebar").show()',
    )
    watch_for(
      css:     '.active.content .js-activityContent',
      value:   'Nicole Braun created Article for Test Ticket!',
      timeout: 35,
    )

    # check update
    click(css: '.active.content a[href="#channels/form"]')
    sleep 2
    switch(
      css:  '.content.active .js-formSetting',
      type: 'on',
    )
    click(css: '#navigation a[href="#dashboard"]')
    hit = false
    37.times do
      next if !@browser.find_elements(css: '.active.content a[href="#channels/form"].todo.is-done')[0]

      hit = true
      break
    end
    assert(hit)

  end

end
