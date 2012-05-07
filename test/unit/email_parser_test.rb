# encoding: utf-8
require 'test_helper'
 
class EmailParserTest < ActiveSupport::TestCase
  test 'parse' do
    files = [
      {
        :data     => IO.read('test/fixtures/mail1.box'),
        :body_md5 => 'fb6ed5070ffbb821b67b15b83239e1db',
        :params   => {
          :from               => 'John.Smith@example.com',
          :from_email         => 'John.Smith@example.com',
          :from_display_name  => nil,
          :subject            => 'CI Daten für PublicView ',
        },
      },
      {
        :data     => IO.read('test/fixtures/mail2.box'),
        :body_md5 => '25a1ff722497271965b55e52659784a6',
        :params   => {
          :from               => 'Martin Edenhofer <martin@example.com>',
          :from_email         => 'martin@example.com',
          :from_display_name  => 'Martin Edenhofer',
          :subject            => 'aaäöüßad asd',
          :plain_part         => "äöüß ad asd\r\n\r\n-Martin\r\n\r\n--\r\nOld programmers never die. They just branch to a new address.",
        },
      },
      {
        :data     => IO.read('test/fixtures/mail3.box'),
        :body_md5 => '0914848466334919eb33ad4de79d6189',
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
          :plain_part         => "Hallo Katja,

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
    ]

    files.each { |file|
 
      parser = Channel::EmailParser.new
      data = parser.parse( file[:data] )
      
      # check body
      md5 = Digest::MD5.hexdigest( data[:plain_part] )
      assert_equal( file[:body_md5], md5 )

      # check params
      file[:params].each { |key, value|
        if key.to_s == 'plain_part'
          assert_equal( Digest::MD5.hexdigest( file[:params][key.to_sym].to_s ), Digest::MD5.hexdigest( data[key.to_sym].to_s ) )
        else
          assert_equal( file[:params][key.to_sym], data[key.to_sym] )
        end
      }
    }
  end
end