# encoding: utf-8
require 'browser_test_helper'

class AgentUserManageTest < TestCase
  def test_agent_user
    customer_user_email = 'customer-test-' + rand(999_999).to_s + '@example.com'
    firstname           = 'Customer Firstname'
    lastname            = 'Customer Lastname'
    fullname            = "#{firstname} #{lastname} <#{customer_user_email}>"

    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    sleep 1

    # create customer
    click( css: 'a[href="#new"]' )
    click( css: 'a[href="#ticket/create"]' )
    click( css: '.active .newTicket [name="customer_id_completion"]' )

    # check if pulldown is open, it's not working stable via selenium
    @browser.execute_script( "$('.active .newTicket .js-recipientDropdown').addClass('open')" )

    sleep 1
    sendkey( value: :arrow_down )
    sleep 0.5
    click( css: '.active .newTicket .recipientList-entry.js-objectNew' )
    sleep 1

    set(
      css: '.modal input[name="firstname"]',
      value: firstname,
    )
    set(
      css: '.modal input[name="lastname"]',
      value: lastname,
    )
    set(
      css: '.modal input[name="email"]',
      value: customer_user_email,
    )

    click( css: '.modal button.js-submit' )
    sleep 4

    # check is used to check selected
    match(
      css: '.active input[name="customer_id"]',
      value: '^\d+$',
      no_quote: true,
    )
    match(
      css: '.active input[name="customer_id_completion"]',
      value: firstname,
    )
    match(
      css: '.active input[name="customer_id_completion"]',
      value: lastname,
    )
    match(
      css: '.active input[name="customer_id_completion"]',
      value: customer_user_email,
    )
    match(
      css: '.active input[name="customer_id_completion"]',
      value: fullname,
    )
    sleep 4

    # call new ticket screen again
    tasks_close_all()

    click( css: 'a[href="#new"]' )
    click( css: 'a[href="#ticket/create"]' )
    sleep 2

    match(
      css: '.active input[name="customer_id"]',
      value: '',
    )
    match(
      css: '.active input[name="customer_id_completion"]',
      value: '',
    )
    set(
      css: '.active .newTicket input[name="customer_id_completion"]',
      value: customer_user_email,
    )
    sleep 3

    click( css: '.active .newTicket .recipientList-entry.js-object.is-active' )
    sleep 1

    # check is used to check selected
    match(
      css: '.active input[name="customer_id"]',
      value: '^\d+$',
      no_quote: true,
    )
    match(
      css: '.active input[name="customer_id_completion"]',
      value: firstname,
    )
    match(
      css: '.active input[name="customer_id_completion"]',
      value: lastname,
    )
    match(
      css: '.active input[name="customer_id_completion"]',
      value: customer_user_email,
    )
    match(
      css: '.active input[name="customer_id_completion"]',
      value: fullname,
    )
  end

end
