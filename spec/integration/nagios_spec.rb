# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Nagios integration', :aggregate_failures do # rubocop:disable RSpec/DescribeClass

  # according
  # https://github.com/NagiosEnterprises/nagioscore/blob/754218e67653929a58938b99ef6b6039b6474fe4/sample-config/template-object/commands.cfg.in#L35

  before do
    Setting.set('nagios_integration', true)
    Setting.set('nagios_sender', 'nagios2@monitoring.example.com')
  end

  it 'processes service and host notifications and closes tickets on recovery' do # rubocop:disable RSpec/ExampleLength

    # matching sender - CPU Load/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-2@monitoring.zammad.com>
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
    expect(ticket_1.state.name).to eq('new')
    expect(ticket_1.preferences).to be_truthy
    expect(ticket_1.preferences['nagios']).to be_truthy
    expect(ticket_1.preferences['nagios']['host']).to eq('host.internal.loc')
    expect(ticket_1.preferences['nagios']['service']).to eq('CPU Load')
    expect(ticket_1.preferences['nagios']['state']).to eq('WARNING')

    # matching sender - Disk Usage 123/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/Disk Usage 123 is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-3@monitoring.zammad.com>
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
    expect(ticket_2.state.name).to eq('new')
    expect(ticket_2.preferences).to be_truthy
    expect(ticket_2.preferences['nagios']).to be_truthy
    expect(ticket_2.preferences['nagios']['host']).to eq('host.internal.loc')
    expect(ticket_2.preferences['nagios']['service']).to eq('Disk Usage 123')
    expect(ticket_2.preferences['nagios']['state']).to eq('WARNING')
    expect(ticket_1.id).not_to eq(ticket_2.id)

    # matching sender - follow-up - CPU Load/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-4@monitoring.zammad.com>
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
    expect(ticket_1_1.state.name).to eq('new')
    expect(ticket_1_1.preferences).to be_truthy
    expect(ticket_1_1.preferences['nagios']).to be_truthy
    expect(ticket_1_1.preferences['nagios']['host']).to eq('host.internal.loc')
    expect(ticket_1_1.preferences['nagios']['service']).to eq('CPU Load')
    expect(ticket_1_1.preferences['nagios']['state']).to eq('WARNING')
    expect(ticket_1_1.id).to eq(ticket_1.id)

    # matching sender - follow-up - recovery - CPU Load/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-5@monitoring.zammad.com>
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
    expect(ticket_1_2.id).to eq(ticket_1.id)
    expect(ticket_1_2.state.name).to eq('closed')
    expect(ticket_1_2.preferences).to be_truthy
    expect(ticket_1_2.preferences['nagios']).to be_truthy
    expect(ticket_1_2.preferences['nagios']['host']).to eq('host.internal.loc')
    expect(ticket_1_2.preferences['nagios']['service']).to eq('CPU Load')
    expect(ticket_1_2.preferences['nagios']['state']).to eq('WARNING')

    # host down
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Host Alert: apn4711.dc.example.com is DOWN **
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-5@monitoring.zammad.com>
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
    expect(ticket_3.state.name).to eq('new')
    expect(ticket_3.preferences).to be_truthy
    expect(ticket_3.preferences['nagios']).to be_truthy
    expect(ticket_3.preferences['nagios']['host']).to eq('apn4711.dc.example.com')
    expect(ticket_3.preferences['nagios']['service']).to be_nil
    expect(ticket_3.preferences['nagios']['state']).to eq('DOWN')
    expect(ticket_1.id).not_to eq(ticket_3.id)

    # host up
    email_raw_string = "To: support@example.com
Subject: ** RECOVERY Host Alert: apn4711.dc.example.com is UP **
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-5@monitoring.zammad.com>
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
    expect(ticket_3_1.id).to eq(ticket_3.id)
    expect(ticket_3_1.state.name).to eq('closed')
    expect(ticket_3_1.preferences).to be_truthy
    expect(ticket_3_1.preferences['nagios']).to be_truthy
    expect(ticket_3_1.preferences['nagios']['host']).to eq('apn4711.dc.example.com')
    expect(ticket_3_1.preferences['nagios']['service']).to be_nil
    expect(ticket_3_1.preferences['nagios']['state']).to eq('DOWN')

    # Setting.set('nagios_integration', false)

  end

  it 'does not set nagios preferences when the sender does not match' do # rubocop:disable RSpec/ExampleLength

    # not matching sender
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-1@monitoring.zammad.com>
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
    expect(ticket_p.state.name).to eq('new')
    expect(ticket_p.preferences).to be_truthy
    expect(ticket_p.preferences['nagios']).to be_falsey

    Setting.set('nagios_sender', 'icinga2@monitoring.example.com')

    # not matching sender
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-1@monitoring.zammad.com>
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
    expect(ticket_p.state.name).to eq('new')
    expect(ticket_p.preferences).to be_truthy
    expect(ticket_p.preferences['nagios']).to be_falsey

    # not matching sender
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-1@monitoring.zammad.com>
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
    expect(ticket_p.state.name).to eq('new')
    expect(ticket_p.preferences).to be_truthy
    expect(ticket_p.preferences['nagios']).to be_falsey
  end

  it 'sets nagios preferences when the sender matches' do # rubocop:disable RSpec/ExampleLength

    # matching sender - follow-up - CPU Load/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-2@monitoring.zammad.com>
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
    expect(ticket_1.state.name).to eq('new')
    expect(ticket_1.preferences).to be_truthy
    expect(ticket_1.preferences['nagios']).to be_truthy
    expect(ticket_1.preferences['nagios']['host']).to eq('host.internal.loc')
    expect(ticket_1.preferences['nagios']['service']).to eq('CPU Load')
    expect(ticket_1.preferences['nagios']['state']).to eq('WARNING')

    Setting.set('nagios_sender', 'nagios2@monitoring.example.com')

    # matching sender I
    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-2@monitoring.zammad.com>
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
    expect(ticket_1.state.name).to eq('new')
    expect(ticket_1.preferences).to be_truthy
    expect(ticket_1.preferences['nagios']).to be_truthy
    expect(ticket_1.preferences['nagios']['host']).to eq('host1.internal.loc')
    expect(ticket_1.preferences['nagios']['service']).to eq('CPU Load')
    expect(ticket_1.preferences['nagios']['state']).to eq('WARNING')

    # matching sender I
    Setting.set('nagios_sender', '(nagios2|abc123)@monitoring.example.com')

    email_raw_string = "To: support@example.com
Subject: ** PROBLEM Service Alert: host.internal.loc/CPU Load is WARNING **
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-2@monitoring.zammad.com>
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
    expect(ticket_1.state.name).to eq('new')
    expect(ticket_1.preferences).to be_truthy
    expect(ticket_1.preferences['nagios']).to be_truthy
    expect(ticket_1.preferences['nagios']['host']).to eq('host2.internal.loc')
    expect(ticket_1.preferences['nagios']['service']).to eq('CPU Load')
    expect(ticket_1.preferences['nagios']['state']).to eq('WARNING')

  end

  it 'does not create a ticket for a recovery without a preceding problem' do

    # host up without problem
    email_raw_string = "To: support@example.com
Subject: ** RECOVERY Host Alert: apn4711.dc.example.com is UP **
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-nagios-5@monitoring.zammad.com>
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
    expect(ticket_1).to eq({})
    expect(Ticket.count).to eq(ticket_count)
  end

end
