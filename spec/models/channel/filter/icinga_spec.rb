# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::Icinga, :aggregate_failures do

  # according
  # https://github.com/Icinga/icinga2/blob/master/etc/icinga2/scripts/mail-service-notification.sh
  # http://docs.icinga.org/icinga2/latest/doc/module/icinga2/chapter/monitoring-basics#host-states
  # http://docs.icinga.org/icinga2/latest/doc/module/icinga2/chapter/monitoring-basics#service-states

  before do
    Setting.set('icinga_integration', true)
    Setting.set('icinga_sender', 'icinga2@monitoring.example.com')
  end

  context 'with a sequence of notifications' do
    def process_email(raw)
      Channel::EmailParser.new.process({}, raw).first
    end

    let(:rbl_problem) do
      "To: support@example.com
Subject: [PROBLEM] RBL check on apn4711.dc.example.com is CRITICAL!
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-1-1@monitoring.zammad.com>
From: icinga2@monitoring.example.com (icinga)

***** Icinga 2 Service Monitoring on apn4711.dc.example.com *****

=3D=3D> RBL check on apn4711.dc.example.com is CRITICAL! <=3D=3D

Info:    CHECK_RBL CRITICAL - apn4711.dc.example.com BLACKLISTED on 1 server of=
 38 (ix.dnsbl.example.com)=20

