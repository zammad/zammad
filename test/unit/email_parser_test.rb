# encoding: utf-8
require 'test_helper'
 
class EmailParserTest < ActiveSupport::TestCase
  test 'parse' do
    files = [
      {
        :data     => IO.read('test/fixtures/mail1.box'),
        :body_md5 => 'b57d21dcac6b05e1aa67af51a9e4c1ec',
        :params   => {
          :from               => 'John.Smith@example.com',
          :from_email         => 'John.Smith@example.com',
          :from_display_name  => nil,
          :subject            => 'CI Daten für PublicView ',
        },
      },
      {
        :data     => IO.read('test/fixtures/mail2.box'),
        :body_md5 => '548917e0bff0806f9b27c09bbf23bb38',
        :params   => {
          :from               => 'Martin Edenhofer <martin@example.com>',
          :from_email         => 'martin@example.com',
          :from_display_name  => 'Martin Edenhofer',
          :subject            => 'aaäöüßad asd',
          :plain_part_md5     => "äöüß ad asd\n\n-Martin\n\n--\nOld programmers never die. They just branch to a new address.",
        },
      },
      {
        :data     => IO.read('test/fixtures/mail3.box'),
        :body_md5 => '218971f005cddf7a1b70a980507f589d',
        :params   => {
          :from               => '"Günther John | Example GmbH" <k.guenther@example.com>',
          :from_email         => 'k.guenther@example.com',
          :from_display_name  => 'Günther John | Example GmbH',
          :subject            => 'Ticket Templates',
        },
      },
      {
        :data     => IO.read('test/fixtures/mail4.box'),
        :body_md5 => '2f2c3a5c233dbd9658ab37d39469b7d0',
        :params   => {
          :from               => '"Günther Katja | Example GmbH" <k.guenther@example.com>',
          :from_email         => 'k.guenther@example.com',
          :from_display_name  => 'Günther Katja | Example GmbH',
          :subject            => 'AW: Ticket Templates [Ticket#11168]',
          :plain_part_md5     => "Hallo Katja,

super! Ich freu mich!

Wir würden gerne die Präsentation/Einführung in die Ticket Templates per Screensharing oder zumindest per Telefon machen.

Mögliche Termine:
o Do, 10.05.2012 15:00-16:00
o Fr,  11.05.2012 13:00-14:00
o Di,  15.05.2012 17:00-18:00

Über Feedback würde ich mich freuen!

PS: Zur besseren Übersicht habe ich ein Ticket erstellt. :) Im Footer sind unsere geschäftlichen Kontaktdaten (falls diese irgendwann einmal benötigt werden sollten), mehr dazu in ein paar Tagen.

Liebe Grüße!

 -Martin
",
        },
      },
      {
        :data     => IO.read('test/fixtures/mail5.box'),
        :body_md5 => '51364a306362f513f53f2bbea7820f37',
        :params   => {
          :from               => 'marc.smith@example.com (Marc Smith)',
          :from_email         => 'marc.smith@example.com',
          :from_display_name  => 'Marc Smith',
          :subject            => 'Re: XXXX Betatest Ticket Templates [Ticket#11162]',
        },
      },
      {
        :data     => IO.read('test/fixtures/mail6.box'),
        :body_md5 => '1fc492b8d762d82f861dbb70b7cf7610',
        :params   => {
          :from               => '"Hans BÄKOSchönland" <me@bogen.net>',
          :from_email         => 'me@bogen.net',
          :from_display_name  => 'Hans BÄKOSchönland',
          :subject            => 'utf8: 使って / ISO-8859-1: Priorität"  / cp-1251: Сергей Углицких',
          :plain_part         => "this is a test [1]Compare Cable, DSL or Satellite plans: As low as $2.95. 

Test1:8

Test2:&amp;

Test3:&ni;

Test4:&amp;

Test5:=


[1] http://localhost/8HMZENUS/2737??PS=
"
        },
      },
      {
        :data     => IO.read('test/fixtures/mail7.box'),
        :body_md5 => '775a69acf8ba0495712a3953f2ecff6a',
        :params   => {
          :from               => 'Eike.Ehringer@example.com',
          :from_email         => 'Eike.Ehringer@example.com',
          :from_display_name  => nil,
          :subject            => 'AW:Installation [Ticket#11392]',
          :plain_part_md5     => "Hallo.
Jetzt muss ich dir noch kurzfristig absagen für morgen.
Lass uns evtl morgen Tel.

Mfg eike 

Martin Edenhofer via Znuny Team --- Installation [Ticket#11392] --- 
Von:&quot;Martin Edenhofer via Znuny Team&quot; &lt;support@example.com&gt;Aneike.xx@xx-corpxx.comDatum:Mi., 13.06.2012 14:30BetreffInstallation [Ticket#11392]
Hi Eike,
anbei wie gestern telefonisch besprochen Informationen zur Vorbereitung.
a) Installation von http://ftp.gwdg.de/pub/misc/zammad/RPMS/fedora/4/zammad-3.0.13-01.noarch.rpm (dieses RPM ist RHEL kompatible) und dessen Abhängigkeiten.
b) Installation von &quot;mysqld&quot; und &quot;perl-DBD-MySQL&quot;.
Das wäre es zur Vorbereitung!
Bei Fragen nur zu!
-Martin
--
Martin Edenhofer
Znuny GmbH // Marienstraße 11 // 10117 Berlin // Germany
P: +49 (0) 30 60 98 54 18-0
F: +49 (0) 30 60 98 54 18-8
W: http://example.com 
Location: Berlin - HRB 139852 B Amtsgericht Berlin-Charlottenburg
Managing Director: Martin Edenhofer


",
        },
      },
      {
        :data         => IO.read('test/fixtures/mail8.box'),
        :body_md5     => 'b506a6aa5f76e608c982d15a449ee163',
        :attachments  => [
          {
            :md5      => '635e03d2ddde520b925262c8ffd03234',
            :filename => 'message.html',            
          },
        ],
        :params   => {
          :from               => 'Franz.Schaefer@example.com',
          :from_email         => 'Franz.Schaefer@example.com',
          :from_display_name  => nil,
          :subject            => 'could not rename: ZZZAAuto',
          :plain_part_md5     => "Gravierend?

Mit freundlichen Grüßen

Franz Schäfer
Manager Information Systems

Telefon 
+49 000 000 8565
franz.schaefer@example.com

Example Stoff GmbH
Fakultaet
Düsseldorfer Landstraße 395
D-00000 Hof
www.example.com


Geschäftsführung/Management Board: Jan Bauer (Vorsitzender/Chairman), 
Oliver Bauer, Heiko Bauer, Boudewijn Bauer
Sitz der Gesellschaft / Registered Office: Hof
Registergericht / Commercial Register of the Local Court: HRB 0000 AG 
Hof",
        },
      },
      {
        :data         => IO.read('test/fixtures/mail9.box'),
        :body_md5     => 'd2f0a663dd0e371e9f0c3d5688441a6f',
        :attachments  => [
          {
            :md5      => '9964263c167ab47f8ec59c48e57cb905',
            :filename => 'message.html',
          },
          {
            :md5      => 'ddbdf67aa2f5c60c294008a54d57082b',
            :filename => 'super-seven.jpg',
          },
        ],
        :params   => {
          :from               => 'Martin Edenhofer <martin@example.de>',
          :from_email         => 'martin@example.de',
          :from_display_name  => 'Martin Edenhofer',
          :subject            => 'AW: OTRS / Anfrage OTRS Einführung/Präsentation [Ticket#11545]',
          :plain_part         => "Enjoy!\n\n-Martin\n\n--\nOld programmers never die. They just branch to a new address."
        },
      },
    ]

    files.each { |file|
 
      parser = Channel::EmailParser.new
      data = parser.parse( file[:data] )
      
      # check body
      md5 = Digest::MD5.hexdigest( data[:plain_part] )
      assert_equal( file[:body_md5], md5 )

      # check params
      file[:params].each { |key, value|
        if key.to_s == 'plain_part_md5'
#          puts 'md5'
#          puts '++' + data[:plain_part].to_s + '++'
#          puts '++' + file[:params][key.to_sym].to_s + '++'
          assert_equal( Digest::MD5.hexdigest( file[:params][key.to_sym].to_s ), Digest::MD5.hexdigest( data[:plain_part].to_s ) )
        else
          assert_equal( file[:params][key.to_sym], data[key.to_sym] )
        end
      }

      # check attachments
      if file[:attachments]
        attachment_count_config = file[:attachments].length 
        attachment_count_email = 0
        file[:attachments].each { |attachment|
          attachment_count_email += 1
          found = false
          data[:attachments].each { |attachment_parser|
            next if found
            file_md5 = Digest::MD5.hexdigest( attachment_parser[:data] )
            if attachment[:md5] == file_md5
              found = true
              assert_equal( attachment[:filename], attachment_parser[:filename] )
            end
          }
          if !found
            assert( false, "Attachment not found! MD5: #{attachment[:md5]} - #{attachment[:filename].to_s}" )
          end
        }
        assert_equal( attachment_count_config, attachment_count_email )
      end
    }
  end
end