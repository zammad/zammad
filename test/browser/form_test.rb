# encoding: utf-8
require 'browser_test_helper'

class FormTest < TestCase

  def test_basic
    agent = browser_instance
    login(
      browser: agent,
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all(
      browser: agent,
    )

    # disable form
    click(
      browser: agent,
      css: 'a[href="#manage"]',
    )
    click(
      browser: agent,
      css: 'a[href="#channels/form"]',
    )
    switch(
      browser: agent,
      css: '#content .js-formSetting',
      type: 'off',
    )
    sleep 2

    customer = browser_instance
    location(
      browser: customer,
      url:     "#{browser_url}/assets/form/form.html",
    )
    sleep 4
    match(
      browser: customer,
      css: '.js-logDisplay',
      value: 'Faild to load form config, feature is disabled',
    )
    switch(
      browser: agent,
      css: '#content .js-formSetting',
      type: 'on',
    )
    sleep 2

    reload(
      browser: customer,
    )
    sleep 4
    match_not(
      browser: customer,
      css: '.js-logDisplay',
      value: 'Faild to load form config, feature is disabled',
    )

    exists_not(
      browser: customer,
      css: 'body div.modal',
    )

    # modal dialog
    click(
      browser: customer,
      css: '#feedback-form-modal',
    )
    exists(
      browser: customer,
      css: 'body div.modal',
    )

    # fill form valid data - but too fast
    set(
      browser: customer,
      css: 'body div.modal [name="name"]',
      value: 'some name',
    )
    set(
      browser: customer,
      css: 'body div.modal [name="email"]',
      value: 'discard@znuny.com',
    )
    set(
      browser: customer,
      css: 'body div.modal [name="body"]',
      value: "some text\nnew line",
    )
    click(
      browser: customer,
      css: 'body div.modal button[type="submit"]',
    )

    # check warning
    alert = customer.switch_to.alert
    alert.dismiss()
    sleep 10

    # fill form invalid data - within correct time
    set(
      browser: customer,
      css: 'body div.modal [name="name"]',
      value: 'some name',
    )
    set(
      browser: customer,
      css: 'body div.modal [name="email"]',
      value: 'invalid_email',
    )
    set(
      browser: customer,
      css: 'body div.modal [name="body"]',
      value: "some text\nnew line",
    )
    click(
      browser: customer,
      css: 'body div.modal button[type="submit"]',
    )
    sleep 10
    exists(
      browser: customer,
      css: 'body div.modal',
    )

    # fill form valid data
    set(
      browser: customer,
      css: 'body div.modal [name="email"]',
      value: 'discard@znuny.com',
    )
    click(
      browser: customer,
      css: 'body div.modal button[type="submit"]',
    )
    watch_for(
      browser: customer,
      css:     'body div.modal',
      value:   'Thank you for your inquiry',
    )

    # click on backgroud (not on thank you dialog)
    element = customer.find_elements({ css: 'body div.modal' })[0]
    customer.action.move_to(element, 200, 200).perform
    customer.action.click.perform

    sleep 1
    exists_not(
      browser: customer,
      css: 'body div.modal',
    )

    # fill form invalid data - within correct time
    click(
      browser: customer,
      css: '#feedback-form-modal',
    )
    sleep 10
    set(
      browser: customer,
      css: 'body div.modal [name="name"]',
      value: '',
    )
    set(
      browser: customer,
      css: 'body div.modal [name="email"]',
      value: 'discard@znuny.com',
    )
    set(
      browser: customer,
      css: 'body div.modal [name="body"]',
      value: "some text\nnew line",
    )
    click(
      browser: customer,
      css: 'body div.modal button[type="submit"]',
    )
    exists(
      browser: customer,
      css: 'body div.modal .has-error [name="name"]',
    )
    set(
      browser: customer,
      css: 'body div.modal [name="name"]',
      value: 'some sender',
    )
    set(
      browser: customer,
      css: 'body div.modal [name="body"]',
      value: '',
    )
    click(
      browser: customer,
      css: 'body div.modal button[type="submit"]',
    )
    exists(
      browser: customer,
      css: 'body div.modal .has-error [name="body"]',
    )
    set(
      browser: customer,
      css: 'body div.modal [name="body"]',
      value: 'new body',
    )
    set(
      browser: customer,
      css: 'body div.modal [name="email"]',
      value: 'somebody@notexistinginanydomainspacealsonothere.nowhere',
    )
    click(
      browser: customer,
      css: 'body div.modal button[type="submit"]',
    )
    exists(
      browser: customer,
      css: 'body div.modal .has-error [name="email"]',
    )
    set(
      browser: customer,
      css: 'body div.modal [name="email"]',
      value: 'notexistinginanydomainspacealsonothere@znuny.com',
    )
    click(
      browser: customer,
      css: 'body div.modal button[type="submit"]',
    )
    exists(
      browser: customer,
      css: 'body div.modal .has-error [name="email"]',
    )
    set(
      browser: customer,
      css: 'body div.modal [name="email"]',
      value: 'discard@znuny.com',
    )
    click(
      browser: customer,
      css: 'body div.modal button[type="submit"]',
    )
    watch_for(
      browser: customer,
      css:     'body div.modal',
      value:   'Thank you for your inquiry',
    )

    # click on backgroud (not on thank you dialog)
    element = customer.find_elements({ css: 'body div.modal' })[0]
    customer.action.move_to(element, 200, 200).perform
    customer.action.click.perform

    sleep 1
    exists_not(
      browser: customer,
      css: 'body div.modal',
    )

    # inline form
    set(
      browser: customer,
      css: '.zammad-form [name="name"]',
      value: 'Some Name',
    )
    set(
      browser: customer,
      css: '.zammad-form [name="email"]',
      value: 'discard@znuny.com',
    )
    set(
      browser: customer,
      css: '.zammad-form [name="body"]',
      value: 'some text',
    )
    click(
      browser: customer,
      css: '.zammad-form button[type="submit"]',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-form',
      value:   'Thank you for your inquiry',
    )
  end

end
