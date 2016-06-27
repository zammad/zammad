# encoding: utf-8
# rubocop:disable all
require 'test_helper'

class EmailParserTest < ActiveSupport::TestCase
  test 'parse' do
    files = [
      {
        data: IO.binread('test/fixtures/mail1.box'),
        body_md5: '91abe9128a5dcba13f44c01015e229c4',
        params: {
          from: 'John.Smith@example.com',
          from_email: 'John.Smith@example.com',
          from_display_name: '',
          subject: 'CI Daten für PublicView ',
          content_type: 'text/html',
          body: "Hallo Martin,<br><br>wie besprochen hier noch die Daten für die Intranetseite:<br><br>Schriftart/-größe: Verdana 11 Pt wenn von Browser nicht unterstützt oder nicht vorhanden wird Arial 11 Pt genommen<br>Schriftfarbe: Schwarz<br>Farbe für die Balken in der Grafik: D7DDE9 (Blau)<br><br>Wenn noch was fehlt oder du was brauchst sag mir Bescheid.<br><br>Mit freundlichem Gruß<br><br>John Smith<br>Service und Support<br><br>Example Service AG &amp; Co.<br>Management OHG<br>Someware-Str. 4<br>xxxxx Someware<br><br>Tel.: +49 001 7601 462<br>Fax: +49 001 7601 472<br>john.smith@example.com<br><a href=\"http://www.example.com\" target=\"_blank\">www.example.com</a><br><br>OHG mit Sitz in Someware<br>AG: Someware - HRA 4158<br>Geschäftsführung: Tilman Test, Klaus Jürgen Test,<br>Bernhard Test, Ulrich Test<br>USt-IdNr. DE 1010101010<br><br>Persönlich haftende geschäftsführende Gesellschafterin:<br>Marie Test Example Stiftung, Someware<br>Vorstand: Rolf Test<br><br>Persönlich haftende Gesellschafterin:<br>Example Service AG, Someware<br>AG: Someware - HRB xxx<br>Vorstand: Marie Test",
        },
      },
      {
        data: IO.binread('test/fixtures/mail2.box'),
        body_md5: '154c7d3ae7b94f99589df62882841b08',
        params: {
          from: 'Martin Edenhofer <martin@example.com>',
          from_email: 'martin@example.com',
          from_display_name: 'Martin Edenhofer',
          subject: 'aaäöüßad asd',
          body_md5: "äöüß ad asd\n\n-Martin\n\n--\nOld programmers never die. They just branch to a new address.\n",
          content_type: 'text/plain',
          body: "äöüß ad asd

-Martin

--
Old programmers never die. They just branch to a new address.
"
        },
      },
      {
        data: IO.binread('test/fixtures/mail3.box'),
        body_md5: '9b4488001c61cbbe89a1a806665e8881',
        params: {
          from: '"Günther John | Example GmbH" <k.guenther@example.com>',
          from_email: 'k.guenther@example.com',
          from_display_name: 'Günther John | Example GmbH',
          subject: 'Ticket Templates',
          content_type: 'text/html',
          body: "Hallo Martin,<br><br>ich möchte mich gern für den Beta-Test für die Ticket Templates unter XXXX 2.4 anmelden.<br><br>Mit freundlichen Grüßen<br>John Günther<br><br>example.com (<a href=\"http://www.GeoFachDatenServer.de\" target=\"_blank\">http://www.GeoFachDatenServer.de</a>) – profitieren Sie vom umfangreichen Daten-Netzwerk<br><br>_ __ ___ ____________________________ ___ __ _<br><br>Example GmbH<br>Some What<br><br>Sitz: Someware-Straße 9, XXXXX Someware<br><br>M: +49 (0)  XXX XX XX 70<br>T: +49 (0) XXX XX XX 22<br>F: +49 (0) XXX XX XX 11<br>W: <a href=\"http://www.brain-scc.de\" target=\"_blank\">http://www.brain-scc.de</a><br><br>Geschäftsführer: John Smith<br>HRB XXXXXX AG Someware<br>St.-Nr.: 112/107/05858<br><br>ISO 9001:2008 Zertifiziert -Qualitätsstandard mit Zukunft<br>_ __ ___ ____________________________ ___ __ _<br><br>Diese Information ist ausschließlich für den Adressaten bestimmt und kann vertrauliche oder gesetzlich geschützte Informationen enthalten. Wenn Sie nicht der bestimmungsgemäße Adressat sind, unterrichten Sie bitte den Absender und vernichten Sie diese Mail. Anderen als dem bestimmungsgemäßen Adressaten ist es untersagt, diese E-Mail zu lesen, zu speichern, weiterzuleiten oder ihren Inhalt auf welche Weise auch immer zu verwenden.<br><br><b>Von:</b> Fritz Bauer [mailto:me@example.com]<br><b>Gesendet:</b> Donnerstag, 3. Mai 2012 11:51<br><b>An:</b> John Smith<br><b>Cc:</b> Smith, John Marian; johnel.fratczak@example.com; ole.brei@example.com; Günther John | Example GmbH; bkopon@example.com; john.heisterhagen@team.example.com; sven.rocked@example.com; michael.house@example.com; tgutzeit@example.com<br><b>Betreff:</b> Re: OTRS::XXX Erweiterung - Anhänge an CI&#39;s<br><br>Hallo,<br><br>ich versuche an den Punkten anzuknüpfen.<br><br><b>a) LDAP Muster Konfigdatei</b><br><br><a href=\"https://wiki.lab.example.com/doku.php?id=xxxx:start&amp;#ldap\" target=\"_blank\">https://wiki.lab.example.com/doku.php?id=xxxx:start&amp;#ldap</a><br><br>PS: Es gibt noch eine Reihe weiterer Möglichkeiten, vor allem im Bezug auf Agenten-Rechte/LDAP Gruppen Synchronisation. Wenn Ihr hier weitere Informationen benötigt, einfach im Wiki die Aufgabenbeschreibung rein machen und ich kann eine Beispiel-Config dazu legen.<br><br><b>b) Ticket Templates</b><br><br>Wir haben das Paket vom alten Maintainer übernommen, es läuft nun auf XXXX 2.4, XXXX 3.0 und XXXX 3.1. Wir haben das Paket um weitere Funktionen ergänzt und würden es gerne hier in diesen Kreis zum Beta-Test bereit stellen.<br><br>Vorgehen:<br><br>Wer Interesse hat, bitte eine Email an mich und ich versende Zugänge zu den Beta-Test-Systemen. Nach ca. 2 Wochen werden wir die Erweiterungen in der Version 1.0 veröffentlichen.<br><br><b>c) XXXX Entwickler Schulung</b><br><br>Weil es immer wieder Thema war, falls jemand Interesse hat, das XXXX bietet nun auch OTRS Entwickler Schulungen an (<a href=\"http://www.example.com/kurs/xxxx_entwickler/\" target=\"_blank\">http://www.example.com/kurs/xxxx_entwickler/</a>).<br><br><b>d) Genelle Fragen?</b><br><br>Haben sich beim ein oder anderen generell noch Fragen aufgetan?<br><br>Viele Grüße!<br><br>-Fritz<br><br>On May 2, 2012, at 14:25 , John Smith wrote:<br><br>Moin Moin,<br><br>die Antwort ist zwar etwas spät, aber nach der Schulung war ich krank und danach<br>hatte ich viel zu tun auf der Arbeit, sodass ich keine Zeit für XXXX hatte.<br>Ich denke das ist allgemein das Problem, wenn sowas nebenbei gemacht werden muss.<br><br>Wie auch immer, danke für die mail mit dem ITSM Zusatz auch wenn das zur Zeit bei der Example nicht relevant ist.<br><br>Ich habe im XXXX Wiki den Punkt um die Vorlagen angefügt.<br>Ticket Template von John Bäcker<br>Bei uns habe ich das Ticket Template von John Bäcker in der Version 0.1.96 unter XXXX 3.0.10 implementiert.<br><br>Fritz wollte sich auch um das andere Ticket Template Modul kümmern und uns zur Verfügung stellen, welches unter XXXX 3.0 nicht lauffähig sein sollte.<br><br>Im Wiki kann ich die LDAP Muster Konfigdatei nicht finden.<br>Hat die jemand von euch zufälligerweise ?<br><br>Danke und Gruß<br>John Smith<br><br>Am 4. April 2012 08:24 schrieb Smith, John Marian &lt;john.hinz@example.com&gt;:<br>Hallo zusammen,<br><br>ich hoffe Ihr seid noch gut nach Hause gekommen am Mittwoch. Der XXX Kurs Donnerstag und Freitag war noch ganz gut, wobei ich mir den letzten halben Tag eigentlich hätte schenken können.<br><br>Soweit ich weiß arbeitet Ihr nicht mit XXX? Falls doch habe ich hier eine tolle (eigentlich) kostenpflichtige Erweiterung für Euch.<br><br>Es handelt sich um eine programmiertes Paket von der XXXX AG. Die Weitergabe ist legal.<br><br>Mit dem Paket kann man Anhänge an CI’s (Configuration Items) verknüpfen. Das ist sehr praktisch wenn man zum Beispiel Rechnungen an Server, Computern und und und anhängen möchte.<br><br>Der Dank geht an Frank Linden, der uns das Paket kostenlos zur Verfügung gestellt hat.<br><br>Viele Grüße aus Someware<br><br>John<br><br>_________________________<br>SysAdmin<br>John Marian Smith<br>IT-Management<br><br>Example GmbH &amp; Co. KG<br>Der Provider für<br>Mehrwertdienste &amp; YYY<br><br>Someware 23<br>XXXXX Someware<br><br>Tel. (01802) XX XX XX - 42<br>Fax (01802) XX XX XX - 99<br>nur 6 Cent je Anruf aus dem dt. Festnetz,<br>max. 42 Cent pro Min. aus dem Mobilfunknetz<br><br>E-Mail john.smith@Example.de<br>Web <a href=\"http://www.Example.de\" target=\"_blank\">www.Example.de</a><br>Amtsgericht Hannover HRA xxxxxxxx<br>Komplementärin: Example Verwaltungs- GmbH<br>Vertreten durch: Somebody, Somebody<br>Amtsgericht Someware HRB XXX XXX<br><br>_________________________<br>Highlights der Example Contact Center-Suite:<br>Virtual XXX&amp;Power-XXX, Self-Services&amp;XXX-Portale,<br>XXX-/Web-Kundenbefragungen, CRM, PEP, YYY",
        },
      },
      {
        data: IO.binread('test/fixtures/mail4.box'),
        body_md5: '9fab9a0e8523011fde0f3ecd80f8d72c',
        params: {
          from: '"Günther Katja | Example GmbH" <k.guenther@example.com>',
          from_email: 'k.guenther@example.com',
          from_display_name: 'Günther Katja | Example GmbH',
          subject: 'AW: Ticket Templates [Ticket#11168]',
          content_type: 'text/plain',
          body: "Hallo Katja,

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
        data: IO.binread('test/fixtures/mail5.box'),
        body_md5: 'f34033e9a34bb5367062dd5df21115df',
        params: {
          from: 'marc.smith@example.com (Marc Smith)',
          from_email: 'marc.smith@example.com',
          from_display_name: 'Marc Smith',
          subject: 'Re: XXXX Betatest Ticket Templates [Ticket#11162]',
          content_type: 'text/plain',
        },
      },
      {
        data: IO.binread('test/fixtures/mail6.box'),
        body_md5: 'a9416d1457835b10b03abcddbbb7a662',
        params: {
          from: '"Hans BÄKOSchönland" <me@bogen.net>',
          from_email: 'me@bogen.net',
          from_display_name: 'Hans BÄKOSchönland',
          subject: 'utf8: 使って / ISO-8859-1: Priorität"  / cp-1251: Сергей Углицких',
          content_type: 'text/html',
          body: "this is a test<br><br><hr> Compare Cable, DSL or Satellite plans: As low as $2.95. (<a href=\"http://localhost/8HMZENUS/2737??PS=\" target=\"_blank\">http://localhost/8HMZENUS/2737??PS=</a>)<br><br>Test1:–<br>Test2:&amp;<br>Test3:∋<br>Test4:&amp;<br>Test5:="
        },
      },
      {
        data: IO.binread('test/fixtures/mail7.box'),
        body_md5: 'e1ecaf74295ab491e437de5415475ea6',
        params: {
          from: 'Eike.Ehringer@example.com',
          from_email: 'Eike.Ehringer@example.com',
          from_display_name: '',
          subject: 'AW:Installation [Ticket#11392]',
          content_type: 'text/html',
          body: "Hallo.<br>Jetzt muss ich dir noch kurzfristig absagen für morgen.<br>Lass uns evtl morgen Tel.<br><br>Mfg eike<br><br>Martin Edenhofer via Znuny Team --- Installation [Ticket#11392] ---<br><br>Von: &quot;Martin Edenhofer via Znuny Team&quot; &lt;support@example.com&gt;<br>An eike.xx@xx-corpxx.com<br>Datum: Mi., 13.06.2012 14:30<br>Betreff Installation [Ticket#11392] <hr><br><br>Hi Eike,<br>anbei wie gestern telefonisch besprochen Informationen zur Vorbereitung.<br>a) Installation von <a href=\"http://ftp.gwdg.de/pub/misc/zammad/RPMS/fedora/4/zammad-3.0.13-01.noarch.rpm\" target=\"_blank\">http://ftp.gwdg.de/pub/misc/zammad/RPMS/fedora/4/zammad-3.0.13-01.noarch.rpm</a> (dieses RPM ist RHEL kompatible) und dessen Abhängigkeiten.<br>b) Installation von &quot;mysqld&quot; und &quot;perl-DBD-MySQL&quot;.<br>Das wäre es zur Vorbereitung!<br>Bei Fragen nur zu!<br>-Martin<br>--<br>Martin Edenhofer<br>Znuny GmbH // Marienstraße 11 // 10117 Berlin // Germany<br>P: +49 (0) 30 60 98 54 18-0<br>F: +49 (0) 30 60 98 54 18-8<br>W: <a href=\"http://example.com\" target=\"_blank\">http://example.com</a><br>Location: Berlin - HRB 139852 B Amtsgericht Berlin-Charlottenburg<br>Managing Director: Martin Edenhofer",
        },
      },
      {
        data: IO.binread('test/fixtures/mail8.box'),
        body_md5: '28b76ef044d8db3b3ef196011314101b',
        attachments: [
          {
            md5: 'c3ca4aab222eed8a148a716371b70129',
            filename: 'message.html',
          },
        ],
        params: {
          from: 'Franz.Schaefer@example.com',
          from_email: 'Franz.Schaefer@example.com',
          from_display_name: '',
          subject: 'could not rename: ZZZAAuto',
          content_type: 'text/html',
          body: 'Gravierend?<br><br>Mit freundlichen Grüßen<br><br><b>Franz Schäfer</b><br>Manager Information Systems<br><br>Telefon  +49 000 000 8565<br>christian.schaefer@example.com<br><br><b>Example Stoff GmbH</b><br>Fakultaet<br>Düsseldorfer Landstraße395<br>D-00000 Hof<br><u>www.example.com</u><br><br><hr><br>Geschäftsführung/Management Board: Jan Bauer (Vorsitzender/Chairman), Oliver Bauer, Heiko Bauer,Boudewijn Bauer<br>Sitz der Gesellschaft / Registered Office: Hof<br>Registergericht/ Commercial Register of the Local Court: HRB 0000 AG Hof',
        },
      },
      {
        data: IO.binread('test/fixtures/mail9.box'),
        body_md5: '652ed115a40e4abb8232cf1817e89486',
        attachments: [
          {
            md5: '9964263c167ab47f8ec59c48e57cb905',
            filename: 'message.html',
          },
          {
            md5: 'ddbdf67aa2f5c60c294008a54d57082b',
            filename: 'super-seven.jpg',
          },
        ],
        params: {
          from: 'Martin Edenhofer <martin@example.de>',
          from_email: 'martin@example.de',
          from_display_name: 'Martin Edenhofer',
          subject: 'AW: OTRS / Anfrage OTRS Einführung/Präsentation [Ticket#11545]',
          content_type: 'text/html',
          body: 'Enjoy!<br><br>-Martin<br><br>--<br>Old programmers never die. They just branch to a new address.'
        },
      },
      {
        data: IO.binread('test/fixtures/mail10.box'),
        body_md5: '68469244f1a9f3c3fddd46c19efcef7b',
        attachments: [
          {
            md5: '52d946fdf1a9304d0799cceb2fcf0e36',
            filename: 'message.html',
          },
          {
            md5: 'a618d671348735744d4c9a4005b56799',
            filename: 'image001.jpg',
          },
        ],
        params: {
          from: 'Smith Sepp <smith@example.com>',
          from_email: 'smith@example.com',
          from_display_name: 'Smith Sepp',
          subject: 'Gruß aus Oberalteich',
          content_type: 'text/html',
          body: "Herzliche Grüße aus Oberalteich sendet Herrn Smith<br><br>Sepp Smith  - Dipl.Ing. agr. (FH)<br>Geschäftsführer der example Straubing-Bogen<br>Klosterhof 1 | 94327 Bogen-Oberalteich<br>Tel: 09422-505601 | Fax: 09422-505620<br>Internet: <a href=\"http://example-straubing-bogen.de/\" target=\"_blank\">http://example-straubing-bogen.de</a><br>Facebook: <a href=\"http://facebook.de/examplesrbog\" target=\"_blank\">http://facebook.de/examplesrbog</a><br><b></b><b>  -  European Foundation für Quality Management</b>",
        },
      },
      {
        data: IO.binread('test/fixtures/mail11.box'),
        body_md5: '2b6c76ff8e6f6e4d2b77800a64321013',
        attachments: [
          {
            md5: '08660cd33ce8c64b95bcf0207ff6c4d6',
            filename: 'message.html',
          },
        ],
        params: {
          from: 'CYLEX Newsletter <carina.merkant@cylex.de>',
          from_email: 'carina.merkant@cylex.de',
          from_display_name: 'CYLEX Newsletter',
          subject: 'Eine schöne Adventszeit für ZNUNY GMBH - ENTERPRISE SERVICES FÜR OTRS',
          to: 'enjoy_us@znuny.com',
          content_type: 'text/html',
          body: "<a href=\"http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-2/http%3a%2f%2fweb2.cylex.de%2fadvent2012%3fb2b\" target=\"_blank\">http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-2/http%3a%2f%2fweb2.cylex.de%2fadvent2012%3fb2b</a><br>Lieber CYLEX Eintragsinhaber,<br>das Jahr neigt sich dem Ende und die besinnliche Zeit beginnt laut Kalender mit dem<br>1. Advent. Und wie immer wird es in der vorweihnachtlichen Zeit meist beruflich und privat<br>so richtig schön hektisch.<br>Um Ihre Weihnachtsstimmung in Schwung zu bringen kommen wir nun mit unserem Adventskalender ins Spiel. Denn 24 Tage werden Sie unsere netten Geschichten, Rezepte und Gewinnspiele sowie ausgesuchte Geschenktipps und Einkaufsgutscheine online begleiten. Damit lässt sich Ihre Freude auf das Fest garantiert mit jedem Tag steigern.<br><br>Einen gemütlichen Start in die Adventszeit wünscht Ihnen <a href=\"http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-1/http%3a%2f%2fweb2.cylex.de%2fadvent2012%3fb2b\" target=\"_blank\">http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-1/http%3a%2f%2fweb2.cylex.de%2fadvent2012%3fb2b</a><br>Ihr CYLEX Team<br><br>P.S. Damit Sie keinen Tag versäumen, empfehlen wir Ihnen den Link des Adventkalenders (<a href=\"http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-3/http%3a%2f%2fweb2.cylex.de%2fadvent2012%3fb2b\" target=\"_blank\">http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-3/http%3a%2f%2fweb2.cylex.de%2fadvent2012%3fb2b</a>) in<br>       Ihrer Lesezeichen-Symbolleiste zu ergänzen.<br><br>Impressum<br>S.C. CYLEX INTERNATIONAL S.N.C.<br>Sat. Palota 119/A RO 417516 Palota Romania<br>Tel.: +49 208/62957-0 |<br>Geschäftsführer: Francisc Osvald<br>Handelsregister: J05/1591/2009<br>USt.IdNr.: RO26332771<br><br>E-Mail Kontakt<br>Homepage (<a href=\"http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-98/http%3a%2f%2fweb2.cylex.de%2fHomepage%2fHome.asp\" target=\"_blank\">http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-98/http%3a%2f%2fweb2.cylex.de%2fHomepage%2fHome.asp</a>)<br>Newsletter abbestellen (<a href=\"http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-99/http%3a%2f%2fnewsletters.cylex.de%2funsubscribe.aspx%3fuid%3d4134001%26d%3dwww.cylex.de%26e%3denjoy%40znuny.com%26sc%3d3009%26l%3dd\" target=\"_blank\">http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-99/http%3a%2f%2fnewsletters.cylex.de%2funsubscribe.aspx%3fuid%3d4134001%26d%3dwww.cylex.de%26e%3denjoy%40znuny.com%26sc%3d3009%26l%3dd</a>)",
        },
      },
      {
        data: IO.binread('test/fixtures/mail12.box'),
        body_md5: '4aa6a9aac5b327cba682b8be9b8ee3a2',
        attachments: [
          {
            md5: '46cf0f95ea0c8211cbb704e1959b9173',
            filename: 'message.html',
          },
          {
            md5: 'b6e70f587c4b1810facbb20bb5ec69ef',
            filename: 'image002.png',
          },
        ],
        params: {
          from: 'Alex.Smith@example.com',
          from_email: 'Alex.Smith@example.com',
          from_display_name: '',
          subject: 'AW: Agenda [Ticket#11995]',
          to: 'example@znuny.com',
          content_type: 'text/html',
          body: "Hallo Herr Edenhofer,<br><br>möglicherweise haben wir für unsere morgige Veranstaltung ein Problem mit unserer Develop-Umgebung.<br>Der Kollege Smith wollte uns noch die Möglichkeit geben, direkt auf die Datenbank zugreifen zu können, hierzu hat er Freitag noch einige Einstellungen vorgenommen und uns die Zugangsdaten mitgeteilt. Eine der Änderungen hatte aber offenbar zur Folge, dass ein Starten der Develop-Anwendung nicht mehr möglich ist (s. Fehlermeldung)<br><br>Herr Smith ist im Urlaub, er wurde von seinen Datenbank-Kollegen kontaktiert aber offenbar lässt sich nicht mehr 100%ig rekonstruieren, was am Freitag noch verändert wurde.<br>Meinen Sie, dass Sie uns bei der Behebung der o. a. Störung morgen helfen können? Die Datenbank-Kollegen werden uns nach besten Möglichkeiten unterstützen, Zugriff erhalten wir auch.<br><br>Mit freundlichen Grüßen<br><br>Alex Smith<br><br>Abteilung IT-Strategie, Steuerung &amp; Support<br>im Bereich Informationstechnologie<br><br>Example – Example GmbH<br>(Deutsche Example)<br>Longstreet 5<br>11111 Frankfurt am Main<br><br>Telefon: (069) 11 1111 – 11 30<br>Telefon ServiceDesk: (069) 11 1111 – 12 22<br>Telefax: (069) 11 1111 – 14 85<br>Internet: <a href=\"http://www.example.com/\" target=\"_blank\">www.example.com</a><br><br>-----Ursprüngliche Nachricht-----<br>Von: Martin Edenhofer via Znuny Sales [mailto:example@znuny.com]<br>Gesendet: Freitag, 30. November 2012 13:50<br>An: Smith, Alex<br>Betreff: Agenda [Ticket#11995]<br><br>Sehr geehrte Frau Smith,<br><br>ich habe (wie telefonisch avisiert) versucht eine Agenda für nächste Woche zusammen zu stellen.<br><br>Leider ist es mir dies Inhaltlich nur unzureichend gelungen (es gibt zu wenig konkrete Anforderungen im Vorfeld :) ).<br><br>Dadurch würde ich gerne am Dienstag als erste Amtshandlung (mit Herrn Molitor im Boot) die Anforderungen und Ziele der zwei Tage, Mittelfristig und Langfristig definieren. Aufgrund dessen können wir die Agenda der zwei Tage fixieren.Inhaltlich können wir (ich) alles abdecken, von daher gibt es hier keine Probleme. ;)<br><br>Ist dies für Sie so in Ordnung?<br><br>Für Fragen stehe ich gerne zur Verfügung!<br><br>Ich freue mich auf Dienstag,<br><br>  Martin Edenhofer<br><br>--<br>Enterprise Services for OTRS<br><br>Znuny GmbH // Marienstraße 11 // 10117 Berlin // Germany<br><br>P: +49 (0) 30 60 98 54 18-0<br>F: +49 (0) 30 60 98 54 18-8<br>W: <a href=\"http://znuny.com\" target=\"_blank\">http://znuny.com</a><br><br>Location: Berlin - HRB 139852 B Amtsgericht Berlin-Charlottenburg Managing Director: Martin Edenhofer<br><br>-------------------------------------------------------------------------------------------------<br>Rechtsform: GmbH<br>Geschaeftsfuehrer: Dr. Carl Heinz Smith, Dr. Carsten Smith<br>Sitz der Gesellschaft und Registergericht: Frankfurt/Main, HRB 11111<br>Alleiniger Gesellschafter: Bundesrepublik Deutschland,<br>vertreten durch das XXX der Finanzen.",
        },
      },
      {
        data: IO.binread('test/fixtures/mail13.box'),
        body_md5: '58806e006b14b04a535784a5462d09b0',
        attachments: [
          {
            md5: '29cc1679f8a44c72be6be7c1da4278ac',
            filename: 'message.html',
          },
        ],
        params: {
          from: 'thomas.smith@example.com',
          from_email: 'thomas.smith@example.com',
          from_display_name: '',
          subject: 'Antwort: Probleme ADB / Anlegen von Tickets [Ticket#111079]',
          to: 'q1@znuny.com',
          content_type: 'text/html',
          body: 'JA',
        },
      },
      {
        data: IO.binread('test/fixtures/mail14.box'),
        body_md5: '154c7d3ae7b94f99589df62882841b08',
        attachments: [
          {
            md5: '5536be23f647953dc39c1673205d6f5b',
            filename: 'file-1',
          },
          {
            md5: '4eeeae078b920f9d0708353ba0f6aa63',
            filename: 'file-2',
          },
        ],
        params: {
          from: '"Müller, Bernd" <Bernd.Mueller@example.com>',
          from_email: 'Bernd.Mueller@example.com',
          from_display_name: 'Müller, Bernd',
          subject: 'AW: OTRS [Ticket#118192]',
          to: '\'Martin Edenhofer via Znuny Sales\' <sales@znuny.com>',
          content_type: 'text/plain',
          body: "äöüß ad asd\n\n-Martin\n\n--\nOld programmers never die. They just branch to a new address.\n"
        },
      },
      # spam email
      {
        data: IO.binread('test/fixtures/mail15.box'),
        body_md5: '5872ddcdfdf6bfe40f36cd0408fca667',
        attachments: [
          # :preferences=>{"Message-ID"=>"<temp@test>", "Content-Type"=>"application/octet-stream; name=\"\xBC\xA8\xD0\xA7\xB9\xDC\xC0\xED,\xBE\xBF\xBE\xB9\xCB\xAD\xB4\xED\xC1\xCB.xls\"", "Mime-Type"=>"application/octet-stream", "Charset"=>"UTF-8"}}
          # mutt c1abb5fb77a9d2ab2017749a7987c074
          {
            md5: '2ef81e47872d42efce7ef34bfa2de043',
            filename: 'file-1',
          },
        ],
        params: {
          from: '"Sara.Gang" <ynbe.ctrhk@gmail.com>',
          from_email: 'ynbe.ctrhk@gmail.com',
          from_display_name: 'Sara.Gang',
          subject: '绩效管理,究竟谁错了',
          to: 'info42@znuny.com',
          content_type: 'text/plain',
        },
      },
      # spam email
      {
        data: IO.binread('test/fixtures/mail16.box'),
        body_md5: '1ba72c0e2bccdd967a4041083b5fb2b3',
        params: {
          from: nil,
          from_email: 'vipyimin@126.com',
          from_display_name: '',
          subject: '【 直通美国排名第49大学 成功后付费 】',
          to: '"enterprisemobility.apacservice" <enterprisemobility.apacservice@motorola.com>',
        },
      },
      # spam email
      {
        data: IO.binread('test/fixtures/mail17.box'),
        body_md5: 'b2c2af190e7174577e964fad442d90e4',
        params: {
          from: '"都琹" <ghgbwum@185.com.cn>',
          from_email: 'ghgbwum@185.com.cn',
          from_display_name: '都琹',
          subject: '【专业为您注册香港及海外公司（好处多多）】　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　人物                    互联网事百度新闻独家出品传媒换一批捷克戴维斯杯决赛前任命临时领队 前领队因病住院最新:盖世汽车讯 11月6日，通用汽车宣布今年10月份在华销量...减持三特索道 孟凯将全力发展湘鄂情江青摄影作品科技日报讯 （记者过国忠 通讯员陈飞燕）江苏省无线电科学研究所有限公司院士工作站日前正式建...[详细]',
          to: 'info@znuny.com',
        },
      },
      {
        data: IO.binread('test/fixtures/mail18.box'),
        body_md5: '66f20e8557095762ccad9a6cb6f59c3a',
        params: {
          from: 'postmaster@example.com',
          from_email: 'postmaster@example.com',
          from_display_name: '',
          subject: 'Benachrichtung zum =?unicode-1-1-utf-7?Q?+ANw-bermittlungsstatus (Fehlgeschlagen)?=',
          to: 'sales@znuny.org',
        },
      },
      {
        data: IO.binread('test/fixtures/mail19.box'),
        body_md5: 'b9c5addcdc9ded331eb0c66df13b466b',
        params: {
          from: '"我" <>',
          from_email: '"=?GB2312?B?ztI=?=" <>',
          from_display_name: '',
          subject: '《欧美简讯》',
          to: '377861373 <377861373@qq.com>',
        },
      },
      {
        data: IO.binread('test/fixtures/mail20.box'),
        body_md5: '0b982a2aaceee0b9af47882e681ad098',
        params: {
          from: 'Health and Care-Mall <drugs-cheapest8@sicor.com>',
          from_email: 'drugs-cheapest8@sicor.com',
          from_display_name: 'Health and Care-Mall',
          subject: 'The Highest Grade Drugs And EXTRA LOW Price .',
          to: 'info2@znuny.com',
          body: "________________________________________________________________________Yeah but even when they. Beth liî ed her neck as well<br><br>óû5aHw5³½IΨµÁxG⌊o8KHCmς9-Ö½23QgñV6UAD¿ùAX←t¨Lf7⊕®Ir²r½TLA5pYJhjV gPnãM36V®E89RUDΤÅ©ÈI9æsàCΘYEϒAfg∗bT¡1∫rIoiš¦O5oUIN±IsæSØ¹Pp Ÿÿq1FΧ⇑eGOz⌈F³R98y§ 74”lTr8r§HÐæuØEÛPËq VmkfB∫SKNElst4S∃Á8üTðG°í lY9åPu×8&gt;RÒ¬⊕ΜIÙzÙCC4³ÌQEΡºSè!XgŒs.<br>çγ⇓BcwspC L I C K  H E R Eëe3¸ ! (<a href=\"http://pxmzcgy.storeprescription.ru?zz=fkxffti\" target=\"_blank\">http://pxmzcgy.storeprescription.ru?zz=fkxffti</a>)Calm dylan for school today.<br>Closing the nursery with you down. Here and made the mess. Maybe the oï from under his mother. Song of course beth touched his pants.<br>When someone who gave up from here. Feel of god knows what.<br>TBϖ∃M5T5ΕEf2û–N¶ÁvΖ&#39;®⇓∝5SÐçË5 Χ0jΔHbAgþE—2i6A2lD⇑LGjÓnTOy»¦Hëτ9’:Their mother and tugged it seemed like<br>d3RsV¶HÓΘi¯B∂gax1bîgdHä3rýJÿ1aIKÇ² n1jfaTk³Vs395ß C˜lBl‘mxGo0√úXwT8Ya õ8ksa∫f·ℵs”6ÑQ ÍAd7$p32d1e∏æe.0”×61aîΚ63αSMû Nf5ÉCdL∪1i↔xcaa5êR3l6Lc3iãz16só9èU zDE²aEÈ¨gs25ËÞ hE§cl⊃¢¢ÂoÒÂµBw²zF© qÏkõaXUius1r0⊆ d•∈ø$¢Z2F12­8l.07d56PÚl25JAO6<br>45loVóiv1i2ãΥ⌊að⊃d2gÃΥ3™rÎÍu¸aWjO8 n40–Soyè2u¡∅Î3p¢JΜNeÌé×jráÒrΚ 1ÌÓ9AúrAkc8nuEtl22ai‡OB8vSbéσeιõq1+65cw Òs8Uaò4PrsE1y8 〈fMElhϒ⋅Jo8pmzwjˆN¥ wv39aW¡WtsvuU3 1aœ³$éΝnR2OÏ⌉B.∀þc→5Ê9χw5pÃ⁄N fHGFVfE³ãiσjGpa5¶kgg¡ìcWrUq5æakx2h 0Fè4P¸ÕLñrn22ÏoþÝÐHfoRb2eUαw6sñN‾ws¶§3ΒiòX¶¸ofgtHnR⊥3âase9álF¿H5 à6BÁa⊃2iϒsô¡ói ÅkMylÚJ¾ÄoQ–0ℑwvmùþ Ëˆμ&quot;aQ7jVse6Ðf «hÜp$Lâr£3i1tÚ.323h5qP8g0♥÷R÷<br>·iƒPV1Β∋øiF¤RÃa4v3âgL9¢wr¨7ø×aÏû0η þ1àßStuÞ³u7á¡lpÑocEe·SLlrVàXj ⊥Uµ¢F¬48ðov7¨Arm×4ÍcùVwÞe1§⊇N ÂÛ4äaLþZ2ski×5 c€pBlûù6∂olÃfÚwKß3Ñ 4iíla4C³êsREÕ1 ãeIó$âz8t442fG.¸1≤¸2F’Ã152in⊄ Tl©ëC2v7Ci7·X8a×ú5NlþU〉ιicO∑«s·iKN UuϒjSÃj5Ýu÷Jü§pn5°§e¥Û3℘rÆW‡ò J‹S7A1j0sc&amp;ºpkt·qqøiZ56½vn8¨∗eîØQ3+7Î3Š ∑RkLaKXËasÐsÌ2 ïÇ­¶lDäz8oã78wwU–ÀC T6Uûaϒ938sÌ0Gÿ Oxó∈$98‘R2ÂHï5.ÒL6b9θrδÜ92f9j<br>Please matt on his neck. Okay matt huï ed into your mind Since her head to check dylan. Where dylan matt got up there<br>1È±ΑAYQªdN¬ÚϒXT00ÀvI∨ío8-½b®8AΕºV4LgÕ↑7LKtgcEiw­yR5YýæGRA1°I¿0CïCàTiü/þwc0Ax211SÜÂùŒTÁ2êòHpNâùM6È¾0A5Tb»:Simmons and now you really is what. Matt picked up this moment later that.<br>25¯yV9ÙßYeg·↑DnJ3l4tÝæb1os∏jll÷iSÐiwBÎ4n0ú1Ö ªf÷Ña§1løsuÚ8ê 2LCblgvN½o¼oP3wn♠90 FZora&amp;M™xsΚbbÂ ç5Ãξ$Âô·×2iGæ∇1⊇Ξ¬3.0P0κ53VÁö03ÝYz øX¢BAZ4KwdduÜvvuB↑ΒaÄ’THi0—93rZεj0 §rΜÅa2­·§s7¸Ιf 8⇓þolW„6Ýo6yH¥wKZ∧6 21hÒaKJ“ℜs48IÌ ÔÀ¬­$ZΣ¹ü2ñÙ6B42YMZ.Ô¹V¼9f·0å54⌈R8<br>÷w&quot;9N2gBÀaðSê¢s≅gGÔo0Dn4n↵γ7⊗eS7eýxf3Jd q÷CMaÍä³isNMZp zz0˜lΚLw8oë29ww¤§Qu ¥D⌈íaýË¢ésJ8Á¬ 3oùÙ$¦1Nℜ1&gt;Rét7WPM¨.¶8¹D92k5D9∗8≈R l©3ªSj·Ψ8pΣïKùi6rrÔrbÛu¬i2V∗∏v5ª10a27BÁ Ú♦Ξsa9j3χsa¯iΟ Oi℘ml6óféowbz∀wA6ù→ ñ×bàai´wbs♦βGs Ù81i$iÀˆ12⊃2wC82n8o.µ3NJ9S1©Θ0P1Sd<br>What made no one in each time. Mommy was thinking of course beth. Everything you need the same thing<br>PïEVGÿ9srEx⇐9oN3U®yEÎi2OR5kÇÿAΤηνULP¿∧q R5¿FHt7J6E»¯C∅Aå∃aVLu∗¢tT〈2ÃšHq9Né:<br>⊥ÞÞ¨T¦ªBrrC7³2adš6lmzb¨6ai07tdBo×KopíΡÄlj4Hy ÝaÓ1aÖí∉Ós1aá’ 4D­kleowËo3–1ÍwjR≤Π £RhÈafà7≅sù6u2 8NLV$∪⇓»↓1Y¶2µ.vßÈ23ÖS7û0Ün¬Ä m5VKZy3KÎiñë¹DtÚ2HrhGaMvr5ïR«oÂ1namΜwÐãanFu8x7⌈sU E4cva£Âε™s7ΑGO dA35ldñÌèoAξI1wXKïn f¼x¾a∏7ffs†ìÖð 5msC$7Ët¦0z„n÷.it¡T7O8vt5¼8å·<br>Jï1ÏPkáO¶rnùrAo8s5∅z—4Rha1®t˜cq5YΧ ΤQÍraÑ⌋4¹sÜ5²§ ûVBιluwóioL3ëBw£±1¶ 5∈àáa1IÊ2sšÛÛÂ G´7ρ$kJM80∼∠ℵl.J1Km32µÚ⊃5ãé¼§ p°ÿ­A¹NU0c¥xçfo〈Øácm14QGpHEj7lnDPVieV2¶aΠ2H7 ²j26azBSesë1c9 ´2Ù¬l0nò¤oõâRVw¦X´Ï αVõ­a≅σ¼Zs§jJå 3pFN$¾Kf821YΟ7.3ÍY95JΑqŸ0v9ÄQ<br>ñ↑yjPΤ1u6rFwhNeCOϖúd5Γêcne¼a0iTF¹5sxUS0o88ℵªlaÅT℘oOBÀ¹në·­1e∧Kpf υ98ξabp†3sj8â&amp; 9©BolÎAWSo7wNgwø¦mM tteQat0ϖ2s4≡NÇ ÕÆ¦Θ$ùRÓq0·Ã7ª.mt¾³1—uwF57H♣f æ∪HYSjψ3Byš²g¤ndXÀ5tµ¯ò6hZ⇒yÿr8ÿmdowyðdiψ8YΗd0ršŠ N0Ý9aÃ3I¦sQaýê Õ0Y7lZ¯18o∫50Çwµ&quot;©Ζ n6Ü≥a∇lßnsF›J9 ºDΟK$Á4ÉL0S7zÖ.Ta2X3²R995391¡<br>Turning to mess up with. Well that to give her face Another for what she found it then. Since the best to hear<br>GX°♦Ca2isA¾8¡bNÉî8ÂAöÜzΘD∇tNXIfWi–Ap2WYNYF®b ≠7yφDpj6©R04EÂU´ñn7GÆoÌjSÂ³Á∋TC⊥πËO1∗÷©RtS2wE66è­ νÑêéASi21DP“8λV∧W⋅OAÖg6qNtNp1T269XA7¥À²GGI6SEwU2íS3Χ1â!Okay let matt climbed in front door. Well then dropped the best she kissed<br>¤ÊüC&gt;ΦÉí© flQkWMŠtvoÐdV¯rT´ZtlN6R9dZ¾ïLwuD¢9i3B5FdcÆlÝeSwJd KªtDDfoX±evrýwlK7P÷i§e³3vÎzèCe¬Μ♣ΝrGhsáy°72Y!gZpá R6O4O»£ð∋r9ÊZÀdB6iÀeîσ∼ÓrCZ1s ²ú÷I3ÁeÒ¤+⌉CêU »k6wG´c‚¾o60AJoR7Ösd3i¿Ásððpt Øè77añ∀f5np¤nþduE8⇒ È¹SHGJVAtew∇LëtςëDæ 6kÌ8FgQQ⊂R8ÇL2EI2∉iEHÍÉ3 Hÿr5Af1qximςρ‡r6©2jmWv9ÛaWð¸giACÜ¢lM⌋¿k ÊVÚ¸SÓùθçhµ5BΙi∗ttEp8¢EPpSzWJi32UÎn5ìIhgx8n⌉!j∏e5<br>x¯qJ&gt;mC7f 5ºñy1GA4Ý0lCQe09s9u%uksã ψìX5A4g3nu←Τyst7ÍpMhšgÀÖe〉pÚ£n¼YƒŠtÉÚLGizqQ↓c3tÙI œïbXMKÛRSertj×d&quot;OtÊss58®!oo2i FÂWáEWøDDx7hIÕpΦSôBiÒdrUr⇔J&lt;Õa1Αzwt0°p×ià8RÌoHÛ1Än¥7ÿr ¯¥õàDYvO7aká»htì04Πe∂λÇ1 1ÈdUoο°X3fc63¶ e&amp;∪GOxT3CvXcO·e3KËνr3¸y2 26Ëz3Ã∞I± Pì∃zYt6F4e6è⇓va5÷þ9rkΘ3äsKP5R!ιµmz<br>3í1ë&gt;ð2′L 2óB⊥S∩OQMeý∉ÑΦcöè9Tuãa∫drâ5ûMeLk9Ô £æ1OOø9oKnÿψÀWl7HÏ∅i9ρÈÊniâ•ÛeXPxí ´Í5¡SUqtBh7æa5otSZ9pØËÛDpf®ÝÊiÛωbjn¯½Ÿ2gsçh− båÌswxðoSiq8hvtèé6Òh⌈b²S ×6þSVBEFCiøUàds9Ñ¤ΕaÆ§ξÜ,1„wv jw7AMKÈ↔laæG9¦së3«etuB2keDãæìr°¨IeC¾EaÄao÷″∧r&gt;6e¸d9DùÇ,mtSö I∗44A¹RˆêM98zME≅QŸÐX¹4j6 î0n3a1&#39;Êânxpl6d83þJ 06Ð9Eïãýã-28Ú9c4ßrØh7è¥med½♠kcñ3sPk¶2•r!〉QCa<br>ŠeÏÀ&gt;Ãσ½å bpøNERN8eaD6Åns7Abhy±Æü∩ D7sVR8&#39;ºEeÿáDVfc˜3ëu7ÏÆqncË3qdÊ∼4∇sρmi5 6æ¾Êaä°∝TnQb9sdÀMùℑ ∑gMÿ2bNð¶4cä½⊆/4X1κ7¥f1z ϖ1úECzf•1uMbycs1•9¾ts0Tào3hêDmSs3Áe7BíÉrô⋅ãÔ φ8Ä″SSXð¤uúI¸5p58uHp2cß±o∂T©Rrd6sMt∪µµξ!é4Xb<br>Both hands through the fear in front.<br>Wade to give it seemed like this. Yeah but one for any longer. Everything you going inside the kids.",
        },
      },
      {
        data: IO.binread('test/fixtures/mail21.box'),
        body_md5: 'ca181b534e98acc7674a70e8497e9791',
        params: {
          from: 'Viagra Super Force Online <pharmacy_affordable1@ertelecom.ru>',
          from_email: 'pharmacy_affordable1@ertelecom.ru',
          from_display_name: 'Viagra Super Force Online',
          subject: 'World Best DRUGS Mall For a Reasonable Price.',
          to: 'info@znuny.nix',
        },
      },
      {
        data: IO.binread('test/fixtures/mail22.box'),
        body_md5: 'f17142bd7a519bb2b8791dba2539b2f7',
        params: {
          from: 'Gilbertina Suthar <ireoniqla@lipetsk.ru>',
          from_email: 'ireoniqla@lipetsk.ru',
          from_display_name: 'Gilbertina Suthar',
          subject: 'P..E..N-I..S__-E N L A R-G E-M..E..N T-___P..I-L-L..S...Info.',
          to: 'Info <info@znuny.nix>',
          body: "Puzzled by judith bronte dave. Melvin will want her way through with.<br>Continued adam helped charlie cried. Soon joined the master bathroom. Grinned adam rubbed his arms she nodded.<br>Freemont and they talked with beppe.<br>Thinking of bed and whenever adam.<br>Mike was too tired man to hear.<br>I10PQSHEJl2Nwf&amp;tilde;2113S173 &amp;Icirc;1mEbb5N371L&amp;piv;C7AlFnR1&amp;diams;HG64B242&amp;brvbar;M2242zk&amp;Iota;N&amp;rceil;7&amp;rceil;TBN&amp;ETH; T2xPI&amp;ograve;gI2&amp;Atilde;lL2&amp;Otilde;ML&amp;perp;22Sa&amp;Psi;RBreathed adam gave the master bedroom door.<br>Better get charlie took the wall.<br>Charlotte clark smile he saw charlie.<br>Dave and leaned her tears adam.<br>Maybe we want any help me that.<br>Next morning charlie gazed at their father.<br>Well as though adam took out here. Melvin will be more money. Called him into this one last night.<br>Men joined the pickup truck pulled away. Chuck could make sure that.&amp;dagger;p1C?L&amp;thinsp;I?C&amp;ensp;K?88&amp;ensp;5 E R?EEOD ! (<a href=\"11115441111411?jmlfwnwe&amp;ucwkiyyc\" target=\"_blank\">11115441111411?jmlfwnwe&amp;ucwkiyyc</a>)Chuckled adam leaned forward and le? charlie.<br>Just then returned to believe it here.<br>Freemont and pulling out several minutes.",
        },

      },
      {
        data: IO.binread('test/fixtures/mail23.box'),
        body_md5: '545a1b067fd10ac636c20b44f5df8868',
        params: {
          from: 'marketingmanager@nthcpghana.com',
          from_email: 'marketingmanager@nthcpghana.com',
          from_display_name: '',
          subject: nil,
          to: '',
        },
      },
      {
        data: IO.binread('test/fixtures/mail24.box'),
        body_md5: '5872ddcdfdf6bfe40f36cd0408fca667',
        params: {
          from: 'oracle@IG0-1-DB01.example.com',
          from_email: 'oracle@IG0-1-DB01.example.com',
          from_display_name: '',
          subject: 'Regelsets im Test-Status gefunden: 1',
          to: 'support@example.com',
          body: 'no visible content',
        },
        attachments: [
          {
            data: 'RULESET_ID;NAME;ACTIV;RUN_MODE;AUDIT_MODIFY_DATE
387;DP DHL JOIN - EN : Einladung eAC;T;SM;1.09.14
',
            md5: 'a61c76479fdc2f107fe2697ac5ad60ae',
            filename: 'rulesets-report.csv',
          },
        ],
      },
      {
        data: IO.binread('test/fixtures/mail25.box'),
        body_md5: '436f71d8d8a4ffbd3f18fc9de7d7f767',
        params: {
          from: 'oracle@IG0-1-DB01.example.com',
          from_email: 'oracle@IG0-1-DB01.example.com',
          from_display_name: '',
          subject: 'Regelsets im Test-Status gefunden: 1',
          to: 'support@example.com',
          body: "begin 644 rulesets-report.csv
M4E5,15-%5%])1#M.04U%.T%#5$E6.U)53E]-3T1%.T%51$E47TU/1$E&65]$
M051%\"C,X-SM$4\"!$2$P@2D])3B`M($5.(#H@16EN;&%D=6YG(&5!0SM4.U--
*.S$W+C`Y+C$T\"@``
`
end
",
        },
      },
      {
        data: IO.binread('test/fixtures/mail26.box'),
        body_md5: '869353c72cf4efc83536c577eac14c6f',
        params: {
          from: 'gate <team@support.gate.de>',
          from_email: 'team@support.gate.de',
          from_display_name: 'gate',
          subject: 'Ihre Rechnung als PDF-Dokument',
          to: 'Martin Edenhofer <billing@znuny.inc>',
          body: 'Ihre Rechnung als PDF-Dokument',
        },
        attachments: [
          {
            md5: '5d6a49a266987af128bb7254abcb2896',
            filename: 'message.html',
          },
          {
            md5: '552e21cd4cd9918678e3c1a0df491bc3',
            filename: 'invoice_gatede_B181347.txt',
          },
        ],
      },
      {
        data: IO.binread('test/fixtures/mail27.box'),
        body_md5: '5872ddcdfdf6bfe40f36cd0408fca667',
        params: {
          from: 'caoyaoewfzfw@21cn.com',
          from_email: 'caoyaoewfzfw@21cn.com',
          from_display_name: '',
          subject: "\r\n蠭龕中層管理者如何避免角色行为誤区",
          to: 'duan@seat.com.cn, info@znuny.com, jinzh@kingdream.com',
          body: 'no visible content',
        },
        attachments: [
          {
            md5: '498b8ae7b26033af1a08f85644d6695c',
            filename: 'message.html',
          },
        ],
      },
      {
        data: IO.binread('test/fixtures/mail28.box'),
        body_md5: '5872ddcdfdf6bfe40f36cd0408fca667',
        params: {
          from: 'kontakt@example.de',
          from_email: 'kontakt@example.de',
          from_display_name: '',
          subject: 'Bewerbung auf Ihr Stellenangebot',
          to: 'info@znuny.inc',
          body: 'no visible content',
        },
        attachments: [
          {
            md5: '6605d016bda980cdc65fb72d232e4df9',
            filename: 'Znuny GmbH .pdf',
          },
          {
            md5: '6729bc7cbe44fc967a9d953c4af114b7',
            filename: 'Lebenslauf.pdf',
          },
        ],
      },
      {
        data: IO.binread('test/fixtures/mail29.box'),
        body_md5: 'f44654bdf989aac0b9f9b26a895cb51e',
        params: {
          from: 'Example Sales <sales@example.com>',
          from_email: 'sales@example.com',
          from_display_name: 'Example Sales',
          subject: 'Example licensing information: No channel available',
          to: 'info@znuny.inc',
          body: "Dear Mr. Edenhofer,<br>We want to keep you updated on TeamViewer licensing shortages on a regular basis.<br>We would like to inform you that since the last message on 25-Nov-2014 there have been temporary session channel exceedances which make it impossible to establish more sessions. Since the last e-mail this has occurred in a total of 1 cases.<br>Additional session channels can be added at any time. Please visit our TeamViewer Online Shop (<a href=\"https://www.teamviewer.com/en/licensing/update.aspx?channel=D842CS9BF85-P1009645N-348785E76E\" target=\"_blank\">https://www.teamviewer.com/en/licensing/update.aspx?channel=D842CS9BF85-P1009645N-348785E76E</a>) for pricing information.<br>Thank you - and again all the best with TeamViewer!<br>Best regards,<br><i>Your TeamViewer Team</i><br>P.S.: You receive this e-mail because you are listed in our database as person who ordered a TeamViewer license. Please click here (<a href=\"http://www.teamviewer.com/en/company/unsubscribe.aspx?id=1009645&amp;ident=E37682EAC65E8CA6FF36074907D8BC14\" target=\"_blank\">http://www.teamviewer.com/en/company/unsubscribe.aspx?id=1009645&amp;ident=E37682EAC65E8CA6FF36074907D8BC14</a>) to unsubscribe from further e-mails.<br>-----------------------------<br><a href=\"http://www.teamviewer.com\" target=\"_blank\">www.teamviewer.com</a><br><br>TeamViewer GmbH * Jahnstr. 30 * 73037 Göppingen * Germany<br>Tel. 07161 60692 50 * Fax 07161 60692 79<br><br>Registration AG Ulm HRB 534075 * General Manager Holger Felgner",
        },
      },
      {
        data: IO.binread('test/fixtures/mail30.box'),
        body_md5: '9c60b391d161d683fe8d7c96d07d2ab8',
        params: {
          from: 'Manfred Haert <Manfred.Haert@example.com>',
          from_email: 'Manfred.Haert@example.com',
          from_display_name: 'Manfred Haert',
          subject: 'Antragswesen in TesT abbilden',
          to: 'info@znuny.inc',
          body: "Sehr geehrte Damen und Herren,<br><br>wir hatten bereits letztes Jahr einen TesT-Workshop mit Ihrem Herrn XXX durchgeführt und würden nun gerne erneut Ihre Dienste in Anspruch nehmen.<br><br>Mittlerweile setzen wir TesT produktiv ein und würden nun gerne an einem Anwendungsfall (Change-Management) die Machbarkeit des Abbildens eines derzeit &quot;per Papier&quot; durchgeführten Antragswesens in TesT prüfen wollen.<br><br>Wir bitten gerne um ein entsprechendes Angebot.<br><br>Für Rückfragen stehe ich gerne zur Verfügung. Vielen Dank!<br><br>--<br> Freundliche Grüße<br>i.A. Manfred Härt<br><br>Test Somewhere GmbH<br>Ferdinand-Straße 99<br>99073 Korlben<br><b>Bitte beachten Sie die neuen Rufnummern!</b><br>Telefon: 011261 00000-2460<br>Fax: 011261 0000-7460<br>mailto:manfred.haertel@example.com<br><a href=\"http://www.example.com\" target=\"_blank\">http://www.example.com</a><br>JETZT AUCH BEI FACEBOOK !<br><a href=\"https://www.facebook.com/test\" target=\"_blank\">https://www.facebook.com/test</a><br>___________________________________<br>Test Somewhere GmbH<br><br>Diese e-Mail ist ausschließlich für den beabsichtigten Empfänger bestimmt. Sollten Sie irrtümlich diese e-Mail erhalten haben, unterrichten Sie uns bitte umgehend unter kontakt@example.com und vernichten Sie diese Mitteilung einschließlich der ggf. beigefügten Dateien.<br>Weil wir die Echtheit oder Vollständigkeit der in dieser Nachricht enthaltenen Informationen nicht garantieren können, bitten wir um Verständnis, dass wir zu Ihrem und unserem Schutz die rechtliche Verbindlichkeit der vorstehenden Erklärungen ausschließen, soweit wir mit Ihnen keine anders lautenden Vereinbarungen getroffen haben.",
        },
      },
      {
        data: IO.binread('test/fixtures/mail31.box'),
        body_md5: '10484f3b096e85e7001da387c18871d5',
        params: {
          from: '"bertha　mou" <zhengkang@ha.chinamobile.com>',
          from_email: 'zhengkang@ha.chinamobile.com',
          from_display_name: 'bertha　mou',
          subject: '內應力產生与注塑工艺条件之间的关系；',
          to: 'info@znuny.inc',
        },
      },
      {
        data: IO.binread('test/fixtures/mail32.box'),
        body_md5: '6bed82e0d079e521f506e4e5d3529107',
        params: {
          from: '"Dana.Qin" <Dana.Qin6e1@gmail.com>',
          from_email: 'Dana.Qin6e1@gmail.com',
          from_display_name: 'Dana.Qin',
          subject: '发现最美车间主任',
          to: 'info@znuny.inc',
        },
      },
      {
        data: IO.binread('test/fixtures/mail34.box'),
        body_md5: 'b855b615a2c9568ea7708f9dee6b6230',
        params: {
          from: 'Bay <memberbay+12345@members.somewhat>',
          from_email: 'memberbay+12345@members.somewhat',
          from_display_name: 'Bay',
          subject: 'strange email with empty text/plain',
          to: 'bay@example.com',
          body: '<b>some html text</b>',
        },
      },
      {
        data: IO.binread('test/fixtures/mail36.box'),
        body_md5: 'fd3218b540c481e596b7bf283911e349',
        params: {
          from: 'Martin Smith <m.Smith@example.com>',
          from_email: 'm.Smith@example.com',
          from_display_name: 'Martin Smith',
          subject: 'Fw: Zugangsdaten',
          to: 'Martin Edenhofer <me@example.com>',
          body: "--<br>don&#39;t cry - work! (Rainald Goetz)<br><br><b>Gesendet:</b> Mittwoch, 03. Februar 2016 um 12:43 Uhr<br><b>Von:</b> &quot;Martin Smith&quot; &lt;m.Smith@example.com&gt;<br><b>An:</b> linuxhotel@zammad.com<br><b>Betreff:</b> Fw: Zugangsdaten<br><br>--<br>don&#39;t cry - work! (Rainald Goetz)<br><br><b>Gesendet:</b> Freitag, 22. Januar 2016 um 11:52 Uhr<br><b>Von:</b> &quot;Martin Edenhofer&quot; &lt;me@example.com&gt;<br><b>An:</b> m.Smith@example.com<br><b>Betreff:</b> Zugangsdaten<br>Um noch vertrauter zu werden, kannst Du mit einen externen E-Mail Account (z. B. <a href=\"http://web.de\" target=\"_blank\">web.de</a>) mal ein wenig selber “spielen”. :)",
        },
      },
      {
        data: IO.binread('test/fixtures/mail37.box'),
        body_md5: 'dd67e5037a740c053c2bf91f67be072f',
        params: {
          from: 'Example <info@example.com>',
          from_email: 'info@example.com',
          from_display_name: 'Example',
          subject: 'Example: Java 8 Neuerungen',
          to: 'Max Kohl | [example.com] <kohl@example.com>',
          cc: 'Ingo Best <iw@example.com>',
          body: "Tag Max / Ingo!\n",
        },
      },
    ]

    count = 0
    files.each { |file|
      count += 1
      #p "Count: #{count}"
      parser = Channel::EmailParser.new
      data = parser.parse(file[:data])

      #puts '++' + data[:body].to_s + '++'
      # check body
      md5 = Digest::MD5.hexdigest(data[:body])
      #puts "IS #{md5} / should #{file[:body_md5]}"
      assert_equal(file[:body_md5], md5)

      # check params
      file[:params].each { |key, value|
        if key.to_s == 'body_md5'
          #puts 'md5'
          #puts '++' + data[:body].to_s + '++'
          #puts '++' + file[:params][key.to_sym].to_s + '++'
          assert_equal( Digest::MD5.hexdigest( file[:params][key.to_sym].to_s ), Digest::MD5.hexdigest( data[:body].to_s ) )
        else
          assert_equal( file[:params][key.to_sym], data[key.to_sym], "check #{key}" )
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
            #puts 'Attachment:' + attachment_parser.inspect + '-' + file_md5
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
