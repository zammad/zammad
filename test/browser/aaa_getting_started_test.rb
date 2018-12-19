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
      value: 'test1234äöüß',
    )
    set(
      css:   '.js-admin input[name="password_confirm"]',
      value: 'test1234äöüß',
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
      value: 'A URL looks like',
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

  def test_b_accounts_auto
    #return # TODO: temp disable
    accounts = []
    (1..10).each do |count|
      next if !ENV["MAILBOX_AUTO#{count}"]

      mailbox_user     = ENV["MAILBOX_AUTO#{count}"].split(':')[0]
      mailbox_password = ENV["MAILBOX_AUTO#{count}"].split(':')[1]
      account = {
        realname: 'auto account',
        email:    mailbox_user,
        password: mailbox_password,
      }
      accounts.push account
    end
    if accounts.blank?
      #raise "Need min. MAILBOX_AUTO1 as ENV variable like export MAILBOX_AUTO1='nicole.braun2015@gmail.com:somepass'"
      puts "NOTICE: Need min. MAILBOX_AUTO1 as ENV variable like export MAILBOX_AUTO1='nicole.braun2015@gmail.com:somepass'"
      return
    end
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    accounts.each do |account|

      # getting started - auto mail
      location(url: browser_url + '/#getting_started/channel')
      click(
        css: '.js-channel .email .provider_name',
      )
      set(
        css:   '.js-intro input[name="realname"]',
        value: account[:realname],
      )
      set(
        css:   '.js-intro input[name="email"]',
        value: account[:email],
      )
      set(
        css:   '.js-intro input[name="password"]',
        value: account[:password],
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
      location_check(
        url: '#getting_started/agents',
      )
    end
  end

  def test_b_accounts_manual
    #return # TODO: temp disable
    accounts = []
    (1..10).each do |count|
      next if !ENV["MAILBOX_MANUAL#{count}"]

      mailbox_user     = ENV["MAILBOX_MANUAL#{count}"].split(':')[0]
      mailbox_password = ENV["MAILBOX_MANUAL#{count}"].split(':')[1]
      mailbox_inbound  = ENV["MAILBOX_MANUAL#{count}"].split(':')[2]
      mailbox_outbound = ENV["MAILBOX_MANUAL#{count}"].split(':')[3]
      account = {
        realname: 'manual account',
        email:    mailbox_user,
        password: mailbox_password,
        inbound:  {
          'options::host' => mailbox_inbound,
        },
        outbound: {
          'options::host' => mailbox_outbound,
        },
      }
      accounts.push account
    end
    if accounts.blank?
      #raise "Need min. MAILBOX_MANUAL1 as ENV variable like export MAILBOX_MANUAL1='nicole.bauer2015@yahoo.de:somepass:imap.mail.yahoo.com:smtp.mail.yahoo.com'"
      puts "NOTICE: Need min. MAILBOX_MANUAL1 as ENV variable like export MAILBOX_MANUAL1='nicole.bauer2015@yahoo.de:somepass:imap.mail.yahoo.com:smtp.mail.yahoo.com'"
      return
    end

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    accounts.each do |account|

      # getting started - manual mail
      location(url: browser_url + '/#getting_started/channel')

      click(
        css: '.js-channel .email .provider_name',
      )
      set(
        css:   '.js-intro input[name="realname"]',
        value: account[:realname],
      )
      set(
        css:   '.js-intro input[name="email"]',
        value: account[:email],
      )
      set(
        css:   '.js-intro input[name="password"]',
        value: account[:password],
      )
      click(
        css: '.js-intro .btn--primary',
      )
      watch_for(
        css:     '.js-inbound h2',
        value:   'inbound',
        timeout: 220,
      )
      watch_for(
        css:   '.js-inbound',
        value: 'manual',
      )
      set(
        css:   '.js-inbound input[name="options::host"]',
        value: account[:inbound]['options::host'],
      )
      click(
        css: '.js-inbound .btn--primary',
      )
      watch_for(
        css:   '.js-outbound h2',
        value: 'outbound',
      )
      select(
        css:   '.js-outbound select[name="adapter"]',
        value: 'SMTP - configure your own outgoing SMTP settings',
      )
      set(
        css:   '.js-outbound input[name="options::host"]',
        value: account[:outbound]['options::host'],
      )
      click(
        css: '.js-outbound .btn--primary',
      )
      watch_for(
        css:   'body',
        value: 'verify',
      )
      watch_for(
        css:     'body',
        value:   'invite',
        timeout: 190,
      )
      location_check(
        url: '#getting_started/agents',
      )
    end
  end
end
