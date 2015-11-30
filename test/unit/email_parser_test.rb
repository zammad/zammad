# encoding: utf-8
# rubocop:disable all
require 'test_helper'

class EmailParserTest < ActiveSupport::TestCase
  test 'parse' do
    files = [
      {
        data: IO.read('test/fixtures/mail1.box'),
        body_md5: 'b57d21dcac6b05e1aa67af51a9e4c1ec',
        params: {
          from: 'John.Smith@example.com',
          from_email: 'John.Smith@example.com',
          from_display_name: '',
          subject: 'CI Daten für PublicView ',
        },
      },
      {
        data: IO.read('test/fixtures/mail2.box'),
        body_md5: '154c7d3ae7b94f99589df62882841b08',
        params: {
          from: 'Martin Edenhofer <martin@example.com>',
          from_email: 'martin@example.com',
          from_display_name: 'Martin Edenhofer',
          subject: 'aaäöüßad asd',
          body_md5: "äöüß ad asd\n\n-Martin\n\n--\nOld programmers never die. They just branch to a new address.\n",
          body: "äöüß ad asd

-Martin

--
Old programmers never die. They just branch to a new address.
"
        },
      },
      {
        data: IO.read('test/fixtures/mail3.box'),
        body_md5: '96a0a7847c1c60e82058db8f8bff8136',
        params: {
          from: '"Günther John | Example GmbH" <k.guenther@example.com>',
          from_email: 'k.guenther@example.com',
          from_display_name: 'Günther John | Example GmbH',
          subject: 'Ticket Templates',
        },
      },
      {
        data: IO.read('test/fixtures/mail4.box'),
        body_md5: '9fab9a0e8523011fde0f3ecd80f8d72c',
        params: {
          from: '"Günther Katja | Example GmbH" <k.guenther@example.com>',
          from_email: 'k.guenther@example.com',
          from_display_name: 'Günther Katja | Example GmbH',
          subject: 'AW: Ticket Templates [Ticket#11168]',
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
        data: IO.read('test/fixtures/mail5.box'),
        body_md5: 'f34033e9a34bb5367062dd5df21115df',
        params: {
          from: 'marc.smith@example.com (Marc Smith)',
          from_email: 'marc.smith@example.com',
          from_display_name: 'Marc Smith',
          subject: 'Re: XXXX Betatest Ticket Templates [Ticket#11162]',
        },
      },
      {
        data: IO.read('test/fixtures/mail6.box'),
        body_md5: '6229bcc5fc1396445d781daf3c12a285',
        params: {
          from: '"Hans BÄKOSchönland" <me@bogen.net>',
          from_email: 'me@bogen.net',
          from_display_name: 'Hans BÄKOSchönland',
          subject: 'utf8: 使って / ISO-8859-1: Priorität"  / cp-1251: Сергей Углицких',
          body: "this is a test

___
 [1] Compare Cable, DSL or Satellite plans: As low as $2.95.

Test1:8
Test2:&
Test3:&ni;
Test4:&
Test5:=


[1] http://localhost/8HMZENUS/2737??PS="
        },
      },
      {
        data: IO.read('test/fixtures/mail7.box'),
        body_md5: 'c78f6a91905538ee32bc0bf71f70fcf2',
        params: {
          from: 'Eike.Ehringer@example.com',
          from_email: 'Eike.Ehringer@example.com',
          from_display_name: '',
          subject: 'AW:Installation [Ticket#11392]',
          body: "Hallo.
Jetzt muss ich dir noch kurzfristig absagen für morgen.
Lass uns evtl morgen Tel.

Mfg eike

Martin Edenhofer via Znuny Team --- Installation [Ticket#11392] ---

Von: \"Martin Edenhofer via Znuny Team\" <support@example.com> 
An eike.xx@xx-corpxx.com 
Datum: Mi., 13.06.2012 14:30 
Betreff Installation [Ticket#11392]

___

Hi Eike,
anbei wie gestern telefonisch besprochen Informationen zur Vorbereitung.
a) Installation von http://ftp.gwdg.de/pub/misc/zammad/RPMS/fedora/4/zammad-3.0.13-01.noarch.rpm (dieses RPM ist RHEL kompatible) und dessen Abhängigkeiten.
b) Installation von \"mysqld\" und \"perl-DBD-MySQL\".
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
Managing Director: Martin Edenhofer",
        },
      },
      {
        data: IO.read('test/fixtures/mail8.box'),
        body_md5: 'ca502c70a1b006f5184d1f0bf79d5799',
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
          body_md5: "Gravierend?

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
Hof
",
        },
      },
      {
        data: IO.read('test/fixtures/mail9.box'),
        body_md5: 'c70de14cc69b17b07850b570d7a4fbe7',
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
          body: "Enjoy!\n\n-Martin\n\n--\nOld programmers never die. They just branch to a new address.\n\n"
        },
      },
      {
        data: IO.read('test/fixtures/mail10.box'),
        body_md5: 'ddfad696bd34d83f607763180243f3c5',
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
#          :body         => "Herzliche Grüße aus Oberalteich sendet Herrn Smith\n\n \n\nSepp Smith  - Dipl.Ing. agr. (FH)\n\nGeschäftsführer der example Straubing-Bogen\n\nKlosterhof 1 | 94327 Bogen-Oberalteich\n\nTel: 09422-505601 | Fax: 09422-505620\n\nInternet: http://example-straubing-bogen.de <http://example-straubing-bogen.de/> \n\nFacebook: http://facebook.de/examplesrbog <http://facebook.de/examplesrbog> \n\n   -  European Foundation für Quality Management\n\n"
        },
      },
      {
        data: IO.read('test/fixtures/mail11.box'),
        body_md5: 'cf8b26d9fc4ce9abb19a36ce3a130c79',
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
        },
      },
      {
        data: IO.read('test/fixtures/mail12.box'),
        body_md5: '8b48e082bc77e927d395448875259172',
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
        },
      },
      {
        data: IO.read('test/fixtures/mail13.box'),
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
        },
      },
      {
        data: IO.read('test/fixtures/mail14.box'),
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
        },
      },
      # spam email
      {
        data: IO.read('test/fixtures/mail15.box'),
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
        },
      },
      # spam email
      {
        data: IO.read('test/fixtures/mail16.box'),
        body_md5: '5e96cc53e78c0e44523502ee50647808',
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
        data: IO.read('test/fixtures/mail17.box'),
        body_md5: 'c32d6502f47435e613a2112625118270',
        params: {
          from: '"都琹" <ghgbwum@185.com.cn>',
          from_email: 'ghgbwum@185.com.cn',
          from_display_name: '都琹',
          subject: '【专业为您注册香港及海外公司（好处多多）】　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　人物                    互联网事百度新闻独家出品传媒换一批捷克戴维斯杯决赛前任命临时领队 前领队因病住院最新:盖世汽车讯 11月6日，通用汽车宣布今年10月份在华销量...减持三特索道 孟凯将全力发展湘鄂情江青摄影作品科技日报讯 （记者过国忠 通讯员陈飞燕）江苏省无线电科学研究所有限公司院士工作站日前正式建...[详细]',
          to: 'info@znuny.com',
        },
      },
      {
        data: IO.read('test/fixtures/mail18.box'),
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
        data: IO.read('test/fixtures/mail19.box'),
        body_md5: '0bf7e746158d121bce7e2c46b64b0d39',
        params: {
          from: '"我" <>',
          from_email: '"=?GB2312?B?ztI=?=" <>',
          from_display_name: '',
          subject: '《欧美简讯》',
          to: '377861373 <377861373@qq.com>',
        },
      },
      {
        data: IO.read('test/fixtures/mail20.box'),
        body_md5: '646e803f30cddf06db90f426df3672c1',
        params: {
          from: 'Health and Care-Mall <drugs-cheapest8@sicor.com>',
          from_email: 'drugs-cheapest8@sicor.com',
          from_display_name: 'Health and Care-Mall',
          subject: 'The Highest Grade Drugs And EXTRA LOW Price .',
          to: 'info2@znuny.com',
          body: "________________________________________________________________________Yeah but even when they. Beth liî ed her neck as well

&oacute;25aHw511I&Psi;11xG&lfloor;o8KHCm&sigmaf;9-2&frac12;23Qg&ntilde;V6UAD12AX&larr;t1Lf7&oplus;1Ir&sup2;r1TLA5pYJhjV gPn&atilde;M36V1E89RUD&Tau;&Aring;12I92s2C&Theta;YE&upsih;Afg&lowast;bT11&int;rIoi&scaron;&brvbar;O5oUIN1Is2S21Pp &Yuml;2q1F&Chi;&uArr;eGOz&lceil;F1R98y&sect; 74&rdquo;lTr8r1H2&aelig;u2E2P2q VmkfB&int;SKNElst4S&exist;182T2G1&iacute; lY92Pu&times;8>R&Ograve;&not;&oplus;&Mu;I&Ugrave;z&Ugrave;CC412QE&Rho;&ordm;S2!Xg&OElig;s. 
2&gamma;&dArr;B[1] cwspC&ensp;L8I C K88H E1R?E2e31 !Calm dylan for school today.
Closing the nursery with you down. Here and made the mess. Maybe the oï from under his mother. Song of course beth touched his pants.
When someone who gave up from here. Feel of god knows what. 
TB&piv;&exist;M5T5&Epsilon;Ef2&ucirc;&ndash;N&para;1v&Zeta;'1&dArr;&prop;5S2225 &Chi;0j&Delta;HbAg&thorn;E&mdash;2i6A2lD&uArr;LGj2nTOy11H2&tau;9&rsquo;:Their mother and tugged it seemed like 
d3RsV&para;H2&Theta;i&macr;B&part;gax1b&icirc;gdH23r2J&yuml;1aIK1&sup2; n1jfaTk1Vs3952 C&tilde;lBl&lsquo;mxGo0&radic;2XwT8Ya 28ksa&int;f1&alefsym;s&rdquo;62Q 2Ad7$p32d1e&prod;2e.0&rdquo;261a2&Kappa;63&alpha;SM2 Nf52CdL&cup;1i&harr;xcaa52R3l6Lc3i2z16s&oacute;9&egrave;U zDE1aE21gs25&Euml;2 hE1cl&sup;&cent;11o21&micro;Bw1zF1 q2k&otilde;aXUius1r0&sube; d&bull;&isin;2$1Z2F1218l.07d56P&Uacute;l25JAO6 
45loV2iv1i2&atilde;&Upsilon;&lfloor;a2&sup;d2g&Atilde;&Upsilon;3&trade;r22u&cedil;aWjO8 n40&ndash;Soy&egrave;2u1&empty;23p1J&Mu;Ne&Igrave;22jr&aacute;2r&Kappa; 1229A2rAkc8nuEtl22ai&Dagger;OB8vSb&eacute;&sigma;e&iota;&otilde;q1+65cw 2s8Ua&ograve;4PrsE1y8 &lang;fMElh&upsih;&sdot;Jo8pmzwj&circ;N1 wv39aW1WtsvuU3 1a&oelig;1$2&Nu;nR2O2&rceil;B.&forall;2c&rarr;5&Ecirc;9&chi;w5p1&frasl;N fHGFVfE&sup3;2i&sigma;jGpa51kgg12cWrUq52akx2h 0F24P&cedil;2L2rn22&Iuml;o2&Yacute;2HfoRb2eU&alpha;w6s2N&oline;ws&para;13&Beta;i2X1&cedil;ofgtHnR&perp;32ase92lF1H5 26B1a&sup;2i&upsih;s&ocirc;12i &Aring;kMyl2J1&Auml;oQ&ndash;0&image;wvm&ugrave;2 2&circ;&mu;\"aQ7jVse62f 1h2p$L2r&pound;3i1t2.323h5qP8g0&hearts;&divide;R2 
&middot;i&fnof;PV1&Beta;&ni;&oslash;iF1R1a4v32gL9&cent;wr1722a2&ucirc;0&eta; &thorn;12&szlig;Stu21u7&aacute;&iexcl;lp2ocEe1SLlrV2Xj &perp;U&micro;1F&not;48&eth;ov71Arm242c2Vw2e1&sect;&supe;N 1242aL&thorn;Z2ski&times;5 c&euro;pBl&ucirc;26&part;ol1f&Uacute;wK&szlig;32 4i2la4C12sRE21 &atilde;eI2$2z8t442fG.&cedil;1&le;12F&rsquo;&Atilde;152in&nsub; Tl1&euml;C2v7Ci71X8a225Nl&thorn;U&rang;&iota;icO&sum;&laquo;s&middot;iKN Uu&upsih;jS1j52u2J&uuml;&sect;pn5&deg;1e&yen;&Ucirc;3&weierp;r1W&Dagger;2 J&lsaquo;S7A1j0sc&1pkt1qq2iZ561vn81&lowast;e22Q3+723&Scaron; &sum;RkLaKX2as2s22 &iuml;111lD2z8o278wwU&ndash;&Agrave;C T6U2a&upsih;938s20G&yuml; Ox2&isin;$98&lsquo;R21H25.&Ograve;L6b9&theta;r&delta;292f9j 
Please matt on his neck. Okay matt huï ed into your mind Since her head to check dylan. Where dylan matt got up there 
1&Egrave;&plusmn;&Alpha;AYQ1dN12&upsih;XT00&Agrave;vI&or;&iacute;o8-1b&reg;8A&Epsilon;1V4Lg&Otilde;&uarr;7LKtgcEiw1yR5Y22GRA1&deg;I10C2C2Ti&uuml;/2wc0Ax211S&Uuml;&Acirc;2&OElig;T&Aacute;22&ograve;HpN&acirc;&ugrave;M6&Egrave;10A5Tb1:Simmons and now you really is what. Matt picked up this moment later that. 
251yV922Yeg1&uarr;DnJ3l4t22b1os&prod;jll&divide;iS2iwB&Icirc;4n021&Ouml; 1f&divide;2a11l2su&Uacute;82 2LCblgvN&frac12;o1oP3wn&spades;90 FZora&M&trade;xs&Kappa;bb1 251&xi;$12&middot;22iG2&nabla;1&supe;&Xi;&not;3.0P0&kappa;53V1203&Yacute;Yz 2X&cent;BAZ4Kwddu2vvuB&uarr;&Beta;a1&rsquo;THi0&mdash;93rZ&epsilon;j0 1r&Mu;1a2111s71&Iota;f 8&dArr;2olW&bdquo;62o6yH&yen;wKZ&and;6 21h2aKJ&ldquo;&real;s48I&Igrave; 21&not;1$Z&Sigma;122&ntilde;26B42YMZ.21V19f10&aring;54&lceil;R8 
2w\"9N2gB&Agrave;a2S&ecirc;1s&cong;gG&Ocirc;o0Dn4n&crarr;&gamma;7&otimes;eS7e2xf3Jd q&divide;CMa221isNMZp zz0&tilde;l&Kappa;Lw8o229ww1&sect;Qu 1D&lceil;&iacute;a2212sJ811 3o&ugrave;2$&brvbar;1N&real;1>R2t7WPM1.181D92k5D9&lowast;8&asymp;R l131Sj1&Psi;8p&Sigma;2K&ugrave;i6rr2rb&Ucirc;u&not;i2V&lowast;&prod;v5&ordf;10a27B1 &Uacute;&diams;&Xi;sa9j3&chi;sa1i&Omicron; Oi&weierp;ml6&oacute;f2owbz&forall;wA6&ugrave;&rarr; 22b2ai1wbs&diams;&beta;Gs 281i$i&Agrave;&circ;12&sup;2wC82n8o.13NJ9S11&Theta;0P1Sd 
What made no one in each time. Mommy was thinking of course beth. Everything you need the same thing 
P2EVG29srEx&lArr;9oN3U1yE2i2OR5k&Ccedil;&yuml;A&Tau;&eta;&nu;ULP&iquest;&and;q R5&iquest;FHt7J6E&raquo;1C&empty;A2&exist;aVLu&lowast;&cent;tT&lang;21&scaron;Hq9N&eacute;: 
&perp;&THORN;21T11BrrC712ad&scaron;6lmzb16ai07tdBo&times;Kop&iacute;&Rho;1lj4Hy 2a&Oacute;1a&Ouml;&iacute;&notin;&Oacute;s1a2&rsquo; 4D1kleow2o3&ndash;12wjR&le;&Pi; 1Rh2af27&cong;s26u2 8NLV$&cup;&dArr;1&darr;1Y&para;21.v2&Egrave;232S7202n11 m5VKZy3K2i&ntilde;21Dt&Uacute;2HrhGaMvr5&iuml;R1o11nam&Mu;w22anFu8x7&lceil;sU E4cva11&epsilon;&trade;s7&Alpha;GO dA35ld&ntilde;&Igrave;&egrave;oA&xi;I1wXK2n f1x&frac34;a&prod;7ffs&dagger;222 5msC$72t10z&bdquo;n2.it1T7O8vt5182&middot; J&iuml;12Pk&aacute;O1rn2rAo8s5&empty;z&mdash;4Rha11t&tilde;cq5Y&Chi; &Tau;Q2ra2&rfloor;4&sup1;s&Uuml;51&sect; 2VB&iota;luw2ioL32Bw1111 5&isin;22a1I22s&scaron;&Ucirc;21 G17&rho;$kJM80&sim;&ang;&alefsym;l.J1Km3212&sup;52&eacute;&frac14;&sect; p121A1NU0c&yen;x2fo&lang;22cm14QGpHEj7lnDPVieV21a&Pi;2H7 1j26azBSes&euml;1c9 &acute;2&Ugrave;&not;l0n21o22RVw1X1&Iuml; &alpha;V21a&cong;&sigma;1Zs&sect;jJ&aring; 3pFN$1Kf821Y&Omicron;7.32Y95J&Alpha;q&Yuml;0v91Q 
&ntilde;&uarr;yjP&Tau;1u6rFwhNeCO&piv;2d5&Gamma;&ecirc;cne&frac14;a0iTF15sxUS0o88&alefsym;1la&Aring;T&weierp;oOB11n2111e&and;Kpf &upsilon;98&xi;abp&dagger;3sj82& 9&copy;Bol2AWSo7wNgw21mM tteQat0&piv;2s4&equiv;N&Ccedil; &Otilde;&AElig;1&Theta;$2R2q0117&ordf;.mt111&mdash;uwF57H&clubs;f &aelig;&cup;HYSj&psi;3By&scaron;1g1ndX15t1126hZ&rArr;y2r82mdowy2di&psi;8Y&Eta;d0r&scaron;&Scaron; N029a13I&brvbar;sQa&yacute;2 20Y7lZ118o&int;50&Ccedil;w1\"1&Zeta; n6&Uuml;&ge;a&nabla;l&szlig;nsF&rsaquo;J9 1D&Omicron;K$142L0S7z2.Ta2X31R9953911 
Turning to mess up with. Well that to give her face Another for what she found it then. Since the best to hear 
GX1&diams;Ca2isA18&iexcl;bN2&icirc;81A22z&Theta;D&nabla;tNXIfWi&ndash;Ap2WYNYF1b &ne;7y&phi;Dpj6&copy;R04E1U1&ntilde;n7G1o2jS111&ni;TC&perp;&pi;&Euml;O1&lowast;21RtS2wE6621 &nu;222ASi21DP&ldquo;8&lambda;V&and;W&sdot;OA2g6qNtNp1T269XA7&yen;11GGI6SEwU22S3&Chi;12!Okay let matt climbed in front door. Well then dropped the best she kissed 
122C>&Phi;221 flQkWM&Scaron;tvo2dV1rT1ZtlN6R9dZ12LwuD19i3B5Fdc&AElig;l2eSwJd K1tDDfoX&plusmn;evr&yacute;wlK7P&divide;i1e13v2z&egrave;Ce&not;&Mu;&clubs;&Nu;rGhs2y172Y!gZp&aacute; R6O4O112&ni;r92Z1dB6i1e2&sigma;&sim;&Oacute;rCZ1s 122I31e2&curren;+&rceil;C&ecirc;U 1k6wG1c&sbquo;1o60AJoR72sd3i11s22pt &Oslash;277a2&forall;f5np&curren;n2duE8&rArr; 21SHGJVAtew&nabla;L&euml;t&sigmaf;2D2 6k28FgQQ&sub;R81L2EI2&notin;iEH&Iacute;&Eacute;3 H2r5Af1qxim&sigmaf;&rho;&Dagger;r6&copy;2jmWv92aW21giAC21lM&rfloor;1k 2V2&cedil;S2&ugrave;&theta;2h15B&Iota;i&lowast;ttEp8&cent;EPpSzWJi32U2n5&igrave;Ihgx8n&rceil;!j&prod;e5 
x1qJ>mC7f 512y1GA420lCQe09s9u%uks&atilde; &psi;2X5A4g3nu&larr;&Tau;yst72pMh&scaron;g12e&rang;p&Uacute;1n1Y&fnof;&Scaron;t&Eacute;2LGizqQ&darr;c3t&Ugrave;I &oelig;&iuml;bXMK&Ucirc;RSertj2d\"Ot2ss581!oo2i F&Acirc;W2EW2DDx7hI2p&Phi;S2Bi2drUr&hArr;J<2a1&Alpha;zwt01p2i28R2oH21&Auml;n172r 1122DYvO7ak21ht204&Pi;e&part;&lambda;11 12dUo&omicron;1X3fc631 e&&cup;GOxT3CvXcO1e3K2&nu;r31y2 262z31&infin;I1 P&igrave;&exist;zYt6F4e6&egrave;&dArr;va5229rk&Theta;32sKP5R!&iota;&micro;mz 
3212>22&prime;L 2&oacute;B&perp;S&cap;OQMe&yacute;&notin;2&Phi;c229Tu2a&int;dr25&ucirc;MeLk92 121OO&oslash;9oKn&yuml;&psi;&Agrave;Wl7H2&empty;i9&rho;&Egrave;2ni2&bull;2eXPx&iacute; 1251SUqtBh72a5otSZ9p222Dpf1&Yacute;2i2&omega;bjn11&Yuml;2gs2h&minus; b&aring;2swx2oSiq8hvt2262h&lceil;b&sup2;S 26&thorn;SVBEFCi2U&agrave;ds9&Ntilde;1&Epsilon;a11&xi;2,1&bdquo;wv jw7AMK2&harr;la2G91s23&laquo;etuB2keD&atilde;2&igrave;r1&uml;IeC&frac34;Ea&Auml;ao&divide;&Prime;&and;r>6e1d9D21,mtS2 I&lowast;44A1R&circ;2M98zME&cong;Q&Yuml;&ETH;X&sup1;4j6 20n3a1&apos;22nxpl6d832J 06&ETH;9E22&yacute;2-2829c42r2h72&yen;med&frac12;&spades;kc23sPk12&bull;r!&rang;QCa 
&Scaron;e21>1&sigma;12 bp&oslash;NERN8eaD61ns7Abhy&plusmn;12&cap; D7sVR8&apos;1Ee22DVfc&tilde;32u72&AElig;qnc23qd2&sim;4&nabla;s&rho;mi5 6212a21&prop;TnQb9sd1M&ugrave;&image; &sum;gM22bN2&para;4c&auml;&frac12;&sube;/4X1&kappa;71f1z &piv;12ECzf&bull;1uMbycs1&bull;9&frac34;ts0T2o3h2DmSs31e7B2&Eacute;r2&sdot;22 &phi;81&Prime;SSX&eth;1u&uacute;I15p58uHp2c2&plusmn;o&part;T1Rrd6sMt&cup;1&micro;&xi;!24Xb

Both hands through the fear in front.
Wade to give it seemed like this. Yeah but one for any longer. Everything you going inside the kids.


[1] http://pxmzcgy.storeprescription.ru?zz=fkxffti"
        },
      },
      {
        data: IO.read('test/fixtures/mail21.box'),
        body_md5: '617017ee0b2d1842f410fceaac696230',
        params: {
          from: 'Viagra Super Force Online <pharmacy_affordable1@ertelecom.ru>',
          from_email: 'pharmacy_affordable1@ertelecom.ru',
          from_display_name: 'Viagra Super Force Online',
          subject: 'World Best DRUGS Mall For a Reasonable Price.',
          to: 'info@znuny.nix',
        },
      },
      {
        data: IO.read('test/fixtures/mail22.box'),
        body_md5: '7dd64b40dce1aa3053fc7bbdea136612',
        params: {
          from: 'Gilbertina Suthar <ireoniqla@lipetsk.ru>',
          from_email: 'ireoniqla@lipetsk.ru',
          from_display_name: 'Gilbertina Suthar',
          subject: 'P..E..N-I..S__-E N L A R-G E-M..E..N T-___P..I-L-L..S...Info.',
          to: 'Info <info@znuny.nix>',
          body: "Puzzled by judith bronte dave. Melvin will want her way through with.
Continued adam helped charlie cried. Soon joined the master bathroom. Grinned adam rubbed his arms she nodded.
Freemont and they talked with beppe.
Thinking of bed and whenever adam.
Mike was too tired man to hear.
I10PQSHEJl2Nwf&tilde;2113S173 &Icirc;1mEbb5N371L&piv;C7AlFnR1&diams;HG64B242&brvbar;M2242zk&Iota;N&rceil;7&rceil;TBN&ETH; T2xPI&ograve;gI2&Atilde;lL2&Otilde;ML&perp;22Sa&Psi;RBreathed adam gave the master bedroom door.
Better get charlie took the wall.
Charlotte clark smile he saw charlie.
Dave and leaned her tears adam.
Maybe we want any help me that.
Next morning charlie gazed at their father.
Well as though adam took out here. Melvin will be more money. Called him into this one last night.
Men joined the pickup truck pulled away. Chuck could make sure that.[1] &dagger;p1C?L&thinsp;I?C&ensp;K?88&ensp;5 E R?EEOD !Chuckled adam leaned forward and le? charlie.
Just then returned to believe it here.
Freemont and pulling out several minutes.


[1] &#104;&#116;&#116;&#112;&#58;&#47;&#47;&#1072;&#1086;&#1089;&#1082;&#46;&#1088;&#1092;?jmlfwnwe&ucwkiyyc",
        },

      },
      {
        data: IO.read('test/fixtures/mail23.box'),
        body_md5: '545a1b067fd10ac636c20b44f5df8868',
        params: {
          from: 'marketingmanager@nthcpghana.com',
          from_email: 'marketingmanager@nthcpghana.com',
          from_display_name: '',
          subject: nil,
          to: 'undisclosed-recipients: ;',
        },
      },
      {
        data: IO.read('test/fixtures/mail24.box'),
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
        data: IO.read('test/fixtures/mail25.box'),
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
        data: IO.read('test/fixtures/mail26.box'),
        body_md5: 'c68fd31c71a463c7ea820ccdf672c680',
        params: {
          from: 'gate <team@support.gate.de>',
          from_email: 'team@support.gate.de',
          from_display_name: 'gate',
          subject: 'Ihre Rechnung als PDF-Dokument',
          to: 'Martin Edenhofer <billing@znuny.inc>',
          body: "********************************************************************

gate                                                      Service

--------------------------------------------------------------------

gate GmbH   *   Gladbacher Str. 74   *  40219  Düsseldorf

",
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
        data: IO.read('test/fixtures/mail27.box'),
        body_md5: 'd41d8cd98f00b204e9800998ecf8427e',
        params: {
          from: 'caoyaoewfzfw@21cn.com',
          from_email: 'caoyaoewfzfw@21cn.com',
          from_display_name: '',
          subject: "\r\n蠭龕中層管理者如何避免角色行为誤区",
          to: 'duan@seat.com.cn, info@znuny.com, jinzh@kingdream.com',
          body: '',
        },
        attachments: [
          {
            md5: '498b8ae7b26033af1a08f85644d6695c',
            filename: 'message.html',
          },
        ],
      },
      {
        data: IO.read('test/fixtures/mail28.box'),
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
        data: IO.read('test/fixtures/mail29.box'),
        body_md5: 'bd34701dd5246b7651f67aeea6dd0fd3',
        params: {
          from: 'Example Sales <sales@example.com>',
          from_email: 'sales@example.com',
          from_display_name: 'Example Sales',
          subject: 'Example licensing information: No channel available',
          to: 'info@znuny.inc',
          body: "Dear Mr. Edenhofer,
We want to keep you updated on TeamViewer licensing shortages on a regular basis.
We would like to inform you that since the last message on 25-Nov-2014 there have been temporary session channel exceedances which make it impossible to establish more sessions. Since the last e-mail this has occurred in a total of 1 cases.
Additional session channels can be added at any time. Please visit our [1] TeamViewer Online Shop for pricing information.
Thank you - and again all the best with TeamViewer!
Best regards,
Your TeamViewer Team
P.S.: You receive this e-mail because you are listed in our database as person who ordered a TeamViewer license. Please click [2] here to unsubscribe from further e-mails.
-----------------------------
[3] www.teamviewer.com

TeamViewer GmbH * Jahnstr. 30 * 73037 Göppingen * Germany
Tel. 07161 60692 50 * Fax 07161 60692 79

Registration AG Ulm HRB 534075 * General Manager Holger Felgner


[1] https://www.teamviewer.com/en/licensing/update.aspx?channel=D842CS9BF85-P1009645N-348785E76E
[2] http://www.teamviewer.com/en/company/unsubscribe.aspx?id=1009645&ident=E37682EAC65E8CA6FF36074907D8BC14
[3] http://www.teamviewer.com",
        },
      },
      {
        data: IO.read('test/fixtures/mail30.box'),
        body_md5: '23220f9537e59a8febc62705aa1c387c',
        params: {
          from: 'Manfred Haert <Manfred.Haert@example.com>',
          from_email: 'Manfred.Haert@example.com',
          from_display_name: 'Manfred Haert',
          subject: 'Antragswesen in TesT abbilden',
          to: 'info@znuny.inc',
          body: "Sehr geehrte Damen undHerren,

wir hatten bereits letztes Jahr einen TesT-Workshop mit IhremHerrn XXX durchgeführt und würden nun gerne erneutIhre Dienste in Anspruch nehmen.

Mittlerweile setzen wir TesT produktiv ein und würden nun gerne aneinem Anwendungsfall (Change-Management) die Machbarkeit desAbbildens eines derzeit \"per Papier\" durchgeführten Antragswesensin TesT prüfen wollen.

Wir bitten gerne um ein entsprechendes Angebot.

Für Rückfragen stehe ich gerne zur Verfügung. Vielen Dank!

-- 
 Freundliche Grüße
i.A. Manfred Härt

Test Somewhere GmbH
Ferdinand-Straße 99
99073 Korlben
Bitte beachten Sie die neuen Rufnummern!
Telefon: 011261 00000-2460
Fax: 011261 0000-7460
[1] mailto:manfred.haertel@example.com
[2] http://www.example.com
JETZT AUCH BEI FACEBOOK !
[3] https://www.facebook.com/test
___________________________________
Test Somewhere GmbH
 
Diesee-Mail ist ausschließlich für den beabsichtigten Empfängerbestimmt. Sollten Sie irrtümlich diese e-Mail erhaltenhaben, unterrichten Sie uns bitte umgehend unter[4] kontakt@example.com und vernichten Sie diese Mitteilungeinschließlich der ggf. beigefügten Dateien.
Weil wir die Echtheit oder Vollständigkeit der in dieserNachricht enthaltenen Informationen nicht garantierenkönnen, bitten wir um Verständnis, dass wir zu Ihrem undunserem Schutz die rechtliche Verbindlichkeit dervorstehenden Erklärungen ausschließen, soweit wir mitIhnen keine anders lautenden Vereinbarungen getroffenhaben.


[1] mailto:manfred.haertel@example.com
[2] http://www.example.com
[3] https://www.facebook.com/test
[4] mailto:kontakt@example.com",
        },
      },
      {
        data: IO.read('test/fixtures/mail31.box'),
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
        data: IO.read('test/fixtures/mail32.box'),
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
        data: IO.read('test/fixtures/mail34.box'),
        body_md5: 'b6e46176404ec81b3ab412fe71dff0f0',
        params: {
          from: 'Bay <memberbay+12345@members.somewhat>',
          from_email: 'memberbay+12345@members.somewhat',
          from_display_name: 'Bay',
          subject: 'strange email with empty text/plain',
          to: 'bay@example.com',
          body: 'some html text',
        },
      },
    ]

    count = 0
    files.each { |file|
      count += 1
      #p "Count: #{count}"
      parser = Channel::EmailParser.new
      data = parser.parse( file[:data] )

      #puts '++' + data[:body].to_s + '++'
      # check body
      md5 = Digest::MD5.hexdigest( data[:body] )
      #puts "IS #{md5} / should #{file[:body_md5]}"
      assert_equal( file[:body_md5], md5 )

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
