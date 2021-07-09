# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class IntegrationNagiosTest < ActiveSupport::TestCase

  # according
  # https://github.com/NagiosEnterprises/nagioscore/blob/754218e67653929a58938b99ef6b6039b6474fe4/sample-config/template-object/commands.cfg.in#L35

  setup do
    Setting.set('nagios_integration', true)
    Setting.set('nagios_sender', 'nagios2@monitoring.example.com')
  end

  test 'base tests' do

    # matching sender - CPU Load/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-2@monitoring.znuny.com>
From: nagios2@monitoring.example.com (nagios)

***** Nagios *****

Notification Type: PROBLEM

Service: CPU Load
Host: host.internal.loc
Address: 1.1.1.1
State: WARNING

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info:
WARNING - load average: 3.44, 0.99, 0.35
"

    ticket_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_1.state.name)
    assert(ticket_1.preferences)
    assert(ticket_1.preferences['nagios'])
    assert_equal('host.internal.loc', ticket_1.preferences['nagios']['host'])
    assert_equal('CPU Load', ticket_1.preferences['nagios']['service'])
    assert_equal('WARNING', ticket_1.preferences['nagios']['state'])

    # matching sender - Disk Usage 123/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/Disk Usage 123 is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-3@monitoring.znuny.com>
From: nagios2@monitoring.example.com (nagios)

***** Nagios *****

Notification Type: PROBLEM

Service: Disk Usage 123
Host: host.internal.loc
Address: 1.1.1.1
State: WARNING

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info:
WARNING - load average: 3.44, 0.99, 0.35
"

    ticket_2, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_2.state.name)
    assert(ticket_2.preferences)
    assert(ticket_2.preferences['nagios'])
    assert_equal('host.internal.loc', ticket_2.preferences['nagios']['host'])
    assert_equal('Disk Usage 123', ticket_2.preferences['nagios']['service'])
    assert_equal('WARNING', ticket_2.preferences['nagios']['state'])
    assert_not_equal(ticket_2.id, ticket_1.id)

    # matching sender - follow-up - CPU Load/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-4@monitoring.znuny.com>
From: nagios2@monitoring.example.com (nagios)

***** Nagios *****

Notification Type: PROBLEM

Service: CPU Load
Host: host.internal.loc
Address: 1.1.1.1
State: WARNING

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info:
WARNING - load average: 3.44, 0.99, 0.35
"

    ticket_1_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_1_1.state.name)
    assert(ticket_1_1.preferences)
    assert(ticket_1_1.preferences['nagios'])
    assert_equal('host.internal.loc', ticket_1_1.preferences['nagios']['host'])
    assert_equal('CPU Load', ticket_1_1.preferences['nagios']['service'])
    assert_equal('WARNING', ticket_1_1.preferences['nagios']['state'])
    assert_equal(ticket_1.id, ticket_1_1.id)

    # matching sender - follow-up - recovery - CPU Load/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-5@monitoring.znuny.com>
From: nagios2@monitoring.example.com (nagios)

***** Nagios *****

Notification Type: PROBLEM

Service: CPU Load
Host: host.internal.loc
Address: 1.1.1.1
State: OK

Date/Time: 2016-01-31 10:48:02 +0100

Additional Info:
"
    ticket_1_2, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(ticket_1.id, ticket_1_2.id)
    assert_equal('closed', ticket_1_2.state.name)
    assert(ticket_1_2.preferences)
    assert(ticket_1_2.preferences['nagios'])
    assert_equal('host.internal.loc', ticket_1_2.preferences['nagios']['host'])
    assert_equal('CPU Load', ticket_1_2.preferences['nagios']['service'])
    assert_equal('WARNING', ticket_1_2.preferences['nagios']['state'])

    # host down
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Host Alert: apn4711.dc.example.com is DOWN **
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-5@monitoring.znuny.com>
From: nagios2@monitoring.example.com (nagios)

***** Nagios *****

Notification Type: PROBLEM

Host: apn4711.dc.example.com
Address: 127.0.0.1
State: DOWN

Date/Time: 2017-01-14 11:33:02 +0100

Additional Info: CRITICAL - Host Unreachable (127.0.0.1)

Comment: [] =
"
    ticket_3, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_3.state.name)
    assert(ticket_3.preferences)
    assert(ticket_3.preferences['nagios'])
    assert_equal('apn4711.dc.example.com', ticket_3.preferences['nagios']['host'])
    assert_nil(ticket_3.preferences['nagios']['service'])
    assert_equal('DOWN', ticket_3.preferences['nagios']['state'])
    assert_not_equal(ticket_3.id, ticket_1.id)

    # host up
    email_raw_string = "To: support@example.com
Subject: ** RECOVERY Host Alert: apn4711.dc.example.com is UP **
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-5@monitoring.znuny.com>
From: nagios2@monitoring.example.com (nagios)

***** Nagios *****

Notification Type: RECOVERY

Host: apn4711.dc.example.com
Address: 127.0.0.1
State: UP

Date/Time: 2017-01-14 12:07:11 +0100

Additional Info: PING OK - Packet loss = 0%, RTA = 21.37 ms

