# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'
require 'net/imap'

class EmailPostmasterToSender < ActiveSupport::TestCase

  setup do
    Setting.set('postmaster_max_size', 0.1)

    @test_id = rand(999_999_999)

    # setup the IMAP account info for Zammad
    if ENV['MAIL_SERVER'].blank?
      raise "Need MAIL_SERVER as ENV variable like export MAIL_SERVER='mx.example.com'"
    end
    if ENV['MAIL_SERVER_ACCOUNT'].blank?
      raise "Need MAIL_SERVER_ACCOUNT as ENV variable like export MAIL_SERVER_ACCOUNT='user:somepass'"
    end

    @server_address = ENV['MAIL_SERVER']
    @server_login = ENV['MAIL_SERVER_ACCOUNT'].split(':')[0]
    @server_password = ENV['MAIL_SERVER_ACCOUNT'].split(':')[1]

    @folder = "postmaster_to_sender_#{@test_id}"

    if ENV['MAIL_SERVER_EMAIL'].blank?
      raise "Need MAIL_SERVER_EMAIL as ENV variable like export MAIL_SERVER_EMAIL='master@example.com'"
    end

    @sender_email_address = ENV['MAIL_SERVER_EMAIL']

    @email_address = EmailAddress.create!(
      realname:      'me Helpdesk',
      email:         "some-zammad-#{ENV['MAIL_SERVER_EMAIL']}",
      updated_by_id: 1,
      created_by_id: 1,
    )

    group = Group.create_or_update(
      name:             'PostmasterToSenderTest',
      email_address_id: @email_address.id,
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
            host:           @server_address,
            user:           @server_login,
            password:       @server_password,
            ssl:            true,
            folder:         @folder,
            keep_on_server: false,
          }
        },
        outbound: {
          adapter: 'smtp',
          options: {
            host:      @server_address,
            port:      25,
            start_tls: true,
            user:      @server_login,
            password:  @server_password,
            email:     @email_address.email
          },
        },
      },
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    @email_address.channel_id = @channel.id
    @email_address.save!
  end

  test 'postmaster reply with email on oversized incoming emails' do
    imap = Net::IMAP.new(@server_address, 993, true, nil, false)
    imap.login(@server_login, @server_password)
    imap.create(@folder)
    imap.select(@folder)

    # put a very large message in it
    large_message = "Subject: Oversized Email Message
From: Max Mustermann <#{@sender_email_address}>
To: shugo@example.com
Message-ID: <#{@test_id}@zammad.test.com>

Oversized Email Message Body #{'#' * 120_000}
".gsub(%r{\n}, "\r\n")

    large_message_md5 = Digest::MD5.hexdigest(large_message)
    large_message_size = format('%<MB>.2f', MB: large_message.size.to_f / 1024 / 1024)

    imap.append(@folder, large_message, [], Time.zone.now)

    @channel.fetch(true)

    # 1. verify that the oversized email has been saved locally to:
    # /tmp/oversized_mail/yyyy-mm-ddThh:mm:ss-:md5.eml
    path = Rails.root.join('tmp/oversized_mail')
    target_files = Dir.entries(path).select do |filename|
      filename =~ %r{^#{large_message_md5}\.eml$}
    end
    assert(target_files.present?, 'Large message .eml log file must be present.')

    # pick the latest file that matches the criteria
    target_file = target_files.max

    # verify that the file is byte for byte identical to the sent message
    file_path = Rails.root.join('tmp/oversized_mail', target_file)
    eml_data = File.read(file_path)
    assert_equal(large_message, eml_data)

    # 2. verify that a postmaster response email has been sent to the sender
    message_ids = nil
    5.times do |sleep_offset|
      imap.select('inbox')
      message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')

      break if message_ids.count.positive?

      # send mail hasn't arrived yet in the inbox
      sleep sleep_offset
    end

    assert(message_ids.count.positive?, 'Must have received a reply from the postmaster')
    imap_message_id = message_ids.last
    msg = imap.fetch(imap_message_id, 'RFC822')[0].attr['RFC822']
    assert(msg.present?, 'Must have received a reply from the postmaster')
    imap.store(imap_message_id, '+FLAGS', [:Deleted])
    imap.expunge()

    # parse the reply mail and verify the various headers
    parser = Channel::EmailParser.new
    mail = parser.parse(msg)
    assert_equal(mail[:from_email], @email_address.email)
    assert_equal(mail[:subject], '[undeliverable] Message too large')
    assert_equal("<#{@test_id}@zammad.test.com>",
                 mail['references'],
                 'Reply\'s Referecnes header must match the send message ID')
    assert_equal("<#{@test_id}@zammad.test.com>",
                 mail['in-reply-to'],
                 'Reply\'s In-Reply-To header must match the send message ID')

    # verify the reply mail body content
    body = mail[:body]
    assert(body.start_with?('Dear Max Mustermann'), 'Body must contain sender name')
    assert(body.include?('Oversized Email Message'), 'Body must contain original subject')
    assert(body.include?('0.1 MB'), 'Body must contain max allowed message size')
    assert(body.include?("#{large_message_size} MB"), 'Body must contain the original message size')
    assert(body.include?(Setting.get('fqdn')), 'Body must contain the Zammad instance name')

    # 3. check if original mail got removed
    imap.select(@folder)
    message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
    assert_equal(message_ids.count, 0, 'Original customer mail must be deleted.')

    # final clean up
    imap.delete(@folder)
    @channel.destroy!
  end

  test 'postmaster reply with no email on oversized incoming emails' do
    Setting.set('postmaster_send_reject_if_mail_too_large', false)
    imap = Net::IMAP.new(@server_address, 993, true, nil, false)
    imap.login(@server_login, @server_password)

    imap.select('inbox')
    message_count = imap.sort(['DATE'], ['ALL'], 'US-ASCII').count

    imap.create(@folder)
    imap.select(@folder)

    # put a very large message in it
    large_message = "Subject: Oversized Email Message
From: Max Mustermann <#{@sender_email_address}>
To: shugo@example.com
Message-ID: <#{@test_id}@zammad.test.com>

Oversized Email Message Body #{'#' * 120_000}
".gsub(%r{\n}, "\r\n")

    imap.append(@folder, large_message, [], Time.zone.now)

    @channel.fetch(true)

    # 1. verify that the oversized email has been saved locally to:
    # /tmp/oversized_mail/yyyy-mm-ddThh:mm:ss-:md5.eml
    path = Rails.root.join('tmp/oversized_mail')
    target_files = Dir.entries(path).select do |filename|
      filename =~ %r{^.+?\.eml$}
    end
    assert_not(target_files.blank?, 'Large message .eml log file must be blank.')

    # 2. verify that a postmaster response email has been sent to the sender
    imap.select('inbox')
    message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
    assert_equal(message_ids.count, message_count, 'Must not have received a reply from the postmaster')

    # 3. check if original mail got removed
    imap.select(@folder)
    message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
    imap_message_id = message_ids.last
    msg = imap.fetch(imap_message_id, 'RFC822')[0].attr['RFC822']
    imap.store(imap_message_id, '+FLAGS', [:Deleted])
    imap.expunge()
    assert(msg.present?, 'Oversized Email Message')
    assert_equal(message_ids.count, 1, 'Original customer mail must be deleted.')

    # final clean up
    imap.delete(@folder)
    @channel.destroy!
  end

  teardown do
    Setting.set('postmaster_max_size', 10)
  end
end
