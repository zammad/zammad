# encoding: utf-8
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
      url: browser_url,
    )
    tasks_close_all()

    click(css: 'a[href="#manage"]')
    click(css: 'a[href="#channels/email"]')

    click(css: '#content .js-channelNew')

    sleep 2

    set(
      css: '.modal input[name="realname"]',
      value: 'My System',
    )
    set(
      css: '.modal input[name="email"]',
      value: mailbox_user,
    )
    set(
      css: '.modal input[name="password"]',
      value: mailbox_password,
    )
    select(
      css:   '.modal select[name="group_id"]',
      value: 'Users',
    )
    click(css: '.modal button.js-submit')
    sleep 4

    watch_for(
      css: '.modal',
      value: '(already exists|unknown mailbox)',
    )

    click(css: '.modal .js-close')

    # delete all channels
    loop do
      break if !@browser.find_elements(css: '#content .js-channelDelete')[0]
      click(css: '#content .js-channelDelete')
      sleep 2
      click(css: '.modal .js-submit')
      sleep 2
    end

    # re-create
    click(css: '#content .js-channelNew')

    sleep 2

    set(
      css: '.modal input[name="realname"]',
      value: 'My System',
    )
    set(
      css: '.modal input[name="email"]',
      value: mailbox_user,
    )
    set(
      css: '.modal input[name="password"]',
      value: mailbox_password,
    )
    select(
      css:   '.modal select[name="group_id"]',
      value: 'Users',
    )
    click(css: '.modal button.js-submit')
    sleep 2

    watch_for_disappear(
      css: '.modal',
    )
    sleep 2
    exists_not(css: '.modal')

    watch_for(
      css: '#content',
      value: mailbox_user,
    )

    # set invalid folder
    click(css: '#content .js-editInbound')
    sleep 2

    set(
      css: '.modal input[name="options::folder"]',
      value: 'not_existing_folder',
    )
    click(css: '.modal .js-inbound button.js-submit')
    watch_for(
      css: '.modal',
      value: 'Mailbox doesn\'t exist',
    )

  end

end
