# encoding: utf-8
require 'test_helper'

class EmailProcessReplyToTest < ActiveSupport::TestCase

  test 'normal processing' do

    setting_orig = Setting.get('postmaster_sender_based_on_reply_to')
    Setting.set('postmaster_sender_based_on_reply_to', '')

    email = "From: Bob Smith <marketing_tool@example.com>
To: zammad@example.com
Subject: some new subject
Reply-To: replay_to_customer_process1@example.com

Some Text"

    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email)
    assert_equal('Bob Smith <marketing_tool@example.com>', article_p.from)
    assert_equal('replay_to_customer_process1@example.com', article_p.reply_to)
    assert_equal('marketing_tool@example.com', ticket_p.customer.email)
    assert_equal('Bob', ticket_p.customer.firstname)
    assert_equal('Smith', ticket_p.customer.lastname)

    Setting.set('postmaster_sender_based_on_reply_to', setting_orig)

  end

  test 'normal processing - take reply to as customer' do

    setting_orig = Setting.get('postmaster_sender_based_on_reply_to')
    Setting.set('postmaster_sender_based_on_reply_to', 'as_sender_of_email')

    email = "From: Bob Smith <marketing_tool@example.com>
To: zammad@example.com
Subject: some new subject
Reply-To: replay_to_customer_process2@example.com

Some Text"

    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email)
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

    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email)
    assert_equal('Some Name <replay_to_customer_process2-1@example.com>', article_p.from)
    assert_equal('Some Name <replay_to_customer_process2-1@example.com>', article_p.reply_to)
    assert_equal('replay_to_customer_process2-1@example.com', ticket_p.customer.email)
    assert_equal('Some', ticket_p.customer.firstname)
    assert_equal('Name', ticket_p.customer.lastname)

    Setting.set('postmaster_sender_based_on_reply_to', setting_orig)

  end

  test 'normal processing - take reply to as customer and use from as realname' do

    setting_orig = Setting.get('postmaster_sender_based_on_reply_to')
    Setting.set('postmaster_sender_based_on_reply_to', 'as_sender_of_email_use_from_realname')

    email = "From: Bob Smith <marketing_tool@example.com>
To: zammad@example.com
Subject: some new subject
Reply-To: replay_to_customer_process3@example.com

Some Text"

    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email)
    assert_equal('replay_to_customer_process3@example.com', article_p.from)
    assert_equal('replay_to_customer_process3@example.com', article_p.reply_to)
    assert_equal('replay_to_customer_process3@example.com', ticket_p.customer.email)
    assert_equal('Bob', ticket_p.customer.firstname)
    assert_equal('Smith', ticket_p.customer.lastname)

    email = "From: Bob Smith <marketing_tool@example.com>
To: zammad@example.com
Subject: some new subject
Reply-To: Some Name <replay_to_customer_process3-1@example.com>

Some Text"

    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email)
    assert_equal('Some Name <replay_to_customer_process3-1@example.com>', article_p.from)
    assert_equal('Some Name <replay_to_customer_process3-1@example.com>', article_p.reply_to)
    assert_equal('replay_to_customer_process3-1@example.com', ticket_p.customer.email)
    assert_equal('Bob', ticket_p.customer.firstname)
    assert_equal('Smith', ticket_p.customer.lastname)

    Setting.set('postmaster_sender_based_on_reply_to', setting_orig)

  end

end
