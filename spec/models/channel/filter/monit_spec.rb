# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::Monit, :aggregate_failures do

  before do
    Setting.set('monit_integration', true)
    Setting.set('monit_sender', 'monit@monitoring.example.com')
  end

  shared_examples 'handles monitoring start and resolution events' do
    it 'handles monitoring start and resolution events' do
      ticket_start, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, start_email)
      expect(ticket_start).to have_attributes(
        state:       have_attributes(name: 'new'),
        preferences: eq({ 'monit' => monit_config })
      )
      ticket_stop, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, stop_email)
      expect(ticket_stop).to have_attributes(
        id:          ticket_start.id,
        state:       have_attributes(name: 'closed'),
        preferences: eq({ 'monit' => monit_config })
      )
    end

  end

  context 'with unmonitor action' do

    let(:monit_config) do
      {
        'action'      => 'unmonitor',
        'host'        => 'web1.example',
        'description' => 'service restarted 6 times within 3 cycles(s) - unmonitor',
        'service'     => 'php-fpm',
        'state'       => 'CRITICAL',
      }
    end
    let(:start_email) do
      <<~MAIL
        Message-Id: <20160131094621.29ECD400F29C-monit-1-1@monitoring.zammad.com>
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
      MAIL
    end
    let(:stop_email) do
      <<~MAIL
        Message-Id: <20160131094621.29ECD400F29C-monit-1-2@monitoring.zammad.com>
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
        Monit
      MAIL
    end

    include_examples 'handles monitoring start and resolution events'
  end

  context 'with alert action' do

    let(:monit_config) do
      {
        'action'      => 'alert',
        'host'        => 'web5.host.example',
        'description' => 'failed protocol test [HTTP] at [host.example]:80 [TCP/IP] -- HTTP: Error receiving data -- Resource temporarily unavailable',
        'service'     => 'host.example',
        'state'       => 'CRITICAL',
      }
    end
    let(:start_email) do
      <<~MAIL
        Message-Id: <20160131094621.29ECD400F29C-monit-2-1@monitoring.zammad.com>
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
        Monit
      MAIL
    end
    let(:stop_email) do
      <<~MAIL
        Message-Id: <20160131094621.29ECD400F29C-monit-2-2@monitoring.zammad.com>
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
        Monit
      MAIL
    end

    include_examples 'handles monitoring start and resolution events'
  end

  context 'with exec action' do

    let(:monit_config) do
      {
        'action'      => 'exec',
        'host'        => 'web5.example.net',
        'description' => 'loadavg(1min) of 10.7 matches resource limit [loadavg(1min) > 6.0]',
        'service'     => 'web5.example.net',
        'state'       => 'CRITICAL',
      }
    end
    let(:start_email) do
      <<~MAIL
        Message-Id: <20160131094621.29ECD400F29C-monit-3-1@monitoring.zammad.com>
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
        Monit
      MAIL
    end
    let(:stop_email) do
      <<~MAIL
        Message-Id: <20160131094621.29ECD400F29C-monit-3-2@monitoring.zammad.com>
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
        Monit
      MAIL
    end

    include_examples 'handles monitoring start and resolution events'
  end
end
