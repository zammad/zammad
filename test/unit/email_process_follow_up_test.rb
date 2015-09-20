# encoding: utf-8
require 'test_helper'

class EmailProcessFollowUpTest < ActiveSupport::TestCase

  test 'process with follow up check' do

    ticket = Ticket.create(
      title: 'follow up check',
      group: Group.lookup( name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup( name: 'new' ),
      priority: Ticket::Priority.lookup( name: '2 normal' ),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'follow up check',
      message_id: '<20150830145601.30.608882@edenhofer.zammad.com>',
      body: 'some message article',
      internal: false,
      sender: Ticket::Article::Sender.where(name: 'Agent').first,
      type: Ticket::Article::Type.where(name: 'email').first,
      updated_by_id: 1,
      created_by_id: 1,
    )

    email_raw_string_subject = "From: me@example.com
To: customer@example.com
Subject: #{ticket.subject_build('some new subject')}

Some Text"

    email_raw_string_body = "From: me@example.com
To: customer@example.com
Subject: no reference

Some Text #{ticket.subject_build('some new subject')} "

    email_raw_string_attachment = "From: me@example.com
Content-Type: multipart/mixed; boundary=\"Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2\"
Subject: no reference
Date: Sun, 30 Aug 2015 23:20:54 +0200
To: Martin Edenhofer <me@znuny.com>
Mime-Version: 1.0 (Mac OS X Mail 8.2 \(2104\))
X-Mailer: Apple Mail (2.2104)


--Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2
Content-Transfer-Encoding: 7bit
Content-Type: text/plain;
  charset=us-ascii

no reference
--Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2
Content-Disposition: attachment;
  filename=test1.txt
Content-Type: text/plain;
  name=\"test.txt\"
Content-Transfer-Encoding: 7bit

Some Text #{ticket.subject_build('some new subject')}

--Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2--"

    email_raw_string_references1 = "From: me@example.com
To: customer@example.com
Subject: no reference
In-Reply-To: <20150830145601.30.608882@edenhofer.zammad.com>
References: <DA918CD1-BE9A-4262-ACF6-5001E59291B6@znuny.com>

no reference "

    email_raw_string_references2 = "From: me@example.com
To: customer@example.com
Subject: no reference
References: <DA918CD1-BE9A-4262-ACF6-5001E59291B6@znuny.com> <20150830145601.30.608882@edenhofer.zammad.com> <DA918CD1-BE9A-4262-ACF6-5001E59291XX@znuny.com>

no reference "

    setting_orig = Setting.get('postmaster_follow_up_search_in')
    Setting.set('postmaster_follow_up_search_in', %w(body attachment references))

    sleep 1
    ticket_p, article_p, user_p = Channel::EmailParser.new.process( {}, email_raw_string_subject)
    assert_equal(ticket.id, ticket_p.id)

    sleep 1
    ticket_p, article_p, user_p = Channel::EmailParser.new.process( {}, email_raw_string_body)
    assert_equal(ticket.id, ticket_p.id)

    sleep 1
    ticket_p, article_p, user_p = Channel::EmailParser.new.process( {}, email_raw_string_attachment)
    assert_equal(ticket.id, ticket_p.id)

    sleep 1
    ticket_p, article_p, user_p = Channel::EmailParser.new.process( {}, email_raw_string_references1)
    assert_equal(ticket.id, ticket_p.id)

    sleep 1
    ticket_p, article_p, user_p = Channel::EmailParser.new.process( {}, email_raw_string_references2)
    assert_equal(ticket.id, ticket_p.id)

    Setting.set('postmaster_follow_up_search_in', setting_orig)

    sleep 1
    ticket_p, article_p, user_p = Channel::EmailParser.new.process( {}, email_raw_string_subject)
    assert_equal(ticket.id, ticket_p.id)

    sleep 1
    ticket_p, article_p, user_p = Channel::EmailParser.new.process( {}, email_raw_string_body)
    assert_not_equal(ticket.id, ticket_p.id)

    sleep 1
    ticket_p, article_p, user_p = Channel::EmailParser.new.process( {}, email_raw_string_attachment)
    assert_not_equal(ticket.id, ticket_p.id)

    sleep 1
    ticket_p, article_p, user_p = Channel::EmailParser.new.process( {}, email_raw_string_references1)
    assert_not_equal(ticket.id, ticket_p.id)

    sleep 1
    ticket_p, article_p, user_p = Channel::EmailParser.new.process( {}, email_raw_string_references2)
    assert_not_equal(ticket.id, ticket_p.id)
  end

end
