# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::CheckMk, :aggregate_failures do

  before do
    Setting.set('check_mk_integration', true)
    Setting.set('check_mk_sender', 'check_mk@monitoring.example.com')
  end

  shared_examples 'handling monitoring start and resolution events' do
    it 'handles monitoring start and resolution events' do
      ticket_start, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, start_email)
      expect(ticket_start).to have_attributes(
        state:       have_attributes(name: 'new'),
        preferences: include({ 'check_mk' => check_mk_config })
      )
      ticket_stop, _article_p, _user_p, _mail = Channel::EmailParser.new.process({}, stop_email)
      expect(ticket_stop).to have_attributes(
        id:          ticket_start.id,
        state:       have_attributes(name: 'closed'),
        preferences: include({ 'check_mk' => check_mk_config })
      )
    end
  end

  context 'with a host notification (DOWN)' do
    let(:check_mk_config) do
      {
        'host'    => 'host.tld (host.tld)',
        'address' => '172.16.1.103',
        'state'   => 'DOWN',
      }
    end

    let(:start_email) do
      <<~MAIL
        Message-Id: <20181129101927.22239217@monitoring.example.com>
        From: check_mk@monitoring.example.com
        To: admin@example.com
        Subject: Check_MK: host.tld - UP -> DOWN
        Date: Thu, 29 Nov 2018 11:19:26 +0100 (CET)
        Content-Type: text/html
        Content-Transfer-Encoding: 8bit
        MIME-Version: 1.0

        <table>
        <tr>
        <td>Host</td>
        <td>host.tld (host.tld)</td>
        </tr>
        <tr>
        <td>Event</td>
        <td> UP → DOWN </td>
        </tr>
        <tr>
        <td>Address</td>
        <td>172.16.1.103</td>
        </tr>
        <tr>
        <td>Date / Time</td>
        <td>Thu Nov 29 11:19:26 CET 2018</td>
        </tr>
        <tr>
        <td>Plugin Output</td>
        <td>Test</td>
        </tr>
        <tr>
        <td>Metrics</td>
        <td>Test</td>
        </tr>
        <tr><th colspan="2">Graphs</th></tr>
        <tr><td colspan="2">
        <img src="cid:host.tld-_HOST_-0.png"><img src="cid:host.tld-_HOST_-1.png">
        </td></tr>
        </table>
      MAIL
    end

    let(:stop_email) do
      <<~MAIL
        Message-Id: <20181129101951.41AA6327@monitoring.example.com>
        From: check_mk@monitoring.example.com
        To: admin@example.com
        Subject: Check_MK: host.tld - DOWN -> UP
        Date: Thu, 29 Nov 2018 11:19:51 +0100 (CET)
        Content-Type: text/html
        Content-Transfer-Encoding: 8bit
        MIME-Version: 1.0

        <table>
        <tr>
        <td>Host</td>
        <td>host.tld (host.tld)</td>
        </tr>
        <tr>
        <td>Event</td>
        <td> DOWN → UP </td>
        </tr>
        <tr>
        <td>Address</td>
        <td>172.16.1.103</td>
        </tr>
        <tr>
        <td>Date / Time</td>
        <td>Thu Nov 29 11:19:50 CET 2018</td>
        </tr>
        <tr>
        <td>Plugin Output</td>
        <td>OK - 172.16.1.103: rta 0.281ms, lost 0%</td>
        </tr>
        <tr>
        <td>Metrics</td>
        <td>rta=0.281ms;200.000;500.000;0; pl=0%;80;100;; rtmax=0.491ms;;;; rtmin=0.216ms;;;;</td>
        </tr>
        <tr><th colspan="2">Graphs</th></tr>
        <tr><td colspan="2">
        <img src="cid:host.tld-_HOST_-0.png"><img src="cid:host.tld-_HOST_-1.png">
        </td></tr>
        </table>
      MAIL
    end

    include_examples 'handling monitoring start and resolution events'
  end

  context 'with a service notification (CRIT)' do
    let(:check_mk_config) do
      {
        'host'    => 'another-host.tld (another-host.tld)',
        'service' => 'Filesystem /opt/zammad/tmp',
        'address' => '172.16.230.110',
        'state'   => 'CRITICAL',
      }
    end

    let(:start_email) do
      <<~MAIL
        Message-Id: <20181129101946.4A5E7327@monitoring.example.com>
        From: check_mk@monitoring.example.com
        To: admin@example.com
        Subject: Check_MK: another-host.tld/Filesystem /opt/zammad/tmp OK -> CRIT
        Date: Thu, 29 Nov 2018 11:19:45 +0100 (CET)
        Content-Type: text/html; charset=utf-8
        Content-Transfer-Encoding: 8bit
        MIME-Version: 1.0

        <table>
        <tr>
        <td>Host</td>
        <td>another-host.tld (another-host.tld)</td>
        </tr>
        <tr>
        <td>Service</td>
        <td>Filesystem /opt/zammad/tmp</td>
        </tr>
        <tr>
        <td>Event</td>
        <td> OK → CRITICAL </td>
        </tr>
        <tr>
        <td>Address</td>
        <td>172.16.230.110</td>
        </tr>
        <tr>
        <td>Date / Time</td>
        <td>Thu Nov 29 11:19:45 CET 2018</td>
        </tr>
        <tr>
        <td>Plugin Output</td>
        <td>Test</td>
        </tr>
        <tr>
        <td>Additional Output</td>
        <td></td>
        </tr>
        <tr>
        <td>Host Metrics</td>
        <td>rta=0.188ms;200.000;500.000;0; pl=0%;80;100;; rtmax=0.334ms;;;; rtmin=0.129ms;;;;</td>
        </tr>
        <tr>
        <td>Service Metrics</td>
        <td>Test</td>
        </tr>
        <tr><th colspan="2">Graphs</th></tr>
        <tr><td colspan="2">
        <img src="cid:another-host.tld-Filesystem_x47optx47zammadx47tmp-0.png"><img src="cid:another-host.tld-Filesystem_x47optx47zammadx47tmp-1.png"><img src="cid:another-host.tld-Filesystem_x47optx47zammadx47tmp-2.png"><img src="cid:another-host.tld-Filesystem_x47optx47zammadx47tmp-3.png">
        </td></tr>
        </table>
      MAIL
    end

    let(:stop_email) do
      <<~MAIL
        Message-Id: <20181129102022.4E0F9349@monitoring.example.com>
        From: check_mk@monitoring.example.com
        To: admin@example.com
        Subject: Check_MK: another-host.tld/Filesystem /opt/zammad/tmp CRIT -> OK
        Date: Thu, 29 Nov 2018 11:20:21 +0100 (CET)
        Content-Type: text/html; charset=utf-8
        Content-Transfer-Encoding: 8bit
        MIME-Version: 1.0

        <table>
        <tr>
        <td>Host</td>
        <td>another-host.tld (another-host.tld)</td>
        </tr>
        <tr>
        <td>Service</td>
        <td>Filesystem /opt/zammad/tmp</td>
        </tr>
        <tr>
        <td>Event</td>
        <td> CRITICAL → OK </td>
        </tr>
        <tr>
        <td>Address</td>
        <td>172.16.230.110</td>
        </tr>
        <tr>
        <td>Date / Time</td>
        <td>Thu Nov 29 11:20:21 CET 2018</td>
        </tr>
        <tr>
        <td>Plugin Output</td>
        <td>OK - 3.3% used (34.12 MB of 1.00 GB), trend: +16.24 MB / 24 hours</td>
        </tr>
        <tr>
        <td>Additional Output</td>
        <td></td>
        </tr>
        <tr>
        <td>Host Metrics</td>
        <td>rta=0.233ms;200.000;500.000;0; pl=0%;80;100;; rtmax=0.330ms;;;; rtmin=0.167ms;;;;</td>
        </tr>
        <tr>
        <td>Service Metrics</td>
        <td>/opt/zammad/tmp=34.117188;819.2;921.6;0;1024 fs_size=1024;;;; growth=0;;;; trend=16.241443;;;0;42.666667 inodes_used=13268;1849104.9;1951832.95;0;2054561</td>
        </tr>
        <tr><th colspan="2">Graphs</th></tr>
        <tr><td colspan="2">
        <img src="cid:another-host.tld-Filesystem_x47optx47zammadx47tmp-0.png"><img src="cid:another-host.tld-Filesystem_x47optx47zammadx47tmp-1.png"><img src="cid:another-host.tld-Filesystem_x47optx47zammadx47tmp-2.png"><img src="cid:another-host.tld-Filesystem_x47optx47zammadx47tmp-3.png">
        </td></tr>
        </table>
      MAIL
    end

    include_examples 'handling monitoring start and resolution events'
  end

  context 'with a service notification (WARN)' do
    let(:check_mk_config) do
      {
        'host'    => 'yet-another-host.tld (yet-another-host.tld)',
        'service' => 'Disk IO SUMMARY',
        'address' => '172.16.230.109',
        'state'   => 'WARNING',
      }
    end

    let(:start_email) do
      <<~MAIL
        Message-Id: <20181129102002.E374E349@monitoring.example.com>
        From: check_mk@monitoring.example.com
        To: admin@example.com
        Subject: Check_MK: yet-another-host.tld/Disk IO SUMMARY OK -> WARN
        Date: Thu, 29 Nov 2018 11:20:01 +0100 (CET)
        Content-Type: text/html; charset=utf-8
        Content-Transfer-Encoding: 8bit
        MIME-Version: 1.0

        <table>
        <tr>
        <td>Host</td>
        <td>yet-another-host.tld (yet-another-host.tld)</td>
        </tr>
        <tr>
        <td>Service</td>
        <td>Disk IO SUMMARY</td>
        </tr>
        <tr>
        <td>Event</td>
        <td> OK → WARNING </td>
        </tr>
        <tr>
        <td>Address</td>
        <td>172.16.230.109</td>
        </tr>
        <tr>
        <td>Date / Time</td>
        <td>Thu Nov 29 11:20:01 CET 2018</td>
        </tr>
        <tr>
        <td>Plugin Output</td>
        <td>Test</td>
        </tr>
        <tr>
        <td>Additional Output</td>
        <td></td>
        </tr>
        <tr>
        <td>Host Metrics</td>
        <td>rta=0.167ms;200.000;500.000;0; pl=0%;80;100;; rtmax=0.247ms;;;; rtmin=0.136ms;;;;</td>
        </tr>
        <tr>
        <td>Service Metrics</td>
        <td>Test</td>
        </tr>
        <tr><th colspan="2">Graphs</th></tr>
        <tr><td colspan="2">
        <img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-0.png"><img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-1.png"><img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-2.png"><img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-3.png"><img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-4.png"><img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-5.png"><img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-6.png"><img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-7.png"><img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-8.png">
        </td></tr>
        </table>
      MAIL
    end

    let(:stop_email) do
      <<~MAIL
        Message-Id: <20181129102049.DF193349@monitoring.example.com>
        From: check_mk@monitoring.example.com
        To: admin@example.com
        Subject: Check_MK: yet-another-host.tld/Disk IO SUMMARY WARN -> OK
        Date: Thu, 29 Nov 2018 11:20:48 +0100 (CET)
        Content-Type: text/html; charset=utf-8
        Content-Transfer-Encoding: 8bit
        MIME-Version: 1.0

        <table>
        <tr>
        <td>Host</td>
        <td>yet-another-host.tld (yet-another-host.tld)</td>
        </tr>
        <tr>
        <td>Service</td>
        <td>Disk IO SUMMARY</td>
        </tr>
        <tr>
        <td>Event</td>
        <td> WARNING → OK </td>
        </tr>
        <tr>
        <td>Address</td>
        <td>172.16.230.109</td>
        </tr>
        <tr>
        <td>Date / Time</td>
        <td>Thu Nov 29 11:20:48 CET 2018</td>
        </tr>
        <tr>
        <td>Plugin Output</td>
        <td>OK - Utilization: 1.5%, Read: 12.27 kB/s, Write: 83.33 kB/s, Average Wait: 3.13 ms, Average Read Wait: 6.74 ms, Average Write Wait: 2.22 ms, Latency: 2.46 ms, Average Queue Length: 0.00</td>
        </tr>
        <tr>
        <td>Additional Output</td>
        <td></td>
        </tr>
        <tr>
        <td>Host Metrics</td>
        <td>rta=0.173ms;200.000;500.000;0; pl=0%;80;100;; rtmax=0.332ms;;;; rtmin=0.123ms;;;;</td>
        </tr>
        <tr>
        <td>Service Metrics</td>
        <td>disk_average_read_request_size=10324.164384;;;; disk_average_read_wait=0.00674;;;; disk_average_request_size=16315.733333;;;; disk_average_wait=0.003133;;;; disk_average_write_request_size=17839.721254;;;; disk_average_write_wait=0.002216;;;; disk_latency=0.002456;;;; disk_queue_length=0;;;; disk_read_ios=1.216667;;;; disk_read_throughput=12561.066667;;;; disk_utilization=0.014733;;;; disk_write_ios=4.783333;;;; disk_write_throughput=85333.333333;;;;</td>
        </tr>
        <tr><th colspan="2">Graphs</th></tr>
        <tr><td colspan="2">
        <img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-0.png"><img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-1.png"><img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-2.png"><img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-3.png"><img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-4.png"><img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-5.png"><img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-6.png"><img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-7.png"><img src="cid:yet-another-host.tld-Disk_IO_SUMMARY-8.png">
        </td></tr>
        </table>
      MAIL
    end

    include_examples 'handling monitoring start and resolution events'
  end

end
