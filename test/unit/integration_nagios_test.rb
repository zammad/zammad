# encoding: utf-8
require 'test_helper'

class IntegrationNagiosTest < ActiveSupport::TestCase

  # according
  # https://github.com/NagiosEnterprises/nagioscore/blob/754218e67653929a58938b99ef6b6039b6474fe4/sample-config/template-object/commands.cfg.in#L35

  test 'base tests' do

    Setting.set('nagios_integration', true)

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

    ticket_p, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_p.state.name)
    assert(ticket_p.preferences)
    assert_not(ticket_p.preferences['integration'])
    assert_not(ticket_p.preferences['nagios'])

    # matching sender - CPU Load/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-2@monitoring.znuny.com>
From: nagios@monitoring.example.com (nagios)

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

    ticket_1, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_1.state.name)
    assert(ticket_1.preferences)
    assert(ticket_1.preferences['integration'])
    assert_equal('nagios', ticket_1.preferences['integration'])
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
From: nagios@monitoring.example.com (nagios)

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

    ticket_2, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_2.state.name)
    assert(ticket_2.preferences)
    assert(ticket_2.preferences['integration'])
    assert_equal('nagios', ticket_2.preferences['integration'])
    assert(ticket_2.preferences['nagios'])
    assert_equal('host.internal.loc', ticket_2.preferences['nagios']['host'])
    assert_equal('Disk Usage 123', ticket_2.preferences['nagios']['service'])
    assert_equal('WARNING', ticket_2.preferences['nagios']['state'])
    assert_not_equal(ticket_2.id, ticket_1.id)

    # matching sender - follow up - CPU Load/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-4@monitoring.znuny.com>
From: nagios@monitoring.example.com (nagios)

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

    ticket_1_1, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_1_1.state.name)
    assert(ticket_1_1.preferences)
    assert(ticket_1_1.preferences['integration'])
    assert_equal('nagios', ticket_1_1.preferences['integration'])
    assert(ticket_1_1.preferences['nagios'])
    assert_equal('host.internal.loc', ticket_1_1.preferences['nagios']['host'])
    assert_equal('CPU Load', ticket_1_1.preferences['nagios']['service'])
    assert_equal('WARNING', ticket_1_1.preferences['nagios']['state'])
    assert_equal(ticket_1.id, ticket_1_1.id)

    # matching sender - follow up - recovery - CPU Load/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-5@monitoring.znuny.com>
From: nagios@monitoring.example.com (nagios)

***** Nagios *****

Notification Type: PROBLEM

Service: CPU Load
Host: host.internal.loc
Address: 1.1.1.1
State: OK

Date/Time: 2016-01-31 10:48:02 +0100

Additional Info:
"
    ticket_1_2, article_p, user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(ticket_1.id, ticket_1_2.id)
    assert_equal('closed', ticket_1_2.state.name)
    assert(ticket_1_2.preferences)
    assert(ticket_1_2.preferences['integration'])
    assert_equal('nagios', ticket_1_2.preferences['integration'])
    assert(ticket_1_2.preferences['nagios'])
    assert_equal('host.internal.loc', ticket_1_2.preferences['nagios']['host'])
    assert_equal('CPU Load', ticket_1_2.preferences['nagios']['service'])
    assert_equal('WARNING', ticket_1_2.preferences['nagios']['state'])

    #Setting.set('nagios_integration', false)

  end

end
