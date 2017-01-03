# encoding: utf-8
require 'browser_test_helper'

class CustomerTicketCreateTest < TestCase
  def test_customer_ticket_create
    @browser = browser_instance
    login(
      username: 'nicole.braun@zammad.org',
      password: 'test',
      url: browser_url,
    )

    # customer ticket create
    click(css: 'a[href="#new"]')
    click(css: 'a[href="#customer_ticket_new"]')
    sleep 2

    select(
      css: '.newTicket select[name="group_id"]',
      value: 'Users',
    )

    set(
      css: '.newTicket input[name="title"]',
      value: 'some subject 123äöü',
    )
    set(
      css: '.newTicket [data-name="body"]',
      value: 'some body 123äöü',
    )
    exists_not(
      css: '.newTicket input[name="customer_id"]',
    )
    exists_not(
      css: '.newTicket input[name="priority_id"]',
    )

    click(css: '.newTicket button.js-submit')
    sleep 5

    # check if ticket is shown
    location_check(url: '#ticket/zoom/')

    match(
      css: '.active div.ticket-article',
      value: 'some body 123äöü',
      no_quote: true,
    )

    # update ticket
    set(
      css: '.content.active [data-name="body"]',
      value: 'some body 1234 äöüß',
      no_click: true,
    )

    task_type(
      type: 'stayOnTab',
    )

    click(css: '.content.active .js-submit')

    watch_for(
      css: '.content.active div.ticket-article',
      value: 'some body 1234 äöüß',
    )
  end
end
