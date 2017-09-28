# encoding: utf-8
require 'test_helper'

class IntegrationIcingaTest < ActiveSupport::TestCase

  # according
  # https://github.com/Icinga/icinga2/blob/master/etc/icinga2/scripts/mail-service-notification.sh
  # http://docs.icinga.org/icinga2/latest/doc/module/icinga2/chapter/monitoring-basics#host-states
  # http://docs.icinga.org/icinga2/latest/doc/module/icinga2/chapter/monitoring-basics#service-states

  setup do
    Setting.set('icinga_integration', true)
    Setting.set('icinga_sender', 'icinga2@monitoring.example.com')
  end

  test 'base tests' do

    # RBL check
    email_raw_string = "To: support@example.com
Subject: [PROBLEM] RBL check on apn4711.dc.example.com is CRITICAL!
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-1-1@monitoring.znuny.com>
From: icinga2@monitoring.example.com (icinga)

***** Icinga 2 Service Monitoring on apn4711.dc.example.com *****

=3D=3D> RBL check on apn4711.dc.example.com is CRITICAL! <=3D=3D

Info:    CHECK_RBL CRITICAL - apn4711.dc.example.com BLACKLISTED on 1 server of=
 38 (ix.dnsbl.example.com)=20

When:    2017-08-06 22:18:43 +0200
Service: RBL check (Display Name: \"RBL check\")
Host:    apn4711.dc.example.com (Display Name: \"apn4711.dc.example.com\")
IPv4:    127.0.0.1="

    ticket_0, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_0.state.name)
    assert(ticket_0.preferences)
    assert(ticket_0.preferences['icinga'])
    assert_equal('apn4711.dc.example.com (Display Name: "apn4711.dc.example.com")', ticket_0.preferences['icinga']['host'])
    assert_equal('CHECK_RBL CRITICAL - apn4711.dc.example.com BLACKLISTED on 1 server of 38 (ix.dnsbl.example.com)', ticket_0.preferences['icinga']['info'])
    assert_equal('RBL check (Display Name: "RBL check")', ticket_0.preferences['icinga']['service'])
    assert_equal('CRITICAL', ticket_0.preferences['icinga']['state'])

    # RBL check II
    email_raw_string = "To: support@example.com
Subject: [PROBLEM] RBL check on apn4711.dc.example.com is CRITICAL!
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-1-2@monitoring.znuny.com>
From: icinga2@monitoring.example.com (icinga)

***** Icinga 2 Service Monitoring on apn4711.dc.example.com *****

=3D=3D> RBL check on apn4711.dc.example.com is CRITICAL! <=3D=3D

Info:    CHECK_RBL CRITICAL - apn4711.dc.example.com BLACKLISTED on 1 server of=
 38 (ix.dnsbl.example.com)=20

When:    2017-08-06 22:18:43 +0200
Service: RBL check (Display Name: \"RBL check\")
Host:    apn4711.dc.example.com (Display Name: \"apn4711.dc.example.com\")
IPv4:    127.0.0.1="

    ticket_0_1, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_0_1.state.name)
    assert(ticket_0_1.preferences)
    assert(ticket_0_1.preferences['icinga'])
    assert_equal('apn4711.dc.example.com (Display Name: "apn4711.dc.example.com")', ticket_0_1.preferences['icinga']['host'])
    assert_equal('CHECK_RBL CRITICAL - apn4711.dc.example.com BLACKLISTED on 1 server of 38 (ix.dnsbl.example.com)', ticket_0_1.preferences['icinga']['info'])
    assert_equal('RBL check (Display Name: "RBL check")', ticket_0_1.preferences['icinga']['service'])
    assert_equal('CRITICAL', ticket_0_1.preferences['icinga']['state'])
    assert_equal(ticket_0_1.id, ticket_0.id)

    email_raw_string = "To: support@example.com
Subject: [PROBLEM] RBL check on apn4711.dc.example.com is OK!
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-1-2@monitoring.znuny.com>
From: icinga2@monitoring.example.com (icinga)

***** Icinga 2 Service Monitoring on apn4711.dc.example.com *****

=3D=3D> RBL check on apn4711.dc.example.com is OK! <=3D=3D

Info:    CHECK_RBL OK - apn4711.dc.example.com BLACKLISTED on 1 server of=
 38 (ix.dnsbl.example.com)=20

When:    2017-08-06 22:18:43 +0200
Service: RBL check (Display Name: \"RBL check\")
Host:    apn4711.dc.example.com (Display Name: \"apn4711.dc.example.com\")
IPv4:    127.0.0.1="

    ticket_0_2, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('closed', ticket_0_2.state.name)
    assert(ticket_0_2.preferences)
    assert(ticket_0_2.preferences['icinga'])
    assert_equal('apn4711.dc.example.com (Display Name: "apn4711.dc.example.com")', ticket_0_2.preferences['icinga']['host'])
    assert_equal('CHECK_RBL CRITICAL - apn4711.dc.example.com BLACKLISTED on 1 server of 38 (ix.dnsbl.example.com)', ticket_0_2.preferences['icinga']['info'])
    assert_equal('RBL check (Display Name: "RBL check")', ticket_0_2.preferences['icinga']['service'])
    assert_equal('CRITICAL', ticket_0_2.preferences['icinga']['state'])
    assert_equal(ticket_0_2.id, ticket_0.id)

    # matching sender - CPU Load/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: PROBLEM - host.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-2@monitoring.znuny.com>
From: icinga2@monitoring.example.com (icinga)

***** Icinga  *****

Notification Type: PROBLEM

Service: CPU Load
Host: host.internal.loc
Address:=20
State: WARNING

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info: WARNING - load average: 3.44, 0.99, 0.35

Comment: [] =
"

    ticket_1, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_1.state.name)
    assert(ticket_1.preferences)
    assert(ticket_1.preferences['icinga'])
    assert_equal('host.internal.loc', ticket_1.preferences['icinga']['host'])
    assert_equal('CPU Load', ticket_1.preferences['icinga']['service'])
    assert_equal('WARNING', ticket_1.preferences['icinga']['state'])

    # matching sender - Disk Usage 123/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: PROBLEM - host.internal.loc - Disk Usage 123 is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-3@monitoring.znuny.com>
From: icinga2@monitoring.example.com (icinga)

***** Icinga  *****

Notification Type: PROBLEM

Service: Disk Usage 123
Host: host.internal.loc
Address:=20
State: WARNING

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info: WARNING - load average: 3.44, 0.99, 0.35

Comment: [] =
"

    ticket_2, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_2.state.name)
    assert(ticket_2.preferences)
    assert(ticket_2.preferences['icinga'])
    assert_equal('host.internal.loc', ticket_2.preferences['icinga']['host'])
    assert_equal('Disk Usage 123', ticket_2.preferences['icinga']['service'])
    assert_equal('WARNING', ticket_2.preferences['icinga']['state'])
    assert_not_equal(ticket_2.id, ticket_1.id)

    # matching sender - follow up - CPU Load/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: PROBLEM - host.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-4@monitoring.znuny.com>
From: icinga2@monitoring.example.com (icinga)

***** Icinga  *****

Notification Type: PROBLEM

Service: CPU Load
Host: host.internal.loc
Address:=20
State: WARNING

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info: WARNING - load average: 3.44, 0.99, 0.35

Comment: [] =
"

    ticket_1_1, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_1_1.state.name)
    assert(ticket_1_1.preferences)
    assert(ticket_1_1.preferences['icinga'])
    assert_equal('host.internal.loc', ticket_1_1.preferences['icinga']['host'])
    assert_equal('CPU Load', ticket_1_1.preferences['icinga']['service'])
    assert_equal('WARNING', ticket_1_1.preferences['icinga']['state'])
    assert_equal(ticket_1.id, ticket_1_1.id)

    # matching sender - follow up - recovery - CPU Load/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: PROBLEM - host.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-5@monitoring.znuny.com>
From: icinga2@monitoring.example.com (icinga)

***** Icinga  *****

Notification Type: RECOVERY

Service: CPU Load
Host: host.internal.loc
Address:=20
State: OK

Date/Time: 2016-01-31 10:48:02 +0100

Additional Info: OK - load average: 1.62, 1.17, 0.49

Comment: [] =
"

    ticket_1_2, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(ticket_1.id, ticket_1_2.id)
    assert_equal('closed', ticket_1_2.state.name)
    assert(ticket_1_2.preferences)
    assert(ticket_1_2.preferences['icinga'])
    assert_equal('host.internal.loc', ticket_1_2.preferences['icinga']['host'])
    assert_equal('CPU Load', ticket_1_2.preferences['icinga']['service'])
    assert_equal('WARNING', ticket_1_2.preferences['icinga']['state'])

    # host down
    email_raw_string = "To: support@example.com
Subject: PROBLEM - apn4711.dc.example.com is DOWN
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-5@monitoring.znuny.com>
From: icinga2@monitoring.example.com (icinga)

***** Icinga *****

Notification Type: PROBLEM

Host: apn4711.dc.example.com
Address: 127.0.0.1
State: DOWN

Date/Time: 2017-01-14 11:33:02 +0100

Additional Info: CRITICAL - Host Unreachable (127.0.0.1)

Comment: [] =
"
    ticket_3, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_3.state.name)
    assert(ticket_3.preferences)
    assert(ticket_3.preferences['icinga'])
    assert_equal('apn4711.dc.example.com', ticket_3.preferences['icinga']['host'])
    assert_nil(ticket_3.preferences['icinga']['service'])
    assert_equal('DOWN', ticket_3.preferences['icinga']['state'])
    assert_not_equal(ticket_3.id, ticket_1.id)

    # host up
    email_raw_string = "To: support@example.com