Comment: [] =
"
    ticket_3_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(ticket_3.id, ticket_3_1.id)
    assert_equal('closed', ticket_3_1.state.name)
    assert(ticket_3_1.preferences)
    assert(ticket_3_1.preferences['nagios'])
    assert_equal('apn4711.dc.example.com', ticket_3.preferences['nagios']['host'])
    assert_nil(ticket_3_1.preferences['nagios']['service'])
    assert_equal('DOWN', ticket_3_1.preferences['nagios']['state'])

    #Setting.set('nagios_integration', false)

  end

  test 'not matching sender tests' do

    # not matching sender
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-1@monitoring.znuny.com>
From: nagios_not_matching@monitoring.example.com (nagios)

***** Nagios *****

Notification Type: PROBLEM

Service: CPU Load
Host: host.internal.loc
Address: 1.1.1.1
State: PROBLEM

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info:
WARNING - load average: 3.44, 0.99, 0.35
"

    ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_p.state.name)
    assert(ticket_p.preferences)
    assert_not(ticket_p.preferences['nagios'])

    Setting.set('nagios_sender', 'regex:icinga2@monitoring.example.com')

    # not matching sender
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-1@monitoring.znuny.com>
From: nagios_not_matching@monitoring.example.com (nagios)

***** Nagios *****

Notification Type: PROBLEM

Service: CPU Load
Host: host.internal.loc
Address: 1.1.1.1
State: PROBLEM

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info:
WARNING - load average: 3.44, 0.99, 0.35
"

    ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_p.state.name)
    assert(ticket_p.preferences)
    assert_not(ticket_p.preferences['nagios'])

    # not matching sender
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-1@monitoring.znuny.com>
Return-Path: bob@example.com

***** Nagios *****

Notification Type: PROBLEM

Service: CPU Load
Host: host.internal.loc
Address: 1.1.1.1
State: PROBLEM

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info:
WARNING - load average: 3.44, 0.99, 0.35
"

    ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_p.state.name)
    assert(ticket_p.preferences)
    assert_not(ticket_p.preferences['nagios'])
  end

  test 'matching sender tests' do

    # matching sender - follow-up - CPU Load/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-2@monitoring.znuny.com>
From: nagios2@monitoring.example.com (nagios)

***** Nagios *****

Notification Type: PROBLEM

Service: CPU Load
Host: host.internal.loc
Address: 1.1.1.1
State: WARNING

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info:
WARNING - load average: 3.44, 0.99, 0.35
"

    ticket_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_1.state.name)
    assert(ticket_1.preferences)
    assert(ticket_1.preferences['nagios'])
    assert_equal('host.internal.loc', ticket_1.preferences['nagios']['host'])
    assert_equal('CPU Load', ticket_1.preferences['nagios']['service'])
    assert_equal('WARNING', ticket_1.preferences['nagios']['state'])

    Setting.set('icinga_sender', 'regex:icinga2@monitoring.example.com')

    # matching sender I
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-2@monitoring.znuny.com>
From: nagios2@monitoring.example.com (nagios)

***** Nagios *****

Notification Type: PROBLEM

Service: CPU Load
Host: host1.internal.loc
Address: 1.1.1.1
State: WARNING

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info:
WARNING - load average: 3.44, 0.99, 0.35
"

    ticket_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_1.state.name)
    assert(ticket_1.preferences)
    assert(ticket_1.preferences['nagios'])
    assert_equal('host1.internal.loc', ticket_1.preferences['nagios']['host'])
    assert_equal('CPU Load', ticket_1.preferences['nagios']['service'])
    assert_equal('WARNING', ticket_1.preferences['nagios']['state'])

    # matching sender I
    Setting.set('icinga_sender', 'regex:(icinga2|abc123)@monitoring.example.com')

    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-2@monitoring.znuny.com>
From: nagios2@monitoring.example.com (nagios)

***** Nagios *****

Notification Type: PROBLEM

Service: CPU Load
Host: host2.internal.loc
Address: 1.1.1.1
State: WARNING

Date/Time: 2016-01-31 10:46:20 +0100

Additional Info:
WARNING - load average: 3.44, 0.99, 0.35
"

    ticket_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_1.state.name)
    assert(ticket_1.preferences)
    assert(ticket_1.preferences['nagios'])
    assert_equal('host2.internal.loc', ticket_1.preferences['nagios']['host'])
    assert_equal('CPU Load', ticket_1.preferences['nagios']['service'])
    assert_equal('WARNING', ticket_1.preferences['nagios']['state'])

  end

  test 'recover without problem tests' do

    # host up without problem
    email_raw_string = "To: support@example.com
Subject: ** RECOVERY Host Alert: apn4711.dc.example.com is UP **
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-5@monitoring.znuny.com>
From: nagios2@monitoring.example.com (nagios)

***** Nagios *****

Notification Type: RECOVERY

Host: apn4711.dc.example.com
Address: 127.0.0.1
State: UP

Date/Time: 2017-01-14 12:07:11 +0100

Additional Info: PING OK - Packet loss = 0%, RTA = 21.37 ms

Comment: [] =
"
    ticket_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket_count = Ticket.count
    assert_not(ticket_1)
    assert_equal(ticket_count, Ticket.count)
  end

end
