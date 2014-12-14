# encoding: utf-8
require 'browser_test_helper'

class AaaGettingStartedTest < TestCase
  def test_a_getting_started
    #return # TODO: temp disable
    if !ENV['MAILBOX_INIT']
      #raise "Need MAILBOX_INIT as ENV variable like export MAILBOX_INIT='unittest01@znuny.com:somepass'"
      puts "NOTICE: Need MAILBOX_INIT as ENV variable like export MAILBOX_INIT='unittest01@znuny.com:somepass'"
      return
    end
    mailbox_user     = ENV['MAILBOX_INIT'].split(':')[0]
    mailbox_password = ENV['MAILBOX_INIT'].split(':')[1]
    tests            = [
      {
        :name     => 'start',
        :instance => browser_instance,
        :url      => browser_url + '/',
        :action   => [
          {
            :execute => 'check',
            :css     => '.setup.wizard',
            :result  => true,
          },
        ],
      },
      {
        :name     => 'getting started - master agent',
        :action   => [
          {
            :execute => 'click',
            :css     => '.js-start .btn--primary',
          },

          {
            :execute => 'set',
            :css     => '.js-admin input[name="firstname"]',
            :value   => 'Test Master',
          },
          {
            :execute => 'set',
            :css     => '.js-admin input[name="lastname"]',
            :value   => 'Agent',
          },
          {
            :execute => 'set',
            :css     => '.js-admin input[name="email"]',
            :value   => 'master@example.com',
          },
          {
            :execute => 'set',
            :css     => '.js-admin input[name="password"]',
            :value   => 'test1234äöüß',
          },
          {
            :execute => 'set',
            :css     => '.js-admin input[name="password_confirm"]',
            :value   => 'test1234äöüß',
          },
          {
            :execute => 'click',
            :css     => '.js-admin .btn--success',
          },
          {
            :execute => 'watch_for',
            :area    => '.js-base h2',
            :value   => 'Organization',
          },
        ],
      },

      # set base
      {
        :name     => 'getting started - base',
        :action   => [
          {
            :execute      => 'match',
            :css          => '.js-base h2',
            :value        => 'Organization',
            :match_result => true,
          },
          {
            :execute => 'set',
            :css     => '.js-base input[name="organization"]',
            :value   => 'Some Organization',
          },
          {
            :execute => 'set',
            :css     => '.js-base input[name="url"]',
            :value   => 'some host',
          },
          {
            :execute => 'click',
            :css     => '.js-base .btn--primary',
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'A URL looks like',
          },
          {
            :execute => 'set',
            :css     => '.js-base input[name="url"]',
            :value   => 'http://localhost:3333',
          },
          {
            :execute => 'click',
            :css     => '.js-base .btn--primary',
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'channel',
          },
          {
            :execute => 'check',
            :element => :url,
            :result  => '#getting_started/channel',
          },
        ],
      },

      # create email account
      {
        :name     => 'getting started - base',
        :action   => [
          {
            :execute      => 'match',
            :css          => '.js-channel h2',
            :value        => 'Connect Channels',
            :match_result => true,
          },
          {
            :execute => 'click',
            :css     => '.js-channel .email .provider_name',
          },
          {
            :execute => 'set',
            :css     => '.js-intro input[name="realname"]',
            :value   => 'Some Realname',
          },
          {
            :execute => 'set',
            :css     => '.js-intro input[name="email"]',
            :value   => mailbox_user,
          },
          {
            :execute => 'set',
            :css     => '.js-intro input[name="password"]',
            :value   => mailbox_password,
          },
          {
            :execute => 'click',
            :css     => '.js-intro .btn--primary',
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'verify',
            :timeout => 20,
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'invite',
            :timeout => 100,
          },
          {
            :execute => 'check',
            :element => :url,
            :result  => '#getting_started/agents',
          },
        ],
      },

      # invite agent1
      {
        :name     => 'getting started - agent 1',
        :action   => [
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'Invite',
            :match_result => true,
          },
          {
            :execute => 'set',
            :css     => '.js-agent input[name="firstname"]',
            :value   => 'Agent 1',
          },
          {
            :execute => 'set',
            :css     => '.js-agent input[name="lastname"]',
            :value   => 'Test',
          },
          {
            :execute => 'set',
            :css     => '.js-agent input[name="email"]',
            :value   => 'agent1@example.com',
          },
          {
            :execute => 'click',
            :css     => '.js-agent input[name="group_ids"][value="1"]',
          },
          {
            :execute => 'click',
            :css     => '.js-agent .btn--success',
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'Invitation sent',
          },
          {
            :execute => 'check',
            :element => :url,
            :result  => '#getting_started/agents',
          },
          {
            :execute => 'click',
            :css     => '.js-agent .btn--primary',
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'My Stats',
          },
          {
            :execute => 'check',
            :element => :url,
            :result  => '#dashboard',
          },
        ],
      },
    ]
    browser_single_test(tests)
  end

  def test_b_accounts_auto
    #return # TODO: temp disable
    accounts = []
    (1..10).each {|count|
      next if !ENV["MAILBOX_AUTO#{count.to_s}"]
      mailbox_user     = ENV["MAILBOX_AUTO#{count.to_s}"].split(':')[0]
      mailbox_password = ENV["MAILBOX_AUTO#{count.to_s}"].split(':')[1]
      account = {
        :realname => 'auto account',
        :email    => mailbox_user,
        :password => mailbox_password,
      }
      accounts.push account
    }
    if accounts.empty?
      #raise "Need min. MAILBOX_AUTO1 as ENV variable like export MAILBOX_AUTO1='nicole.braun2015@gmail.com:somepass'"
      puts "NOTICE: Need min. MAILBOX_AUTO1 as ENV variable like export MAILBOX_AUTO1='nicole.braun2015@gmail.com:somepass'"
      return
    end
    accounts.each {|account|
      tests = [
        {
          :name     => 'getting started - auto mail',
          :action   => [
            {
              :execute => 'navigate',
              :to      => browser_url + '/#getting_started/channel',
            },
            {
              :execute => 'click',
              :css     => '.js-channel .email .provider_name',
            },
            {
              :execute => 'set',
              :css     => '.js-intro input[name="realname"]',
              :value   => account[:realname],
            },
            {
              :execute => 'set',
              :css     => '.js-intro input[name="email"]',
              :value   => account[:email],
            },
            {
              :execute => 'set',
              :css     => '.js-intro input[name="password"]',
              :value   => account[:password],
            },
            {
              :execute => 'click',
              :css     => '.js-intro .btn--primary',
            },
            {
              :execute => 'watch_for',
              :area    => 'body',
              :value   => 'verify',
              :timeout => 20,
            },
            {
              :execute => 'watch_for',
              :area    => 'body',
              :value   => 'invite',
              :timeout => 100,
            },
            {
              :execute => 'check',
              :element => :url,
              :result  => '#getting_started/agents',
            },
          ],
        },
      ]
      browser_signle_test_with_login(tests, { :username => 'master@example.com' })
    }
  end

  def test_b_accounts_manual
    #return # TODO: temp disable
    accounts = []
    (1..10).each {|count|
      next if !ENV["MAILBOX_MANUAL#{count.to_s}"]
      mailbox_user     = ENV["MAILBOX_MANUAL#{count.to_s}"].split(':')[0]
      mailbox_password = ENV["MAILBOX_MANUAL#{count.to_s}"].split(':')[1]
      mailbox_inbound  = ENV["MAILBOX_MANUAL#{count.to_s}"].split(':')[2]
      mailbox_outbound = ENV["MAILBOX_MANUAL#{count.to_s}"].split(':')[3]
      account = {
        :realname => 'manual account',
        :email    => mailbox_user,
        :password => mailbox_password,
        :inbound  => {
          'options::host' => mailbox_inbound,
        },
        :outbound  => {
          'options::host' => mailbox_outbound,
        },
      }
      accounts.push account
    }
    if accounts.empty?
      #raise "Need min. MAILBOX_MANUAL1 as ENV variable like export MAILBOX_MANUAL1='nicole.bauer2015@yahoo.de:somepass:imap.mail.yahoo.com:smtp.mail.yahoo.com'"
      puts "NOTICE: Need min. MAILBOX_MANUAL1 as ENV variable like export MAILBOX_MANUAL1='nicole.bauer2015@yahoo.de:somepass:imap.mail.yahoo.com:smtp.mail.yahoo.com'"
      return
    end

    accounts.each {|account|
      tests = [
        {
          :name   => 'getting started - manual mail',
          :action => [
            {
              :execute => 'navigate',
              :to      => browser_url + '/#getting_started/channel',
            },
            {
              :execute => 'click',
              :css     => '.js-channel .email .provider_name',
            },
            {
              :execute => 'set',
              :css     => '.js-intro input[name="realname"]',
              :value   => account[:realname],
            },
            {
              :execute => 'set',
              :css     => '.js-intro input[name="email"]',
              :value   => account[:email],
            },
            {
              :execute => 'set',
              :css     => '.js-intro input[name="password"]',
              :value   => account[:password],
            },
            {
              :execute => 'click',
              :css     => '.js-intro .btn--primary',
            },
            {
              :execute => 'watch_for',
              :area    => '.js-inbound h2',
              :value   => 'inbound',
              :timeout => 220,
            },
            {
              :execute => 'watch_for',
              :area    => '.js-inbound',
              :value   => 'manual',
            },
            {
              :execute => 'set',
              :css     => '.js-inbound input[name="options::host"]',
              :value   => account[:inbound]['options::host'],
            },
            {
              :execute => 'click',
              :css     => '.js-inbound .btn--primary',
            },
            {
              :execute => 'watch_for',
              :area    => '.js-outbound h2',
              :value   => 'outbound',
            },
            {
              :execute => 'select',
              :css     => '.js-outbound select[name="adapter"]',
              :value   => 'SMTP - configure your own outgoing SMTP settings',
            },
            {
              :execute => 'set',
              :css     => '.js-outbound input[name="options::host"]',
              :value   => account[:outbound]['options::host'],
            },
            {
              :execute => 'click',
              :css     => '.js-outbound .btn--primary',
            },
            {
              :execute => 'watch_for',
              :area    => 'body',
              :value   => 'verify',
            },
            {
              :execute => 'watch_for',
              :area    => 'body',
              :value   => 'invite',
              :timeout => 190,
            },
            {
              :execute => 'check',
              :element => :url,
              :result  => '#getting_started/agents',
            },
          ],
        },
      ]
      browser_signle_test_with_login(tests, { :username => 'master@example.com' })
    }
  end

end