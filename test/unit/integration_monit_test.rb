# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class IntegrationMonitTest < ActiveSupport::TestCase

  # according
  # https://mmonit.com/monit/documentation/#ALERT-MESSAGES

  setup do
    Setting.set('monit_integration', true)
    Setting.set('monit_sender', 'monit@monitoring.example.com')
  end

  test 'base tests' do

    # Service
    email_raw_string = "Message-Id: <20160131094621.29ECD400F29C-monit-1-1@monitoring.znuny.com>
From: monit@monitoring.example.com
To: admin@example
Subject: monit alert --  Timeout php-fpm
Date: Thu, 24 Aug 2017 08:30:42 GMT
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8bit
X-Mailer: Monit 5.23.0
MIME-Version: 1.0

Timeout Service php-fpm

    Date:        Thu, 24 Aug 2017 10:30:42
    Action:      unmonitor
    Host:        web1.example
    Description: service restarted 6 times within 3 cycles(s) - unmonitor

Your faithful employee,
Monit
"

    ticket_0, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_0.state.name)
    assert(ticket_0.preferences)
    assert(ticket_0.preferences['monit'])
    assert_equal('unmonitor', ticket_0.preferences['monit']['action'])
    assert_equal('web1.example', ticket_0.preferences['monit']['host'])
    assert_equal('service restarted 6 times within 3 cycles(s) - unmonitor', ticket_0.preferences['monit']['description'])
    assert_equal('php-fpm', ticket_0.preferences['monit']['service'])
    assert_equal('CRITICAL', ticket_0.preferences['monit']['state'])

    email_raw_string = "Message-Id: <20160131094621.29ECD400F29C-monit-1-2@monitoring.znuny.com>
From: monit@monitoring.example.com
To: admin@example
Subject: monit alert --  Action done php-fpm
Date: Thu, 24 Aug 2017 08:30:42 GMT
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8bit
X-Mailer: Monit 5.23.0
MIME-Version: 1.0

Action done Service php-fpm

    Date:        Thu, 24 Aug 2017 10:37:39
    Action:      alert
    Host:        web1.example
    Description: monitor action done

Your faithful employee,
Monit"

    ticket_0_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('closed', ticket_0_1.state.name)
    assert(ticket_0_1.preferences)
    assert(ticket_0_1.preferences['monit'])
    assert_equal('unmonitor', ticket_0.preferences['monit']['action'])
    assert_equal('web1.example', ticket_0_1.preferences['monit']['host'])
    assert_equal('service restarted 6 times within 3 cycles(s) - unmonitor', ticket_0_1.preferences['monit']['description'])
    assert_equal('php-fpm', ticket_0_1.preferences['monit']['service'])
    assert_equal('CRITICAL', ticket_0_1.preferences['monit']['state'])
    assert_equal(ticket_0_1.id, ticket_0.id)

    # Service
    email_raw_string = "Message-Id: <20160131094621.29ECD400F29C-monit-2-1@monitoring.znuny.com>
From: monit@monitoring.example.com
To: admin@example
Subject: monit alert --  Connection failed host.example
Date: Thu, 24 Aug 2017 08:30:42 GMT
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: quoted-printable
X-Mailer: Monit 5.23.0
MIME-Version: 1.0

Connection failed Service host.example=20

    Date:        Fri, 25 Aug 2017 02:28:31
    Action:      alert
    Host:        web5.host.example
    Description: failed protocol test [HTTP] at [host.example]:80 [TCP/I=
P] -- HTTP: Error receiving data -- Resource temporarily unavailable

Your faithful employee,
Monit"

    ticket_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_1.state.name)
    assert(ticket_1.preferences)
    assert(ticket_1.preferences['monit'])
    assert_equal('alert', ticket_1.preferences['monit']['action'])
    assert_equal('web5.host.example', ticket_1.preferences['monit']['host'])
    assert_equal('failed protocol test [HTTP] at [host.example]:80 [TCP/IP] -- HTTP: Error receiving data -- Resource temporarily unavailable', ticket_1.preferences['monit']['description'])
    assert_equal('host.example', ticket_1.preferences['monit']['service'])
    assert_equal('CRITICAL', ticket_1.preferences['monit']['state'])

    email_raw_string = "Message-Id: <20160131094621.29ECD400F29C-monit-2-2@monitoring.znuny.com>
