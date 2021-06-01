# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class FormTest < TestCase

  def test_basic
    agent = browser_instance
    login(
      browser:  agent,
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all(
      browser: agent,
    )

    # disable form
    click(
      browser: agent,
      css:     'a[href="#manage"]',
    )
    click(
      browser: agent,
      css:     '.content.active a[href="#channels/form"]',
    )
    switch(
      browser: agent,
      css:     '.content.active .js-formSetting',
      type:    'off',
    )

    # admin preview test
    sleep 1
    click(
      browser: agent,
      css:     '.content.active .js-formBtn',
    )

    sleep 10
    set(
      browser: agent,
      css:     'body div.zammad-form-modal [name="name"]',
      value:   'some sender',
    )
    set(
      browser: agent,
      css:     'body div.zammad-form-modal [name="body"]',
      value:   '',
    )
    click(
      browser: agent,
      css:     'body div.zammad-form-modal button[type="submit"]',
    )
    watch_for(
      browser: agent,
      css:     'body div.zammad-form-modal .has-error [name="body"]',
    )
    watch_for_disappear(
      browser: agent,
      css:     'body div.zammad-form-modal button[type="submit"][disabled]',
    )
    set(
      browser: agent,
      css:     'body div.zammad-form-modal [name="body"]',
      value:   'new body',
    )
    set(
      browser: agent,
      css:     'body div.zammad-form-modal [name="email"]',
      value:   'somebody@notexistinginanydomainspacealsonothere.nowhere',
    )
    click(
      browser: agent,
      css:     'body div.zammad-form-modal button[type="submit"]',
    )
    watch_for(
      browser: agent,
      css:     'body div.zammad-form-modal .has-error [name="email"]',
    )
    watch_for_disappear(
      browser: agent,
      css:     'body div.zammad-form-modal button[type="submit"][disabled]',
    )
    set(
      browser: agent,
      css:     'body div.zammad-form-modal [name="email"]',
      value:   'discard@znuny.com',
    )
    click(
      browser: agent,
      css:     'body div.zammad-form-modal button[type="submit"]',
    )
    watch_for(
      browser: agent,
      css:     'body div.zammad-form-modal',
      value:   'Thank you for your inquiry',
    )
    # click on backgroud (not on thank you dialog)
    element = agent.find_elements({ css: 'body div.zammad-form-modal' })[0]
    agent.action.move_to(element, 200, 200).perform
    agent.action.click.perform

    customer = browser_instance
    location(
      browser: customer,
      url:     "#{browser_url}/assets/form/form.html",
    )
    watch_for(
      browser: customer,
      css:     '.js-logDisplay',
      value:   'Faild to load form config, feature is disabled',
    )
    switch(
      browser: agent,
      css:     '.content.active .js-formSetting',
      type:    'on',
    )

    reload(
      browser: customer,
    )
    sleep 4
    match_not(
      browser: customer,
      css:     '.js-logDisplay',
      value:   'Faild to load form config, feature is disabled',
    )

    exists_not(
      browser: customer,
      css:     'body div.zammad-form-modal',
    )

    # modal dialog
    click(
      browser: customer,
      css:     '#feedback-form-modal',
    )
    watch_for(
      browser: customer,
      css:     'body div.zammad-form-modal',
    )

    # fill form valid data - but too fast
    set(
      browser: customer,
      css:     'body div.zammad-form-modal [name="name"]',
      value:   'some name',
    )
    set(
      browser: customer,
      css:     'body div.zammad-form-modal [name="email"]',
      value:   'discard@znuny.com',
    )
    set(
      browser: customer,
      css:     'body div.zammad-form-modal [name="body"]',
      value:   "some text\nnew line",
    )
    click(
      browser: customer,
      css:     'body div.zammad-form-modal button[type="submit"]',
    )

    # check warning
    alert = customer.switch_to.alert
    alert.dismiss()
    sleep 10

    # fill form invalid data - within correct time
    set(
      browser: customer,
      css:     'body div.zammad-form-modal [name="name"]',
      value:   'some name',
    )
    set(
      browser: customer,
      css:     'body div.zammad-form-modal [name="email"]',
      value:   'invalid_email',
    )
    set(
      browser: customer,
      css:     'body div.zammad-form-modal [name="body"]',
      value:   "some text\nnew line",
    )
    click(
      browser: customer,
      css:     'body div.zammad-form-modal button[type="submit"]',
    )
    sleep 10
    exists(
      browser: customer,
      css:     'body div.zammad-form-modal',
    )

    # fill form valid data
    set(
      browser: customer,
      css:     'body div.zammad-form-modal [name="email"]',
      value:   'discard@znuny.com',
    )
    click(
      browser: customer,
      css:     'body div.zammad-form-modal button[type="submit"]',
    )
    watch_for(
      browser: customer,
      css:     'body div.zammad-form-modal',
      value:   'Thank you for your inquiry',
    )

    # click on backgroud (not on thank you dialog)
    element = customer.find_elements({ css: 'body div.zammad-form-modal' })[0]
    customer.action.move_to(element, 200, 200).perform
    customer.action.click.perform

    sleep 1
    exists_not(
      browser: customer,
      css:     'body div.zammad-form-modal',
    )

    # fill form invalid data - within correct time
    click(
      browser: customer,
      css:     '#feedback-form-modal',
    )
    sleep 10
    set(
      browser: customer,
      css:     'body div.zammad-form-modal [name="name"]',
      value:   '',
    )
    set(
      browser: customer,
      css:     'body div.zammad-form-modal [name="email"]',
      value:   'discard@znuny.com',
    )
    set(
      browser: customer,
      css:     'body div.zammad-form-modal [name="body"]',
      value:   "some text\nnew line",
    )
    click(
      browser: customer,
      css:     'body div.zammad-form-modal button[type="submit"]',
    )
    watch_for(
      browser: customer,
      css:     'body div.zammad-form-modal .has-error [name="name"]',
    )
    watch_for_disappear(
      browser: customer,
      css:     'body div.zammad-form-modal button[type="submit"][disabled]',
    )
    set(
      browser: customer,
      css:     'body div.zammad-form-modal [name="name"]',
      value:   'some sender',
    )
    set(
      browser: customer,
      css:     'body div.zammad-form-modal [name="body"]',
      value:   '',
    )
    click(
      browser: customer,
      css:     'body div.zammad-form-modal button[type="submit"]',
    )
    watch_for(
      browser: customer,
      css:     'body div.zammad-form-modal .has-error [name="body"]',
    )
    watch_for_disappear(
      browser: customer,
      css:     'body div.zammad-form-modal button[type="submit"][disabled]',
    )
    set(
      browser: customer,
      css:     'body div.zammad-form-modal [name="body"]',
      value:   'new body',
    )
    set(
      browser: customer,
      css:     'body div.zammad-form-modal [name="email"]',
      value:   'somebody@notexistinginanydomainspacealsonothere.nowhere',
    )
    click(
      browser: customer,
      css:     'body div.zammad-form-modal button[type="submit"]',
    )
    watch_for(
      browser: customer,
      css:     'body div.zammad-form-modal .has-error [name="email"]',
    )
    watch_for_disappear(
      browser: customer,
      css:     'body div.zammad-form-modal button[type="submit"][disabled]',
    )
    set(
      browser: customer,
      css:     'body div.zammad-form-modal [name="email"]',
      value:   'discard@znuny.com',
    )
    click(
      browser: customer,
      css:     'body div.zammad-form-modal button[type="submit"]',
    )
    watch_for(
      browser: customer,
      css:     'body div.zammad-form-modal',
      value:   'Thank you for your inquiry',
    )

    # click on backgroud (not on thank you dialog)
    element = customer.find_elements({ css: 'body div.zammad-form-modal' })[0]
    customer.action.move_to(element, 200, 200).perform
    customer.action.click.perform

    sleep 1
    exists_not(
      browser: customer,
      css:     'body div.zammad-form-modal',
    )

    # inline form
    set(
      browser: customer,
      css:     '.zammad-form [name="name"]',
      value:   'Some Name',
    )
    set(
      browser: customer,
      css:     '.zammad-form [name="email"]',
      value:   'discard@znuny.com',
    )
    set(
      browser: customer,
      css:     '.zammad-form [name="body"]',
      value:   'some text',
    )
    click(
      browser: customer,
      css:     '.zammad-form button[type="submit"]',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-form',
      value:   'Thank you for your inquiry',
    )
  end

end
