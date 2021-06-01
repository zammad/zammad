# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AaaGettingStartedTest < TestCase
  def test_a_getting_started
    if !ENV['MAILBOX_INIT']
      #raise "Need MAILBOX_INIT as ENV variable like export MAILBOX_INIT='unittest01@znuny.com:somepass'"
      puts "NOTICE: Need MAILBOX_INIT as ENV variable like export MAILBOX_INIT='unittest01@znuny.com:somepass'"
      return
    end
    mailbox_user     = ENV['MAILBOX_INIT'].split(':')[0]
    mailbox_password = ENV['MAILBOX_INIT'].split(':')[1]

    @browser = browser_instance
    location(url: browser_url)
    watch_for(
      css:   '.setup.wizard',
      value: 'setup new system',
    )
    click(css: '.js-start .btn--primary')
    watch_for(
      css:   '.setup.wizard',
      value: 'admin',
    )
    set(
      css:   '.js-admin input[name="firstname"]',
      value: 'Test Master',
    )
    set(
      css:   '.js-admin input[name="lastname"]',
      value: 'Agent',
    )
    set(
      css:   '.js-admin input[name="email"]',
      value: 'master@example.com',
    )
    set(
      css:   '.js-admin input[name="firstname"]',
      value: 'Test Master',
    )
    set(
      css:   '.js-admin input[name="password"]',
      value: 'TEst1234äöüß',
    )
    set(
      css:   '.js-admin input[name="password_confirm"]',
      value: 'TEst1234äöüß',
    )
    click(css: '.js-admin .btn--success')

    # getting started - base
    watch_for(
      css:   '.js-base h2',
      value: 'Organization',
    )
    set(
      css:   '.js-base input[name="organization"]',
      value: 'Some Organization',
    )
    set(
      css:   '.js-base input[name="url"]',
      value: 'some host',
    )
    click(
      css: '.js-base .btn--primary',
    )
    watch_for(
      css:   'body',
      value: 'An URL looks like this',
    )
    set(
      css:   '.js-base input[name="url"]',
      value: browser_url,
    )
    click(
      css: '.js-base .btn--primary',
    )

    # getting started - email notification
    watch_for(
      css:   '.js-outbound h2',
      value: 'Email Notification',
    )
    location_check(
      url: '#getting_started/email_notification',
    )
    click(
      css: '.js-outbound .btn--primary',
    )

    # getting started - create email account
    watch_for(
      css:   '.js-channel h2',
      value: 'Connect Channels',
    )
    location_check(
      url: '#getting_started/channel',
    )
    click(
      css: '.js-channel .email .provider_name',
    )
    set(
      css:   '.js-intro input[name="realname"]',
      value: 'Some Realname',
    )
    set(
      css:   '.js-intro input[name="email"]',
      value: mailbox_user,
    )
    set(
      css:   '.js-intro input[name="password"]',
      value: mailbox_password,
    )
    click(
      css: '.js-intro .btn--primary',
    )
    watch_for(
      css:     'body',
      value:   'verify',
      timeout: 20,
    )
    watch_for(
      css:     'body',
      value:   'invite',
      timeout: 100,
    )

    # invite agent1
    location_check(
      url: '#getting_started/agents',
    )
    watch_for(
      css: '.js-agent input[name="firstname"]',
    )
    set(
      css:   '.js-agent input[name="firstname"]',
      value: 'Agent 1',
    )
    set(
      css:   '.js-agent input[name="lastname"]',
      value: 'Test',
    )
    set(
      css:   '.js-agent input[name="email"]',
      value: 'agent1@example.com',
    )
    # not needed since we hide group selections if only one group exists
    #click(
    #  css: '.js-agent input[name="group_ids"][value="1"]',
    #)
    click(
      css: '.js-agent .btn--success',
    )
    watch_for(
      css:   'body',
      value: 'Invitation sent',
    )
    location_check(
      url: '#getting_started/agents',
    )
    click(
      css: '.js-agent .btn--primary',
    )
    watch_for(
      css:   'body',
      value: 'My Stats',
    )
    location_check(
      url: '#clues',
    )

    clues_close(
      optional: false,
    )

    # verify organization and fqdn
    click(
      css: 'a[href="#manage"]',
    )
    click(
      css: '.content.active a[href="#settings/branding"]',
    )

    match(
      css:   '.content.active input[name="organization"]',
      value: 'Some Organization',
    )
    click(
      css: '.content.active a[href="#settings/system"]',
    )

    fqdn = nil
    if browser_url =~ %r{://(.+?)(:.+?|/.+?|)$}
      fqdn = $1
    end
    raise "Unable to get fqdn based on #{browser_url}" if !fqdn

    match(
      css:   '.content.active input[name="fqdn"]',
      value: fqdn,
    )
  end
end
