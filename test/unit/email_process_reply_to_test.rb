# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class EmailProcessReplyToTest < ActiveSupport::TestCase

  test 'normal processing' do
    Setting.set('postmaster_sender_based_on_reply_to', '')

    email = "From: Bob Smith <marketing_tool@example.com>
To: zammad@example.com
Subject: some new subject
Reply-To: replay_to_customer_process1@example.com

Some Text"

    ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email)
    assert_equal('Customer', article_p.sender.name)
    assert_equal('email', article_p.type.name)
    assert_equal('Bob Smith <marketing_tool@example.com>', article_p.from)
    assert_equal('replay_to_customer_process1@example.com', article_p.reply_to)
    assert_equal('marketing_tool@example.com', ticket_p.customer.email)
    assert_equal('Bob', ticket_p.customer.firstname)
    assert_equal('Smith', ticket_p.customer.lastname)
    assert_nil(mail[:'raw-origin_from'])
    assert_nil(mail[:origin_from])
    assert_nil(mail[:origin_from_email])
    assert_nil(mail[:origin_from_local])
    assert_nil(mail[:origin_from_domain])
    assert_nil(mail[:origin_from_display_name])
  end

  test 'normal processing - take reply to as customer' do
    Setting.set('postmaster_sender_based_on_reply_to', 'as_sender_of_email')

    email = "From: Bob Smith <marketing_tool@example.com>
To: zammad@example.com
Subject: some new subject
Reply-To: replay_to_customer_process2@example.com

Some Text"

    ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email)
    assert_equal('replay_to_customer_process2@example.com', article_p.from)
    assert_equal('replay_to_customer_process2@example.com', article_p.reply_to)
    assert_equal('replay_to_customer_process2@example.com', ticket_p.customer.email)
    assert_equal('', ticket_p.customer.firstname)
    assert_equal('', ticket_p.customer.lastname)

    email = "From: Bob Smith <marketing_tool@example.com>
To: zammad@example.com
Subject: some new subject
Reply-To: Some Name <replay_to_customer_process2-1@example.com>

Some Text"

    ticket_p, article_p, _user_p = Channel::EmailParser.new.process({}, email)
    assert_equal('Customer', article_p.sender.name)
    assert_equal('email', article_p.type.name)
    assert_equal('Some Name <replay_to_customer_process2-1@example.com>', article_p.from)
    assert_equal('Some Name <replay_to_customer_process2-1@example.com>', article_p.reply_to)
    assert_equal('replay_to_customer_process2-1@example.com', ticket_p.customer.email)
    assert_equal('Some', ticket_p.customer.firstname)
    assert_equal('Name', ticket_p.customer.lastname)
    assert_equal('Bob Smith <marketing_tool@example.com>', mail[:'raw-origin_from'].to_s)
    assert_equal('Bob Smith <marketing_tool@example.com>', mail[:origin_from])
    assert_equal('marketing_tool@example.com', mail[:origin_from_email])
    assert_equal('marketing_tool', mail[:origin_from_local])
    assert_equal('example.com', mail[:origin_from_domain])
    assert_equal('Bob Smith', mail[:origin_from_display_name])
  end

  test 'normal processing - take reply to as customer and use from as realname' do
    Setting.set('postmaster_sender_based_on_reply_to', 'as_sender_of_email_use_from_realname')

    email = "From: Bob Smith <marketing_tool@example.com>
To: zammad@example.com
Subject: some new subject
Reply-To: replay_to_customer_process3@example.com

Some Text"

    ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email)
    assert_equal('replay_to_customer_process3@example.com', article_p.from)
    assert_equal('replay_to_customer_process3@example.com', article_p.reply_to)
    assert_equal('replay_to_customer_process3@example.com', ticket_p.customer.email)
    assert_equal('Bob', ticket_p.customer.firstname)
    assert_equal('Smith', ticket_p.customer.lastname)
    assert_equal('Bob Smith <marketing_tool@example.com>', mail[:'raw-origin_from'].to_s)
    assert_equal('Bob Smith <marketing_tool@example.com>', mail[:origin_from])
    assert_equal('marketing_tool@example.com', mail[:origin_from_email])
    assert_equal('marketing_tool', mail[:origin_from_local])
    assert_equal('example.com', mail[:origin_from_domain])
    assert_equal('Bob Smith', mail[:origin_from_display_name])

    email = "From: Bob Smith <marketing_tool@example.com>
To: zammad@example.com
Subject: some new subject
Reply-To: Some Name <replay_to_customer_process3-1@example.com>

Some Text"

    ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email)
    assert_equal('Customer', article_p.sender.name)
    assert_equal('email', article_p.type.name)
    assert_equal('Some Name <replay_to_customer_process3-1@example.com>', article_p.from)
    assert_equal('Some Name <replay_to_customer_process3-1@example.com>', article_p.reply_to)
    assert_equal('replay_to_customer_process3-1@example.com', ticket_p.customer.email)
    assert_equal('Bob', ticket_p.customer.firstname)
    assert_equal('Smith', ticket_p.customer.lastname)
    assert_equal('Bob Smith <marketing_tool@example.com>', mail[:'raw-origin_from'].to_s)
    assert_equal('Bob Smith <marketing_tool@example.com>', mail[:origin_from])
    assert_equal('marketing_tool@example.com', mail[:origin_from_email])
    assert_equal('marketing_tool', mail[:origin_from_local])
    assert_equal('example.com', mail[:origin_from_domain])
    assert_equal('Bob Smith', mail[:origin_from_display_name])
  end

  test 'normal processing - take reply to as customer and sender is system address' do

    Setting.set('postmaster_sender_based_on_reply_to', 'as_sender_of_email')

    EmailAddress.create!(
      realname:      'address #1',
      email:         'marketing_tool@example.com',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    email = "From: Marketing Tool <marketing_tool@example.com>
To: zammad@example.com
Subject: some new subject
Reply-To: replay_to_customer_process2@example.com

Some Text"

    ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email)
    assert_equal('Customer', article_p.sender.name)
    assert_equal('email', article_p.type.name)
    assert_equal('replay_to_customer_process2@example.com', article_p.from)
    assert_equal('replay_to_customer_process2@example.com', article_p.reply_to)
    assert_equal('replay_to_customer_process2@example.com', ticket_p.customer.email)
    assert_equal('', ticket_p.customer.firstname)
    assert_equal('', ticket_p.customer.lastname)
    assert_equal('Marketing Tool <marketing_tool@example.com>', mail[:'raw-origin_from'].to_s)
    assert_equal('Marketing Tool <marketing_tool@example.com>', mail[:origin_from])
    assert_equal('marketing_tool@example.com', mail[:origin_from_email])
    assert_equal('marketing_tool', mail[:origin_from_local])
    assert_equal('example.com', mail[:origin_from_domain])
    assert_equal('Marketing Tool', mail[:origin_from_display_name])
  end

end
