# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AdminChannelEmailTest < TestCase
  def test_account_add

    if !ENV['MAILBOX_INIT']
      #raise "Need MAILBOX_INIT as ENV variable like export MAILBOX_INIT='unittest01@znuny.com:somepass'"
      puts "NOTICE: Need MAILBOX_INIT as ENV variable like export MAILBOX_INIT='unittest01@znuny.com:somepass'"
      return
    end
    mailbox_user     = ENV['MAILBOX_INIT'].split(':')[0]
    mailbox_password = ENV['MAILBOX_INIT'].split(':')[1]

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    click(css: 'a[href="#manage"]')
    click(css: '.content.active a[href="#channels/email"]')

    # check if postmaster filter are shown
    click(css: '.content.active a[href="#c-filter"]')
    match(
      css:   '.content.active #c-filter .overview',
      value: 'No Entries',
    )

    # check if signatures are shown
    click(css: '.content.active a[href="#c-signature"]')
    match(
      css:   '.content.active #c-signature .overview',
      value: 'default',
    )

    click(css: '.content.active a[href="#c-account"]')
    click(css: '.content.active .js-channelNew')

    modal_ready()
    set(
      css:   '.modal input[name="realname"]',
      value: 'My System',
    )
    set(
      css:   '.modal input[name="email"]',
      value: mailbox_user,
    )
    set(
      css:   '.modal input[name="password"]',
      value: mailbox_password,
    )
    select(
      css:   '.modal select[name="group_id"]',
      value: 'Users',
    )
    click(css: '.modal button.js-submit')
    sleep 4

    watch_for(
      css:   '.modal',
      value: '(already exists|unknown mailbox)',
    )

    click(css: '.modal .js-close')

    # delete all channels
    loop do
      break if !@browser.find_elements(css: '.content.active .js-channelDelete')[0]

      click(css: '.content.active .js-channelDelete')
      sleep 2
      # flanky
      click(css: '.modal .js-submit')
      sleep 2
    end

    # re-create
    click(css: '.content.active .js-channelNew')

    modal_ready()

    set(
      css:   '.modal input[name="realname"]',
      value: 'My System',
    )
    set(
      css:   '.modal input[name="email"]',
      value: mailbox_user,
    )
    set(
      css:   '.modal input[name="password"]',
      value: mailbox_password,
    )
    select(
      css:   '.modal select[name="group_id"]',
      value: 'Users',
    )
    click(css: '.modal button.js-submit')
    modal_disappear(timeout: 20)

    watch_for(
      css:   '.content.active',
      value: mailbox_user,
    )

    # set invalid folder
    click(css: '.content.active .js-editInbound')

    modal_ready()

    set(
      css:   '.modal input[name="options::folder"]',
      value: 'not_existing_folder',
    )
    click(css: '.modal .js-inbound button.js-submit')
    watch_for(
      css:   '.modal',
      value: 'Mailbox doesn\'t exist',
    )

  end

  # test the creation and cloning of Postmaster filters
  # confirm fix for issue #2170 - Cannot clone PostmasterFilter
  def test_filter_clone
    filter_name = "Test Filter #{rand(999_999)}"

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    click(css: 'a[href="#manage"]')
    click(css: '.content.active a[href="#channels/email"]')

    click(css: '.content.active a[href="#c-filter"]')

    # create a new email filter
    click(css: '.content.active a[data-type="new"]')

    modal_ready()
    set(
      css:   '.modal input[name="name"]',
      value: filter_name,
    )
    set(
      css:   '.modal input[name="match::from::value"]',
      value: 'target',
    )
    click(css: '.modal .js-submit')
    modal_disappear()

    watch_for(
      css:   '.content.active .table',
      value: filter_name,
    )

    # now clone filter that we just created
    click(css: '.content.active .table .dropdown .btn--table')
    click(css: '.content.active .table .dropdown .js-clone')

    modal_ready()
    click(css: '.modal .js-submit')
    modal_disappear()

    # confirm the clone exists in the table
    watch_for(
      css:   '.content.active .table',
      value: "Clone: #{filter_name}",
    )
  end
end