Subject: RECOVERY - apn4711.dc.example.com is UP
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-5@monitoring.znuny.com>
From: icinga2@monitoring.example.com (icinga)

***** Icinga *****

Notification Type: RECOVERY

Host: apn4711.dc.example.com
Address: 127.0.0.1
State: UP

Date/Time: 2017-01-14 12:07:11 +0100

Additional Info: PING OK - Packet loss = 0%, RTA = 21.37 ms

Comment: [] =
"
    ticket_3_1, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(ticket_3.id, ticket_3_1.id)
    assert_equal('closed', ticket_3_1.state.name)
    assert(ticket_3_1.preferences)
    assert(ticket_3_1.preferences['icinga'])
    assert_equal('apn4711.dc.example.com', ticket_3.preferences['icinga']['host'])
    assert_nil(ticket_3_1.preferences['icinga']['service'])
    assert_equal('DOWN', ticket_3_1.preferences['icinga']['state'])

    # ping down
    email_raw_string = "To: support@example.com
Subject: [PROBLEM] Ping IPv4 on apn4711.dc.example.com is WARNING!
From: icinga2@monitoring.example.com (icinga)

***** Service Monitoring on monitoring.znuny.com *****

Ping IPv4 on apn4711.dc.example.com is WARNING!

Info:    PING WARNING - Packet loss =3D 0%, RTA =3D 160.57 ms

