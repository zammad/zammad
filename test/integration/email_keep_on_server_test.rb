# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'
require 'net/imap'

class EmailKeepOnServerTest < ActiveSupport::TestCase
  setup do

    if ENV['KEEP_ON_MAIL_SERVER'].blank?
      raise "Need KEEP_ON_MAIL_SERVER as ENV variable like export KEEP_ON_MAIL_SERVER='mx.example.com'"
    end
    if ENV['KEEP_ON_MAIL_SERVER_ACCOUNT'].blank?
      raise "Need KEEP_ON_MAIL_SERVER_ACCOUNT as ENV variable like export KEEP_ON_MAIL_SERVER_ACCOUNT='user:somepass'"
    end

    @server_login = ENV['KEEP_ON_MAIL_SERVER_ACCOUNT'].split(':')[0]
    @server_password = ENV['KEEP_ON_MAIL_SERVER_ACCOUNT'].split(':')[1]

    @folder = "keep_on_mail_server_#{rand(999_999_999)}"

    email_address = EmailAddress.create!(
      realname:      'me Helpdesk',
      email:         "me#{rand(999_999_999)}@example.com",
      updated_by_id: 1,
      created_by_id: 1,
    )

    group = Group.create_or_update(
      name:             'KeepOnServerTest',
      email_address_id: email_address.id,
      updated_by_id:    1,
      created_by_id:    1,
    )

    @channel = Channel.create!(
      area:          'Email::Account',
      group_id:      group.id,
      options:       {
        inbound:  {
          adapter: 'imap',
          options: {
            host:     ENV['KEEP_ON_MAIL_SERVER'],
            user:     @server_login,
            password: @server_password,
            ssl:      true,
            folder:   @folder,
            #keep_on_server: true,
          }
        },
        outbound: {
          adapter: 'sendmail'
        }
      },
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    email_address.channel_id = @channel.id
    email_address.save!

  end

  test 'keep on server' do
    @channel.options[:inbound][:options][:keep_on_server] = true
    @channel.save!

    # clean mailbox
    imap = Net::IMAP.new(ENV['KEEP_ON_MAIL_SERVER'], 993, true, nil, false)
    imap.login(@server_login, @server_password)
    imap.create(@folder)
    imap.select(@folder)

    # put unseen message in it
    imap.append(@folder, "Subject: hello1
From: shugo@example.com
To: shugo@example.com
Message-ID: <some1@example_keep_on_server>

hello world
".gsub(%r{\n}, "\r\n"), [], Time.zone.now)

    # verify if message is still on server
    message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
    assert_equal(1, message_ids.count)

    message_meta = imap.fetch(1, ['FLAGS'])[0].attr
    assert_not(message_meta['FLAGS'].include?(:Seen))

    # fetch messages
    article_count = Ticket::Article.count
    @channel.fetch(true)
    assert_equal(article_count + 1, Ticket::Article.count)

    # verify if message is still on server
    message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
    assert_equal(1, message_ids.count)

    message_meta = imap.fetch(1, ['RFC822.HEADER', 'FLAGS'])[0].attr
    assert(message_meta['FLAGS'].include?(:Seen))

    # fetch messages
    article_count = Ticket::Article.count
    @channel.fetch(true)
    assert_equal(article_count, Ticket::Article.count)

    # verify if message is still on server
    message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
    assert_equal(1, message_ids.count)

    # put unseen message in it
    imap.append(@folder, "Subject: hello2
From: shugo@example.com
To: shugo@example.com
Message-ID: <some2@example_keep_on_server>

hello world
".gsub(%r{\n}, "\r\n"), [], Time.zone.now)

    message_meta = imap.fetch(1, ['FLAGS'])[0].attr
    assert(message_meta['FLAGS'].include?(:Seen))
    message_meta = imap.fetch(2, ['FLAGS'])[0].attr
    assert_not(message_meta['FLAGS'].include?(:Seen))

    # fetch messages
    article_count = Ticket::Article.count
    @channel.fetch(true)
    assert_equal(article_count + 1, Ticket::Article.count)

    # verify if message is still on server
    message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
    assert_equal(2, message_ids.count)

    message_meta = imap.fetch(1, ['FLAGS'])[0].attr
    assert(message_meta['FLAGS'].include?(:Seen))
    message_meta = imap.fetch(2, ['FLAGS'])[0].attr
    assert(message_meta['FLAGS'].include?(:Seen))

    # set messages to not seen
    imap.store(1, '-FLAGS', [:Seen])
    imap.store(2, '-FLAGS', [:Seen])

    # fetch messages
    article_count = Ticket::Article.count
    @channel.fetch(true)
    assert_equal(article_count, Ticket::Article.count)

    imap.delete(@folder)
    @channel.destroy!
  end

  test 'keep not on server' do
    @channel.options[:inbound][:options][:keep_on_server] = false
    @channel.save!

    # clean mailbox
    imap = Net::IMAP.new(ENV['KEEP_ON_MAIL_SERVER'], 993, true, nil, false)
    imap.login(@server_login, @server_password)
    imap.create(@folder)
    imap.select(@folder)

    # put unseen message in it
    imap.append(@folder, "Subject: hello1
From: shugo@example.com
To: shugo@example.com
Message-ID: <some1@example_remove_from_server>

hello world
".gsub(%r{\n}, "\r\n"), [], Time.zone.now)

    # verify if message is still on server
    message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
    assert_equal(1, message_ids.count)

    message_meta = imap.fetch(1, ['FLAGS'])[0].attr
    assert_not(message_meta['FLAGS'].include?(:Seen))

    # fetch messages
    article_count = Ticket::Article.count
    @channel.fetch(true)
    assert_equal(article_count + 1, Ticket::Article.count)

    # verify if message is still on server
    message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
    assert_equal(1, message_ids.count)

    # put unseen message in it
    imap.append(@folder, "Subject: hello2
From: shugo@example.com
To: shugo@example.com
Message-ID: <some2@example_remove_from_server>

hello world
".gsub(%r{\n}, "\r\n"), [], Time.zone.now)

    # verify if message is still on server
    message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
    assert_equal(1, message_ids.count)

    message_meta = imap.fetch(1, ['FLAGS'])[0].attr
    assert_not(message_meta['FLAGS'].include?(:Seen))

    # fetch messages
    article_count = Ticket::Article.count
    @channel.fetch(true)
    assert_equal(article_count + 1, Ticket::Article.count)

    # verify if message is still on server
    message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
    assert_equal(1, message_ids.count)

    # put unseen message in it
    imap.append(@folder, "Subject: hello2
From: shugo@example.com
To: shugo@example.com
Message-ID: <some2@example_remove_from_server>

hello world
".gsub(%r{\n}, "\r\n"), [], Time.zone.now)

    # verify if message is still on server
    message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
    assert_equal(1, message_ids.count)

    # fetch messages
    article_count = Ticket::Article.count
    @channel.fetch(true)
    assert_equal(article_count + 1, Ticket::Article.count)

    imap.delete(@folder)
    @channel.destroy!

  end

end
