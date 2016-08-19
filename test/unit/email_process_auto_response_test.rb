# encoding: utf-8
require 'test_helper'

class EmailProcessAutoResponseTest < ActiveSupport::TestCase

  test 'process with out of office check' do

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(true, mail['x-zammad-send-auto-response'.to_sym])

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
X-Loop: yes

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail['x-zammad-send-auto-response'.to_sym])

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Precedence: Bulk

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail['x-zammad-send-auto-response'.to_sym])

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Auto-Submitted: auto-generated

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail['x-zammad-send-auto-response'.to_sym])

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
X-Auto-Response-Suppress: All


Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail['x-zammad-send-auto-response'.to_sym])

  end

end
