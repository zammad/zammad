# encoding: utf-8
# rubocop:disable all
require 'test_helper'

class EmailParserTest < ActiveSupport::TestCase
  test 'parse' do
    files = [
      {
        data: IO.binread('test/fixtures/mail1.box'),
        body_md5: 'cddd315fac96b3aa836be04a2a8553c2',
        params: {
          from: 'John.Smith@example.com',
          from_email: 'John.Smith@example.com',
          from_display_name: '',
          subject: 'CI Daten für PublicView ',
          content_type: 'text/html',
          body: '<div>
<div>Hallo Martin,</div>
<div> </div>
<div>wie besprochen hier noch die Daten für die Intranetseite:</div>
<div> </div>
<div>Schriftart/-größe: Verdana 11 Pt wenn von Browser nicht unterstützt oder nicht vorhanden wird Arial 11 Pt genommen</div>
<div>Schriftfarbe: Schwarz</div>
<div>Farbe für die Balken in der Grafik: D7DDE9 (Blau)</div>
<div> </div>
<div>Wenn noch was fehlt oder du was brauchst sag mir Bescheid.</div>
<div> </div>
<div>Mit freundlichem Gruß<br><br>John Smith<br>Service und Support<br><br>Example Service AG &amp; Co.</div>
<div>Management OHG<br>Someware-Str. 4<br>xxxxx Someware<br><br>
</div>
<div>Tel.: +49 001 7601 462<br>Fax: +49 001 7601 472 </div>
<div>
john.smith@example.com
</div>
<div>
<a href="http://www.example.com" rel="nofollow noreferrer noopener" target="_blank">www.example.com</a>
</div>
<div>
<br>OHG mit Sitz in Someware<br>AG: Someware - HRA 4158<br>Geschäftsführung: Tilman Test, Klaus Jürgen Test, </div>
<div>Bernhard Test, Ulrich Test<br>USt-IdNr. DE 1010101010<br><br>Persönlich haftende geschäftsführende Gesellschafterin: </div>
<div>Marie Test Example Stiftung, Someware<br>Vorstand: Rolf Test<br><br>Persönlich haftende Gesellschafterin: </div>
<div>Example Service AG, Someware<br>AG: Someware - HRB xxx<br>Vorstand: Marie Test </div>
<div> </div>
</div>',
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
        body_md5: '0bd5580b06c4c4061acd1472eefb149e',
        params: {
          from: '"Günther John | Example GmbH" <k.guenther@example.com>',
          from_email: 'k.guenther@example.com',
          from_display_name: 'Günther John | Example GmbH',
          subject: 'Ticket Templates',
          content_type: 'text/html',
          body: '<div>
<p>Hallo Martin,</p>
<p>&nbsp;</p>
<p>ich möchte mich gern für den Beta-Test für die Ticket Templates unter XXXX 2.4 anmelden.</p>
<p>&nbsp;</p>
<div>
<p>&nbsp;</p>
<p>Mit freundlichen Grüßen</p>
<p>John Günther</p>
<p>&nbsp;</p>
<p>example.com (<a href="http://www.GeoFachDatenServer.de" rel="nofollow noreferrer noopener" target="_blank">http://www.GeoFachDatenServer.de</a>) – profitieren Sie vom umfangreichen Daten-Netzwerk </p>
<p>&nbsp;</p>
<p>_ __ ___ ____________________________ ___ __ _</p>
<p>&nbsp;</p>
<p>Example GmbH</p>
<p>Some What</p>
<p>&nbsp;</p>
<p>Sitz: Someware-Straße 9, XXXXX Someware</p>
<p>&nbsp;</p>
<p>M: +49 (0) XXX XX XX 70</p>
<p>T: +49 (0) XXX XX XX 22</p>
<p>F: +49 (0) XXX XX XX 11</p>
<p>W: <a href="http://www.example.de" rel="nofollow noreferrer noopener" target="_blank">http://www.example.de</a></p>
<p>&nbsp;</p>
<p>Geschäftsführer: John Smith</p>
<p>HRB XXXXXX AG Someware</p>
<p>St.-Nr.: 112/107/05858</p>
<p>&nbsp;</p>
<p>ISO 9001:2008 Zertifiziert -Qualitätsstandard mit Zukunft</p>
<p>_ __ ___ ____________________________ ___ __ _</p>
<p>&nbsp;</p>
<p>Diese Information ist ausschließlich für den Adressaten bestimmt und kann vertrauliche oder gesetzlich geschützte Informationen enthalten. Wenn Sie nicht der bestimmungsgemäße Adressat sind, unterrichten Sie bitte den Absender und vernichten Sie diese Mail. Anderen als dem bestimmungsgemäßen Adressaten ist es untersagt, diese E-Mail zu lesen, zu speichern, weiterzuleiten oder ihren Inhalt auf welche Weise auch immer zu verwenden.</p>
</div>
<p>&nbsp;</p>
<span class="js-signatureMarker"></span><p><b>Von:</b> Fritz Bauer [mailto:me@example.com] <br><b>Gesendet:</b> Donnerstag, 3. Mai 2012 11:51<br><b>An:</b> John Smith<br><b>Cc:</b> Smith, John Marian; johnel.fratczak@example.com; ole.brei@example.com; Günther John | Example GmbH; bkopon@example.com; john.heisterhagen@team.example.com; sven.rocked@example.com; michael.house@example.com; tgutzeit@example.com<br><b>Betreff:</b> Re: OTRS::XXX Erweiterung - Anhänge an CI\'s</p>
<p>&nbsp;</p>
<p>Hallo,</p>
<p>&nbsp;</p>
<p>ich versuche an den Punkten anzuknüpfen.</p>
<p>&nbsp;</p>
<p><b>a) LDAP Muster Konfigdatei</b></p>
<p>&nbsp;</p>
<p><a href="https://wiki.lab.example.com/doku.php?id=xxxx:start&amp;#ldap" rel="nofollow noreferrer noopener" target="_blank">https://wiki.lab.example.com/doku.php?id=xxxx:start&amp;#ldap</a></p>
<p>&nbsp;</p>
<p>PS: Es gibt noch eine Reihe weiterer Möglichkeiten, vor allem im Bezug auf Agenten-Rechte/LDAP Gruppen Synchronisation. Wenn Ihr hier weitere Informationen benötigt, einfach im Wiki die Aufgabenbeschreibung rein machen und ich kann eine Beispiel-Config dazu legen.</p>
<p>&nbsp;</p>
<p><b>b) Ticket Templates</b></p>
<p>Wir haben das Paket vom alten Maintainer übernommen, es läuft nun auf XXXX 2.4, XXXX 3.0 und XXXX 3.1. Wir haben das Paket um weitere Funktionen ergänzt und würden es gerne hier in diesen Kreis zum Beta-Test bereit stellen.</p>
<p>&nbsp;</p>
<p>Vorgehen:</p>
<p>Wer Interesse hat, bitte eine Email an mich und ich versende Zugänge zu den Beta-Test-Systemen. Nach ca. 2 Wochen werden wir die Erweiterungen in der Version 1.0 veröffentlichen.</p>
<p>&nbsp;</p>
<p><b>c) XXXX Entwickler Schulung</b></p>
<p>Weil es immer wieder Thema war, falls jemand Interesse hat, das XXXX bietet nun auch OTRS Entwickler Schulungen an (<a href="http://www.example.com/kurs/xxxx_entwickler/" rel="nofollow noreferrer noopener" target="_blank">http://www.example.com/kurs/xxxx_entwickler/</a>).</p>
<p>&nbsp;</p>
<p><b>d) Genelle Fragen?</b></p>
<p>Haben sich beim ein oder anderen generell noch Fragen aufgetan?</p>
<p>&nbsp;</p>
<p>Viele Grüße!</p>
<p>&nbsp;</p>
<div>
<p>-Fritz</p>
<p>On May 2, 2012, at 14:25 , John Smith wrote:<br><br></p>
<p>Moin Moin,<br><br>die Antwort ist zwar etwas spät, aber nach der Schulung war ich krank und danach<br>hatte ich viel zu tun auf der Arbeit, sodass ich keine Zeit für XXXX hatte.<br>Ich denke das ist allgemein das Problem, wenn sowas nebenbei gemacht werden muss.<br><br>Wie auch immer, danke für die mail mit dem ITSM Zusatz auch wenn das zur Zeit bei der Example nicht relevant ist.<br><br>Ich habe im XXXX Wiki den Punkt um die Vorlagen angefügt.<br>Ticket Template von John Bäcker<br>Bei uns habe ich das Ticket Template von John Bäcker in der Version 0.1.96 unter XXXX 3.0.10 implementiert. <br><br>Fritz wollte sich auch um das andere Ticket Template Modul kümmern und uns zur Verfügung stellen, welches unter XXXX 3.0 nicht lauffähig sein sollte.<br><br>Im Wiki kann ich die LDAP Muster Konfigdatei nicht finden.<br>Hat die jemand von euch zufälligerweise ?<br><br>Danke und Gruß<br>John Smith<br><br>Am 4. April 2012 08:24 schrieb Smith, John Marian &lt;john.smith@example.com&gt;:<br>Hallo zusammen,<br><br>ich hoffe Ihr seid noch gut nach Hause gekommen am Mittwoch. Der XXX Kurs Donnerstag und Freitag war noch ganz gut, wobei ich mir den letzten halben Tag eigentlich hätte schenken können.<br><br>Soweit ich weiß arbeitet Ihr nicht mit XXX? Falls doch habe ich hier eine tolle (eigentlich) kostenpflichtige Erweiterung für Euch.<br><br>Es handelt sich um eine programmiertes Paket von der XXXX AG. Die Weitergabe ist legal.<br><br>Mit dem Paket kann man Anhänge an CI’s (Configuration Items) verknüpfen. Das ist sehr praktisch wenn man zum Beispiel Rechnungen an Server, Computern und und und anhängen möchte.<br><br>Der Dank geht an Frank Linden, der uns das Paket kostenlos zur Verfügung gestellt hat.<br><br>Viele Grüße aus Someware<br><br>John<br><br>_________________________<br>SysAdmin<br>John Marian Smith<br>IT-Management<br><br>Example GmbH &amp; Co. KG<br>Der Provider für<br>Mehrwertdienste &amp; YYY<br><br>Someware 23<br>XXXXX Someware<br><br>Tel. (01802) XX XX XX - 42<br>Fax (01802) XX XX XX - 99<br>nur 6 Cent je Anruf aus dem dt. Festnetz,<br>max. 42 Cent pro Min. aus dem Mobilfunknetz<br><br>E-Mail john.smith@Example.de<br>Web <a href="http://www.Example.de" rel="nofollow noreferrer noopener" target="_blank">www.Example.de</a><br>Amtsgericht Hannover HRA xxxxxxxx<br>Komplementärin: Example Verwaltungs- GmbH<br>Vertreten durch: Somebody, Somebody<br>Amtsgericht Someware HRB XXX XXX<br><br>_________________________ <br>Highlights der Example Contact Center-Suite:<br>Virtual XXX&amp;Power-XXX, Self-Services&amp;XXX-Portale,<br>XXX-/Web-Kundenbefragungen, CRM, PEP, YYY</p>
</div>
</div>',
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
        body_md5: '0e48622e886f03d976ccbda0ec7961a1',
        params: {
          from: '"Hans BÄKOSchönland" <me@bogen.net>',
          from_email: 'me@bogen.net',
          from_display_name: 'Hans BÄKOSchönland',
          subject: 'utf8: 使って / ISO-8859-1: Priorität"  / cp-1251: Сергей Углицких',
          content_type: 'text/html',
          body: '<p>this is a test</p><br><hr> Compare Cable, DSL or Satellite plans: As low as $2.95.  (<a href="http://localhost/8HMZENUS/2737??PS=" rel="nofollow noreferrer noopener" target="_blank">http://localhost/8HMZENUS/2737??PS=</a>) <br> <br> Test1:– <br> Test2:&amp; <br> Test3:∋ <br> Test4:&amp; <br> Test5:=',
        },
      },
      {
        data: IO.binread('test/fixtures/mail7.box'),
        body_md5: '7288f2e0d4551aac7cbaac47eaea9a24',
        params: {
          from: 'Eike.Ehringer@example.com',
          from_email: 'Eike.Ehringer@example.com',
          from_display_name: '',
          subject: 'AW:Installation [Ticket#11392]',
          content_type: 'text/html',
          body: 'Hallo.<br>Jetzt muss ich dir noch kurzfristig absagen für morgen.<br>Lass uns evtl morgen Tel.<br><br>Mfg eike <br><br><div>
<div>Martin Edenhofer via Znuny Team --- Installation [Ticket#11392] --- </div>
<span class="js-signatureMarker"></span><div><br>
Von: "Martin Edenhofer via Znuny Team" &lt;support@example.com&gt; <br>
An eike.xx@xx-corpxx.com <br>
Datum: Mi., 13.06.2012 14:30 <br>
Betreff Installation [Ticket#11392] <br> <hr>
<br><pre>Hi Eike,

anbei wie gestern telefonisch besprochen Informationen zur Vorbereitung.

a) Installation von <a href="http://ftp.gwdg.de/pub/misc/zammad/RPMS/fedora/4/zammad-3.0.13-01.noarch.rpm" rel="nofollow noreferrer noopener" target="_blank">http://ftp.gwdg.de/pub/misc/zammad/RPMS/fedora/4/zammad-3.0.13-01.noarch.rpm</a> (dieses RPM ist RHEL kompatible) und dessen Abhängigkeiten.

b) Installation von "mysqld" und "perl-DBD-MySQL".

Das wäre es zur Vorbereitung!

Bei Fragen nur zu!

 -Martin

--
Martin Edenhofer

Znuny GmbH // Marienstraße 11 // 10117 Berlin // Germany

P: +49 (0) 30 60 98 54 18-0
F: +49 (0) 30 60 98 54 18-8
W: <a href="http://example.com" rel="nofollow noreferrer noopener" target="_blank">http://example.com</a> 

Location: Berlin - HRB 139852 B Amtsgericht Berlin-Charlottenburg
Managing Director: Martin Edenhofer

</pre>
</div>
</div>',
        },
      },
      {
        data: IO.binread('test/fixtures/mail8.box'),
        body_md5: '6b2b3701aaf6b5a1c351664e7d4bab03',
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
          body: '<img src="cid:_1_08FC9B5808FC7D5C004AD64FC1257A28">
<br>
<br>Gravierend?<br>

<br>
Mit freundlichen Grüßen <br>
<br>
<b>Franz Schäfer</b>
<br>
Manager Information Systems <br>
<br>
Telefon 
+49 000 000 8565
<br>
christian.schaefer@example.com <br>
<br>
<b>Example Stoff GmbH</b>
<br>
Fakultaet
<br>
Düsseldorfer Landstraße 395
<br>
D-00000 Hof
<br>
<a href="http://www.example.com" rel="nofollow noreferrer noopener" target="_blank"><u><a href="http://www.example.com" rel="nofollow noreferrer noopener" target="_blank">http://www.example.com</a></u></a> <br>
<br> <hr>
<br>
Geschäftsführung/Management Board: Jan Bauer (Vorsitzender/Chairman), Oliver Bauer, Heiko Bauer, Boudewijn Bauer
<br>
Sitz der Gesellschaft / Registered Office: Hof
<br>
Registergericht / Commercial Register of the Local Court: HRB 0000 AG Hof',
        },
      },
      {
        data: IO.binread('test/fixtures/mail9.box'),
        body_md5: '8a028710b157c68ace0a5b2264c44da7',
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
          body: 'Enjoy!<div>
<br><div>-Martin<br><span class="js-signatureMarker"></span><br>--<br>Old programmers never die. They just branch to a new address.<br>
</div>
<br><div><img src="cid:485376C9-2486-4351-B932-E2010998F579@home" style="width:640px;height:425px;"></div>
</div>'
        },
      },
      {
        data: IO.binread('test/fixtures/mail10.box'),
        body_md5: 'f0d92c2941d99583a40db932a1c038f5',
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
          body: '<div>
<p>Herzliche Grüße aus Oberalteich sendet Herrn Smith</p>
<p>&nbsp;</p>
<p>Sepp Smith - Dipl.Ing. agr. (FH)</p>
<p>Geschäftsführer der example Straubing-Bogen</p>
<p>Klosterhof 1 | 94327 Bogen-Oberalteich</p>
<p>Tel: 09422-505601 | Fax: 09422-505620</p>
<p>Internet: <a href="http://example-straubing-bogen.de/" rel="nofollow noreferrer noopener" target="_blank">http://example-straubing-bogen.de</a></p>
<p>Facebook: <a href="http://facebook.de/examplesrbog" rel="nofollow noreferrer noopener" target="_blank">http://facebook.de/examplesrbog</a></p>
<p><b><img border="0" src="cid:image001.jpg@01CDB132.D8A510F0" alt="Beschreibung: Beschreibung: efqmLogo" style="width:60px;height:19px;"></b><b> - European Foundation für Quality Management</b></p>
<p>&nbsp;</p>
</div>',
        },
      },
      {
        data: IO.binread('test/fixtures/mail11.box'),
        body_md5: '180b01f4565dd07434087f5554ba0e2a',
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
          body: '<a href="http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-2/http://web2.cylex.de/advent2012?b2b" rel="nofollow noreferrer noopener" target="_blank">http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-2/http://web2.cylex.de/advent2012?b2b</a>
<p>Lieber CYLEX Eintragsinhaber,</p><p>das Jahr neigt sich dem Ende und die besinnliche Zeit beginnt laut Kalender mit dem<br> 1. Advent. Und wie immer wird es in der vorweihnachtlichen Zeit meist beruflich und privat<br> so richtig schön hektisch.</p><p>Um Ihre Weihnachtsstimmung in Schwung zu bringen kommen wir nun mit unserem Adventskalender ins Spiel. Denn 24 Tage werden Sie unsere netten Geschichten, Rezepte und Gewinnspiele sowie ausgesuchte Geschenktipps und Einkaufsgutscheine online begleiten. Damit lässt sich Ihre Freude auf das Fest garantiert mit jedem Tag steigern.</p><br> Einen gemütlichen Start in die Adventszeit wünscht Ihnen <a href="http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-1/http://web2.cylex.de/advent2012?b2b" rel="nofollow noreferrer noopener" target="_blank">http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-1/http://web2.cylex.de/advent2012?b2b</a> <br> <p>Ihr CYLEX Team<br>
<br>
<strong>P.S.</strong> Damit Sie keinen Tag versäumen, empfehlen wir Ihnen den Link des Adventkalenders (<a href="http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-3/http://web2.cylex.de/advent2012?b2b" rel="nofollow noreferrer noopener" target="_blank">http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-3/http://web2.cylex.de/advent2012?b2b</a>) in<br> Ihrer Lesezeichen-Symbolleiste zu ergänzen.</p><p>&nbsp;</p><br> Impressum <br> S.C. CYLEX INTERNATIONAL S.N.C.<br> Sat. Palota 119/A RO 417516 Palota Romania <br> Tel.: +49 208/62957-0 | <br> Geschäftsführer: Francisc Osvald<br> Handelsregister: J05/1591/2009<br> USt.IdNr.: RO26332771 <br>
serviceteam@cylex.de<br>
Homepage (<a href="http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-98/http://web2.cylex.de/Homepage/Home.asp" rel="nofollow noreferrer noopener" target="_blank">http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-98/http://web2.cylex.de/Homepage/Home.asp</a>)<br>
Newsletter abbestellen (<a href="http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-99/http://newsletters.cylex.de/unsubscribe.aspx?uid=4134001&amp;d=www.cylex.de&amp;e=enjoy@znuny.com&amp;sc=3009&amp;l=d" rel="nofollow noreferrer noopener" target="_blank">http://newsletters.cylex.de/ref/www.cylex.de/sid-105/uid-4134001/lid-99/http://newsletters.cylex.de/unsubscribe.aspx?uid=4134001&amp;d=www.cylex.de&amp;e=enjoy@znuny.com&amp;sc=3009&amp;l=d</a>)',
        },
      },
      {
        data: IO.binread('test/fixtures/mail12.box'),
        body_md5: 'edcb93c692f914b2fb9eb5bc244c8fa0',
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
          body: '<div>
<p>Hallo Herr Edenhofer,</p>
<p>&nbsp;</p>
<p>möglicherweise haben wir für unsere morgige Veranstaltung ein Problem mit unserer Develop-Umgebung.<br> Der Kollege Smith wollte uns noch die Möglichkeit geben, direkt auf die Datenbank zugreifen zu können, hierzu hat er Freitag noch einige Einstellungen vorgenommen und uns die Zugangsdaten mitgeteilt. Eine der Änderungen hatte aber offenbar zur Folge, dass ein Starten der Develop-Anwendung nicht mehr möglich ist (s. Fehlermeldung)<br>
<img src="cid:image002.png@01CDD14F.29D467A0" style="width:577px;height:345px;"></p>
<p>&nbsp;</p>
<p>Herr Smith ist im Urlaub, er wurde von seinen Datenbank-Kollegen kontaktiert aber offenbar lässt sich nicht mehr 100%ig rekonstruieren, was am Freitag noch verändert wurde.<br> Meinen Sie, dass Sie uns bei der Behebung der o. a. Störung morgen helfen können? Die Datenbank-Kollegen werden uns nach besten Möglichkeiten unterstützen, Zugriff erhalten wir auch.</p>
<p>&nbsp;</p>
<p>Mit freundlichen Grüßen</p>
<p>&nbsp;</p>
<p>Alex Smith<br>
<br> Abteilung IT-Strategie, Steuerung &amp; Support<br> im Bereich Informationstechnologie<br>
<br> Example – Example GmbH<br> (Deutsche Example)<br> Longstreet 5<br> 11111 Frankfurt am Main<br>
<br> Telefon: (069) 11 1111 – 11 30</p>
<p>Telefon ServiceDesk: (069) 11 1111 – 12 22<br> Telefax: (069) 11 1111 – 14 85<br> Internet: <a href="http://www.example.com/" title="http://www.example.com/" rel="nofollow noreferrer noopener" target="_blank">www.example.com</a></p>
<p>&nbsp;</p>
<span class="js-signatureMarker"></span><p>-----Ursprüngliche Nachricht-----<br> Von: Martin Edenhofer via Znuny Sales [mailto:example@znuny.com] <br> Gesendet: Freitag, 30. November 2012 13:50<br> An: Smith, Alex<br> Betreff: Agenda [Ticket#11995]</p>
<p>&nbsp;</p>
<p>Sehr geehrte Frau Smith,</p>
<p>&nbsp;</p>
<p>ich habe (wie telefonisch avisiert) versucht eine Agenda für nächste Woche zusammen zu stellen.</p>
<p>&nbsp;</p>
<p>Leider ist es mir dies Inhaltlich nur unzureichend gelungen (es gibt zu wenig konkrete Anforderungen im Vorfeld :) ).</p>
<p>&nbsp;</p>
<p>Dadurch würde ich gerne am Dienstag als erste Amtshandlung (mit Herrn Molitor im Boot) die Anforderungen und Ziele der zwei Tage, Mittelfristig und Langfristig definieren. Aufgrund dessen können wir die Agenda der zwei Tage fixieren. Inhaltlich können wir (ich) alles abdecken, von daher gibt es hier keine Probleme. ;)</p>
<p>&nbsp;</p>
<p>Ist dies für Sie so in Ordnung?</p>
<p>&nbsp;</p>
<p>Für Fragen stehe ich gerne zur Verfügung!</p>
<p>&nbsp;</p>
<p>Ich freue mich auf Dienstag,</p>
<p>&nbsp;</p>
<p>Martin Edenhofer</p>
<p>&nbsp;</p>
<p>--</p>
<p>Enterprise Services for OTRS</p>
<p>&nbsp;</p>
<p>Znuny GmbH // Marienstraße 11 // 10117 Berlin // Germany</p>
<p>&nbsp;</p>
<p>P: +49 (0) 30 60 98 54 18-0</p>
<p>F: +49 (0) 30 60 98 54 18-8</p>
<p>W: <a href="http://znuny.com" rel="nofollow noreferrer noopener" target="_blank">http://znuny.com</a>
</p>
<p>&nbsp;</p>
<p>Location: Berlin - HRB 139852 B Amtsgericht Berlin-Charlottenburg Managing Director: Martin Edenhofer</p>
</div><div>
<p>-------------------------------------------------------------------------------------------------</p>
<p>Rechtsform: GmbH</p>
<p>Geschaeftsfuehrer: Dr. Carl Heinz Smith, Dr. Carsten Smith</p>
<p>Sitz der Gesellschaft und Registergericht: Frankfurt/Main, HRB 11111</p>
<p>Alleiniger Gesellschafter: Bundesrepublik Deutschland,</p>
<p>vertreten durch das XXX der Finanzen.</p>
</div>',
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
        body_md5: '744d7ba23ee99e7d98d8b2227d6c2bda',
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
        body_md5: '2e162549ffb5c7832c7be0d6538e8aa1',
        params: {
          from: '"我" <>',
          from_email: '"我" <>',
          from_display_name: '',
          subject: '《欧美简讯》',
          to: '377861373 <377861373@qq.com>',
        },
      },
      {
        data: IO.binread('test/fixtures/mail20.box'),
        body_md5: '6a25b76fcd22dd8a7740e9030e7513ef',
        params: {
          from: 'Health and Care-Mall <drugs-cheapest8@sicor.com>',
          from_email: 'drugs-cheapest8@sicor.com',
          from_display_name: 'Health and Care-Mall',
          subject: 'The Highest Grade Drugs And EXTRA LOW Price .',
          to: 'info2@znuny.com',
          body: "________________________________________________________________________Yeah but even when they. Beth liî ed her neck as well <br>
<div>
<br> óû5aHw5³½IΨµÁxG⌊o8KHCmς9-Ö½23QgñV6UAD¿ùAX←t¨Lf7⊕®Ir²r½TLA5pYJhjV gPnãM36V®E89RUDΤÅ©ÈI9æsàCΘYEϒAfg∗bT¡1∫rIoiš¦O5oUIN±IsæSØ¹Pp Ÿÿq1FΧ⇑eGOz⌈F³R98y§ 74”lTr8r§HÐæuØEÛPËq VmkfB∫SKNElst4S∃Á8üTðG°í lY9åPu×8&gt;RÒ¬⊕ΜIÙzÙCC4³ÌQEΡºSè!XgŒs. <br> çγ⇓B<a href=\"http://pxmzcgy.storeprescription.ru?zz=fkxffti\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://pxmzcgy.storeprescription.ru?zz=fkxffti</a>Calm dylan for school today.<br>Closing the nursery with you down. Here and made the mess. Maybe the oï from under his mother. Song of course beth touched his pants.<br>When someone who gave up from here. Feel of god knows what. <br> TBϖ∃M5T5ΕEf2û–N¶ÁvΖ'®⇓∝5SÐçË5 Χ0jΔHbAgþE—2i6A2lD⇑LGjÓnTOy»¦Hëτ9’:Their mother and tugged it seemed like <br> d3RsV¶HÓΘi¯B∂gax1bîgdHä3rýJÿ1aIKÇ² n1jfaTk³Vs395ß C˜lBl‘mxGo0√úXwT8Ya õ8ksa∫f·ℵs”6ÑQ ÍAd7$p32d1e∏æe.0”×61aîΚ63αSMû CdL∪1i↔xcaa5êR3l6Lc3iãz16só9èU zDE²aEÈ¨gs25ËÞ hE§cl⊃¢¢ÂoÒÂµBw²zF© qÏkõaXUius1r0⊆ d•∈ø$¢Z2F12­8l.07d56PÚl25JAO6 <br> 45loVóiv1i2ãΥ⌊að⊃d2gÃΥ3™rÎÍu¸aWjO8 n40–Soyè2u¡∅Î3p¢JΜNeÌé×jráÒrΚ 1ÌÓ9AúrAkc8nuEtl22ai‡OB8vSbéσeιõq1+65cw Òs8Uaò4PrsE1y8 〈fMElhϒ⋅Jo8pmzwjˆN¥ wv39aW¡WtsvuU3 1aœ³$éΝnR2OÏ⌉B.∀þc→5Ê9χw5pÃ⁄N VfE³ãiσjGpa5¶kgg¡ìcWrUq5æakx2h 0Fè4P¸ÕLñrn22ÏoþÝÐHfoRb2eUαw6sñN‾ws¶§3ΒiòX¶¸ofgtHnR⊥3âase9álF¿H5 à6BÁa⊃2iϒsô¡ói ÅkMylÚJ¾ÄoQ–0ℑwvmùþ Ëˆμ\"aQ7jVse6Ðf «hÜp$Lâr£3i1tÚ.323h5qP8g0♥÷R÷ <br> ·iƒPV1Β∋øiF¤RÃa4v3âgL9¢wr¨7ø×aÏû0η þ1àßStuÞ³u7á¡lpÑocEe·SLlrVàXj ⊥Uµ¢F¬48ðov7¨Arm×4ÍcùVwÞe1§⊇N ÂÛ4äaLþZ2ski×5 c€pBlûù6∂olÃfÚwKß3Ñ 4iíla4C³êsREÕ1 ãeIó$âz8t442fG.¸1≤¸2F’Ã152in⊄ C2v7Ci7·X8a×ú5NlþU〉ιicO∑«s·iKN UuϒjSÃj5Ýu÷Jü§pn5°§e¥Û3℘rÆW‡ò J‹S7A1j0sc&amp;ºpkt·qqøiZ56½vn8¨∗eîØQ3+7Î3Š ∑RkLaKXËasÐsÌ2 ïÇ­¶lDäz8oã78wwU–ÀC T6Uûaϒ938sÌ0Gÿ Oxó∈$98‘R2ÂHï5.ÒL6b9θrδÜ92f9j <br> Please matt on his neck. Okay matt huï ed into your mind <br> 1È±ΑAYQªdN¬ÚϒXT00ÀvI∨ío8-½b®8AΕºV4LgÕ↑7LKtgcEiw­yR5YýæGRA1°I¿0CïCàTiü/þwc0Ax211SÜÂùŒTÁ2êòHpNâùM6È¾0A5Tb»:Simmons and now you really is what. Matt picked up this moment later that. <br> 25¯yV9ÙßYeg·↑DnJ3l4tÝæb1os∏jll÷iSÐiwBÎ4n0ú1Ö ªf÷Ña§1løsuÚ8ê 2LCblgvN½o¼oP3wn♠90 FZora&amp;M™xsΚbbÂ ç5Ãξ$Âô·×2iGæ∇1⊇Ξ¬3.0P0κ53VÁö03ÝYz AZ4KwdduÜvvuB↑ΒaÄ’THi0—93rZεj0 §rΜÅa2­·§s7¸Ιf 8⇓þolW„6Ýo6yH¥wKZ∧6 21hÒaKJ“ℜs48IÌ ÔÀ¬­$ZΣ¹ü2ñÙ6B42YMZ.Ô¹V¼9f·0å54⌈R8 <br> ÷w\"9N2gBÀaðSê¢s≅gGÔo0Dn4n↵γ7⊗eS7eýxf3Jd q÷CMaÍä³isNMZp zz0˜lΚLw8oë29ww¤§Qu ¥D⌈íaýË¢ésJ8Á¬ 3oùÙ$¦1Nℜ1&gt;Rét7WPM¨.¶8¹D92k5D9∗8≈R Sj·Ψ8pΣïKùi6rrÔrbÛu¬i2V∗∏v5ª10a27BÁ Ú♦Ξsa9j3χsa¯iΟ Oi℘ml6óféowbz∀wA6ù→ ñ×bàai´wbs♦βGs Ù81i$iÀˆ12⊃2wC82n8o.µ3NJ9S1©Θ0P1Sd <br> What made no one in each time. <br> PïEVGÿ9srEx⇐9oN3U®yEÎi2OR5kÇÿAΤηνULP¿∧q R5¿FHt7J6E»¯C∅Aå∃aVLu∗¢tT〈2ÃšHq9Né: <br> ⊥ÞÞ¨T¦ªBrrC7³2adš6lmzb¨6ai07tdBo×KopíΡÄlj4Hy ÝaÓ1aÖí∉Ós1aá’ 4D­kleowËo3–1ÍwjR≤Π £RhÈafà7≅sù6u2 8NLV$∪⇓»↓1Y¶2µ.vßÈ23ÖS7û0Ün¬Ä Zy3KÎiñë¹DtÚ2HrhGaMvr5ïR«oÂ1namΜwÐãanFu8x7⌈sU E4cva£Âε™s7ΑGO dA35ldñÌèoAξI1wXKïn f¼x¾a∏7ffs†ìÖð 5msC$7Ët¦0z„n÷.it¡T7O8vt5¼8å· <br> Jï1ÏPkáO¶rnùrAo8s5∅z—4Rha1®t˜cq5YΧ ΤQÍraÑ⌋4¹sÜ5²§ ûVBιluwóioL3ëBw£±1¶ 5∈àáa1IÊ2sšÛÛÂ G´7ρ$kJM80∼∠ℵl.J1Km32µÚ⊃5ãé¼§ A¹NU0c¥xçfo〈Øácm14QGpHEj7lnDPVieV2¶aΠ2H7 ²j26azBSesë1c9 ´2Ù¬l0nò¤oõâRVw¦X´Ï αVõ­a≅σ¼Zs§jJå 3pFN$¾Kf821YΟ7.3ÍY95JΑqŸ0v9ÄQ <br> ñ↑yjPΤ1u6rFwhNeCOϖúd5Γêcne¼a0iTF¹5sxUS0o88ℵªlaÅT℘oOBÀ¹në·­1e∧Kpf υ98ξabp†3sj8â&amp; 9©BolÎAWSo7wNgwø¦mM tteQat0ϖ2s4≡NÇ ÕÆ¦Θ$ùRÓq0·Ã7ª.mt¾³1—uwF57H♣f Sjψ3Byš²g¤ndXÀ5tµ¯ò6hZ⇒yÿr8ÿmdowyðdiψ8YΗd0ršŠ N0Ý9aÃ3I¦sQaýê Õ0Y7lZ¯18o∫50Çwµ\"©Ζ n6Ü≥a∇lßnsF›J9 ºDΟK$Á4ÉL0S7zÖ.Ta2X3²R995391¡ <br> Turning to mess up with. Well that to give her face <br> GX°♦Ca2isA¾8¡bNÉî8ÂAöÜzΘD∇tNXIfWi–Ap2WYNYF®b ≠7yφDpj6©R04EÂU´ñn7GÆoÌjSÂ³Á∋TC⊥πËO1∗÷©RtS2wE66è­ νÑêéASi21DP“8λV∧W⋅OAÖg6qNtNp1T269XA7¥À²GGI6SEwU2íS3Χ1â!Okay let matt climbed in front door. Well then dropped the best she kissed <br> ¤ÊüC&gt;ΦÉí© flQkWMŠtvoÐdV¯rT´ZtlN6R9dZ¾ïLwuD¢9i3B5FdcÆlÝeSwJd KªtDDfoX±evrýwlK7P÷i§e³3vÎzèCe¬Μ♣ΝrGhsáy°72Y!gZpá R6O4O»£ð∋r9ÊZÀdB6iÀeîσ∼ÓrCZ1s ²ú÷I3ÁeÒ¤+⌉CêU »k6wG´c‚¾o60AJoR7Ösd3i¿Ásððpt Øè77añ∀f5np¤nþduE8⇒ È¹SHGJVAtew∇LëtςëDæ 6kÌ8FgQQ⊂R8ÇL2EI2∉iEHÍÉ3 Hÿr5Af1qximςρ‡r6©2jmWv9ÛaWð¸giACÜ¢lM⌋¿k ÊVÚ¸SÓùθçhµ5BΙi∗ttEp8¢EPpSzWJi32UÎn5ìIhgx8n⌉!j∏e5 <br> x¯qJ&gt;mC7f 5ºñy1GA4Ý0lCQe09s9u%uksã ψìX5A4g3nu←Τyst7ÍpMhšgÀÖe〉pÚ£n¼YƒŠtÉÚLGizqQ↓c3tÙI œïbXMKÛRSertj×d\"OtÊss58®!oo2i FÂWáEWøDDx7hIÕpΦSôBiÒdrUr⇔J&lt;Õa1Αzwt0°p×ià8RÌoHÛ1Än¥7ÿr ¯¥õàDYvO7aká»htì04Πe∂λÇ1 1ÈdUoο°X3fc63¶ e&amp;∪GOxT3CvXcO·e3KËνr3¸y2 26Ëz3Ã∞I± Pì∃zYt6F4e6è⇓va5÷þ9rkΘ3äsKP5R!ιµmz <br> 3í1ë&gt;ð2′L 2óB⊥S∩OQMeý∉ÑΦcöè9Tuãa∫drâ5ûMeLk9Ô £æ1OOø9oKnÿψÀWl7HÏ∅i9ρÈÊniâ•ÛeXPxí ´Í5¡SUqtBh7æa5otSZ9pØËÛDpf®ÝÊiÛωbjn¯½Ÿ2gsçh− båÌswxðoSiq8hvtèé6Òh⌈b²S ×6þSVBEFCiøUàds9Ñ¤ΕaÆ§ξÜ,1„wv jw7AMKÈ↔laæG9¦së3«etuB2keDãæìr°¨IeC¾EaÄao÷″∧r&gt;6e¸d9DùÇ,mtSö I∗44A¹RˆêM98zME≅QŸÐX¹4j6 î0n3a1'Êânxpl6d83þJ 06Ð9Eïãýã-28Ú9c4ßrØh7è¥med½♠kcñ3sPk¶2•r!〉QCa <br> ŠeÏÀ&gt;Ãσ½å bpøNERN8eaD6Åns7Abhy±Æü∩ D7sVR8'ºEeÿáDVfc˜3ëu7ÏÆqncË3qdÊ∼4∇sρmi5 6æ¾Êaä°∝TnQb9sdÀMùℑ ∑gMÿ2bNð¶4cä½⊆/4X1κ7¥f1z ϖ1úECzf•1uMbycs1•9¾ts0Tào3hêDmSs3Áe7BíÉrô⋅ãÔ φ8Ä″SSXð¤uúI¸5p58uHp2cß±o∂T©Rrd6sMt∪µµξ!é4Xb <br> <br> </div>Both hands through the fear in front.<br>Wade to give it seemed like this. Yeah but one for any longer. Everything you going inside the kids."
        },
      },
      {
        data: IO.binread('test/fixtures/mail21.box'),
        body_md5: '0aeb625b47fe3dd5b7a4771d602ba04d',
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
        body_md5: '869353c72cf4efc83536c577eac14c6f',
        params: {
          from: 'gate <team@support.gate.de>',
          from_email: 'team@support.gate.de',
          from_display_name: 'gate',
          subject: 'Ihre Rechnung als PDF-Dokument',
          to: 'Martin Edenhofer <billing@znuny.inc>',
          body: "Ihre Rechnung als PDF-Dokument",
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
        body_md5: 'ccc0542425a5996a085214c204aeaf39',
        params: {
          from: 'Manfred Haert <Manfred.Haert@example.com>',
          from_email: 'Manfred.Haert@example.com',
          from_display_name: 'Manfred Haert',
          subject: 'Antragswesen in TesT abbilden',
          to: 'info@znuny.inc',
          body: 'Sehr geehrte Damen und Herren,<br> <br> wir hatten bereits letztes Jahr einen TesT-Workshop mit Ihrem Herrn XXX durchgeführt und würden nun gerne erneut Ihre Dienste in Anspruch nehmen.<br> <br> Mittlerweile setzen wir TesT produktiv ein und würden nun gerne an einem Anwendungsfall (Change-Management) die Machbarkeit des Abbildens eines derzeit "per Papier" durchgeführten Antragswesens in TesT prüfen wollen.<br> <br> Wir bitten gerne um ein entsprechendes Angebot.<br> <br> Für Rückfragen stehe ich gerne zur Verfügung. Vielen Dank!<br> <br>  <div>--<br>    Freundliche Grüße<br> i.A. Manfred Härt<br> <br> <small>Test Somewhere GmbH<br> Ferdinand-Straße 99<br> 99073 Korlben<br> <b>Bitte beachten Sie die neuen Rufnummern!</b><br> Telefon: 011261 00000-2460<br> Fax: 011261 0000-7460<br> manfred.haertel@example.com<br> <a href="http://www.example.com" rel="nofollow noreferrer noopener" target="_blank">http://www.example.com</a><br> JETZT AUCH BEI FACEBOOK !<br> <a href="https://www.facebook.com/test" rel="nofollow noreferrer noopener" target="_blank">https://www.facebook.com/test</a><span class="js-signatureMarker"></span><br> ___________________________________<br> Test Somewhere GmbH<br> </small>  <p><small>Diese e-Mail ist ausschließlich für den beabsichtigten Empfänger bestimmt. Sollten Sie irrtümlich diese e-Mail erhalten haben, unterrichten Sie uns bitte umgehend unter kontakt@example.com und vernichten Sie diese Mitteilung einschließlich der ggf. beigefügten Dateien.<br> Weil wir die Echtheit oder Vollständigkeit der in dieser Nachricht enthaltenen Informationen nicht garantieren können, bitten wir um Verständnis, dass wir zu Ihrem und unserem Schutz die rechtliche Verbindlichkeit der vorstehenden Erklärungen ausschließen, soweit wir mit Ihnen keine anders lautenden Vereinbarungen getroffen haben.</small>  </p>
</div>'
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
        body_md5: '12d445b1e194453401d6cd65745ce48a',
        params: {
          from: 'Martin Smith <m.Smith@example.com>',
          from_email: 'm.Smith@example.com',
          from_display_name: 'Martin Smith',
          subject: 'Fw: Zugangsdaten',
          to: 'Martin Edenhofer <me@example.com>',
          body: "<div>
<div> </div>
<div>--<br> don't cry - work! (Rainald Goetz)</div>
<div> <div> <div>
<div>
<b>Gesendet:</b> Mittwoch, 03. Februar 2016 um 12:43 Uhr<span class=\"js-signatureMarker\"></span><br>
<b>Von:</b> \"Martin Smith\" &lt;m.Smith@example.com&gt;<br>
<b>An:</b> linuxhotel@example.com<br>
<b>Betreff:</b> Fw: Zugangsdaten</div>
<div>
<div>
<div> </div>
<div>--<br> don't cry - work! (Rainald Goetz)</div>
<div> <div> <div>
<div>
<b>Gesendet:</b> Freitag, 22. Januar 2016 um 11:52 Uhr<br>
<b>Von:</b> \"Martin Edenhofer\" &lt;me@example.com&gt;<br>
<b>An:</b> m.Smith@example.com<br>
<b>Betreff:</b> Zugangsdaten</div>
<div>Um noch vertrauter zu werden, kannst Du mit einen externen E-Mail Account (z. B. <a href=\"http://web.de\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">web.de</a>) mal ein wenig selber “spielen”. :)</div>
</div>
</div>
</div>
</div>
</div>
</div>
</div>
</div>
</div>"
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
        body_md5: '8899417f4323db1e46b086b31b2abeb0',
        params: {
          from: 'Paula <databases.en@example.com>',
          from_email: 'databases.en@example.com',
          from_display_name: 'Paula',
          subject: 'Kontakte',
          to: 'info@example.ch',
          cc: nil,
          body: '<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnaWVpLGUzZHx4bnxlZWY=" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnaWVpLGUzZHx4bnxlZWY=</a> <br><br><p><i>Geben Sie diese Information an den Direktor oder den für Marketing und Umsatzsteigerung verantwortlichen Mitarbeiter Ihrer Firma weiter!</i></p><br><br><p>Hallo,</p><ul> <li>Sie suchen nach Möglichkeiten, den Umsatz Ihre Firma zu steigern?</li>
<li>Sie brauchen neue Geschäftskontakte?</li>
<li>Sie sind es leid, Kontaktdaten manuell zu erfassen?</li>
<li>Ihr Kontaktdatenanbieter ist zu teuer oder Sie sind mit seinen Dienstleistungen unzufrieden?</li>
<li>Sie möchten Ihre Kontaktinformationen gern effizienter auf dem neuesten Stand halten?</li> </ul> <p><br>Bei uns können Sie mit nur wenigen Clicks <b>Geschäftskontakte</b> verschiedener Länder erwerben.</p><p>Dies ist eine <b>schnelle und bequeme</b> Methode, um Daten zu einem vernünftigen Preis zu erhalten.</p><p>Alle Daten werden <b>ständig aktualisiert</b>m so dass Sie sich keine Sorgen machen müssen.</p><p>&nbsp;</p><br><a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0LnNzdXJobGZzZWVsdGEtLm10cmVzb2YvY2VtL2xpZ25pYWlnaV9hbC9zOG1lOXgyOTdzZW1hL2VlL2xwZWxheHB4Q18ubXhzfEhsODh8Y2M=" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0LnNzdXJobGZzZWVsdGEtLm10cmVzb2YvY2VtL2xpZ25pYWlnaV9hbC9zOG1lOXgyOTdzZW1hL2VlL2xwZWxheHB4Q18ubXhzfEhsODh8Y2M=</a>  <a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnaWVpLGUzZHx4bnxlZWY=" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnaWVpLGUzZHx4bnxlZWY=</a> <br><br><p>XLS-Muster herunterladen
                                                 (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0LnNzdXJobGZzZWVsdGEtLm10cmVzb2YvY2VtL2xpZ25pYWlnaV9hbC9zOG1lOXgyOTdzZW1hL2VlL2xwZWxheHB4Q18ubXhzfEhsODh8Y2M=" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0LnNzdXJobGZzZWVsdGEtLm10cmVzb2YvY2VtL2xpZ25pYWlnaV9hbC9zOG1lOXgyOTdzZW1hL2VlL2xwZWxheHB4Q18ubXhzfEhsODh8Y2M=</a>)</p><p>Datenbank bestellen
                                                 (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnaWVpLGUzZHx4bnxlZWY=" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnaWVpLGUzZHx4bnxlZWY=</a>)</p><br> <br> <p><b>Die Anmeldung ist absolut kostenlos und unverbindlich.</b> Sie können die Kataloge gemäß Ihren eigenen Kriterien filtern und ein kostenloses Datenmuster bestellen, sobald Sie sich angemeldet haben.<br> </p><br><br><p> <b>Wir haben Datenbanken der folgenden Länder:</b> </p><br> <li>Österreich (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NUQWVpMjZ8fGEx" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NUQWVpMjZ8fGEx</a>)</li>
<li>Belgien (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NFQmVpYzR8fGNh" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NFQmVpYzR8fGNh</a>)</li>
<li>Belarus (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NZQmVpMGJ8fDAw" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NZQmVpMGJ8fDAw</a>)</li> <li>Schweiz (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NIQ2VpYjF8fGY4" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NIQ2VpYjF8fGY4</a>)</li>
<li>Tschechische Republik (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NaQ2VpMTZ8fDc1" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NaQ2VpMTZ8fDc1</a>)</li>
<li>Deutschland (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NFRGVpMDl8fDM1" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NFRGVpMDl8fDM1</a>)</li>
<li>Estland (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NFRWVpYTd8fGNm" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NFRWVpYTd8fGNm</a>)</li>
<li>Frankreich (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NSRmVpNGN8fDBl" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NSRmVpNGN8fDBl</a>)</li>
<li>Vereinigtes Königreich (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NCR2VpNjh8fDA4" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NCR2VpNjh8fDA4</a>)</li>
<li>Ungarn (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NVSGVpNDB8fGQx" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NVSGVpNDB8fGQx</a>)</li>
<li>Irland (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NFSWVpNDd8fGNi" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NFSWVpNDd8fGNi</a>)</li> <li>Italien (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NUSWVpOTJ8fDU3" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NUSWVpOTJ8fDU3</a>)</li>
<li>Liechtenstein (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NJTGVpNTF8fDlk" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NJTGVpNTF8fDlk</a>)</li>
<li>Litauen (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NUTGVpN2R8fDgw" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NUTGVpN2R8fDgw</a>)</li>
<li>Luxemburg (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NVTGVpNWZ8fGZh" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NVTGVpNWZ8fGZh</a>)</li>
<li>Lettland (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NWTGVpZWZ8fDE2" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NWTGVpZWZ8fDE2</a>)</li>
<li>Niederlande (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NMTmVpOTV8fDQw" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NMTmVpOTV8fDQw</a>)</li>
<li>Polen (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NMUGVpNGV8fDBm" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NMUGVpNGV8fDBm</a>)</li>
<li>Russland (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NVUmVpZTV8fGVk" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NVUmVpZTV8fGVk</a>)</li>
<li>Slowenien (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NJU2VpN2R8fGYz" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NJU2VpN2R8fGYz</a>)</li>
<li>Slowakei (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NLU2VpNjZ8fDQ5" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NLU2VpNjZ8fDQ5</a>)</li>
<li>Ukraine (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NBVWVpYTd8fDNh" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NBVWVpYTd8fDNh</a>)</li> <br><br><p>Anwendungsmöglichkeiten für Geschäftskontakte<br> <br> </p><ul> <li>
<i>Newsletter senden</i> - Senden von Werbung per E-Mail (besonders effizient).</li>
<li>
<i>Telemarketing</i> - Telefonwerbung.</li>
<li>
<i>SMS-Marketing</i> - Senden von Kurznachrichten.</li>
<li>
<i>Gezielte Werbung</i> - Briefpostwerbung.</li>
<li>
<i>Marktforschung</i> - Telefonumfragen zur Erforschung Ihrer Produkte oder Dienstleistungen.</li> </ul> <p>&nbsp;</p><p>Sie können <b>Abschnitte wählen (filtern)</b> Empfänger gemäß Tätigkeitsbereichen und Standort der Firmen, um die Effizienz Ihrer Werbemaßnahmen zu erhöhen.</p><p>&nbsp;</p><br><p>Für jeden Kauf von <b>2016-11-05 23:59:59</b> </p><p>wir gewähren <b>30%</b> Rabatt</p><p><b>RABATTCODE: WZ2124DD</b></p><br><br><p><b>Bestellen Sie online bei:</b><br> </p><p>company-catalogs.com (<a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnaWVpLGUzZHx4bnxlZWY=" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnaWVpLGUzZHx4bnxlZWY=</a>)<br> </p><p><b>Für weitere Informationen:</b><br> </p><p>E-Mail: databases.en@example.com<br> Telefon: +370-52-071554 (languages: EN, PL, RU, LT)</p><br><br>Unsubscribe from newsletter: Click here (<a href="http://business-catalogs.example.com/c2JudXVlcmNic2I4MWk7MTgxOTMyNS1jMmMtNzA=" rel="nofollow noreferrer noopener" target="_blank">http://business-catalogs.example.com/c2JudXVlcmNic2I4MWk7MTgxOTMyNS1jMmMtNzA=</a>)'
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
        body_md5: '8a028710b157c68ace0a5b2264c44da7',
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
          body: 'Enjoy!<div>
<br><div>-Martin<br><span class="js-signatureMarker"></span><br>--<br>Old programmers never die. They just branch to a new address.<br>
</div>
<br><div><img src="cid:485376C9-2486-4351-B932-E2010998F579@home" style="width:640px;height:425px;"></div>
</div>'
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
          assert_equal(file[:params][key.to_sym], data[key.to_sym], "check #{key}")
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
