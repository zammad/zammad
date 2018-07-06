
require 'test_helper'

class EmailProcessFollowUpTest < ActiveSupport::TestCase

  test 'process with follow up check' do

    ticket = Ticket.create(
      title: 'follow up check',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
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
      sender: Ticket::Article::Sender.lookup(name: 'Agent'),
      type: Ticket::Article::Type.lookup(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    email_raw_string_subject = "From: me@example.com
To: customer@example.com
Subject: #{ticket.subject_build('some new subject')}

Some Text"

    email_raw_string_other_subject = "From: me@example.com
To: customer@example.com
Subject: other subject #{Setting.get('ticket_hook')}#{ticket.number}

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
    Setting.set('postmaster_follow_up_search_in', %w[body attachment references])

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_subject)
    assert_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_other_subject)
    assert_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_body)
    assert_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_attachment)
    assert_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_references1)
    assert_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_references2)
    assert_equal(ticket.id, ticket_p.id)

    Setting.set('postmaster_follow_up_search_in', nil)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_subject)
    assert_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_other_subject)
    assert_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_body)
    assert_not_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_attachment)
    assert_not_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_references1)
    assert_not_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_references2)
    assert_not_equal(ticket.id, ticket_p.id)

    Setting.set('postmaster_follow_up_search_in', 'references')

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_subject)
    assert_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_other_subject)
    assert_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_body)
    assert_not_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_attachment)
    assert_not_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_references1)
    assert_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_references2)
    assert_equal(ticket.id, ticket_p.id)

    Setting.set('postmaster_follow_up_search_in', setting_orig)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_subject)
    assert_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_other_subject)
    assert_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_body)
    assert_not_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_attachment)
    assert_not_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_references1)
    assert_not_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_references2)
    assert_not_equal(ticket.id, ticket_p.id)
    travel_back
  end

  test 'process with follow up check with different ticket hook' do

    Setting.set('ticket_hook', 'VD-Ticket#')

    ticket = Ticket.create(
      title: 'follow up check ticket hook',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'follow up check',
      message_id: '<20150830145601.30.608882.123123@edenhofer.zammad.com>',
      body: 'some message article',
      internal: false,
      sender: Ticket::Article::Sender.lookup(name: 'Agent'),
      type: Ticket::Article::Type.lookup(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    email_raw_string_subject = "From: me@example.com
To: customer@example.com
Subject: #{ticket.subject_build('some new subject')}

Some Text"

    email_raw_string_other_subject = "From: me@example.com
To: customer@example.com
Subject: Aw: RE: other subject [#{Setting.get('ticket_hook')}#{ticket.number}]

Some Text"

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_subject)
    assert_equal(ticket.id, ticket_p.id)

    travel 1.second
    ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, email_raw_string_other_subject)
    assert_equal(ticket.id, ticket_p.id)

    travel_back
  end

  test 'process with follow up check with two external reference headers' do

    Setting.set('postmaster_follow_up_search_in', %w[body attachment references])

    data1 = "From: me@example.com
To: z@example.com
Subject: test 123
Message-ID: <9d16181c-2db2-c6c1-ff7f-41f2da4e289a@linuxhotel.de>

test 123
"
    ticket_p1, article_p1, user_p1 = Channel::EmailParser.new.process({}, data1)

    travel 1.second

    data1 = "From: me@example.com
To: z@example.com
Subject: test 123
Message-ID: <9d16181c-2db2-c6c1-ff7f-41f2da4e289a@linuxhotel.de>

test 123
"
    ticket_p2, article_p2, user_p2 = Channel::EmailParser.new.process({}, data1)
    assert_not_equal(ticket_p1.id, ticket_p2.id)

    data2 = "From: you@example.com
To: y@example.com
Subject: RE: test 123
Message-ID: <oknn9teOke2uqbFQdGj2umXUwTkqgu0CqWHkA6V4K8p@akmail>
References: <9d16181c-2db2-c6c1-ff7f-41f2da4e289a@linuxhotel.de>

test 123
"
    ticket_p3, article_p3, user_p3 = Channel::EmailParser.new.process({}, data2)

    assert_equal(ticket_p2.id, ticket_p3.id)

    travel_back
  end

  test 'process with follow up check - with auto responses and no T# in subject_build' do

    ticket = Ticket.create(
      title: 'follow up - with references follow up check',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'closed'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'follow up with references follow up check',
      message_id: '<20151222145601.30.608881@edenhofer.zammad.com>',
      body: 'some message with references follow up check',
      internal: false,
      sender: Ticket::Article::Sender.lookup(name: 'Agent'),
      type: Ticket::Article::Type.lookup(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    travel 1.second

    # auto response without T# in subject, find follow up by references header
    email_raw_string = "From: bob@example.com
To: customer@example.com
Subject: =?ISO-8859-1?Q?AUTO=3A_Bob_Smith_ist_au=DFer_Haus=2E_=2F_is_out_of?=
 =?ISO-8859-1?Q?_office=2E_=28R=FCckkehr_am_28=2E12=2E2015=29?=
In-Reply-To: <20251222081758.116249.983698@portal.znuny.com>
References: <OF9D1FD72A.878EF84E-ONC1257F22.003D7BB4-C1257F22.003F4503@example.com> <20151222145601.30.608881@edenhofer.zammad.com> <20251222081758.116249.983698@portal.znuny.com>
Message-ID: <OFD563742F.FC05EEAF-ONC1257F23.002DAE02@example.com>
Auto-Submitted: auto-replied

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.id, ticket_p.id)
    assert_equal('open', ticket.state.name)
    travel_back
  end

  test 'process with follow up check - email with more forgein T#\'s in subject' do

    ticket = Ticket.create(
      title: 'email with more forgein T#\'s in subject',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'closed'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'follow up with references follow up check',
      message_id: '<20151222145601.30.608881@edenhofer.zammad.com>',
      body: 'some message with references follow up check',
      internal: false,
      sender: Ticket::Article::Sender.lookup(name: 'Agent'),
      type: Ticket::Article::Type.lookup(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    travel 1.second

    system_id           = Setting.get('system_id')
    ticket_hook         = Setting.get('ticket_hook')
    ticket_hook_divider = Setting.get('ticket_hook_divider')

    tn = "[#{ticket_hook}#{ticket_hook_divider}#{system_id}#{Ticket::Number.generate}99]"

    email_raw_string_subject = "From: me@example.com
To: customer@example.com
Subject: First foreign Tn #{tn} #{tn} #{tn} - #{ticket.subject_build('some new subject')}

Some Text"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string_subject)
    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.id, ticket_p.id)
    assert_equal('open', ticket.state.name)
    travel_back
  end

  test 'process with follow up check - ticket initiated by customer without T# in subject and other people in Cc reply to all' do

    # check if follow up based on inital system sender address
    Setting.set('postmaster_follow_up_search_in', [])

    subject = "ticket initiated by customer without T# in subject and other people in Cc reply to all #{rand(9999)}"

    email_raw_string = "From: me@example.com
To: my@system.test, bob@example.com
Subject: #{subject}
Message-ID: <123456789-$follow-up-test§-1@linuxhotel.de>

Some Text"

    ticket_p1, article_1, user_1, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket1 = Ticket.find(ticket_p1.id)
    assert_equal(subject, ticket1.title)

    # follow up possible because same subject
    email_raw_string = "From: bob@example.com
To: my@system.test, me@example.com
Subject: AW: #{subject}
Message-ID: <123456789-$follow-up-test§-2@linuxhotel.de>
References: <123456789-$follow-up-test§-1@linuxhotel.de>

Some Text"

    ticket_p2, article_p2, user_p2, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket2 = Ticket.find(ticket_p2.id)
    assert_equal(ticket1.id, ticket2.id)
    assert_equal(subject, ticket2.title)

    # follow up possible because same subject
    email_raw_string = "From: bob@example.com
To: my@system.test, me@example.com
Subject: AW: RE: #{subject}
Message-ID: <123456789-$follow-up-test§-2@linuxhotel.de>
References: <123456789-$follow-up-test§-1@linuxhotel.de>

Some Text"

    ticket_p3, article_p3, user_p3, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket3 = Ticket.find(ticket_p3.id)
    assert_equal(ticket1.id, ticket3.id)
    assert_equal(subject, ticket3.title)

    # follow up not possible because subject has changed
    subject = "new subject without ticket ref #{rand(9_999_999)}"
    email_raw_string = "From: bob@example.com
To: my@system.test
Subject: #{subject}
Message-ID: <123456789-$follow-up-test§-3@linuxhotel.de>
References: <123456789-$follow-up-test§-1@linuxhotel.de>

Some Text"

    ticket_p4, article_p4, user_p4, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket4 = Ticket.find(ticket_p4.id)
    assert_not_equal(ticket1.id, ticket4.id)
    assert_equal(subject, ticket4.title)

    # usecase with same subject but no Ticket# (reference headers check because of same subject)
    subject = 'Embedded Linux 20.03 - 23.03.17'

    email_raw_string = "From: iw@example.com
To: customer@example.com
Subject: #{subject}
Message-ID: <b1a84d36-4475-28e8-acde-5c18ebe94182@example.com>

Some Text"

    ticket_p5, article_5, user_5, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket5 = Ticket.find(ticket_p5.id)
    assert_not_equal(ticket1.id, ticket5.id)
    assert_equal(subject, ticket5.title)

    email_raw_string = "From: customer@example.com
To: iw@example.com
Subject: Re:  #{subject}
Message-ID: <b1a84d36-4475-28e8-acde-5c18ebe94183@customer.example.com>
In-Reply-To: <b1a84d36-4475-28e8-acde-5c18ebe94182@example.com>

Some other Text"

    ticket_p6, article_6, user_6, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket6 = Ticket.find(ticket_p6.id)
    assert_equal(ticket5.id, ticket6.id)
    assert_equal(subject, ticket6.title)

  end

  test 'process with follow up check - with none ticket# in subject' do

    Setting.set('postmaster_follow_up_search_in', [])
    Setting.set('ticket_hook_position', 'none')

    subject = 'some title'
    email_raw_string = "From: me@example.com
To: bob@example.com
Subject: #{subject}
Message-ID: <123456789-follow-up-test-ticket_hook_position-none@linuxhotel.de>

Some Text"

    ticket_p1, article_1, user_1, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket1 = Ticket.find(ticket_p1.id)
    assert_equal(subject, ticket1.title)

    # follow up possible because same subject
    subject = 'new subject lalala'
    email_raw_string = "From: bob@example.com
To: me@example.com
Subject: AW: #{subject}
Message-ID: <123456789-follow-up-test-ticket_hook_position-none-2@linuxhotel.de>
References: <123456789-follow-up-test-ticket_hook_position-none@linuxhotel.de>

Some Text"

    ticket_p2, article_p2, user_p2, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket2 = Ticket.find(ticket_p2.id)
    assert_equal(ticket1.id, ticket2.id)
  end

  test 'process with follow up check - in body' do

    Setting.set('postmaster_follow_up_search_in', %w[body attachment references])
    Setting.set('ticket_hook', '#')

    email_raw_string = "From: me@example.com
To: bob@example.com
Subject: some subject

Some Text"

    ticket_p1, article_1, user_1, mail = Channel::EmailParser.new.process({}, email_raw_string)

    email_raw_string = "From: me@example.com
To: bob@example.com
Subject: some subject

Some Text #{Setting.get('ticket_hook')}#{ticket_p1.number} asdasd"

    ticket_p2, article_2, user_2, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(ticket_p1.id, ticket_p2.id)

    email_raw_string = "From: me@example.com
To: bob@example.com
Subject: some subject
Content-Transfer-Encoding: 7bit
Content-Type: text/html;

<b>Some Text #{Setting.get('ticket_hook')}#{ticket_p1.number}</b>
"

    ticket_p3, article_3, user_3, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(ticket_p1.id, ticket_p3.id)

    email_raw_string = "From: me@example.com
To: bob@example.com
Subject: some subject
Content-Transfer-Encoding: 8bit
Content-Type: text/html;

<b>Some Text <span color=\"#{Setting.get('ticket_hook')}#{ticket_p1.number}\">test</span></b>
"

    ticket_p4, article_4, user_4, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_not_equal(ticket_p1.id, ticket_p4.id)

  end
end
