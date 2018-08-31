
require 'test_helper'

class EmailProcessBounceDeliveryTemporaryFailed < ActiveSupport::TestCase

  test 'process with temp faild bounce email' do

    ticket = Ticket.create!(
      title: 'temp failed check - ms',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'closed'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    article = Ticket::Article.create!(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'temp failed check',
      message_id: '<20150830145601.30.608881@edenhofer.zammad.com>',
      body: 'some message bounce check',
      internal: false,
      sender: Ticket::Article::Sender.lookup(name: 'Agent'),
      type: Ticket::Article::Type.lookup(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    travel 1.second

    # temp faild bounce email
    email_raw_string = "Content-Type: multipart/report; boundary=\"000000000000ca4a1a057417a375\"; report-type=delivery-status
From: Mail Delivery Subsystem <mailer-daemon@example.com>
To: service@example.de
Auto-Submitted: auto-replied
Subject: Delivery Status Notification (Delay)
References: #{article.message_id}
In-Reply-To: #{article.message_id}
Message-ID: <5b7e8af4.1c69fb81.3ac1b.e296.GMRIR@mx.example.com>
Date: Thu, 23 Aug 2018 03:22:44 -0700 (PDT)

--000000000000ca4a1a057417a375
Content-Type: multipart/related; boundary=\"000000000000ca53d4057417a37c\"

--000000000000ca53d4057417a37c
Content-Type: multipart/alternative; boundary=\"000000000000ca53de057417a37d\"

--000000000000ca53de057417a37d
Content-Type: text/plain; charset=\"UTF-8\"
Content-Transfer-Encoding: quoted-printable


** Zustellung nicht abgeschlossen **

Bei der Zustellung Ihrer Nachricht an bob.smith@example.d=
e ist ein vor=C3=BCbergehendes Problem aufgetreten. Gmail versucht noch wei=
tere 46=C2=A0Stunden, die Nachricht zuzustellen. Sie werden benachrichtigt,=
 falls die Zustellung dauerhaft fehlschl=C3=A4gt.

Hier erfahren Sie mehr: https://support.example.com/mail/answer/7720

Antwort:

The recipient server did not accept our requests to connect. Learn more at =
https://support.example.com/mail/answer/7720=20
[example.de 00:00:00:c00::13: timed out]
[example.de 127.0.0.17: timed out]

--000000000000ca4a1a057417a375
Content-Type: message/delivery-status

Reporting-MTA: dns; example.com
Received-From-MTA: dns; service@example.de
Arrival-Date: Wed, 22 Aug 2018 02:00:03 -0700 (PDT)
X-Original-Message-ID: #{article.message_id}

Final-Recipient: rfc822; bob.smith@example.de
Action: delayed
Status: 4.4.1
Diagnostic-Code: smtp; The recipient server did not accept our requests to connect. Learn more at https://support.example.com/mail/answer/7720
 [example.de 00:00:00:c00::13: timed out]
 [example.de 127.0.0.17: timed out]
 Last-Attempt-Date: Thu, 23 Aug 2018 03:22:44 -0700 (PDT)
Will-Retry-Until: Sat, 25 Aug 2018 02:00:04 -0700 (PDT)

--000000000000ca4a1a057417a375
Content-Type: message/rfc822

Date: Wed, 22 Aug 2018 11:00:03 +0200
From: example Helpdesk <service@example.de>
To: bob.smith@example.de
Message-ID: #{article.message_id}
Subject: Ihre Anfrage () [Ticket#638810]
Content-Type: text/plain; charset=UTF-8

ABC

--000000000000ca4a1a057417a375--
"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(true, mail['x-zammad-out-of-office'.to_sym])
    ticket = Ticket.find(ticket.id)
    assert_equal(ticket.id, ticket_p.id)
    assert_equal('closed', ticket.state.name)

  end

end