When:    2017-08-06 22:18:43 +0200
Service: RBL check (Display Name: \"RBL check\")
Host:    apn4711.dc.example.com (Display Name: \"apn4711.dc.example.com\")
IPv4:    127.0.0.1="
    end
    let(:rbl_problem_repeated) do
      "To: support@example.com
Subject: [PROBLEM] RBL check on apn4711.dc.example.com is CRITICAL!
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-1-2@monitoring.zammad.com>
From: icinga2@monitoring.example.com (icinga)

***** Icinga 2 Service Monitoring on apn4711.dc.example.com *****

=3D=3D> RBL check on apn4711.dc.example.com is CRITICAL! <=3D=3D

Info:    CHECK_RBL CRITICAL - apn4711.dc.example.com BLACKLISTED on 1 server of=
 38 (ix.dnsbl.example.com)=20

When:    2017-08-06 22:18:43 +0200
Service: RBL check (Display Name: \"RBL check\")
Host:    apn4711.dc.example.com (Display Name: \"apn4711.dc.example.com\")
IPv4:    127.0.0.1="
    end
    let(:rbl_recovery) do
      "To: support@example.com
Subject: [PROBLEM] RBL check on apn4711.dc.example.com is OK!
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-1-2@monitoring.zammad.com>
From: icinga2@monitoring.example.com (icinga)

***** Icinga 2 Service Monitoring on apn4711.dc.example.com *****

=3D=3D> RBL check on apn4711.dc.example.com is OK! <=3D=3D

Info:    CHECK_RBL OK - apn4711.dc.example.com BLACKLISTED on 1 server of=
 38 (ix.dnsbl.example.com)=20

When:    2017-08-06 22:18:43 +0200
Service: RBL check (Display Name: \"RBL check\")
Host:    apn4711.dc.example.com (Display Name: \"apn4711.dc.example.com\")
IPv4:    127.0.0.1="
    end
    let(:cpu_problem) do
      "To: support@example.com
Subject: PROBLEM - host.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-2@monitoring.zammad.com>
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
    end
    let(:disk_problem) do
      "To: support@example.com
Subject: PROBLEM - host.internal.loc - Disk Usage 123 is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-3@monitoring.zammad.com>
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
    end
    let(:cpu_problem_repeated) do
      "To: support@example.com
Subject: PROBLEM - host.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-4@monitoring.zammad.com>
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
    end
    let(:cpu_recovery) do
      "To: support@example.com
Subject: PROBLEM - host.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-5@monitoring.zammad.com>
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
    end
    let(:host_down) do
      "To: support@example.com
Subject: PROBLEM - apn4711.dc.example.com is DOWN
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-5@monitoring.zammad.com>
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
    end
    let(:host_up) do
      "To: support@example.com
Subject: RECOVERY - apn4711.dc.example.com is UP
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-5@monitoring.zammad.com>
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
    end
    let(:ping_problem) do
      "To: support@example.com
Subject: [PROBLEM] Ping IPv4 on apn4711.dc.example.com is WARNING!
From: icinga2@monitoring.example.com (icinga)

***** Service Monitoring on monitoring.example.com *****

Ping IPv4 on apn4711.dc.example.com is WARNING!

Info:    PING WARNING - Packet loss =3D 0%, RTA =3D 160.57 ms

When:    2017-09-28 09:41:03 +0200
Service: Ping IPv4
Host:    apn4711.dc.example.com
IPv4:    127.0.0.1="
    end
    let(:ping_recovery) do
      "To: support@example.com
Subject: [RECOVERY] Ping IPv4 on apn4711.dc.example.com is OK!
From: icinga2@monitoring.example.com (icinga)

***** Service Monitoring on monitoring.example.com *****

Ping IPv4 on apn4711.dc.example.com is OK!

Info:    PING OK - Packet loss =3D 0%, RTA =3D 20.23 ms

When:    2017-09-28 11:42:01 +0200
Service: Ping IPv4
Host:    apn4711.dc.example.com
IPv4:    127.0.0.1="
    end
    let(:other_host_down) do
      "To: support@example.com
Subject: [PROBLEM] Host apn4709.dc.example.com is DOWN!
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
From: icinga2@monitoring.example.com (icinga)

***** Host Monitoring on monitoring.example.com *****

apn4709.dc.example.com is DOWN!

Info:    CRITICAL - Plugin timed out


When:    2017-09-29 14:19:40 +0200
Host:    apn4709.dc.example.com
IPv4:=09 127.0.0.1="
    end
    let(:other_host_up) do
      "To: support@example.com
Subject: [RECOVERY] Host apn4709.dc.example.com is UP!
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
From: icinga2@monitoring.example.com (icinga)

***** Host Monitoring on monitoring.example.com *****

apn4709.dc.example.com is UP!

Info:    PING OK - Packet loss =3D 0%, RTA =3D 20.20 ms

When:    2017-09-29 14:23:36 +0200
Host:    apn4709.dc.example.com
IPv4:=09 127.0.0.1=
"
    end

    it 'opens a ticket for a service problem with display names' do
      expect(process_email(rbl_problem)).to have_attributes(state: have_attributes(name: 'new'), preferences: include('icinga' => include('host' => 'apn4711.dc.example.com (Display Name: "apn4711.dc.example.com")', 'service' => 'RBL check (Display Name: "RBL check")', 'state' => 'CRITICAL')))
    end

    it 'adds a repeated problem with display names to the open ticket' do
      rbl_ticket = process_email(rbl_problem)

      expect(process_email(rbl_problem_repeated)).to have_attributes(id: rbl_ticket.id, state: have_attributes(name: 'new'))
    end

    it 'closes the ticket with display names on recovery' do
      rbl_ticket = process_email(rbl_problem)

      expect(process_email(rbl_recovery)).to have_attributes(id: rbl_ticket.id, state: have_attributes(name: 'closed'), preferences: include('icinga' => include('host' => 'apn4711.dc.example.com (Display Name: "apn4711.dc.example.com")', 'service' => 'RBL check (Display Name: "RBL check")', 'state' => 'CRITICAL')))
    end

    it 'opens a ticket for a service problem' do
      expect(process_email(cpu_problem)).to have_attributes(state: have_attributes(name: 'new'), preferences: include('icinga' => include('host' => 'host.internal.loc', 'service' => 'CPU Load', 'state' => 'WARNING')))
    end

    it 'opens a separate ticket for a problem of another service' do
      cpu_ticket = process_email(cpu_problem)

      expect(process_email(disk_problem)).to have_attributes(
        id:          not_eq(cpu_ticket.id),
        preferences: include('icinga' => include('host' => 'host.internal.loc', 'service' => 'Disk Usage 123', 'state' => 'WARNING'))
      )
    end

    it 'adds a repeated problem to the open ticket' do
      cpu_ticket = process_email(cpu_problem)

      expect(process_email(cpu_problem_repeated)).to have_attributes(id: cpu_ticket.id, state: have_attributes(name: 'new'))
    end

    it 'closes the ticket on recovery' do
      cpu_ticket = process_email(cpu_problem)

      expect(process_email(cpu_recovery)).to have_attributes(id: cpu_ticket.id, state: have_attributes(name: 'closed'), preferences: include('icinga' => include('host' => 'host.internal.loc', 'service' => 'CPU Load', 'state' => 'WARNING')))
    end

    it 'opens a ticket for a host problem' do
      expect(process_email(host_down)).to have_attributes(
        state:       have_attributes(name: 'new'),
        preferences: include('icinga' => include('host' => 'apn4711.dc.example.com', 'state' => 'DOWN').and(not_include('service')))
      )
    end

    it 'closes the host ticket once the host is up' do
      host_ticket = process_email(host_down)

      expect(process_email(host_up)).to have_attributes(id: host_ticket.id, state: have_attributes(name: 'closed'))
    end

    it 'opens and closes a ticket for a ping problem' do
      ping_ticket = process_email(ping_problem)
      expect(ping_ticket).to have_attributes(
        state:       have_attributes(name: 'new'),
        preferences: include('icinga' => include('host' => 'apn4711.dc.example.com', 'service' => 'Ping IPv4', 'state' => 'WARNING'))
      )

      expect(process_email(ping_recovery)).to have_attributes(id: ping_ticket.id, state: have_attributes(name: 'closed'))
    end

    it 'opens and closes a ticket for a host problem in the bracketed subject format' do
      host_ticket = process_email(other_host_down)
      expect(host_ticket).to have_attributes(
        state:       have_attributes(name: 'new'),
        preferences: include('icinga' => include('host' => 'apn4709.dc.example.com', 'state' => 'DOWN').and(not_include('service')))
      )

      expect(process_email(other_host_up)).to have_attributes(id: host_ticket.id, state: have_attributes(name: 'closed'))
    end
  end

  it 'does not set icinga preferences when the sender does not match' do # rubocop:disable RSpec/ExampleLength

    # not matching sender
    email_raw_string = "To: support@example.com
Subject: PROBLEM - host.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-1-0@monitoring.zammad.com>
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

    ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    expect(ticket_p.state.name).to eq('new')
    expect(ticket_p.preferences).not_to have_key('icinga')

    Setting.set('icinga_sender', 'icinga2@monitoring.example.com')

    # not matching sender
    email_raw_string = "To: support@example.com
Subject: PROBLEM - host.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-1-0@monitoring.zammad.com>
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

    ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    expect(ticket_p.state.name).to eq('new')
    expect(ticket_p.preferences).not_to have_key('icinga')

    # not matching sender
    email_raw_string = "To: support@example.com
Subject: PROBLEM - host.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-1-0@monitoring.zammad.com>
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

    ticket_p, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    expect(ticket_p.state.name).to eq('new')
    expect(ticket_p.preferences).not_to have_key('icinga')
  end

  it 'sets icinga preferences when the sender matches' do # rubocop:disable RSpec/ExampleLength

    # matching sender - follow-up - CPU Load/host.internal.loc
    email_raw_string = "To: support@example.com
Subject: PROBLEM - host.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-4@monitoring.zammad.com>
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

    ticket_1_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    expect(ticket_1_1.state.name).to eq('new')
    expect(ticket_1_1.preferences['icinga']['host']).to eq('host.internal.loc')
    expect(ticket_1_1.preferences['icinga']['service']).to eq('CPU Load')
    expect(ticket_1_1.preferences['icinga']['state']).to eq('WARNING')

    Setting.set('icinga_sender', 'icinga2@monitoring.example.com')

    # matching sender I
    email_raw_string = "To: support@example.com
Subject: PROBLEM - host1.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-4@monitoring.zammad.com>
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

    ticket_1_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    expect(ticket_1_1.state.name).to eq('new')
    expect(ticket_1_1.preferences['icinga']['host']).to eq('host1.internal.loc')
    expect(ticket_1_1.preferences['icinga']['service']).to eq('CPU Load')
    expect(ticket_1_1.preferences['icinga']['state']).to eq('WARNING')

    # matching sender I
    Setting.set('icinga_sender', '(icinga2|abc123)@monitoring.example.com')

    email_raw_string = "To: support@example.com
Subject: PROBLEM - host2.internal.loc - CPU Load is WARNING
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-4@monitoring.zammad.com>
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

    ticket_1_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    expect(ticket_1_1.state.name).to eq('new')
    expect(ticket_1_1.preferences['icinga']['host']).to eq('host2.internal.loc')
    expect(ticket_1_1.preferences['icinga']['service']).to eq('CPU Load')
    expect(ticket_1_1.preferences['icinga']['state']).to eq('WARNING')

  end

  it 'does not create a ticket for a recovery without a preceding problem' do

    # host up without problem
    email_raw_string = "To: support@example.com
Subject: RECOVERY - apn4711.dc.example.com is UP
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20160131094621.29ECD400F29C-icinga-5@monitoring.zammad.com>
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
    ticket_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    ticket_count = Ticket.count
    expect(ticket_1).to eq({})
    expect(Ticket.count).to eq(ticket_count)
  end

  it 'closes the ticket automatically when the recovery email arrives' do # rubocop:disable RSpec/ExampleLength
    Setting.set('icinga_sender', 'zaihan@example.com')
    email_raw_string = 'Return-Path: <support@example.com>
Received: from 04747418efb9 ([175.137.28.47])
        by smtp.example.com with ESMTPSA id r14sm6448824pfa.163.2018.04.03.10.10.59
	for <support@example.com>
        (version=TLS1_2 cipher=ECDHE-RSA-AES128-GCM-SHA256 bits=128/128);
        Tue, 03 Apr 2018 10:11:00 -0700 (PDT)
From: "zaihan@example.com" <zaihan@example.com>
X-Google-Original-From: "zaihan@example.com" <zaihan@example.com>
Message-ID: <301139.467253478-sendEmail@04747418efb9>
To: "support@example.com" <support@example.com>
Subject: PROBLEM - Awesell -  is DOWN
Date: Tue, 3 Apr 2018 17:11:04 +0000
X-Mailer: sendEmail-1.56
MIME-Version: 1.0
Content-Type: multipart/related; boundary="----MIME delimiter for sendEmail-587258.191387267"

This is a multi-part message in MIME format. To properly display this message you need a MIME-Version 1.0 compliant Email program.

------MIME delimiter for sendEmail-587258.191387267
Content-Type: text/plain;
        charset="iso-8859-1"
Content-Transfer-Encoding: 7bit

***** Host Monitoring on 04747418efb9 *****

Awesell is DOWN!

Info:    PING CRITICAL - Packet loss = 100%

When:    2018-04-03 17:11:04 +0000
Host:    Awesell
IPv4:	 192.168.1.8

------MIME delimiter for sendEmail-587258.191387267--'
    ticket_0, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    expect(ticket_0.state.name).to eq('new')
    expect(ticket_0.preferences['icinga']['state']).to eq('DOWN')

    email_raw_string = 'Return-Path: <support@example.com>
Received: from 04747418efb9 ([175.137.28.47])
	by smtp.example.com with ESMTPSA id b73sm6127782pga.62.2018.04.03.10.31.00
	for <support@example.com>
        (version=TLS1_2 cipher=ECDHE-RSA-AES128-GCM-SHA256 bits=128/128);
        Tue, 03 Apr 2018 10:31:01 -0700 (PDT)
From: "zaihan@example.com" <zaihan@example.com>
X-Google-Original-From: "zaihan@example.com" <zaihan@example.com>
Message-ID: <601339.882795827-sendEmail@04747418efb9>
To: "support@example.com" <support@example.com>
Subject: RECOVERY - Awesell -  is UP
Date: Tue, 3 Apr 2018 17:31:05 +0000
X-Mailer: sendEmail-1.56
MIME-Version: 1.0
Content-Type: multipart/related; boundary="----MIME delimiter for sendEmail-322998.239033954"

This is a multi-part message in MIME format. To properly display this message you need a MIME-Version 1.0 compliant Email program.

------MIME delimiter for sendEmail-322998.239033954
Content-Type: text/plain;
        charset="iso-8859-1"
Content-Transfer-Encoding: 7bit

***** Host Monitoring on 04747418efb9 *****

Awesell is UP!

Info:    PING OK - Packet loss = 68%, RTA = 0.59 ms

When:    2018-04-03 17:31:05 +0000
Host:    Awesell
IPv4:	 192.168.1.8

------MIME delimiter for sendEmail-322998.239033954--
    '
    ticket_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    expect(ticket_1.state.name).to eq('closed')
    expect(ticket_1.preferences['icinga']['state']).to eq('DOWN')

  end

  it 'matches also values without new line at the end of a line' do # rubocop:disable RSpec/ExampleLength

    email_raw_string = 'Return-Path: <icinga2@monitoring.example.com>
Date: Tue, 21 Aug 2018 03:05:01 +0200
To: hostmaster@example.com
Subject: [PROBLEM] OS Updates (yum) on host.example.com is CRITICAL!
User-Agent: Heirloom mailx 12.5 7/5/10
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: quoted-printable
Message-Id: <20180821010501.4A182846DBA@monitoring.example.com>
From: icinga2@monitoring.example.com (icinga)

***** Service Monitoring on monitoring.example.com *****

OS Updates (yum) on host.example.com is CRITICAL!

Info:    CHECK_UPDATES CRITICAL - 12 non-critical updates available=20
audit-libs.x86_64
dracut.x86_64
initscripts.x86_64
kpartx.x86_64
libblkid.x86_64
libmount.x86_64
libuuid.x86_64
mariadb-libs.x86_64
systemd.x86_64
systemd-libs.x86_64
systemd-sysv.x86_64
util-linux.x86_64

When:    2018-08-21 03:05:01 +0200
Service: OS Updates (yum)
Host:    host.example.com'

    ticket_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    expect(ticket_1.state.name).to eq('new')
    expect(ticket_1.preferences['icinga']['state']).to eq('CRITICAL')
    expect(ticket_1.preferences['icinga']['info']).to eq('CHECK_UPDATES CRITICAL - 12 non-critical updates available')
    expect(ticket_1.preferences['icinga']['service']).to eq('OS Updates (yum)')
    expect(ticket_1.preferences['icinga']['host']).to eq('host.example.com')

  end
end