When:    2017-09-28 09:41:03 +0200
Service: Ping IPv4
Host:    apn4711.dc.example.com
IPv4:    127.0.0.1="

    ticket_4, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_4.state.name)
    assert(ticket_4.preferences)
    assert(ticket_4.preferences['icinga'])
    assert_equal('apn4711.dc.example.com', ticket_4.preferences['icinga']['host'])
    assert_equal('Ping IPv4', ticket_4.preferences['icinga']['service'])
    assert_equal('WARNING', ticket_4.preferences['icinga']['state'])
    assert_not_equal(ticket_4.id, ticket_1.id)

    # ping up
    email_raw_string = "To: support@example.com
Subject: [RECOVERY] Ping IPv4 on apn4711.dc.example.com is OK!
From: icinga2@monitoring.example.com (icinga)

***** Service Monitoring on monitoring.znuny.com *****

Ping IPv4 on apn4711.dc.example.com is OK!

Info:    PING OK - Packet loss =3D 0%, RTA =3D 20.23 ms

When:    2017-09-28 11:42:01 +0200
Service: Ping IPv4
Host:    apn4711.dc.example.com
IPv4:    127.0.0.1="

    ticket_4_1, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(ticket_4.id, ticket_4_1.id)
    assert_equal('closed', ticket_4_1.state.name)
    assert(ticket_4_1.preferences)
    assert(ticket_4_1.preferences['icinga'])
    assert_equal('apn4711.dc.example.com', ticket_4.preferences['icinga']['host'])
    assert_equal('Ping IPv4', ticket_4.preferences['icinga']['service'])
    assert_equal('WARNING', ticket_4_1.preferences['icinga']['state'])
  end

  test 'not matching sender tests' do

    # not matching sender
    email_raw_string = "To: support@example.com
Subject: PROBLEM - host.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-1-0@monitoring.znuny.com>
From: icinga_not_matching@monitoring.example.com (icinga)

***** Icinga  *****

Notification Type: PROBLEM

Service: CPU Load
Host: host.internal.loc
Address:=20
State: WARNING

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info: WARNING - load average: 3.44, 0.99, 0.35

Comment: [] =
"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_p.state.name)
    assert(ticket_p.preferences)
    assert_not(ticket_p.preferences['icinga'])

    Setting.set('icinga_sender', 'regex:icinga2@monitoring.example.com')

    # not matching sender
    email_raw_string = "To: support@example.com
