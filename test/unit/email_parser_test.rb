# encoding: utf-8
# rubocop:disable all
require 'test_helper'

class EmailParserTest < ActiveSupport::TestCase
  test 'parse' do
    files = [
      {
        data: IO.binread('test/fixtures/mail1.box'),
        body_md5: 'e5cf748bf60cbbf324ee20314750fdf7',
        params: {
          from: 'John.Smith@example.com',
          from_email: 'John.Smith@example.com',
          from_display_name: '',
          subject: 'CI Daten für PublicView ',
          content_type: 'text/html',
          body: "<div>
<div>Hallo Martin,</div><p>&nbsp;</p><div>wie besprochen hier noch die Daten für die Intranetseite:</div><p>&nbsp;</p><div>Schriftart/-größe: Verdana 11 Pt wenn von Browser nicht unterstützt oder nicht vorhanden wird Arial 11 Pt genommen</div><div>Schriftfarbe: Schwarz</div><div>Farbe für die Balken in der Grafik: D7DDE9 (Blau)</div><p>&nbsp;</p><div>Wenn noch was fehlt oder du was brauchst sag mir Bescheid.</div><p>&nbsp;</p><div>Mit freundlichem Gruß<br><br>John Smith<br>Service und Support<br><br>Example Service AG &amp; Co. </div><div>Management OHG<br>Someware-Str. 4<br>xxxxx Someware<br><br>
</div><div>Tel.: +49 001 7601 462<br>Fax: +49 001 7601 472 </div><div>john.smith@example.com</div><div>
<a href=\"http://www.example.com\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">www.example.com</a>
</div><div>
<br>OHG mit Sitz in Someware<br>AG: Someware - HRA 4158<br>Geschäftsführung: Tilman Test, Klaus Jürgen Test, </div><div>Bernhard Test, Ulrich Test<br>USt-IdNr. DE 1010101010<br><br>Persönlich haftende geschäftsführende Gesellschafterin: </div><div>Marie Test Example Stiftung, Someware<br>Vorstand: Rolf Test<br><br>Persönlich haftende Gesellschafterin: </div><div>Example Service AG, Someware<br>AG: Someware - HRB xxx<br>Vorstand: Marie Test </div><p>&nbsp;</p></div>",
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
        body_md5: '4681e5d8ee07ea0b53dfeaf5789c5a00',
        params: {
          from: '"Günther John | Example GmbH" <k.guenther@example.com>',
          from_email: 'k.guenther@example.com',
          from_display_name: 'Günther John | Example GmbH',
          subject: 'Ticket Templates',
          content_type: 'text/html',
          body: "<div>
<p>Hallo Martin,</p><p>&nbsp;</p><p>ich möchte mich gern für den Beta-Test für die Ticket Templates unter XXXX 2.4 anmelden.</p><p>&nbsp;</p><div> <p>&nbsp;</p><p>Mit freundlichen Grüßen</p><p>John Günther</p><p>&nbsp;</p><p>example.com (<a href=\"http://www.GeoFachDatenServer.de\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://www.GeoFachDatenServer.de</a>) – profitieren Sie vom umfangreichen Daten-Netzwerk </p><p>&nbsp;</p><p>_ __ ___ ____________________________ ___ __ _</p><p>&nbsp;</p><p>Example GmbH</p><p>Some What</p><p>&nbsp;</p><p>Sitz: Someware-Straße 9, XXXXX Someware</p><p>&nbsp;</p><p>M: +49 (0) XXX XX XX 70</p><p>T: +49 (0) XXX XX XX 22</p><p>F: +49 (0) XXX XX XX 11</p><p>W: <a href=\"http://www.example.de\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://www.example.de</a></p><p>&nbsp;</p><p>Geschäftsführer: John Smith</p><p>HRB XXXXXX AG Someware</p><p>St.-Nr.: 112/107/05858</p><p>&nbsp;</p><p>ISO 9001:2008 Zertifiziert -Qualitätsstandard mit Zukunft</p><p>_ __ ___ ____________________________ ___ __ _</p><p>&nbsp;</p><p>Diese Information ist ausschließlich für den Adressaten bestimmt und kann vertrauliche oder gesetzlich geschützte Informationen enthalten. Wenn Sie nicht der bestimmungsgemäße Adressat sind, unterrichten Sie bitte den Absender und vernichten Sie diese Mail. Anderen als dem bestimmungsgemäßen Adressaten ist es untersagt, diese E-Mail zu lesen, zu speichern, weiterzuleiten oder ihren Inhalt auf welche Weise auch immer zu verwenden.</p></div><p>&nbsp;</p><div>
<span class=\"js-signatureMarker\"></span><p><b>Von:</b> Fritz Bauer [mailto:me@example.com] <br><b>Gesendet:</b> Donnerstag, 3. Mai 2012 11:51<br><b>An:</b> John Smith<br><b>Cc:</b> Smith, John Marian; johnel.fratczak@example.com; ole.brei@example.com; Günther John | Example GmbH; bkopon@example.com; john.heisterhagen@team.example.com; sven.rocked@example.com; michael.house@example.com; tgutzeit@example.com<br><b>Betreff:</b> Re: OTRS::XXX Erweiterung - Anhänge an CI's</p></div><p>&nbsp;</p><p>Hallo,</p><div> <p>&nbsp;</p></div><div>
<p>ich versuche an den Punkten anzuknüpfen.</p></div><div> <p>&nbsp;</p></div><div>
<p><b>a) LDAP Muster Konfigdatei</b></p></div><div> <p>&nbsp;</p></div><div>
<p><a href=\"https://wiki.lab.example.com/doku.php?id=xxxx:start&amp;#ldap\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">https://wiki.lab.example.com/doku.php?id=xxxx:start&amp;#ldap</a></p></div><div> <p>&nbsp;</p></div><div>
<p>PS: Es gibt noch eine Reihe weiterer Möglichkeiten, vor allem im Bezug auf Agenten-Rechte/LDAP Gruppen Synchronisation. Wenn Ihr hier weitere Informationen benötigt, einfach im Wiki die Aufgabenbeschreibung rein machen und ich kann eine Beispiel-Config dazu legen.</p></div><div>
<p>&nbsp;</p></div><div> <p>&nbsp;</p></div><div>
<p><b>b) Ticket Templates</b></p></div><div>
<p>Wir haben das Paket vom alten Maintainer übernommen, es läuft nun auf XXXX 2.4, XXXX 3.0 und XXXX 3.1. Wir haben das Paket um weitere Funktionen ergänzt und würden es gerne hier in diesen Kreis zum Beta-Test bereit stellen.</p></div><div> <p>&nbsp;</p></div><div>
<p>Vorgehen:</p></div><div>
<p>Wer Interesse hat, bitte eine Email an mich und ich versende Zugänge zu den Beta-Test-Systemen. Nach ca. 2 Wochen werden wir die Erweiterungen in der Version 1.0 veröffentlichen.</p></div><div> <p>&nbsp;</p></div><div> <p>&nbsp;</p></div><div>
<p><b>c) XXXX Entwickler Schulung</b></p></div><div>
<p>Weil es immer wieder Thema war, falls jemand Interesse hat, das XXXX bietet nun auch OTRS Entwickler Schulungen an (<a href=\"http://www.example.com/kurs/xxxx_entwickler/\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://www.example.com/kurs/xxxx_entwickler/</a>).</p></div><div> <p>&nbsp;</p></div><div> <p>&nbsp;</p></div><div>
<p><b>d) Genelle Fragen?</b></p></div><div>
<p>Haben sich beim ein oder anderen generell noch Fragen aufgetan?</p></div><div> <p>&nbsp;</p></div><div> <p>&nbsp;</p></div><div>
<p>Viele Grüße!</p></div><div> <p>&nbsp;</p></div><div>
<div>
<p>-Fritz</p></div><p>On May 2, 2012, at 14:25 , John Smith wrote:<br><br></p><p>Moin Moin,<br><br>die Antwort ist zwar etwas spät, aber nach der Schulung war ich krank und danach<br>hatte ich viel zu tun auf der Arbeit, sodass ich keine Zeit für XXXX hatte.<br>Ich denke das ist allgemein das Problem, wenn sowas nebenbei gemacht werden muss.<br><br>Wie auch immer, danke für die mail mit dem ITSM Zusatz auch wenn das zur Zeit bei der Example nicht relevant ist.<br><br>Ich habe im XXXX Wiki den Punkt um die Vorlagen angefügt.<br>Ticket Template von John Bäcker<br>Bei uns habe ich das Ticket Template von John Bäcker in der Version 0.1.96 unter XXXX 3.0.10 implementiert. <br><br>Fritz wollte sich auch um das andere Ticket Template Modul kümmern und uns zur Verfügung stellen, welches unter XXXX 3.0 nicht lauffähig sein sollte.<br><br>Im Wiki kann ich die LDAP Muster Konfigdatei nicht finden.<br>Hat die jemand von euch zufälligerweise ?<br><br>Danke und Gruß<br>John Smith<br><br>Am 4. April 2012 08:24 schrieb Smith, John Marian &lt;john.smith@example.com&gt;:<br>Hallo zusammen,<br><br>ich hoffe Ihr seid noch gut nach Hause gekommen am Mittwoch. Der XXX Kurs Donnerstag und Freitag war noch ganz gut, wobei ich mir den letzten halben Tag eigentlich hätte schenken können.<br><br>Soweit ich weiß arbeitet Ihr nicht mit XXX? Falls doch habe ich hier eine tolle (eigentlich) kostenpflichtige Erweiterung für Euch.<br><br>Es handelt sich um eine programmiertes Paket von der XXXX AG. Die Weitergabe ist legal.<br><br>Mit dem Paket kann man Anhänge an CI’s (Configuration Items) verknüpfen. Das ist sehr praktisch wenn man zum Beispiel Rechnungen an Server, Computern und und und anhängen möchte.<br><br>Der Dank geht an Frank Linden, der uns das Paket kostenlos zur Verfügung gestellt hat.<br><br>Viele Grüße aus Someware<br><br>John<br><br>_________________________<br>SysAdmin<br>John Marian Smith<br>IT-Management<br><br>Example GmbH &amp; Co. KG<br>Der Provider für<br>Mehrwertdienste &amp; YYY<br><br>Someware 23<br>XXXXX Someware<br><br>Tel. (01802) XX XX XX - 42<br>Fax (01802) XX XX XX - 99<br>nur 6 Cent je Anruf aus dem dt. Festnetz,<br>max. 42 Cent pro Min. aus dem Mobilfunknetz<br><br>E-Mail john.smith@Example.de<br>Web <a href=\"http://www.Example.de\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">www.Example.de</a><br>Amtsgericht Hannover HRA xxxxxxxx<br>Komplementärin: Example Verwaltungs- GmbH<br>Vertreten durch: Somebody, Somebody<br>Amtsgericht Someware HRB XXX XXX<br><br>_________________________ <br>Highlights der Example Contact Center-Suite:<br>Virtual XXX&amp;Power-XXX, Self-Services&amp;XXX-Portale,<br>XXX-/Web-Kundenbefragungen, CRM, PEP, YYY</p></div></div>",
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
        body_md5: 'a05afcf7de7be17e74f191a58974f682',
        params: {
          from: '"Hans BÄKOSchönland" <me@bogen.net>',
          from_email: 'me@bogen.net',
          from_display_name: 'Hans BÄKOSchönland',
          subject: 'utf8: 使って / ISO-8859-1: Priorität"  / cp-1251: Сергей Углицких',
          content_type: 'text/html',
          body: "<p>this is a test</p><br><hr> Compare Cable, DSL or Satellite plans: As low as $2.95. (<a href=\"http://localhost/8HMZENUS/2737??PS=\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://localhost/8HMZENUS/2737??PS=</a>) <br> <br> Test1:– <br> Test2:&amp; <br> Test3:∋ <br> Test4:&amp; <br> Test5:=",
        },
      },
#<span class="js-signatureMarker"></span><div><br>

      {
        data: IO.binread('test/fixtures/mail7.box'),
        body_md5: 'b779b65c7d90aa5e350d37998a6c5fc6',
        params: {
          from: 'Eike.Ehringer@example.com',
          from_email: 'Eike.Ehringer@example.com',
          from_display_name: '',
          subject: 'AW:Installation [Ticket#11392]',
          content_type: 'text/html',
          body:"Hallo.<br>Jetzt muss ich dir noch kurzfristig absagen für morgen.<br>Lass uns evtl morgen Tel.<br><br>Mfg eike <br><br><div>
<div>Martin Edenhofer via Znuny Team --- Installation [Ticket#11392] ---</div><div>
<br><table border=\"0\" cellspacing=\"0\" cellpadding=\"0\">
<tr>
<td>Von:</td>
<td>\"Martin Edenhofer via Znuny Team\" &lt;support@example.com&gt;</td>
</tr>
<tr>
<td>An</td>
<td>eike.xx@xx-corpxx.com</td>
</tr>
<tr>
<td>Datum:</td>
<td>Mi., 13.06.2012 14:30</td>
</tr>
<tr>
<td>Betreff</td>
<td>Installation [Ticket#11392]</td>
</tr>
</table>
<hr>
<br><pre>Hi Eike,

anbei wie gestern telefonisch besprochen Informationen zur Vorbereitung.

a) Installation von <a href=\"http://ftp.gwdg.de/pub/misc/zammad/RPMS/fedora/4/zammad-3.0.13-01.noarch.rpm\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://ftp.gwdg.de/pub/misc/zammad/RPMS/fedora/4/zammad-3.0.13-01.noarch.rpm</a> (dieses RPM ist RHEL kompatible) und dessen Abhängigkeiten.

b) Installation von \"mysqld\" und \"perl-DBD-MySQL\".

Das wäre es zur Vorbereitung!

Bei Fragen nur zu!

 -Martin

--
Martin Edenhofer

Znuny GmbH // Marienstraße 11 // 10117 Berlin // Germany

P: +49 (0) 30 60 98 54 18-0
F: +49 (0) 30 60 98 54 18-8
W: <a href=\"http://example.com\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://example.com</a> 

Location: Berlin - HRB 139852 B Amtsgericht Berlin-Charlottenburg
Managing Director: Martin Edenhofer

</pre>
</div></div>",
        },
      },
      {
        data: IO.binread('test/fixtures/mail8.box'),
        body_md5: 'd540b6f1a7b25468c1bc854ebc4c43fe',
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
          body: "<img src=\"cid:_1_08FC9B5808FC7D5C004AD64FC1257A28\">
<br>
<br>Gravierend?<br> <table>
<tr>
<td>Mit freundlichen Grüßen</td>
</tr>
</table>
<br>
<table>
<tr>
<td>
<b>Franz Schäfer</b>
</td>
</tr>
<tr>
<td>Manager Information Systems</td>
</tr>
</table>
<br>
<table>
<tr>
<td> Telefon </td>
<td> +49 000 000 8565 </td>
</tr>
<tr>
<td colspan=\"2\">christian.schaefer@example.com</td>
</tr>
</table>
<br>
<table>
<tr>
<td>
<b>Example Stoff GmbH</b>
</td>
</tr>
<tr>
<td> Fakultaet </td>
</tr>
<tr>
<td> Düsseldorfer Landstraße 395 </td>
</tr>
<tr>
<td> D-00000 Hof </td>
</tr>
<tr>
<td><a href=\"http://www.example.com\" rel=\"nofollow noreferrer noopener\" target=\"_blank\"><u>www.example.com</u></a></td>
</tr>
</table>
<br>
<table>
<tr>
<td>
<hr>
</td>
</tr>
<tr>
<td> Geschäftsführung/Management Board: Jan Bauer (Vorsitzender/Chairman), Oliver Bauer, Heiko Bauer, Boudewijn Bauer </td>
</tr>
<tr>
<td> Sitz der Gesellschaft / Registered Office: Hof </td>
</tr>
<tr>
<td>Registergericht / Commercial Register of the Local Court: HRB 0000 AG Hof</td>
</tr>
</table>",
        },
      },
      {
        data: IO.binread('test/fixtures/mail9.box'),
        body_md5: '64675a479f80a674eb7c08e385c3622a',
        attachments: [
          {
            md5: '9964263c167ab47f8ec59c48e57cb905',
            filename: 'message.html',
          },
          {
            md5: 'ddbdf67aa2f5c60c294008a54d57082b',
            filename: 'super-seven.jpg',
            cid: '485376C9-2486-4351-B932-E2010998F579@home',
          },
        ],
        params: {
          from: 'Martin Edenhofer <martin@example.de>',
          from_email: 'martin@example.de',
          from_display_name: 'Martin Edenhofer',
          subject: 'AW: OTRS / Anfrage OTRS Einführung/Präsentation [Ticket#11545]',
          content_type: 'text/html',
          body: "Enjoy!<div>
<br><div>-Martin<br><span class=\"js-signatureMarker\"></span><br>--<br>Old programmers never die. They just branch to a new address.<br>
</div><br><div><img src=\"cid:485376C9-2486-4351-B932-E2010998F579@home\" style=\"width:640px;height:425px;\"></div></div>",
        },
      },
      {
        data: IO.binread('test/fixtures/mail10.box'),
        body_md5: '47d41fa38028d5fb02c7d041da60ba1f',
        attachments: [
          {
            md5: '52d946fdf1a9304d0799cceb2fcf0e36',
            filename: 'message.html',
          },
          {
            md5: 'a618d671348735744d4c9a4005b56799',
            filename: 'image001.jpg',
            cid: 'image001.jpg@01CDB132.D8A510F0',
          },
        ],
        params: {
          from: 'Smith Sepp <smith@example.com>',
          from_email: 'smith@example.com',
          from_display_name: 'Smith Sepp',
          subject: 'Gruß aus Oberalteich',
          content_type: 'text/html',
          body: "<div>
<p>Herzliche Grüße aus Oberalteich sendet Herrn Smith</p><p>&nbsp;</p><p>Sepp Smith - Dipl.Ing. agr. (FH)</p><p>Geschäftsführer der example Straubing-Bogen</p><p>Klosterhof 1 | 94327 Bogen-Oberalteich</p><p>Tel: 09422-505601 | Fax: 09422-505620</p><p>Internet: <a href=\"http://example-straubing-bogen.de/\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://example-straubing-bogen.de</a></p><p>Facebook: <a href=\"http://facebook.de/examplesrbog\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://facebook.de/examplesrbog</a></p><p><b><img border=\"0\" src=\"cid:image001.jpg@01CDB132.D8A510F0\" alt=\"Beschreibung: Beschreibung: efqmLogo\" style=\"width:60px;height:19px;\"></b><b> - European Foundation für Quality Management</b></p><p>&nbsp;</p></div>",
        },
      },
      {
        data: IO.binread('test/fixtures/mail11.box'),
        body_md5: 'b211c9c28282ad0dd3fccbbf37d9928d',
        attachments: [
          {
            md5: '08660cd33ce8c64b95bcf0207ff6c4d6',
            filename: 'message.html',
          },
        ],
        params: {
          "reply-to": 'serviceteam@cylex.de',
          from: 'CYLEX Newsletter <carina.merkant@cylex.de>',
          from_email: 'carina.merkant@cylex.de',
          from_display_name: 'CYLEX Newsletter',
          subject: 'Eine schöne Adventszeit für ZNUNY GMBH - ENTERPRISE SERVICES FÜR OTRS',
          to: 'enjoy_us@znuny.com',
          content_type: 'text/html',
          body: "<table border=\"0\" cellpadding=\"0\" style=\" font-size: 14px;\">
<tbody>
<tr>
<td>
<p>
<a href=\"http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-2/http://web2.cylex.de/advent2012?b2b\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-2/http://web2.cylex.de/advent2012?b2b</a></p><p>Lieber CYLEX Eintragsinhaber,</p><p>das Jahr neigt sich dem Ende und die besinnliche Zeit beginnt laut Kalender mit dem<br> 1. Advent. Und wie immer wird es in der vorweihnachtlichen Zeit meist beruflich und privat<br> so richtig schön hektisch.</p><p>Um Ihre Weihnachtsstimmung in Schwung zu bringen kommen wir nun mit unserem Adventskalender ins Spiel. Denn 24 Tage werden Sie unsere netten Geschichten, Rezepte und Gewinnspiele sowie ausgesuchte Geschenktipps und Einkaufsgutscheine online begleiten. Damit lässt sich Ihre Freude auf das Fest garantiert mit jedem Tag steigern.</p><table style=\" font-size: 14px;\">
<tbody>
<tr>
<td align=\"left\" valign=\"middle\"> Einen gemütlichen Start in die Adventszeit wünscht Ihnen</td>
<td align=\"right\" valign=\"middle\">
<a href=\"http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-1/http://web2.cylex.de/advent2012?b2b\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-1/http://web2.cylex.de/advent2012?b2b</a>
</td>
</tr>
</tbody>
</table>
<p>Ihr CYLEX Team<br>
<br>
<strong>P.S.</strong> Damit Sie keinen Tag versäumen, empfehlen wir Ihnen den Link des Adventkalenders (<a href=\"http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-3/http://web2.cylex.de/advent2012?b2b\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-3/http://web2.cylex.de/advent2012?b2b</a>) in<br> Ihrer Lesezeichen-Symbolleiste zu ergänzen.</p><p>&nbsp;</p></td>
</tr>
</tbody>
</table> <table cellspacing=\"0\" cellpadding=\"0\" style=\"color:#6578a0; font-size:10px;\">
<tbody>
<tr>
<td align=\"left\" style=\"text-align:left;\"> Impressum <br> S.C. CYLEX INTERNATIONAL S.N.C.<br> Sat. Palota 119/A RO 417516 Palota Romania <br> Tel.: +49 208/62957-0 | <br> Geschäftsführer: Francisc Osvald<br> Handelsregister: J05/1591/2009<br> USt.IdNr.: RO26332771 <br>
<br> serviceteam@cylex.de<br> Homepage (<a href=\"http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-98/http://web2.cylex.de/Homepage/Home.asp\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-98/http://web2.cylex.de/Homepage/Home.asp</a>)<br> Newsletter abbestellen (<a href=\"http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-99/http://newsletters.cylex.de/unsubscribe.aspx?uid=4134001&amp;d=www.cylex.de&amp;e=enjoy@znuny.com&amp;sc=3009&amp;l=d\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-99/http://newsletters.cylex.de/unsubscribe.aspx?uid=4134001&amp;d=www.cylex.de&amp;e=enjoy@znuny.com&amp;sc=3009&amp;l=d</a>) </td>
</tr>
</tbody>
</table>",
        },
      },
      {
        data: IO.binread('test/fixtures/mail12.box'),
        body_md5: 'dd7e002b6bb709effb56bdb6f2cc2e32',
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
          body: "<div>
<p>Hallo Herr Edenhofer,</p><p>&nbsp;</p><p>möglicherweise haben wir für unsere morgige Veranstaltung ein Problem mit unserer Develop-Umgebung.<br> Der Kollege Smith wollte uns noch die Möglichkeit geben, direkt auf die Datenbank zugreifen zu können, hierzu hat er Freitag noch einige Einstellungen vorgenommen und uns die Zugangsdaten mitgeteilt. Eine der Änderungen hatte aber offenbar zur Folge, dass ein Starten der Develop-Anwendung nicht mehr möglich ist (s. Fehlermeldung)<br>
<img src=\"cid:image002.png@01CDD14F.29D467A0\" style=\"width:577px;height:345px;\"></p><p>&nbsp;</p><p>Herr Smith ist im Urlaub, er wurde von seinen Datenbank-Kollegen kontaktiert aber offenbar lässt sich nicht mehr 100%ig rekonstruieren, was am Freitag noch verändert wurde.<br> Meinen Sie, dass Sie uns bei der Behebung der o. a. Störung morgen helfen können? Die Datenbank-Kollegen werden uns nach besten Möglichkeiten unterstützen, Zugriff erhalten wir auch.</p><p>&nbsp;</p><p>Mit freundlichen Grüßen</p><p>&nbsp;</p><p>Alex Smith<br>
<br> Abteilung IT-Strategie, Steuerung &amp; Support<br> im Bereich Informationstechnologie<br>
<br> Example – Example GmbH<br> (Deutsche Example)<br> Longstreet 5<br> 11111 Frankfurt am Main<br>
<br> Telefon: (069) 11 1111 – 11 30</p><p>Telefon ServiceDesk: (069) 11 1111 – 12 22<br> Telefax: (069) 11 1111 – 14 85<br> Internet: <a href=\"http://www.example.com/\" title=\"http://www.example.com/\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">www.example.com</a></p><p>&nbsp;</p><span class=\"js-signatureMarker\"></span><p>-----Ursprüngliche Nachricht-----<br> Von: Martin Edenhofer via Znuny Sales [mailto:example@znuny.com] <br> Gesendet: Freitag, 30. November 2012 13:50<br> An: Smith, Alex<br> Betreff: Agenda [Ticket#11995]</p><p>&nbsp;</p><p>Sehr geehrte Frau Smith,</p><p>&nbsp;</p><p>ich habe (wie telefonisch avisiert) versucht eine Agenda für nächste Woche zusammen zu stellen.</p><p>&nbsp;</p><p>Leider ist es mir dies Inhaltlich nur unzureichend gelungen (es gibt zu wenig konkrete Anforderungen im Vorfeld :) ).</p><p>&nbsp;</p><p>Dadurch würde ich gerne am Dienstag als erste Amtshandlung (mit Herrn Molitor im Boot) die Anforderungen und Ziele der zwei Tage, Mittelfristig und Langfristig definieren. Aufgrund dessen können wir die Agenda der zwei Tage fixieren. Inhaltlich können wir (ich) alles abdecken, von daher gibt es hier keine Probleme. ;)</p><p>&nbsp;</p><p>Ist dies für Sie so in Ordnung?</p><p>&nbsp;</p><p>Für Fragen stehe ich gerne zur Verfügung!</p><p>&nbsp;</p><p>Ich freue mich auf Dienstag,</p><p>&nbsp;</p><p>Martin Edenhofer</p><p>&nbsp;</p><p>--</p><p>Enterprise Services for OTRS</p><p>&nbsp;</p><p>Znuny GmbH // Marienstraße 11 // 10117 Berlin // Germany</p><p>&nbsp;</p><p>P: +49 (0) 30 60 98 54 18-0</p><p>F: +49 (0) 30 60 98 54 18-8</p><p>W: <a href=\"http://znuny.com\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://znuny.com</a>
</p><p>&nbsp;</p><p>Location: Berlin - HRB 139852 B Amtsgericht Berlin-Charlottenburg Managing Director: Martin Edenhofer</p></div><div>
<p>-------------------------------------------------------------------------------------------------</p><p>Rechtsform: GmbH</p><p>Geschaeftsfuehrer: Dr. Carl Heinz Smith, Dr. Carsten Smith</p><p>Sitz der Gesellschaft und Registergericht: Frankfurt/Main, HRB 11111</p><p>Alleiniger Gesellschafter: Bundesrepublik Deutschland,</p><p>vertreten durch das XXX der Finanzen.</p></div>",
        },
      },
      {
        data: IO.binread('test/fixtures/mail13.box'),
        body_md5: 'c3b62f742eb702910d0074e438b34c72',
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
          body: '<p>JA</p>',
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
            filename: '¼¨Ð§¹ÜÀí,¾¿¾¹Ë­´íÁË.xls',
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
        body_md5: 'c3ea8fde251062d56b7fc72b6d73d702',
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
        body_md5: 'd78731371e3ec120896c51be3d0d3f8e',
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
        body_md5: '6021dd92d8e7844e6bb9b5bb7a4adfb8',
        params: {
          from: '"我" <>',
          from_email: 'vipyiming@126.com',
          from_display_name: '',
          subject: '《欧美简讯》',
          to: '377861373 <377861373@qq.com>',
        },
      },
      {
        data: IO.binread('test/fixtures/mail20.box'),
        body_md5: '7cdfb67ce7bf914fa0a5b85f0a365fdc',
        params: {
          from: 'Health and Care-Mall <drugs-cheapest8@sicor.com>',
          from_email: 'drugs-cheapest8@sicor.com',
          from_display_name: 'Health and Care-Mall',
          subject: 'The Highest Grade Drugs And EXTRA LOW Price .',
          to: 'info2@znuny.com',
          body: "________________________________________________________________________Yeah but even when they. Beth liî ed her neck as well <br>
<div>
<table border=\"0\" cellspacing=\"5\" style=\"color:#e3edea; background-color:#eee0ec; font-size:1px;\">
<tr>
<td colspan=\"2\">óû5a<span style=\"color:#dd7f6f;\">H</span>w5³½<span style=\"color:#dd7f6f;\">I</span>ΨµÁx<span style=\"color:#dd7f6f;\">G</span>⌊o8K<span style=\"color:#dd7f6f;\">H</span>Cmς9<span style=\"color:#dd7f6f;\">-</span>Ö½23<span style=\"color:#dd7f6f;\">Q</span>gñV6<span style=\"color:#dd7f6f;\">U</span>AD¿ù<span style=\"color:#dd7f6f;\">A</span>X←t¨<span style=\"color:#dd7f6f;\">L</span>f7⊕®<span style=\"color:#dd7f6f;\">I</span>r²r½<span style=\"color:#dd7f6f;\">T</span>LA5p<span style=\"color:#dd7f6f;\">Y</span>JhjV<span style=\"color:#dd7f6f;\"> </span>gPnã<span style=\"color:#dd7f6f;\">M</span>36V®<span style=\"color:#dd7f6f;\">E</span>89RU<span style=\"color:#dd7f6f;\">D</span>ΤÅ©È<span style=\"color:#dd7f6f;\">I</span>9æsà<span style=\"color:#dd7f6f;\">C</span>ΘYEϒ<span style=\"color:#dd7f6f;\">A</span>fg∗b<span style=\"color:#dd7f6f;\">T</span>¡1∫r<span style=\"color:#dd7f6f;\">I</span>oiš¦<span style=\"color:#dd7f6f;\">O</span>5oUI<span style=\"color:#dd7f6f;\">N</span>±Isæ<span style=\"color:#dd7f6f;\">S</span>Ø¹Pp<span style=\"color:#dd7f6f;\"> </span>Ÿÿq1<span style=\"color:#dd7f6f;\">F</span>Χ⇑eG<span style=\"color:#dd7f6f;\">O</span>z⌈F³<span style=\"color:#dd7f6f;\">R</span>98y§<span style=\"color:#dd7f6f;\"> </span>74”l<span style=\"color:#dd7f6f;\">T</span>r8r§<span style=\"color:#dd7f6f;\">H</span>ÐæuØ<span style=\"color:#dd7f6f;\">E</span>ÛPËq<span style=\"color:#dd7f6f;\"> </span>Vmkf<span style=\"color:#dd7f6f;\">B</span>∫SKN<span style=\"color:#dd7f6f;\">E</span>lst4<span style=\"color:#dd7f6f;\">S</span>∃Á8ü<span style=\"color:#dd7f6f;\">T</span>ðG°í<span style=\"color:#dd7f6f;\"> </span>lY9å<span style=\"color:#dd7f6f;\">P</span>u×8&gt;<span style=\"color:#dd7f6f;\">R</span>Ò¬⊕Μ<span style=\"color:#dd7f6f;\">I</span>ÙzÙC<span style=\"color:#dd7f6f;\">C</span>4³ÌQ<span style=\"color:#dd7f6f;\">E</span>ΡºSè<span style=\"color:#dd7f6f;\">!</span>XgŒs.</td>
</tr>
<tr>
<td align=\"center\" colspan=\"2\">çγ⇓B<span style=\"color:#2a0984;\">cwspC L I C K H E R Eëe3¸ ! (<a href=\"http://pxmzcgy.storeprescription.ru?zz=fkxffti\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://pxmzcgy.storeprescription.ru?zz=fkxffti</a>)</span>Calm dylan for school today.<br>Closing the nursery with you down. Here and made the mess. Maybe the oï from under his mother. Song of course beth touched his pants.<br>When someone who gave up from here. Feel of god knows what.</td>
</tr>
<tr>
<td colspan=\"2\">TBϖ∃<span style=\"color:#2a0984;\">M</span>5T5Ε<span style=\"color:#2a0984;\">E</span>f2û–<span style=\"color:#2a0984;\">N</span>¶ÁvΖ<span style=\"color:#2a0984;\">'</span>®⇓∝5<span style=\"color:#2a0984;\">S</span>ÐçË5<span style=\"color:#2a0984;\"> </span>Χ0jΔ<span style=\"color:#2a0984;\">H</span>bAgþ<span style=\"color:#2a0984;\">E</span>—2i6<span style=\"color:#2a0984;\">A</span>2lD⇑<span style=\"color:#2a0984;\">L</span>GjÓn<span style=\"color:#2a0984;\">T</span>Oy»¦<span style=\"color:#2a0984;\">H</span>ëτ9’<span style=\"color:#2a0984;\">:</span>Their mother and tugged it seemed like</td>
</tr>
<tr>
<td>d3Rs<span style=\"color:#2a0984;\">V</span>¶HÓΘ<span style=\"color:#2a0984;\">i</span>¯B∂g<span style=\"color:#2a0984;\">a</span>x1bî<span style=\"color:#2a0984;\">g</span>dHä3<span style=\"color:#2a0984;\">r</span>ýJÿ1<span style=\"color:#2a0984;\">a</span>IKÇ²<span style=\"color:#2a0984;\"> </span>n1jf<span style=\"color:#2a0984;\">a</span>Tk³V<span style=\"color:#2a0984;\">s</span>395ß<span style=\"color:#2a0984;\"> </span>C˜lB<span style=\"color:#2a0984;\">l</span>‘mxG<span style=\"color:#2a0984;\">o</span>0√úX<span style=\"color:#2a0984;\">w</span>T8Ya<span style=\"color:#2a0984;\"> </span>õ8ks<span style=\"color:#2a0984;\">a</span>∫f·ℵ<span style=\"color:#2a0984;\">s</span>”6ÑQ<span style=\"color:#2a0984;\"> </span>ÍAd7<span style=\"color:#2a0984;\">$</span>p32d<span style=\"color:#2a0984;\">1</span>e∏æe<span style=\"color:#2a0984;\">.</span>0”×6<span style=\"color:#2a0984;\">1</span>aîΚ6<span style=\"color:#2a0984;\">3</span>αSMû</td>
<td>Nf5É<span style=\"color:#2a0984;\">C</span>dL∪1<span style=\"color:#2a0984;\">i</span>↔xca<span style=\"color:#2a0984;\">a</span>5êR3<span style=\"color:#2a0984;\">l</span>6Lc3<span style=\"color:#2a0984;\">i</span>ãz16<span style=\"color:#2a0984;\">s</span>ó9èU<span style=\"color:#2a0984;\"> </span>zDE²<span style=\"color:#2a0984;\">a</span>EÈ¨g<span style=\"color:#2a0984;\">s</span>25ËÞ<span style=\"color:#2a0984;\"> </span>hE§c<span style=\"color:#2a0984;\">l</span>⊃¢¢Â<span style=\"color:#2a0984;\">o</span>ÒÂµB<span style=\"color:#2a0984;\">w</span>²zF©<span style=\"color:#2a0984;\"> </span>qÏkõ<span style=\"color:#2a0984;\">a</span>XUiu<span style=\"color:#2a0984;\">s</span>1r0⊆<span style=\"color:#2a0984;\"> </span>d•∈ø<span style=\"color:#2a0984;\">$</span>¢Z2F<span style=\"color:#2a0984;\">1</span>2­8l<span style=\"color:#2a0984;\">.</span>07d5<span style=\"color:#2a0984;\">6</span>PÚl2<span style=\"color:#2a0984;\">5</span>JAO6</td>
</tr>
<tr>
<td>45lo<span style=\"color:#2a0984;\">V</span>óiv1<span style=\"color:#2a0984;\">i</span>2ãΥ⌊<span style=\"color:#2a0984;\">a</span>ð⊃d2<span style=\"color:#2a0984;\">g</span>ÃΥ3™<span style=\"color:#2a0984;\">r</span>ÎÍu¸<span style=\"color:#2a0984;\">a</span>WjO8<span style=\"color:#2a0984;\"> </span>n40–<span style=\"color:#2a0984;\">S</span>oyè2<span style=\"color:#2a0984;\">u</span>¡∅Î3<span style=\"color:#2a0984;\">p</span>¢JΜN<span style=\"color:#2a0984;\">e</span>Ìé×j<span style=\"color:#2a0984;\">r</span>áÒrΚ<span style=\"color:#2a0984;\"> </span>1ÌÓ9<span style=\"color:#2a0984;\">A</span>úrAk<span style=\"color:#2a0984;\">c</span>8nuE<span style=\"color:#2a0984;\">t</span>l22a<span style=\"color:#2a0984;\">i</span>‡OB8<span style=\"color:#2a0984;\">v</span>Sbéσ<span style=\"color:#2a0984;\">e</span>ιõq1<span style=\"color:#2a0984;\">+</span>65cw<span style=\"color:#2a0984;\"> </span>Òs8U<span style=\"color:#2a0984;\">a</span>ò4Pr<span style=\"color:#2a0984;\">s</span>E1y8<span style=\"color:#2a0984;\"> </span>〈fME<span style=\"color:#2a0984;\">l</span>hϒ⋅J<span style=\"color:#2a0984;\">o</span>8pmz<span style=\"color:#2a0984;\">w</span>jˆN¥<span style=\"color:#2a0984;\"> </span>wv39<span style=\"color:#2a0984;\">a</span>W¡Wt<span style=\"color:#2a0984;\">s</span>vuU3<span style=\"color:#2a0984;\"> </span>1aœ³<span style=\"color:#2a0984;\">$</span>éΝnR<span style=\"color:#2a0984;\">2</span>OÏ⌉B<span style=\"color:#2a0984;\">.</span>∀þc→<span style=\"color:#2a0984;\">5</span>Ê9χw<span style=\"color:#2a0984;\">5</span>pÃ⁄N</td>
<td>fHGF<span style=\"color:#2a0984;\">V</span>fE³ã<span style=\"color:#2a0984;\">i</span>σjGp<span style=\"color:#2a0984;\">a</span>5¶kg<span style=\"color:#2a0984;\">g</span>¡ìcW<span style=\"color:#2a0984;\">r</span>Uq5æ<span style=\"color:#2a0984;\">a</span>kx2h<span style=\"color:#2a0984;\"> </span>0Fè4<span style=\"color:#2a0984;\">P</span>¸ÕLñ<span style=\"color:#2a0984;\">r</span>n22Ï<span style=\"color:#2a0984;\">o</span>þÝÐH<span style=\"color:#2a0984;\">f</span>oRb2<span style=\"color:#2a0984;\">e</span>Uαw6<span style=\"color:#2a0984;\">s</span>ñN‾w<span style=\"color:#2a0984;\">s</span>¶§3Β<span style=\"color:#2a0984;\">i</span>òX¶¸<span style=\"color:#2a0984;\">o</span>fgtH<span style=\"color:#2a0984;\">n</span>R⊥3â<span style=\"color:#2a0984;\">a</span>se9á<span style=\"color:#2a0984;\">l</span>F¿H5<span style=\"color:#2a0984;\"> </span>à6BÁ<span style=\"color:#2a0984;\">a</span>⊃2iϒ<span style=\"color:#2a0984;\">s</span>ô¡ói<span style=\"color:#2a0984;\"> </span>ÅkMy<span style=\"color:#2a0984;\">l</span>ÚJ¾Ä<span style=\"color:#2a0984;\">o</span>Q–0ℑ<span style=\"color:#2a0984;\">w</span>vmùþ<span style=\"color:#2a0984;\"> </span>Ëˆμ\"<span style=\"color:#2a0984;\">a</span>Q7jV<span style=\"color:#2a0984;\">s</span>e6Ðf<span style=\"color:#2a0984;\"> </span>«hÜp<span style=\"color:#2a0984;\">$</span>Lâr£<span style=\"color:#2a0984;\">3</span>i1tÚ<span style=\"color:#2a0984;\">.</span>323h<span style=\"color:#2a0984;\">5</span>qP8g<span style=\"color:#2a0984;\">0</span>♥÷R÷</td> </tr>
<tr>
<td>·iƒP<span style=\"color:#2a0984;\">V</span>1Β∋ø<span style=\"color:#2a0984;\">i</span>F¤RÃ<span style=\"color:#2a0984;\">a</span>4v3â<span style=\"color:#2a0984;\">g</span>L9¢w<span style=\"color:#2a0984;\">r</span>¨7ø×<span style=\"color:#2a0984;\">a</span>Ïû0η<span style=\"color:#2a0984;\"> </span>þ1àß<span style=\"color:#2a0984;\">S</span>tuÞ³<span style=\"color:#2a0984;\">u</span>7á¡l<span style=\"color:#2a0984;\">p</span>ÑocE<span style=\"color:#2a0984;\">e</span>·SLl<span style=\"color:#2a0984;\">r</span>VàXj<span style=\"color:#2a0984;\"> </span>⊥Uµ¢<span style=\"color:#2a0984;\">F</span>¬48ð<span style=\"color:#2a0984;\">o</span>v7¨A<span style=\"color:#2a0984;\">r</span>m×4Í<span style=\"color:#2a0984;\">c</span>ùVwÞ<span style=\"color:#2a0984;\">e</span>1§⊇N<span style=\"color:#2a0984;\"> </span>ÂÛ4ä<span style=\"color:#2a0984;\">a</span>LþZ2<span style=\"color:#2a0984;\">s</span>ki×5<span style=\"color:#2a0984;\"> </span>c€pB<span style=\"color:#2a0984;\">l</span>ûù6∂<span style=\"color:#2a0984;\">o</span>lÃfÚ<span style=\"color:#2a0984;\">w</span>Kß3Ñ<span style=\"color:#2a0984;\"> </span>4iíl<span style=\"color:#2a0984;\">a</span>4C³ê<span style=\"color:#2a0984;\">s</span>REÕ1<span style=\"color:#2a0984;\"> </span>ãeIó<span style=\"color:#2a0984;\">$</span>âz8t<span style=\"color:#2a0984;\">4</span>42fG<span style=\"color:#2a0984;\">.</span>¸1≤¸<span style=\"color:#2a0984;\">2</span>F’Ã1<span style=\"color:#2a0984;\">5</span>2in⊄</td>
<td>Tl©ë<span style=\"color:#2a0984;\">C</span>2v7C<span style=\"color:#2a0984;\">i</span>7·X8<span style=\"color:#2a0984;\">a</span>×ú5N<span style=\"color:#2a0984;\">l</span>þU〉ι<span style=\"color:#2a0984;\">i</span>cO∑«<span style=\"color:#2a0984;\">s</span>·iKN<span style=\"color:#2a0984;\"> </span>Uuϒj<span style=\"color:#2a0984;\">S</span>Ãj5Ý<span style=\"color:#2a0984;\">u</span>÷Jü§<span style=\"color:#2a0984;\">p</span>n5°§<span style=\"color:#2a0984;\">e</span>¥Û3℘<span style=\"color:#2a0984;\">r</span>ÆW‡ò<span style=\"color:#2a0984;\"> </span>J‹S7<span style=\"color:#2a0984;\">A</span>1j0s<span style=\"color:#2a0984;\">c</span>&amp;ºpk<span style=\"color:#2a0984;\">t</span>·qqø<span style=\"color:#2a0984;\">i</span>Z56½<span style=\"color:#2a0984;\">v</span>n8¨∗<span style=\"color:#2a0984;\">e</span>îØQ3<span style=\"color:#2a0984;\">+</span>7Î3Š<span style=\"color:#2a0984;\"> </span>∑RkL<span style=\"color:#2a0984;\">a</span>KXËa<span style=\"color:#2a0984;\">s</span>ÐsÌ2<span style=\"color:#2a0984;\"> </span>ïÇ­¶<span style=\"color:#2a0984;\">l</span>Däz8<span style=\"color:#2a0984;\">o</span>ã78w<span style=\"color:#2a0984;\">w</span>U–ÀC<span style=\"color:#2a0984;\"> </span>T6Uû<span style=\"color:#2a0984;\">a</span>ϒ938<span style=\"color:#2a0984;\">s</span>Ì0Gÿ<span style=\"color:#2a0984;\"> </span>Oxó∈<span style=\"color:#2a0984;\">$</span>98‘R<span style=\"color:#2a0984;\">2</span>ÂHï5<span style=\"color:#2a0984;\">.</span>ÒL6b<span style=\"color:#2a0984;\">9</span>θrδÜ<span style=\"color:#2a0984;\">9</span>2f9j</td>
</tr>
<tr>
<td>Please matt on his neck. Okay matt huï ed into your mind</td>
<td>Since her head to check dylan. Where dylan matt got up there</td>
</tr>
<tr>
<td colspan=\"2\">1È±Α<span style=\"color:#2a0984;\">A</span>YQªd<span style=\"color:#2a0984;\">N</span>¬ÚϒX<span style=\"color:#2a0984;\">T</span>00Àv<span style=\"color:#2a0984;\">I</span>∨ío8<span style=\"color:#2a0984;\">-</span>½b®8<span style=\"color:#2a0984;\">A</span>ΕºV4<span style=\"color:#2a0984;\">L</span>gÕ↑7<span style=\"color:#2a0984;\">L</span>Ktgc<span style=\"color:#2a0984;\">E</span>iw­y<span style=\"color:#2a0984;\">R</span>5Yýæ<span style=\"color:#2a0984;\">G</span>RA1°<span style=\"color:#2a0984;\">I</span>¿0Cï<span style=\"color:#2a0984;\">C</span>àTiü<span style=\"color:#2a0984;\">/</span>þwc0<span style=\"color:#2a0984;\">A</span>x211<span style=\"color:#2a0984;\">S</span>ÜÂùŒ<span style=\"color:#2a0984;\">T</span>Á2êò<span style=\"color:#2a0984;\">H</span>pNâù<span style=\"color:#2a0984;\">M</span>6È¾0<span style=\"color:#2a0984;\">A</span>5Tb»<span style=\"color:#2a0984;\">:</span>Simmons and now you really is what. Matt picked up this moment later that.</td>
</tr>
<tr>
<td>25¯y<span style=\"color:#2a0984;\">V</span>9ÙßY<span style=\"color:#2a0984;\">e</span>g·↑D<span style=\"color:#2a0984;\">n</span>J3l4<span style=\"color:#2a0984;\">t</span>Ýæb1<span style=\"color:#2a0984;\">o</span>s∏jl<span style=\"color:#2a0984;\">l</span>÷iSÐ<span style=\"color:#2a0984;\">i</span>wBÎ4<span style=\"color:#2a0984;\">n</span>0ú1Ö<span style=\"color:#2a0984;\"> </span>ªf÷Ñ<span style=\"color:#2a0984;\">a</span>§1lø<span style=\"color:#2a0984;\">s</span>uÚ8ê<span style=\"color:#2a0984;\"> </span>2LCb<span style=\"color:#2a0984;\">l</span>gvN½<span style=\"color:#2a0984;\">o</span>¼oP3<span style=\"color:#2a0984;\">w</span>n♠90<span style=\"color:#2a0984;\"> </span>FZor<span style=\"color:#2a0984;\">a</span>&amp;M™x<span style=\"color:#2a0984;\">s</span>ΚbbÂ<span style=\"color:#2a0984;\"> </span>ç5Ãξ<span style=\"color:#2a0984;\">$</span>Âô·×<span style=\"color:#2a0984;\">2</span>iGæ∇<span style=\"color:#2a0984;\">1</span>⊇Ξ¬3<span style=\"color:#2a0984;\">.</span>0P0κ<span style=\"color:#2a0984;\">5</span>3VÁö<span style=\"color:#2a0984;\">0</span>3ÝYz</td>
<td>øX¢B<span style=\"color:#2a0984;\">A</span>Z4Kw<span style=\"color:#2a0984;\">d</span>duÜv<span style=\"color:#2a0984;\">v</span>uB↑Β<span style=\"color:#2a0984;\">a</span>Ä’TH<span style=\"color:#2a0984;\">i</span>0—93<span style=\"color:#2a0984;\">r</span>Zεj0<span style=\"color:#2a0984;\"> </span>§rΜÅ<span style=\"color:#2a0984;\">a</span>2­·§<span style=\"color:#2a0984;\">s</span>7¸Ιf<span style=\"color:#2a0984;\"> </span>8⇓þo<span style=\"color:#2a0984;\">l</span>W„6Ý<span style=\"color:#2a0984;\">o</span>6yH¥<span style=\"color:#2a0984;\">w</span>KZ∧6<span style=\"color:#2a0984;\"> </span>21hÒ<span style=\"color:#2a0984;\">a</span>KJ“ℜ<span style=\"color:#2a0984;\">s</span>48IÌ<span style=\"color:#2a0984;\"> </span>ÔÀ¬­<span style=\"color:#2a0984;\">$</span>ZΣ¹ü<span style=\"color:#2a0984;\">2</span>ñÙ6B<span style=\"color:#2a0984;\">4</span>2YMZ<span style=\"color:#2a0984;\">.</span>Ô¹V¼<span style=\"color:#2a0984;\">9</span>f·0å<span style=\"color:#2a0984;\">5</span>4⌈R8</td>
</tr>
<tr>
<td>÷w\"9<span style=\"color:#2a0984;\">N</span>2gBÀ<span style=\"color:#2a0984;\">a</span>ðSê¢<span style=\"color:#2a0984;\">s</span>≅gGÔ<span style=\"color:#2a0984;\">o</span>0Dn4<span style=\"color:#2a0984;\">n</span>↵γ7⊗<span style=\"color:#2a0984;\">e</span>S7eý<span style=\"color:#2a0984;\">x</span>f3Jd<span style=\"color:#2a0984;\"> </span>q÷CM<span style=\"color:#2a0984;\">a</span>Íä³i<span style=\"color:#2a0984;\">s</span>NMZp<span style=\"color:#2a0984;\"> </span>zz0˜<span style=\"color:#2a0984;\">l</span>ΚLw8<span style=\"color:#2a0984;\">o</span>ë29w<span style=\"color:#2a0984;\">w</span>¤§Qu<span style=\"color:#2a0984;\"> </span>¥D⌈í<span style=\"color:#2a0984;\">a</span>ýË¢é<span style=\"color:#2a0984;\">s</span>J8Á¬<span style=\"color:#2a0984;\"> </span>3oùÙ<span style=\"color:#2a0984;\">$</span>¦1Nℜ<span style=\"color:#2a0984;\">1</span>&gt;Rét<span style=\"color:#2a0984;\">7</span>WPM¨<span style=\"color:#2a0984;\">.</span>¶8¹D<span style=\"color:#2a0984;\">9</span>2k5D<span style=\"color:#2a0984;\">9</span>∗8≈R</td>
<td>l©3ª<span style=\"color:#2a0984;\">S</span>j·Ψ8<span style=\"color:#2a0984;\">p</span>ΣïKù<span style=\"color:#2a0984;\">i</span>6rrÔ<span style=\"color:#2a0984;\">r</span>bÛu¬<span style=\"color:#2a0984;\">i</span>2V∗∏<span style=\"color:#2a0984;\">v</span>5ª10<span style=\"color:#2a0984;\">a</span>27BÁ<span style=\"color:#2a0984;\"> </span>Ú♦Ξs<span style=\"color:#2a0984;\">a</span>9j3χ<span style=\"color:#2a0984;\">s</span>a¯iΟ<span style=\"color:#2a0984;\"> </span>Oi℘m<span style=\"color:#2a0984;\">l</span>6ófé<span style=\"color:#2a0984;\">o</span>wbz∀<span style=\"color:#2a0984;\">w</span>A6ù→<span style=\"color:#2a0984;\"> </span>ñ×bà<span style=\"color:#2a0984;\">a</span>i´wb<span style=\"color:#2a0984;\">s</span>♦βGs<span style=\"color:#2a0984;\"> </span>Ù81i<span style=\"color:#2a0984;\">$</span>iÀˆ1<span style=\"color:#2a0984;\">2</span>⊃2wC<span style=\"color:#2a0984;\">8</span>2n8o<span style=\"color:#2a0984;\">.</span>µ3NJ<span style=\"color:#2a0984;\">9</span>S1©Θ<span style=\"color:#2a0984;\">0</span>P1Sd</td>
</tr>
<tr>
<td>What made no one in each time.</td>
<td>Mommy was thinking of course beth. Everything you need the same thing</td>
</tr>
<tr>
<td colspan=\"2\">PïEV<span style=\"color:#2a0984;\">G</span>ÿ9sr<span style=\"color:#2a0984;\">E</span>x⇐9o<span style=\"color:#2a0984;\">N</span>3U®y<span style=\"color:#2a0984;\">E</span>Îi2O<span style=\"color:#2a0984;\">R</span>5kÇÿ<span style=\"color:#2a0984;\">A</span>ΤηνU<span style=\"color:#2a0984;\">L</span>P¿∧q<span style=\"color:#2a0984;\"> </span>R5¿F<span style=\"color:#2a0984;\">H</span>t7J6<span style=\"color:#2a0984;\">E</span>»¯C∅<span style=\"color:#2a0984;\">A</span>å∃aV<span style=\"color:#2a0984;\">L</span>u∗¢t<span style=\"color:#2a0984;\">T</span>〈2Ãš<span style=\"color:#2a0984;\">H</span>q9Né<span style=\"color:#2a0984;\">:</span>
</td>
</tr>
<tr>
<td>⊥ÞÞ¨<span style=\"color:#2a0984;\">T</span>¦ªBr<span style=\"color:#2a0984;\">r</span>C7³2<span style=\"color:#2a0984;\">a</span>dš6l<span style=\"color:#2a0984;\">m</span>zb¨6<span style=\"color:#2a0984;\">a</span>i07t<span style=\"color:#2a0984;\">d</span>Bo×K<span style=\"color:#2a0984;\">o</span>píΡÄ<span style=\"color:#2a0984;\">l</span>j4Hy<span style=\"color:#2a0984;\"> </span>ÝaÓ1<span style=\"color:#2a0984;\">a</span>Öí∉Ó<span style=\"color:#2a0984;\">s</span>1aá’<span style=\"color:#2a0984;\"> </span>4D­k<span style=\"color:#2a0984;\">l</span>eowË<span style=\"color:#2a0984;\">o</span>3–1Í<span style=\"color:#2a0984;\">w</span>jR≤Π<span style=\"color:#2a0984;\"> </span>£RhÈ<span style=\"color:#2a0984;\">a</span>fà7≅<span style=\"color:#2a0984;\">s</span>ù6u2<span style=\"color:#2a0984;\"> </span>8NLV<span style=\"color:#2a0984;\">$</span>∪⇓»↓<span style=\"color:#2a0984;\">1</span>Y¶2µ<span style=\"color:#2a0984;\">.</span>vßÈ2<span style=\"color:#2a0984;\">3</span>ÖS7û<span style=\"color:#2a0984;\">0</span>Ün¬Ä</td>
<td>m5VK<span style=\"color:#2a0984;\">Z</span>y3KÎ<span style=\"color:#2a0984;\">i</span>ñë¹D<span style=\"color:#2a0984;\">t</span>Ú2Hr<span style=\"color:#2a0984;\">h</span>GaMv<span style=\"color:#2a0984;\">r</span>5ïR«<span style=\"color:#2a0984;\">o</span>Â1na<span style=\"color:#2a0984;\">m</span>ΜwÐã<span style=\"color:#2a0984;\">a</span>nFu8<span style=\"color:#2a0984;\">x</span>7⌈sU<span style=\"color:#2a0984;\"> </span>E4cv<span style=\"color:#2a0984;\">a</span>£Âε™<span style=\"color:#2a0984;\">s</span>7ΑGO<span style=\"color:#2a0984;\"> </span>dA35<span style=\"color:#2a0984;\">l</span>dñÌè<span style=\"color:#2a0984;\">o</span>AξI1<span style=\"color:#2a0984;\">w</span>XKïn<span style=\"color:#2a0984;\"> </span>f¼x¾<span style=\"color:#2a0984;\">a</span>∏7ff<span style=\"color:#2a0984;\">s</span>†ìÖð<span style=\"color:#2a0984;\"> </span>5msC<span style=\"color:#2a0984;\">$</span>7Ët¦<span style=\"color:#2a0984;\">0</span>z„n÷<span style=\"color:#2a0984;\">.</span>it¡T<span style=\"color:#2a0984;\">7</span>O8vt<span style=\"color:#2a0984;\">5</span>¼8å·</td>
</tr>
<tr>
<td>Jï1Ï<span style=\"color:#2a0984;\">P</span>káO¶<span style=\"color:#2a0984;\">r</span>nùrA<span style=\"color:#2a0984;\">o</span>8s5∅<span style=\"color:#2a0984;\">z</span>—4Rh<span style=\"color:#2a0984;\">a</span>1®t˜<span style=\"color:#2a0984;\">c</span>q5YΧ<span style=\"color:#2a0984;\"> </span>ΤQÍr<span style=\"color:#2a0984;\">a</span>Ñ⌋4¹<span style=\"color:#2a0984;\">s</span>Ü5²§<span style=\"color:#2a0984;\"> </span>ûVBι<span style=\"color:#2a0984;\">l</span>uwói<span style=\"color:#2a0984;\">o</span>L3ëB<span style=\"color:#2a0984;\">w</span>£±1¶<span style=\"color:#2a0984;\"> </span>5∈àá<span style=\"color:#2a0984;\">a</span>1IÊ2<span style=\"color:#2a0984;\">s</span>šÛÛÂ<span style=\"color:#2a0984;\"> </span>G´7ρ<span style=\"color:#2a0984;\">$</span>kJM8<span style=\"color:#2a0984;\">0</span>∼∠ℵl<span style=\"color:#2a0984;\">.</span>J1Km<span style=\"color:#2a0984;\">3</span>2µÚ⊃<span style=\"color:#2a0984;\">5</span>ãé¼§</td>
<td>p°ÿ­<span style=\"color:#2a0984;\">A</span>¹NU0<span style=\"color:#2a0984;\">c</span>¥xçf<span style=\"color:#2a0984;\">o</span>〈Øác<span style=\"color:#2a0984;\">m</span>14QG<span style=\"color:#2a0984;\">p</span>HEj7<span style=\"color:#2a0984;\">l</span>nDPV<span style=\"color:#2a0984;\">i</span>eV2¶<span style=\"color:#2a0984;\">a</span>Π2H7<span style=\"color:#2a0984;\"> </span>²j26<span style=\"color:#2a0984;\">a</span>zBSe<span style=\"color:#2a0984;\">s</span>ë1c9<span style=\"color:#2a0984;\"> </span>´2Ù¬<span style=\"color:#2a0984;\">l</span>0nò¤<span style=\"color:#2a0984;\">o</span>õâRV<span style=\"color:#2a0984;\">w</span>¦X´Ï<span style=\"color:#2a0984;\"> </span>αVõ­<span style=\"color:#2a0984;\">a</span>≅σ¼Z<span style=\"color:#2a0984;\">s</span>§jJå<span style=\"color:#2a0984;\"> </span>3pFN<span style=\"color:#2a0984;\">$</span>¾Kf8<span style=\"color:#2a0984;\">2</span>1YΟ7<span style=\"color:#2a0984;\">.</span>3ÍY9<span style=\"color:#2a0984;\">5</span>JΑqŸ<span style=\"color:#2a0984;\">0</span>v9ÄQ</td>
</tr>
<tr>
<td>ñ↑yj<span style=\"color:#2a0984;\">P</span>Τ1u6<span style=\"color:#2a0984;\">r</span>FwhN<span style=\"color:#2a0984;\">e</span>COϖú<span style=\"color:#2a0984;\">d</span>5Γêc<span style=\"color:#2a0984;\">n</span>e¼a0<span style=\"color:#2a0984;\">i</span>TF¹5<span style=\"color:#2a0984;\">s</span>xUS0<span style=\"color:#2a0984;\">o</span>88ℵª<span style=\"color:#2a0984;\">l</span>aÅT℘<span style=\"color:#2a0984;\">o</span>OBÀ¹<span style=\"color:#2a0984;\">n</span>ë·­1<span style=\"color:#2a0984;\">e</span>∧Kpf<span style=\"color:#2a0984;\"> </span>υ98ξ<span style=\"color:#2a0984;\">a</span>bp†3<span style=\"color:#2a0984;\">s</span>j8â&amp;<span style=\"color:#2a0984;\"> </span>9©Bo<span style=\"color:#2a0984;\">l</span>ÎAWS<span style=\"color:#2a0984;\">o</span>7wNg<span style=\"color:#2a0984;\">w</span>ø¦mM<span style=\"color:#2a0984;\"> </span>tteQ<span style=\"color:#2a0984;\">a</span>t0ϖ2<span style=\"color:#2a0984;\">s</span>4≡NÇ<span style=\"color:#2a0984;\"> </span>ÕÆ¦Θ<span style=\"color:#2a0984;\">$</span>ùRÓq<span style=\"color:#2a0984;\">0</span>·Ã7ª<span style=\"color:#2a0984;\">.</span>mt¾³<span style=\"color:#2a0984;\">1</span>—uwF<span style=\"color:#2a0984;\">5</span>7H♣f</td>
<td>æ∪HY<span style=\"color:#2a0984;\">S</span>jψ3B<span style=\"color:#2a0984;\">y</span>š²g¤<span style=\"color:#2a0984;\">n</span>dXÀ5<span style=\"color:#2a0984;\">t</span>µ¯ò6<span style=\"color:#2a0984;\">h</span>Z⇒yÿ<span style=\"color:#2a0984;\">r</span>8ÿmd<span style=\"color:#2a0984;\">o</span>wyðd<span style=\"color:#2a0984;\">i</span>ψ8YΗ<span style=\"color:#2a0984;\">d</span>0ršŠ<span style=\"color:#2a0984;\"> </span>N0Ý9<span style=\"color:#2a0984;\">a</span>Ã3I¦<span style=\"color:#2a0984;\">s</span>Qaýê<span style=\"color:#2a0984;\"> </span>Õ0Y7<span style=\"color:#2a0984;\">l</span>Z¯18<span style=\"color:#2a0984;\">o</span>∫50Ç<span style=\"color:#2a0984;\">w</span>µ\"©Ζ<span style=\"color:#2a0984;\"> </span>n6Ü≥<span style=\"color:#2a0984;\">a</span>∇lßn<span style=\"color:#2a0984;\">s</span>F›J9<span style=\"color:#2a0984;\"> </span>ºDΟK<span style=\"color:#2a0984;\">$</span>Á4ÉL<span style=\"color:#2a0984;\">0</span>S7zÖ<span style=\"color:#2a0984;\">.</span>Ta2X<span style=\"color:#2a0984;\">3</span>²R99<span style=\"color:#2a0984;\">5</span>391¡</td>
</tr>
<tr>
<td>Turning to mess up with. Well that to give her face</td>
<td>Another for what she found it then. Since the best to hear</td>
</tr>
<tr>
<td colspan=\"2\">GX°♦<span style=\"color:#dd7f6f;\">C</span>a2is<span style=\"color:#dd7f6f;\">A</span>¾8¡b<span style=\"color:#dd7f6f;\">N</span>Éî8Â<span style=\"color:#dd7f6f;\">A</span>öÜzΘ<span style=\"color:#dd7f6f;\">D</span>∇tNX<span style=\"color:#dd7f6f;\">I</span>fWi–<span style=\"color:#dd7f6f;\">A</span>p2WY<span style=\"color:#dd7f6f;\">N</span>YF®b<span style=\"color:#dd7f6f;\"> </span>≠7yφ<span style=\"color:#dd7f6f;\">D</span>pj6©<span style=\"color:#dd7f6f;\">R</span>04EÂ<span style=\"color:#dd7f6f;\">U</span>´ñn7<span style=\"color:#dd7f6f;\">G</span>ÆoÌj<span style=\"color:#dd7f6f;\">S</span>Â³Á∋<span style=\"color:#dd7f6f;\">T</span>C⊥πË<span style=\"color:#dd7f6f;\">O</span>1∗÷©<span style=\"color:#dd7f6f;\">R</span>tS2w<span style=\"color:#dd7f6f;\">E</span>66è­<span style=\"color:#dd7f6f;\"> </span>νÑêé<span style=\"color:#dd7f6f;\">A</span>Si21<span style=\"color:#dd7f6f;\">D</span>P“8λ<span style=\"color:#dd7f6f;\">V</span>∧W⋅O<span style=\"color:#dd7f6f;\">A</span>Ög6q<span style=\"color:#dd7f6f;\">N</span>tNp1<span style=\"color:#dd7f6f;\">T</span>269X<span style=\"color:#dd7f6f;\">A</span>7¥À²<span style=\"color:#dd7f6f;\">G</span>GI6S<span style=\"color:#dd7f6f;\">E</span>wU2í<span style=\"color:#dd7f6f;\">S</span>3Χ1â<span style=\"color:#dd7f6f;\">!</span>Okay let matt climbed in front door. Well then dropped the best she kissed</td>
</tr>
<tr>
<td colspan=\"2\">¤ÊüC<span style=\"color:#2a0984;\">&gt;</span>ΦÉí©<span style=\"color:#2a0984;\"> </span>flQk<span style=\"color:#2a0984;\">W</span>MŠtv<span style=\"color:#2a0984;\">o</span>ÐdV¯<span style=\"color:#2a0984;\">r</span>T´Zt<span style=\"color:#2a0984;\">l</span>N6R9<span style=\"color:#2a0984;\">d</span>Z¾ïL<span style=\"color:#2a0984;\">w</span>uD¢9<span style=\"color:#2a0984;\">i</span>3B5F<span style=\"color:#2a0984;\">d</span>cÆlÝ<span style=\"color:#2a0984;\">e</span>SwJd<span style=\"color:#2a0984;\"> </span>KªtD<span style=\"color:#2a0984;\">D</span>foX±<span style=\"color:#2a0984;\">e</span>vrýw<span style=\"color:#2a0984;\">l</span>K7P÷<span style=\"color:#2a0984;\">i</span>§e³3<span style=\"color:#2a0984;\">v</span>ÎzèC<span style=\"color:#2a0984;\">e</span>¬Μ♣Ν<span style=\"color:#2a0984;\">r</span>Ghsá<span style=\"color:#2a0984;\">y</span>°72Y<span style=\"color:#2a0984;\">!</span>gZpá<span style=\"color:#2a0984;\"> </span>R6O4<span style=\"color:#2a0984;\">O</span>»£ð∋<span style=\"color:#2a0984;\">r</span>9ÊZÀ<span style=\"color:#2a0984;\">d</span>B6iÀ<span style=\"color:#2a0984;\">e</span>îσ∼Ó<span style=\"color:#2a0984;\">r</span>CZ1s<span style=\"color:#2a0984;\"> </span>²ú÷I<span style=\"color:#2a0984;\">3</span>ÁeÒ¤<span style=\"color:#2a0984;\">+</span>⌉CêU<span style=\"color:#2a0984;\"> </span>»k6w<span style=\"color:#2a0984;\">G</span>´c‚¾<span style=\"color:#2a0984;\">o</span>60AJ<span style=\"color:#2a0984;\">o</span>R7Ös<span style=\"color:#2a0984;\">d</span>3i¿Á<span style=\"color:#2a0984;\">s</span>ððpt<span style=\"color:#2a0984;\"> </span>Øè77<span style=\"color:#2a0984;\">a</span>ñ∀f5<span style=\"color:#2a0984;\">n</span>p¤nþ<span style=\"color:#2a0984;\">d</span>uE8⇒<span style=\"color:#2a0984;\"> </span>È¹SH<span style=\"color:#2a0984;\">G</span>JVAt<span style=\"color:#2a0984;\">e</span>w∇Lë<span style=\"color:#2a0984;\">t</span>ςëDæ<span style=\"color:#2a0984;\"> </span>6kÌ8<span style=\"color:#2a0984;\">F</span>gQQ⊂<span style=\"color:#2a0984;\">R</span>8ÇL2<span style=\"color:#2a0984;\">E</span>I2∉i<span style=\"color:#2a0984;\">E</span>HÍÉ3<span style=\"color:#2a0984;\"> </span>Hÿr5<span style=\"color:#2a0984;\">A</span>f1qx<span style=\"color:#2a0984;\">i</span>mςρ‡<span style=\"color:#2a0984;\">r</span>6©2j<span style=\"color:#2a0984;\">m</span>Wv9Û<span style=\"color:#2a0984;\">a</span>Wð¸g<span style=\"color:#2a0984;\">i</span>ACÜ¢<span style=\"color:#2a0984;\">l</span>M⌋¿k<span style=\"color:#2a0984;\"> </span>ÊVÚ¸<span style=\"color:#2a0984;\">S</span>Óùθç<span style=\"color:#2a0984;\">h</span>µ5BΙ<span style=\"color:#2a0984;\">i</span>∗ttE<span style=\"color:#2a0984;\">p</span>8¢EP<span style=\"color:#2a0984;\">p</span>SzWJ<span style=\"color:#2a0984;\">i</span>32UÎ<span style=\"color:#2a0984;\">n</span>5ìIh<span style=\"color:#2a0984;\">g</span>x8n⌉<span style=\"color:#2a0984;\">!</span>j∏e5</td>
</tr>
<tr>
<td colspan=\"2\">x¯qJ<span style=\"color:#2a0984;\">&gt;</span>mC7f<span style=\"color:#2a0984;\"> </span>5ºñy<span style=\"color:#2a0984;\">1</span>GA4Ý<span style=\"color:#2a0984;\">0</span>lCQe<span style=\"color:#2a0984;\">0</span>9s9u<span style=\"color:#2a0984;\">%</span>uksã<span style=\"color:#2a0984;\"> </span>ψìX5<span style=\"color:#2a0984;\">A</span>4g3n<span style=\"color:#2a0984;\">u</span>←Τys<span style=\"color:#2a0984;\">t</span>7ÍpM<span style=\"color:#2a0984;\">h</span>šgÀÖ<span style=\"color:#2a0984;\">e</span>〉pÚ£<span style=\"color:#2a0984;\">n</span>¼YƒŠ<span style=\"color:#2a0984;\">t</span>ÉÚLG<span style=\"color:#2a0984;\">i</span>zqQ↓<span style=\"color:#2a0984;\">c</span>3tÙI<span style=\"color:#2a0984;\"> </span>œïbX<span style=\"color:#2a0984;\">M</span>KÛRS<span style=\"color:#2a0984;\">e</span>rtj×<span style=\"color:#2a0984;\">d</span>\"OtÊ<span style=\"color:#2a0984;\">s</span>s58®<span style=\"color:#2a0984;\">!</span>oo2i<span style=\"color:#2a0984;\"> </span>FÂWá<span style=\"color:#2a0984;\">E</span>WøDD<span style=\"color:#2a0984;\">x</span>7hIÕ<span style=\"color:#2a0984;\">p</span>ΦSôB<span style=\"color:#2a0984;\">i</span>ÒdrU<span style=\"color:#2a0984;\">r</span>⇔J&lt;Õ<span style=\"color:#2a0984;\">a</span>1Αzw<span style=\"color:#2a0984;\">t</span>0°p×<span style=\"color:#2a0984;\">i</span>à8RÌ<span style=\"color:#2a0984;\">o</span>HÛ1Ä<span style=\"color:#2a0984;\">n</span>¥7ÿr<span style=\"color:#2a0984;\"> </span>¯¥õà<span style=\"color:#2a0984;\">D</span>YvO7<span style=\"color:#2a0984;\">a</span>ká»h<span style=\"color:#2a0984;\">t</span>ì04Π<span style=\"color:#2a0984;\">e</span>∂λÇ1<span style=\"color:#2a0984;\"> </span>1ÈdU<span style=\"color:#2a0984;\">o</span>ο°X3<span style=\"color:#2a0984;\">f</span>c63¶<span style=\"color:#2a0984;\"> </span>e&amp;∪G<span style=\"color:#2a0984;\">O</span>xT3C<span style=\"color:#2a0984;\">v</span>XcO·<span style=\"color:#2a0984;\">e</span>3KËν<span style=\"color:#2a0984;\">r</span>3¸y2<span style=\"color:#2a0984;\"> </span>26Ëz<span style=\"color:#2a0984;\">3</span>Ã∞I±<span style=\"color:#2a0984;\"> </span>Pì∃z<span style=\"color:#2a0984;\">Y</span>t6F4<span style=\"color:#2a0984;\">e</span>6è⇓v<span style=\"color:#2a0984;\">a</span>5÷þ9<span style=\"color:#2a0984;\">r</span>kΘ3ä<span style=\"color:#2a0984;\">s</span>KP5R<span style=\"color:#2a0984;\">!</span>ιµmz</td>
</tr>
<tr>
<td colspan=\"2\">3í1ë<span style=\"color:#2a0984;\">&gt;</span>ð2′L<span style=\"color:#2a0984;\"> </span>2óB⊥<span style=\"color:#2a0984;\">S</span>∩OQM<span style=\"color:#2a0984;\">e</span>ý∉ÑΦ<span style=\"color:#2a0984;\">c</span>öè9T<span style=\"color:#2a0984;\">u</span>ãa∫d<span style=\"color:#2a0984;\">r</span>â5ûM<span style=\"color:#2a0984;\">e</span>Lk9Ô<span style=\"color:#2a0984;\"> </span>£æ1O<span style=\"color:#2a0984;\">O</span>ø9oK<span style=\"color:#2a0984;\">n</span>ÿψÀW<span style=\"color:#2a0984;\">l</span>7HÏ∅<span style=\"color:#2a0984;\">i</span>9ρÈÊ<span style=\"color:#2a0984;\">n</span>iâ•Û<span style=\"color:#2a0984;\">e</span>XPxí<span style=\"color:#2a0984;\"> </span>´Í5¡<span style=\"color:#2a0984;\">S</span>UqtB<span style=\"color:#2a0984;\">h</span>7æa5<span style=\"color:#2a0984;\">o</span>tSZ9<span style=\"color:#2a0984;\">p</span>ØËÛD<span style=\"color:#2a0984;\">p</span>f®ÝÊ<span style=\"color:#2a0984;\">i</span>Ûωbj<span style=\"color:#2a0984;\">n</span>¯½Ÿ2<span style=\"color:#2a0984;\">g</span>sçh−<span style=\"color:#2a0984;\"> </span>båÌs<span style=\"color:#2a0984;\">w</span>xðoS<span style=\"color:#2a0984;\">i</span>q8hv<span style=\"color:#2a0984;\">t</span>èé6Ò<span style=\"color:#2a0984;\">h</span>⌈b²S<span style=\"color:#2a0984;\"> </span>×6þS<span style=\"color:#2a0984;\">V</span>BEFC<span style=\"color:#2a0984;\">i</span>øUàd<span style=\"color:#2a0984;\">s</span>9Ñ¤Ε<span style=\"color:#2a0984;\">a</span>Æ§ξÜ<span style=\"color:#2a0984;\">,</span>1„wv<span style=\"color:#2a0984;\"> </span>jw7A<span style=\"color:#2a0984;\">M</span>KÈ↔l<span style=\"color:#2a0984;\">a</span>æG9¦<span style=\"color:#2a0984;\">s</span>ë3«e<span style=\"color:#2a0984;\">t</span>uB2k<span style=\"color:#2a0984;\">e</span>Dãæì<span style=\"color:#2a0984;\">r</span>°¨Ie<span style=\"color:#2a0984;\">C</span>¾EaÄ<span style=\"color:#2a0984;\">a</span>o÷″∧<span style=\"color:#2a0984;\">r</span>&gt;6e¸<span style=\"color:#2a0984;\">d</span>9DùÇ<span style=\"color:#2a0984;\">,</span>mtSö<span style=\"color:#2a0984;\"> </span>I∗44<span style=\"color:#2a0984;\">A</span>¹Rˆê<span style=\"color:#2a0984;\">M</span>98zM<span style=\"color:#2a0984;\">E</span>≅QŸÐ<span style=\"color:#2a0984;\">X</span>¹4j6<span style=\"color:#2a0984;\"> </span>î0n3<span style=\"color:#2a0984;\">a</span>1'Êâ<span style=\"color:#2a0984;\">n</span>xpl6<span style=\"color:#2a0984;\">d</span>83þJ<span style=\"color:#2a0984;\"> </span>06Ð9<span style=\"color:#2a0984;\">E</span>ïãýã<span style=\"color:#2a0984;\">-</span>28Ú9<span style=\"color:#2a0984;\">c</span>4ßrØ<span style=\"color:#2a0984;\">h</span>7è¥m<span style=\"color:#2a0984;\">e</span>d½♠k<span style=\"color:#2a0984;\">c</span>ñ3sP<span style=\"color:#2a0984;\">k</span>¶2•r<span style=\"color:#2a0984;\">!</span>〉QCa</td>
</tr>
<tr>
<td colspan=\"2\">ŠeÏÀ<span style=\"color:#2a0984;\">&gt;</span>Ãσ½å<span style=\"color:#2a0984;\"> </span>bpøN<span style=\"color:#2a0984;\">E</span>RN8e<span style=\"color:#2a0984;\">a</span>D6Ån<span style=\"color:#2a0984;\">s</span>7Abh<span style=\"color:#2a0984;\">y</span>±Æü∩<span style=\"color:#2a0984;\"> </span>D7sV<span style=\"color:#2a0984;\">R</span>8'ºE<span style=\"color:#2a0984;\">e</span>ÿáDV<span style=\"color:#2a0984;\">f</span>c˜3ë<span style=\"color:#2a0984;\">u</span>7ÏÆq<span style=\"color:#2a0984;\">n</span>cË3q<span style=\"color:#2a0984;\">d</span>Ê∼4∇<span style=\"color:#2a0984;\">s</span>ρmi5<span style=\"color:#2a0984;\"> </span>6æ¾Ê<span style=\"color:#2a0984;\">a</span>ä°∝T<span style=\"color:#2a0984;\">n</span>Qb9s<span style=\"color:#2a0984;\">d</span>ÀMùℑ<span style=\"color:#2a0984;\"> </span>∑gMÿ<span style=\"color:#2a0984;\">2</span>bNð¶<span style=\"color:#2a0984;\">4</span>cä½⊆<span style=\"color:#2a0984;\">/</span>4X1κ<span style=\"color:#2a0984;\">7</span>¥f1z<span style=\"color:#2a0984;\"> </span>ϖ1úE<span style=\"color:#2a0984;\">C</span>zf•1<span style=\"color:#2a0984;\">u</span>Mbyc<span style=\"color:#2a0984;\">s</span>1•9¾<span style=\"color:#2a0984;\">t</span>s0Tà<span style=\"color:#2a0984;\">o</span>3hêD<span style=\"color:#2a0984;\">m</span>Ss3Á<span style=\"color:#2a0984;\">e</span>7BíÉ<span style=\"color:#2a0984;\">r</span>ô⋅ãÔ<span style=\"color:#2a0984;\"> </span>φ8Ä″<span style=\"color:#2a0984;\">S</span>SXð¤<span style=\"color:#2a0984;\">u</span>úI¸5<span style=\"color:#2a0984;\">p</span>58uH<span style=\"color:#2a0984;\">p</span>2cß±<span style=\"color:#2a0984;\">o</span>∂T©R<span style=\"color:#2a0984;\">r</span>d6sM<span style=\"color:#2a0984;\">t</span>∪µµξ<span style=\"color:#2a0984;\">!</span>é4Xb</td>
</tr> </table>
</div>Both hands through the fear in front.<br>Wade to give it seemed like this. Yeah but one for any longer. Everything you going inside the kids."
        },
      },
      {
        data: IO.binread('test/fixtures/mail21.box'),
        body_md5: '380ca2bca1d7e013abd4109459a06fac',
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
        body_md5: '56223b1ea04a63269020cb64be7a70b0',
        params: {
          from: 'Gilbertina Suthar <ireoniqla@lipetsk.ru>',
          from_email: 'ireoniqla@lipetsk.ru',
          from_display_name: 'Gilbertina Suthar',
          subject: 'P..E..N-I..S__-E N L A R-G E-M..E..N T-___P..I-L-L..S...Info.',
          to: 'Info <info@znuny.nix>',
          body: 'Puzzled by judith bronte dave. Melvin will want her way through with.<br>Continued adam helped charlie cried. Soon joined the master bathroom. Grinned adam rubbed his arms she nodded.<br>Freemont and they talked with beppe.<br>Thinking of bed and whenever adam.<br>Mike was too tired man to hear.<br>I10PQSHEJl2Nwf&amp;tilde;2113S173 &amp;Icirc;1mEbb5N371L&amp;piv;C7AlFnR1&amp;diams;HG64B242&amp;brvbar;M2242zk&amp;Iota;N&amp;rceil;7&amp;rceil;TBN&amp;ETH; T2xPI&amp;ograve;gI2&amp;Atilde;lL2&amp;Otilde;ML&amp;perp;22Sa&amp;Psi;RBreathed adam gave the master bedroom door.<br>Better get charlie took the wall.<br>Charlotte clark smile he saw charlie.<br>Dave and leaned her tears adam.<br>Maybe we want any help me that.<br>Next morning charlie gazed at their father.<br>Well as though adam took out here. Melvin will be more money. Called him into this one last night.<br>Men joined the pickup truck pulled away. Chuck could make sure that.[1] &amp;dagger;p1C?L&amp;thinsp;I?C&amp;ensp;K?88&amp;ensp;5 E R?EEOD !Chuckled adam leaned forward and le? charlie.<br>Just then returned to believe it here.<br>Freemont and pulling out several minutes.<br><br>[1] &amp;#104;&amp;#116;&amp;#116;&amp;#112;&amp;#58;&amp;#47;&amp;#47;&amp;#1072;&amp;#1086;&amp;#1089;&amp;#1082;&amp;#46;&amp;#1088;&amp;#1092;?jmlfwnwe&amp;ucwkiyyc'
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
        body_md5: '48c2843d219a7430bc84533d67719e95',
        params: {
          from: 'gate <team@support.gate.de>',
          from_email: 'team@support.gate.de',
          from_display_name: 'gate',
          subject: 'Ihre Rechnung als PDF-Dokument',
          to: 'Martin Edenhofer <billing@znuny.inc>',
          body: "Ihre Rechnung als PDF-Dokument <table cellpadding=\"0\" cellspacing=\"0\" bgcolor=\"#d9e7f0\" style=\"font-size: 12px;color: #000000;background-color: #d9e7f0;padding: 0px;margin: 0px;\">
<tr>
<td valign=\"top\"> <br><br> </td>
</tr>
</table>",
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
        body_md5: 'f18cceddc06b60f5cdf2d39a556ab1f2',
        params: {
          from: 'Example Sales <sales@example.com>',
          from_email: 'sales@example.com',
          from_display_name: 'Example Sales',
          subject: 'Example licensing information: No channel available',
          to: 'info@znuny.inc',
          body: 'Dear Mr. Edenhofer, <p>We want to keep you updated on TeamViewer licensing shortages on a regular basis.</p><p><strong>We would like to inform you that since the last message on 25-Nov-2014 there have been temporary session channel exceedances which make it impossible to establish more sessions. Since the last e-mail this has occurred in a total of 1 cases.</strong></p><p>Additional session channels can be added at any time. Please visit our TeamViewer Online Shop (<a href="https://www.teamviewer.com/en/licensing/update.aspx?channel=D842CS9BF85-P1009645N-348785E76E" rel="nofollow noreferrer noopener" target="_blank">https://www.teamviewer.com/en/licensing/update.aspx?channel=D842CS9BF85-P1009645N-348785E76E</a>) for pricing information.</p><p>Thank you - and again all the best with TeamViewer!</p><p>Best regards,</p><p><i>Your TeamViewer Team</i></p><p>P.S.: You receive this e-mail because you are listed in our database as person who ordered a TeamViewer license. Please click here (<a href="http://www.teamviewer.com/en/company/unsubscribe.aspx?id=1009645&amp;ident=E37682EAC65E8CA6FF36074907D8BC14" rel="nofollow noreferrer noopener" target="_blank">http://www.teamviewer.com/en/company/unsubscribe.aspx?id=1009645&amp;ident=E37682EAC65E8CA6FF36074907D8BC14</a>) to unsubscribe from further e-mails.</p>-----------------------------<br>
<a href="http://www.teamviewer.com" rel="nofollow noreferrer noopener" target="_blank">www.teamviewer.com</a><br>
<br> TeamViewer GmbH * Jahnstr. 30 * 73037 Göppingen * Germany<br> Tel. 07161 60692 50 * Fax 07161 60692 79<br> <br> Registration AG Ulm HRB 534075 * General Manager Holger Felgner'
        },
      },
      {
        data: IO.binread('test/fixtures/mail30.box'),
        body_md5: '9ce35920f5702a871f227cfe7ddd3d65',
        params: {
          from: 'Manfred Haert <Manfred.Haert@example.com>',
          from_email: 'Manfred.Haert@example.com',
          from_display_name: 'Manfred Haert',
          subject: 'Antragswesen in TesT abbilden',
          to: 'info@znuny.inc',
          body: "Sehr geehrte Damen und Herren,<br> <br> wir hatten bereits letztes Jahr einen TesT-Workshop mit Ihrem Herrn XXX durchgeführt und würden nun gerne erneut Ihre Dienste in Anspruch nehmen.<br> <br> Mittlerweile setzen wir TesT produktiv ein und würden nun gerne an einem Anwendungsfall (Change-Management) die Machbarkeit des Abbildens eines derzeit \"per Papier\" durchgeführten Antragswesens in TesT prüfen wollen.<br> <br> Wir bitten gerne um ein entsprechendes Angebot.<br> <br> Für Rückfragen stehe ich gerne zur Verfügung. Vielen Dank!<br> <br> <div>--<br> Freundliche Grüße<br> i.A. Manfred Härt<br> <br> <small>Test Somewhere GmbH<br> Ferdinand-Straße 99<br> 99073 Korlben<br> <b>Bitte beachten Sie die neuen Rufnummern!</b><br> Telefon: 011261 00000-2460<br> Fax: 011261 0000-7460<br> manfred.haertel@example.com<br> <a href=\"http://www.example.com\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://www.example.com</a><br> JETZT AUCH BEI FACEBOOK !<br> <a href=\"https://www.facebook.com/test\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">https://www.facebook.com/test</a><span class=\"js-signatureMarker\"></span><br> ___________________________________<br> Test Somewhere GmbH<br> </small> <p><small>Diese e-Mail ist ausschließlich für den beabsichtigten Empfänger bestimmt. Sollten Sie irrtümlich diese e-Mail erhalten haben, unterrichten Sie uns bitte umgehend unter kontakt@example.com und vernichten Sie diese Mitteilung einschließlich der ggf. beigefügten Dateien.<br> Weil wir die Echtheit oder Vollständigkeit der in dieser Nachricht enthaltenen Informationen nicht garantieren können, bitten wir um Verständnis, dass wir zu Ihrem und unserem Schutz die rechtliche Verbindlichkeit der vorstehenden Erklärungen ausschließen, soweit wir mit Ihnen keine anders lautenden Vereinbarungen getroffen haben.</small> </p></div>",
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
        body_md5: '3c58aeb003a55cafb0893d69676b4316',
        params: {
          from: 'Martin Smith <m.Smith@example.com>',
          from_email: 'm.Smith@example.com',
          from_display_name: 'Martin Smith',
          subject: 'Fw: Zugangsdaten',
          to: 'Martin Edenhofer <me@example.com>',
          body: "<div>
<div>&nbsp;</div><div>--<br> don't cry - work! (Rainald Goetz)</div><div> <div> <div>
<div>
<b>Gesendet:</b> Mittwoch, 03. Februar 2016 um 12:43 Uhr<span class=\"js-signatureMarker\"></span><br>
<b>Von:</b> \"Martin Smith\" &lt;m.Smith@example.com&gt;<br>
<b>An:</b> linuxhotel@example.com<br>
<b>Betreff:</b> Fw: Zugangsdaten</div><div>
<div>
<div>&nbsp;</div><div>--<br> don't cry - work! (Rainald Goetz)</div><div> <div> <div>
<div>
<b>Gesendet:</b> Freitag, 22. Januar 2016 um 11:52 Uhr<br>
<b>Von:</b> \"Martin Edenhofer\" &lt;me@example.com&gt;<br>
<b>An:</b> m.Smith@example.com<br>
<b>Betreff:</b> Zugangsdaten</div><div>Um noch vertrauter zu werden, kannst Du mit einen externen E-Mail Account (z. B. <a href=\"http://web.de\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">web.de</a>) mal ein wenig selber “spielen”. :)</div></div></div></div></div></div></div></div></div></div>",
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
      {
        data: IO.binread('test/fixtures/mail38.box'),
        body_md5: 'dcd25707eed638ea568644b206a8596e',
        params: {
          from: 'Martin Edenhofer <me@example.com>',
          from_email: 'me@example.com',
          from_display_name: 'Martin Edenhofer',
          subject: 'test 1234 äöü sig test without attachment ',
          to: 'Martin Edenhofer <me@example.net>',
          cc: nil,
          body: "test 1234 äöü sig test without attachment\n\n",
        },
        attachments: [
          {
            md5: '85223228046c010ce4298947018fa33f',
            filename: 'signature.asc',
          },
        ],
      },
      {
        data: IO.binread('test/fixtures/mail39.box'),
        body_md5: '92553234f01a918314f40973dfc2a303',
        params: {
          from: 'Martin Edenhofer <me@example.com>',
          from_email: 'me@example.com',
          from_display_name: 'Martin Edenhofer',
          subject: 'test 1234 äöü sig test with attachment ',
          to: 'Martin Edenhofer <me@example.net>',
          cc: nil,
          body: "test 1234 äöü sig test with attachment<div><img src=\"cid:2ECB31C9-0E1D-4EBF-BD02-8D8B24208A3E@openvpn\" style=\"width:320px;height:213px;\"></div>",

        },
        attachments: [
          {
            md5: 'c0b9a38d7c02516db9f016dc8063d1e8',
            filename: 'signature.asc',
          },
          {
            md5: 'de909e05b3dd8b8ea50e8db422d0971e',
            filename: 'HKT_Super_Seven_GTS.jpeg',
            cid: '2ECB31C9-0E1D-4EBF-BD02-8D8B24208A3E@openvpn',
          },
          {
            md5: '72c2f9aecd24606b6490ff06ea9361ec',
            filename: 'message.html',
          },
        ],
      },
      {
        data: IO.binread('test/fixtures/mail40.box'),
        body_md5: '5db91cb79f889f80bbf8b47ad98efac9',
        params: {
          from: 'Martin Edenhofer <me@example.com>',
          from_email: 'me@example.com',
          from_display_name: 'Martin Edenhofer',
          subject: 'smime signed 123 öäüß',
          to: 'Martin Edenhofer <me@example.net>',
          cc: nil,
          body: 'smime signed 123 öäüß',
        },
        attachments: [
          {
            md5: '6a0434efa5a2eebf4efe46b04f7b3a9c',
            filename: 'smime.p7s',
          },
        ],
      },
      {
        data: IO.binread('test/fixtures/mail41.box'),
        body_md5: '5872ddcdfdf6bfe40f36cd0408fca667',
        params: {
          from: 'Martin Edenhofer <me@example.com>',
          from_email: 'me@example.com',
          from_display_name: 'Martin Edenhofer',
          subject: 'smime sign & crypt',
          to: 'Martin Edenhofer <me@example.com>',
          cc: nil,
          body: 'no visible content',
        },
        attachments: [
          {
            md5: 'fc68cdcbf343c72e456fbf9477501a72',
            filename: 'smime.p7m',
          },
        ],
      },
      {
        data: IO.binread('test/fixtures/mail42.box'),
        body_md5: '5872ddcdfdf6bfe40f36cd0408fca667',
        params: {
          from: 'Martin Edenhofer <me@example.com>',
          from_email: 'me@example.com',
          from_display_name: 'Martin Edenhofer',
          subject: 'pgp sign & crypt',
          to: 'Martin Edenhofer <me@example.com>',
          cc: nil,
          body: 'no visible content',
        },
        attachments: [
          {
            md5: '8d23752cf0211ab3eba43bc3a530e8ab',
            filename: 'encrypted.asc',
          },
        ],
      },
      {
        data: IO.binread('test/fixtures/mail43.box'),
        body_md5: 'a3f7ff5e1876fdbf051c38649b4c9668',
        params: {
          from: 'Paula <databases.en@example.com>',
          from_email: 'databases.en@example.com',
          from_display_name: 'Paula',
          subject: 'Kontakte',
          to: 'info@example.ch',
          cc: nil,
          body: "<table border=\"0\"><tr><td>
<table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td align=\"center\" valign=\"top\"> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td> </td> </tr> </tbody> </table> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\" bgcolor=\"#ffffff\" style=\"border-style:solid; border-collapse: collapse; border-spacing: 0;\"> <tbody> <tr> <td align=\"center\"> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td align=\"center\"><a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnaWVpLGUzZHx4bnxlZWY=\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnaWVpLGUzZHx4bnxlZWY=</a></td> </tr> </tbody> </table> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td> </td> </tr> </tbody> </table> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td align=\"left\" valign=\"top\" style=\"font-size:15px;color:#222222;\"> <span style=\"color: rgb(255, 102, 0);\"><i>Geben Sie diese Information an den Direktor oder den für Marketing und Umsatzsteigerung verantwortlichen Mitarbeiter Ihrer Firma weiter!</i></span>
</td> </tr> <tr> <td> </td> </tr> </tbody> </table> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td style=\" border-top-width:3px;\"> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td align=\"left\" valign=\"top\" style=\"font-size:15px;color:#222222;\"> <p>Hallo,</p><ul> <li>Sie suchen nach Möglichkeiten, den Umsatz Ihre Firma zu steigern?</li>
<li>Sie brauchen neue Geschäftskontakte?</li>
<li>Sie sind es leid, Kontaktdaten manuell zu erfassen?</li>
<li>Ihr Kontaktdatenanbieter ist zu teuer oder Sie sind mit seinen Dienstleistungen unzufrieden?</li>
<li>Sie möchten Ihre Kontaktinformationen gern effizienter auf dem neuesten Stand halten?</li> </ul> <p><br>Bei uns können Sie mit nur wenigen Clicks <b>Geschäftskontakte</b> verschiedener Länder erwerben.</p><p>Dies ist eine <b>schnelle und bequeme</b> Methode, um Daten zu einem vernünftigen Preis zu erhalten.</p><p>Alle Daten werden <b>ständig aktualisiert</b>m so dass Sie sich keine Sorgen machen müssen.</p><p>&nbsp;</p></td> </tr> <tr> <td> </td> </tr> </tbody> </table> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td align=\"center\"> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td><a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0LnNzdXJobGZzZWVsdGEtLm10cmVzb2YvY2VtL2xpZ25pYWlnaV9hbC9zOG1lOXgyOTdzZW1hL2VlL2xwZWxheHB4Q18ubXhzfEhsODh8Y2M=\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0LnNzdXJobGZzZWVsdGEtLm10cmVzb2YvY2VtL2xpZ25pYWlnaV9hbC9zOG1lOXgyOTdzZW1hL2VlL2xwZWxheHB4Q18ubXhzfEhsODh8Y2M=</a></td> <td> </td> <td></td> <td> </td> <td><a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnaWVpLGUzZHx4bnxlZWY=\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnaWVpLGUzZHx4bnxlZWY=</a></td> </tr> <tr> <td> </td> </tr> <tr> <td align=\"left\" valign=\"top\" style=\"font-size:15px;color:#222222;\"> <p>XLS-Muster herunterladen (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0LnNzdXJobGZzZWVsdGEtLm10cmVzb2YvY2VtL2xpZ25pYWlnaV9hbC9zOG1lOXgyOTdzZW1hL2VlL2xwZWxheHB4Q18ubXhzfEhsODh8Y2M=\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0LnNzdXJobGZzZWVsdGEtLm10cmVzb2YvY2VtL2xpZ25pYWlnaV9hbC9zOG1lOXgyOTdzZW1hL2VlL2xwZWxheHB4Q18ubXhzfEhsODh8Y2M=</a>)</p></td> <td> </td> <td align=\"left\" valign=\"top\" style=\"font-size:15px;color:#222222;\"> </td> <td> </td> <td align=\"left\" valign=\"top\" style=\"font-size:15px;color:#222222;\"> <p>Datenbank bestellen (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnaWVpLGUzZHx4bnxlZWY=\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnaWVpLGUzZHx4bnxlZWY=</a>)</p></td> </tr> </tbody> </table> </td> </tr> <tr> <td> </td> </tr> </tbody> </table> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td align=\"left\" valign=\"top\" style=\"font-size:15px;color:#222222;\"> <p><span style=\"color: rgb(255, 102, 0);\"><b>Die Anmeldung ist absolut kostenlos und unverbindlich.</b> Sie können die Kataloge gemäß Ihren eigenen Kriterien filtern und ein kostenloses Datenmuster bestellen, sobald Sie sich angemeldet haben.</span><br> </p></td> </tr> <tr> <td> </td> </tr> </tbody> </table> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td style=\" border-top-width:3px;\"> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td align=\"left\" valign=\"top\" style=\"font-size:15px;color:#222222;\"> <span style=\"color: rgb(0, 0, 0);\"> <b>Wir haben Datenbanken der folgenden Länder:</b> </span>
<table> <tbody> <tr> <td> <ul> <li>Österreich (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NUQWVpMjZ8fGEx\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NUQWVpMjZ8fGEx</a>)</li>
<li>Belgien (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NFQmVpYzR8fGNh\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NFQmVpYzR8fGNh</a>)</li>
<li>Belarus (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NZQmVpMGJ8fDAw\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NZQmVpMGJ8fDAw</a>)</li> <li>Schweiz (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NIQ2VpYjF8fGY4\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NIQ2VpYjF8fGY4</a>)</li>
<li>Tschechische Republik (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NaQ2VpMTZ8fDc1\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NaQ2VpMTZ8fDc1</a>)</li>
<li>Deutschland (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NFRGVpMDl8fDM1\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NFRGVpMDl8fDM1</a>)</li>
<li>Estland (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NFRWVpYTd8fGNm\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NFRWVpYTd8fGNm</a>)</li>
<li>Frankreich (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NSRmVpNGN8fDBl\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NSRmVpNGN8fDBl</a>)</li>
<li>Vereinigtes Königreich (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NCR2VpNjh8fDA4\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NCR2VpNjh8fDA4</a>)</li>
<li>Ungarn (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NVSGVpNDB8fGQx\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NVSGVpNDB8fGQx</a>)</li>
<li>Irland (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NFSWVpNDd8fGNi\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NFSWVpNDd8fGNi</a>)</li> </ul> </td> <td> <ul> <li>Italien (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NUSWVpOTJ8fDU3\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NUSWVpOTJ8fDU3</a>)</li>
<li>Liechtenstein (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NJTGVpNTF8fDlk\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NJTGVpNTF8fDlk</a>)</li>
<li>Litauen (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NUTGVpN2R8fDgw\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NUTGVpN2R8fDgw</a>)</li>
<li>Luxemburg (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NVTGVpNWZ8fGZh\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NVTGVpNWZ8fGZh</a>)</li>
<li>Lettland (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NWTGVpZWZ8fDE2\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NWTGVpZWZ8fDE2</a>)</li>
<li>Niederlande (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NMTmVpOTV8fDQw\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NMTmVpOTV8fDQw</a>)</li>
<li>Polen (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NMUGVpNGV8fDBm\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NMUGVpNGV8fDBm</a>)</li>
<li>Russland (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NVUmVpZTV8fGVk\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NVUmVpZTV8fGVk</a>)</li>
<li>Slowenien (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NJU2VpN2R8fGYz\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NJU2VpN2R8fGYz</a>)</li>
<li>Slowakei (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NLU2VpNjZ8fDQ5\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NLU2VpNjZ8fDQ5</a>)</li>
<li>Ukraine (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NBVWVpYTd8fDNh\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NBVWVpYTd8fDNh</a>)</li> </ul> </td> </tr> </tbody> </table> </td> </tr> <tr> <td> </td> </tr> </tbody> </table> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td style=\" border-top-width:3px;\"> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td align=\"left\" valign=\"top\" style=\"font-size:15px;color:#222222;\"> <p>Anwendungsmöglichkeiten für Geschäftskontakte<br> <br> </p><ul> <li>
<i>Newsletter senden</i> - Senden von Werbung per E-Mail (besonders effizient).</li>
<li>
<i>Telemarketing</i> - Telefonwerbung.</li>
<li>
<i>SMS-Marketing</i> - Senden von Kurznachrichten.</li>
<li>
<i>Gezielte Werbung</i> - Briefpostwerbung.</li>
<li>
<i>Marktforschung</i> - Telefonumfragen zur Erforschung Ihrer Produkte oder Dienstleistungen.</li> </ul> <p>&nbsp;</p><p>Sie können <b>Abschnitte wählen (filtern)</b> Empfänger gemäß Tätigkeitsbereichen und Standort der Firmen, um die Effizienz Ihrer Werbemaßnahmen zu erhöhen.</p><p>&nbsp;</p></td> </tr> <tr> <td> </td> </tr> </tbody> </table> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td style=\" border-top-width:3px;\"> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td align=\"left\" valign=\"top\" style=\"font-size:15px;color:#222222;\"> <span style=\"color: rgb(255, 0, 0);\">Für jeden Kauf von <b>2016-11-05 23:59:59</b> </span>
<span style=\"color: rgb(255, 0, 0);\">wir gewähren <b>30%</b> Rabatt</span>
<span style=\"color: rgb(255, 0, 0);\"><b>RABATTCODE: WZ2124DD</b></span>
</td> </tr> <tr> <td> </td> </tr> </tbody> </table> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td style=\" border-top-width:3px;\"> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> <table cellspacing=\"0\" cellpadding=\"0\" border=\"0\"> <tbody> <tr> <td align=\"left\" valign=\"top\" style=\"font-size:15px;color:#222222;\"> <p><b>Bestellen Sie online bei:</b><br> </p><p>company-catalogs.com (<a href=\"http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnaWVpLGUzZHx4bnxlZWY=\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnaWVpLGUzZHx4bnxlZWY=</a>)<br> </p><p><b>Für weitere Informationen:</b><br> </p><p>E-Mail: databases.en@example.com<br> Telefon: +370-52-071554 (languages: EN, PL, RU, LT)</p></td> </tr> <tr> <td> </td> </tr> </tbody> </table> </td> </tr> </tbody> </table> <br> </td> </tr> </tbody>
</table>
</td></tr></table>
<br>Unsubscribe from newsletter: Click here (<a href=\"http://business-catalogs.example.com/c2JudXVlcmNic2I4MWk7MTgxOTMyNS1jMmMtNzA=\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://business-catalogs.example.com/c2JudXVlcmNic2I4MWk7MTgxOTMyNS1jMmMtNzA=</a>)",
        },
      },
      {
        data: IO.binread('test/fixtures/mail44.box'),
        body_md5: '2f0f5a21e4393c174d4670a188fc5548',
        params: {
          from: '"Clement.Si" <Claudia.Shu@yahoo.com.>',
          from_email: 'Claudia.Shu@yahoo.com.',
          from_display_name: 'Clement.Si',
          subject: '精益生产闪婚,是谁的责任',
          to: 'abuse@domain.com',
          cc: nil,
        },
      },
      {
        data: IO.binread('test/fixtures/mail45.box'),
        body_md5: '1d847e3626145a9e886914ecf0d89368',
        params: {
          from: '"Ups Rémi" <r.ordonaud@example.com>',
          from_email: 'r.ordonaud@example.com',
          from_display_name: 'Ups Rémi',
          subject: 'Nouveau message contact élégibilité Zammad',
          to: 'James-Max ROGER <james-max.roger@example.com>, Support <zammad@example.com>',
          cc: nil,
        },
      },
      {
        data: IO.binread('test/fixtures/mail48.box'),
        body_md5: '64675a479f80a674eb7c08e385c3622a',
        attachments: [
          {
            md5: '9964263c167ab47f8ec59c48e57cb905',
            filename: 'message.html',
          },
          {
            md5: 'ddbdf67aa2f5c60c294008a54d57082b',
            filename: 'CPG-Reklamationsmitteilung bezügl.01234567895 an Voda-28.03.2017.jpg',
            cid: '485376C9-2486-4351-B932-E2010998F579@home',
          },
        ],
        params: {
          from: 'Martin Edenhofer <martin@example.de>',
          from_email: 'martin@example.de',
          from_display_name: 'Martin Edenhofer',
          subject: 'AW: OTRS / Anfrage OTRS Einführung/Präsentation [Ticket#11545]',
          content_type: 'text/html',
          body: "Enjoy!<div>
<br><div>-Martin<br><span class=\"js-signatureMarker\"></span><br>--<br>Old programmers never die. They just branch to a new address.<br>
</div><br><div><img src=\"cid:485376C9-2486-4351-B932-E2010998F579@home\" style=\"width:640px;height:425px;\"></div></div>",
        },
      },
      {
        data: IO.binread('test/fixtures/mail50.box'),
        body_md5: '154c7d3ae7b94f99589df62882841b08',
        attachments: [],
        params: {
          subject: 'ABC / 123 / Wetterau West / ABC',
        },
      },
      {
        data: IO.binread('test/fixtures/mail51.box'),
        body_md5: '64675a479f80a674eb7c08e385c3622a',
        attachments: [
          {
            md5: '9964263c167ab47f8ec59c48e57cb905',
            filename: 'message.html',
          },
          {
            md5: 'ddbdf67aa2f5c60c294008a54d57082b',
            filename: 'super-seven.jpg',
            cid: '485376C9-2486-4351-B932-E2010998F579@home',
          },
        ],
        params: {
          from: 'Martin Edenhofer <martin@example.de>',
          from_email: 'martin@example.de',
          from_display_name: 'Martin Edenhofer',
          subject: 'AW: OTRS / Anfrage OTRS Einführung/Präsentation [Ticket#11545]',
        },
      },
      {
        data: IO.binread('test/fixtures/mail52.box'),
        body_md5: 'ad0c0727cd7d023ec9065daea03335f7',
        params: {
          from: 'MAILER-DAEMON@example.com (Mail Delivery System)',
          from_email: 'MAILER-DAEMON@example.com',
          from_display_name: 'Mail Delivery System',
          subject: 'Undelivered Mail Returned to Sender',
        },
      },
      {
        data: IO.binread('test/fixtures/mail53.box'),
        body_md5: '104da300f70d5683f007951c9780c83d',
        params: {
          from: 'MAILER-DAEMON (Mail Delivery System)',
          from_email: 'MAILER-DAEMON',
          from_display_name: 'Mail Delivery System',
          subject: 'Undelivered Mail Returned to Sender',
        },
      },
      {
        data: IO.binread('test/fixtures/mail54.box'),
        body_md5: '5872ddcdfdf6bfe40f36cd0408fca667',
        params: {
          from: '"Smith, Karoline, Example DE" <Karoline.Smith@example.com>',
          from_email: 'Karoline.Smith@example.com',
          from_display_name: 'Smith, Karoline, Example DE',
          subject: 'AW: One Net Business',
          body: 'no visible content'
        },
      },
      {
        data: IO.binread('test/fixtures/mail56.box'),
        body_md5: 'ee40e852b9fa18652ea66e2eda1ecbd3',
        attachments: [
          {
            md5: 'cd82962457892d2e2f2d6914da3a88ed',
            filename: 'message.html',
          },
          {
            md5: 'ddbdf67aa2f5c60c294008a54d57082b',
            filename: 'Hofjägeralle Wasserschaden.jpg',
          },
        ],
        params: {
          from: 'Martin Edenhofer <martin@example.de>',
          from_email: 'martin@example.de',
          from_display_name: 'Martin Edenhofer',
          subject: 'AW: OTRS / Anfrage OTRS Einführung/Präsentation [Ticket#11545]',
          content_type: 'text/html',
          body: 'Enjoy!',
        },
      },
      {
        data: IO.binread('test/fixtures/mail57.box'),
        body_md5: '3c5e4cf2d2a9bc572f10cd6222556027',
        attachments: [
          {
            md5: 'ddbdf67aa2f5c60c294008a54d57082b',
            filename: 'Hofjägeralle Wasserschaden.jpg',
          },
        ],
        params: {
          from: 'example@example.com',
          from_email: 'example@example.com',
          from_display_name: '',
          subject: 'W.: Invoice',
          content_type: 'text/plain',
          body: ' 


----- Original Nachricht ----
Von:     example@example.com
An:      bob@example.com
Datum:   30.05.2017 16:17
Betreff: Invoice

Dear Mrs.Weber

anbei mal wieder ein paar Invoice.

Wünsche Ihnen noch einen schönen Arbeitstag.

Mit freundlichen Grüßen

Bob Smith
',
        },
      },
      {
        data: IO.binread('test/fixtures/mail58.box'),
        body_md5: '548917e0bff0806f9b27c09bbf23bb38',
        params: {
          from: 'Yangzhou ABC Lighting Equipment <bob@example.com>, LTD <ly@example.com>',
          from_email: 'bob@example.com',
          from_display_name: 'Yangzhou ABC Lighting Equipment',
          subject: 'new design solar street lights',
          content_type: 'text/plain',
          body: "äöüß ad asd

-Martin

--
Old programmers never die. They just branch to a new address."
        },
      },
      {
        data: IO.binread('test/fixtures/mail59.box'),
        body_md5: '548917e0bff0806f9b27c09bbf23bb38',
        params: {
          from: '"Yangzhou ABC Lighting Equipment " <>, "LTD" <ly@example.com>',
          from_email: 'ly@example.com',
          from_display_name: 'LTD',
          subject: 'new design solar street lights',
          content_type: 'text/plain',
          body: "äöüß ad asd

-Martin

--
Old programmers never die. They just branch to a new address."
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
          assert_equal(Digest::MD5.hexdigest(file[:params][key.to_sym].to_s), Digest::MD5.hexdigest(data[:body].to_s))
        else
          if file[:params][key.to_sym] == nil
            assert_nil(data[key.to_sym], "check #{key}")
          else
            assert_equal(file[:params][key.to_sym], data[key.to_sym], "check #{key}")
          end
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
            file_md5 = Digest::MD5.hexdigest(attachment_parser[:data])
            #puts 'Attachment:' + attachment_parser.inspect + '-' + file_md5
            if attachment[:md5] == file_md5
              found = true
              assert_equal(attachment[:filename], attachment_parser[:filename])
              if attachment[:cid]
                assert_equal(attachment[:cid], attachment_parser[:preferences]['Content-ID'])
              end
            end
          }
          if !found
            assert(false, "Attachment not found! MD5: #{attachment[:md5]} - #{attachment[:filename]}")
          end
        }
        assert_equal( attachment_count_config, attachment_count_email )
      end
    }
  end
end