From: monit@monitoring.example.com
To: admin@example
Subject: monit alert --  Connection succeeded host.example
Date: Thu, 24 Aug 2017 08:30:42 GMT
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: quoted-printable
X-Mailer: Monit 5.23.0
MIME-Version: 1.0

Connection succeeded Service host.example=20

    Date:        Fri, 25 Aug 2017 02:29:13
    Action:      alert
    Host:        web5.host.example
    Description: connection succeeded to [host.example]:80 [TCP/IP]

Your faithful employee,
Monit"

    ticket_1_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('closed', ticket_1_1.state.name)
    assert(ticket_1_1.preferences)
    assert(ticket_1_1.preferences['monit'])
    assert_equal('alert', ticket_1.preferences['monit']['action'])
    assert_equal('web5.host.example', ticket_1_1.preferences['monit']['host'])
    assert_equal('failed protocol test [HTTP] at [host.example]:80 [TCP/IP] -- HTTP: Error receiving data -- Resource temporarily unavailable', ticket_1_1.preferences['monit']['description'])
    assert_equal('host.example', ticket_1_1.preferences['monit']['service'])
    assert_equal('CRITICAL', ticket_1_1.preferences['monit']['state'])
    assert_equal(ticket_1_1.id, ticket_1.id)

    # Resource Limit
    email_raw_string = "Message-Id: <20160131094621.29ECD400F29C-monit-3-1@monitoring.znuny.com>
From: monit@monitoring.example.com
To: admin@example
Subject: monit alert --  Resource limit matched web5.example.net
Date: Thu, 24 Aug 2017 08:30:42 GMT
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: quoted-printable
X-Mailer: Monit 5.23.0
MIME-Version: 1.0

Resource limit matched Service web5.example.net=20

    Date:        Fri, 25 Aug 2017 02:02:08
    Action:      exec
    Host:        web5.example.net
    Description: loadavg(1min) of 10.7 matches resource limit [loadavg(1min) >=
 6.0]

Your faithful employee,
Monit"

    ticket_2, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('new', ticket_2.state.name)
    assert(ticket_2.preferences)
    assert(ticket_2.preferences['monit'])
    assert_equal('exec', ticket_2.preferences['monit']['action'])
    assert_equal('web5.example.net', ticket_2.preferences['monit']['host'])
    assert_equal('loadavg(1min) of 10.7 matches resource limit [loadavg(1min) > 6.0]', ticket_2.preferences['monit']['description'])
    assert_equal('web5.example.net', ticket_2.preferences['monit']['service'])
    assert_equal('CRITICAL', ticket_2.preferences['monit']['state'])

    email_raw_string = "Message-Id: <20160131094621.29ECD400F29C-monit-3-2@monitoring.znuny.com>
From: monit@monitoring.example.com
To: admin@example
Subject: monit alert --  Resource limit succeeded web5.example.net
Date: Thu, 24 Aug 2017 08:30:42 GMT
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: quoted-printable
X-Mailer: Monit 5.23.0
MIME-Version: 1.0

Resource limit succeeded Service web5.example.net=20

    Date:        Fri, 25 Aug 2017 02:05:18
    Action:      alert
    Host:        web5.example.net
    Description: loadavg(1min) check succeeded [current loadavg(1min) =3D 4.8]

Your faithful employee,
Monit"

    ticket_2_1, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal('closed', ticket_2_1.state.name)
    assert(ticket_2_1.preferences)
    assert(ticket_2_1.preferences['monit'])
    assert_equal('exec', ticket_2.preferences['monit']['action'])
    assert_equal('web5.example.net', ticket_2_1.preferences['monit']['host'])
    assert_equal('loadavg(1min) of 10.7 matches resource limit [loadavg(1min) > 6.0]', ticket_2_1.preferences['monit']['description'])
    assert_equal('web5.example.net', ticket_2_1.preferences['monit']['service'])
    assert_equal('CRITICAL', ticket_2_1.preferences['monit']['state'])
    assert_equal(ticket_2_1.id, ticket_2.id)
  end

end