Subject: PROBLEM - host.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-1-0@monitoring.znuny.com>
From: icinga_not_matching@monitoring.example.com (icinga)

***** Icinga  *****

Notification Type: PROBLEM

Service: CPU Load
Host: host.internal.loc
Address:=20
State: WARNING

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info: WARNING - load average: 3.44, 0.99, 0.35

Comment: [] =
"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_p.state.name)
    assert(ticket_p.preferences)
    assert_not(ticket_p.preferences['icinga'])

    # not matching sender
    email_raw_string = "To: support@example.com
Subject: PROBLEM - host.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-1-0@monitoring.znuny.com>
Return-Path: bob@example.com

***** Icinga  *****

Notification Type: PROBLEM

Service: CPU Load
Host: host.internal.loc
Address:=20
State: WARNING

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info: WARNING - load average: 3.44, 0.99, 0.35

Comment: [] =
"

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_p.state.name)
    assert(ticket_p.preferences)
    assert_not(ticket_p.preferences['icinga'])
  end

  test 'matching sender tests' do

    # matching sender - follow up - CPU Load/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: PROBLEM - host.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-4@monitoring.znuny.com>
From: icinga2@monitoring.example.com (icinga)

***** Icinga  *****

Notification Type: PROBLEM

Service: CPU Load
Host: host.internal.loc
Address:=20
State: WARNING

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info: WARNING - load average: 3.44, 0.99, 0.35

Comment: [] =
"

    ticket_1_1, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_1_1.state.name)
    assert(ticket_1_1.preferences)
    assert(ticket_1_1.preferences['icinga'])
    assert_equal('host.internal.loc', ticket_1_1.preferences['icinga']['host'])
    assert_equal('CPU Load', ticket_1_1.preferences['icinga']['service'])
    assert_equal('WARNING', ticket_1_1.preferences['icinga']['state'])

    Setting.set('icinga_sender', 'regex:icinga2@monitoring.example.com')

    # matching sender I
    email_raw_string = "To: support@example.com
Subject: PROBLEM - host1.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-4@monitoring.znuny.com>
From: icinga2@monitoring.example.com (icinga)

***** Icinga  *****

Notification Type: PROBLEM

Service: CPU Load
Host: host1.internal.loc
Address:=20
State: WARNING

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info: WARNING - load average: 3.44, 0.99, 0.35

Comment: [] =
"

    ticket_1_1, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_1_1.state.name)
    assert(ticket_1_1.preferences)
    assert(ticket_1_1.preferences['icinga'])
    assert_equal('host1.internal.loc', ticket_1_1.preferences['icinga']['host'])
    assert_equal('CPU Load', ticket_1_1.preferences['icinga']['service'])
    assert_equal('WARNING', ticket_1_1.preferences['icinga']['state'])

    # matching sender I
    Setting.set('icinga_sender', 'regex:(icinga2|abc123)@monitoring.example.com')

    email_raw_string = "To: support@example.com
Subject: PROBLEM - host2.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-4@monitoring.znuny.com>
From: icinga2@monitoring.example.com (icinga)

***** Icinga  *****

Notification Type: PROBLEM

Service: CPU Load
Host: host2.internal.loc
Address:=20
State: WARNING

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info: WARNING - load average: 3.44, 0.99, 0.35

Comment: [] =
"

    ticket_1_1, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_1_1.state.name)
    assert(ticket_1_1.preferences)
    assert(ticket_1_1.preferences['icinga'])
    assert_equal('host2.internal.loc', ticket_1_1.preferences['icinga']['host'])
    assert_equal('CPU Load', ticket_1_1.preferences['icinga']['service'])
    assert_equal('WARNING', ticket_1_1.preferences['icinga']['state'])

  end

  test 'recover without problem tests' do

    # host up without problem
    email_raw_string = "To: support@example.com
Subject: RECOVERY - apn4711.dc.example.com is UP
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-5@monitoring.znuny.com>
From: icinga2@monitoring.example.com (icinga)

***** Icinga *****

Notification Type: RECOVERY

Host: apn4711.dc.example.com
Address: 127.0.0.1
State: UP

Date/Time: 2017-01-14 12:07:11 +0100

Additional Info: PING OK - Packet loss = 0%, RTA = 21.37 ms

Comment: [] =
"
    ticket_1, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket_count = Ticket.count
    assert_not(ticket_1)
    assert_equal(ticket_count, Ticket.count)
  end

end
