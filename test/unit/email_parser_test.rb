# encoding: utf-8
# rubocop:disable all
require 'test_helper'

class EmailParserTest < ActiveSupport::TestCase
  test 'parse' do
    files = [
      {
        data: IO.binread('test/fixtures/mail1.box'),
        body_md5: 'b57d21dcac6b05e1aa67af51a9e4c1ec',
        params: {
          from: 'John.Smith@example.com',
          from_email: 'John.Smith@example.com',
          from_display_name: '',
          subject: 'CI Daten für PublicView ',
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
          body: "äöüß ad asd

-Martin

--
Old programmers never die. They just branch to a new address.
"
        },
      },
      {
        data: IO.binread('test/fixtures/mail3.box'),
        body_md5: '96a0a7847c1c60e82058db8f8bff8136',
        params: {
          from: '"Günther John | Example GmbH" <k.guenther@example.com>',
          from_email: 'k.guenther@example.com',
          from_display_name: 'Günther John | Example GmbH',
          subject: 'Ticket Templates',
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
        },
      },
      {
        data: IO.binread('test/fixtures/mail6.box'),
        body_md5: '683ac042e94e99a8bb5e8ced7893b1d7',
        params: {
          from: '"Hans BÄKOSchönland" <me@bogen.net>',
          from_email: 'me@bogen.net',
          from_display_name: 'Hans BÄKOSchönland',
          subject: 'utf8: 使って / ISO-8859-1: Priorität"  / cp-1251: Сергей Углицких',
          body: "this is a test

___
 [1] Compare Cable, DSL or Satellite plans: As low as $2.95.

Test1:–
Test2:&
Test3:∋
Test4:&
Test5:=


[1] http://localhost/8HMZENUS/2737??PS="
        },
      },
      {
        data: IO.binread('test/fixtures/mail7.box'),
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
        data: IO.binread('test/fixtures/mail8.box'),
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
        data: IO.binread('test/fixtures/mail9.box'),
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
        data: IO.binread('test/fixtures/mail10.box'),
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
        data: IO.binread('test/fixtures/mail11.box'),
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
        data: IO.binread('test/fixtures/mail12.box'),
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
        },
      },
      # spam email
      {
        data: IO.binread('test/fixtures/mail16.box'),
        body_md5: '91e698a1ba3679dff398ba3587b3f3d9',
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
        data: IO.binread('test/fixtures/mail20.box'),
        body_md5: 'ddcbbb850491ae9a174c4f1e42309f84',
        params: {
          from: 'Health and Care-Mall <drugs-cheapest8@sicor.com>',
          from_email: 'drugs-cheapest8@sicor.com',
          from_display_name: 'Health and Care-Mall',
          subject: 'The Highest Grade Drugs And EXTRA LOW Price .',
          to: 'info2@znuny.com',
          body: "________________________________________________________________________Yeah but even when they. Beth liî ed her neck as well

óû5aHw5³½IΨµÁxG⌊o8KHCmς9-Ö½23QgñV6UAD¿ùAX←t¨Lf7⊕®Ir²r½TLA5pYJhjV gPnãM36V®E89RUDΤÅ©ÈI9æsàCΘYEϒAfg∗bT¡1∫rIoiš¦O5oUIN±IsæSØ¹Pp Ÿÿq1FΧ⇑eGOz⌈F³R98y§ 74”lTr8r§HÐæuØEÛPËq VmkfB∫SKNElst4S∃Á8üTðG°í lY9åPu×8>RÒ¬⊕ΜIÙzÙCC4³ÌQEΡºSè!XgŒs. 
çγ⇓B[1] cwspC L I C K  H E R Eëe3¸ !Calm dylan for school today.
Closing the nursery with you down. Here and made the mess. Maybe the oï from under his mother. Song of course beth touched his pants.
When someone who gave up from here. Feel of god knows what. 
TBϖ∃M5T5ΕEf2û–N¶ÁvΖ'®⇓∝5SÐçË5 Χ0jΔHbAgþE—2i6A2lD⇑LGjÓnTOy»¦Hëτ9’:Their mother and tugged it seemed like 
d3RsV¶HÓΘi¯B∂gax1bîgdHä3rýJÿ1aIKÇ² n1jfaTk³Vs395ß C˜lBl‘mxGo0√úXwT8Ya õ8ksa∫f·ℵs”6ÑQ ÍAd7$p32d1e∏æe.0”×61aîΚ63αSMû Nf5ÉCdL∪1i↔xcaa5êR3l6Lc3iãz16só9èU zDE²aEÈ¨gs25ËÞ hE§cl⊃¢¢ÂoÒÂµBw²zF© qÏkõaXUius1r0⊆ d•∈ø$¢Z2F12­8l.07d56PÚl25JAO6 
45loVóiv1i2ãΥ⌊að⊃d2gÃΥ3™rÎÍu¸aWjO8 n40–Soyè2u¡∅Î3p¢JΜNeÌé×jráÒrΚ 1ÌÓ9AúrAkc8nuEtl22ai‡OB8vSbéσeιõq1+65cw Òs8Uaò4PrsE1y8 〈fMElhϒ⋅Jo8pmzwjˆN¥ wv39aW¡WtsvuU3 1aœ³$éΝnR2OÏ⌉B.∀þc→5Ê9χw5pÃ⁄N fHGFVfE³ãiσjGpa5¶kgg¡ìcWrUq5æakx2h 0Fè4P¸ÕLñrn22ÏoþÝÐHfoRb2eUαw6sñN‾ws¶§3ΒiòX¶¸ofgtHnR⊥3âase9álF¿H5 à6BÁa⊃2iϒsô¡ói ÅkMylÚJ¾ÄoQ–0ℑwvmùþ Ëˆμ\"aQ7jVse6Ðf «hÜp$Lâr£3i1tÚ.323h5qP8g0♥÷R÷ 
·iƒPV1Β∋øiF¤RÃa4v3âgL9¢wr¨7ø×aÏû0η þ1àßStuÞ³u7á¡lpÑocEe·SLlrVàXj ⊥Uµ¢F¬48ðov7¨Arm×4ÍcùVwÞe1§⊇N ÂÛ4äaLþZ2ski×5 c€pBlûù6∂olÃfÚwKß3Ñ 4iíla4C³êsREÕ1 ãeIó$âz8t442fG.¸1≤¸2F’Ã152in⊄ Tl©ëC2v7Ci7·X8a×ú5NlþU〉ιicO∑«s·iKN UuϒjSÃj5Ýu÷Jü§pn5°§e¥Û3℘rÆW‡ò J‹S7A1j0sc&ºpkt·qqøiZ56½vn8¨∗eîØQ3+7Î3Š ∑RkLaKXËasÐsÌ2 ïÇ­¶lDäz8oã78wwU–ÀC T6Uûaϒ938sÌ0Gÿ Oxó∈$98‘R2ÂHï5.ÒL6b9θrδÜ92f9j 
Please matt on his neck. Okay matt huï ed into your mind Since her head to check dylan. Where dylan matt got up there 
1È±ΑAYQªdN¬ÚϒXT00ÀvI∨ío8-½b®8AΕºV4LgÕ↑7LKtgcEiw­yR5YýæGRA1°I¿0CïCàTiü/þwc0Ax211SÜÂùŒTÁ2êòHpNâùM6È¾0A5Tb»:Simmons and now you really is what. Matt picked up this moment later that. 
25¯yV9ÙßYeg·↑DnJ3l4tÝæb1os∏jll÷iSÐiwBÎ4n0ú1Ö ªf÷Ña§1løsuÚ8ê 2LCblgvN½o¼oP3wn♠90 FZora&M™xsΚbbÂ ç5Ãξ$Âô·×2iGæ∇1⊇Ξ¬3.0P0κ53VÁö03ÝYz øX¢BAZ4KwdduÜvvuB↑ΒaÄ’THi0—93rZεj0 §rΜÅa2­·§s7¸Ιf 8⇓þolW„6Ýo6yH¥wKZ∧6 21hÒaKJ“ℜs48IÌ ÔÀ¬­$ZΣ¹ü2ñÙ6B42YMZ.Ô¹V¼9f·0å54⌈R8 
÷w\"9N2gBÀaðSê¢s≅gGÔo0Dn4n↵γ7⊗eS7eýxf3Jd q÷CMaÍä³isNMZp zz0˜lΚLw8oë29ww¤§Qu ¥D⌈íaýË¢ésJ8Á¬ 3oùÙ$¦1Nℜ1>Rét7WPM¨.¶8¹D92k5D9∗8≈R l©3ªSj·Ψ8pΣïKùi6rrÔrbÛu¬i2V∗∏v5ª10a27BÁ Ú♦Ξsa9j3χsa¯iΟ Oi℘ml6óféowbz∀wA6ù→ ñ×bàai´wbs♦βGs Ù81i$iÀˆ12⊃2wC82n8o.µ3NJ9S1©Θ0P1Sd 
What made no one in each time. Mommy was thinking of course beth. Everything you need the same thing 
PïEVGÿ9srEx⇐9oN3U®yEÎi2OR5kÇÿAΤηνULP¿∧q R5¿FHt7J6E»¯C∅Aå∃aVLu∗¢tT〈2ÃšHq9Né: 
⊥ÞÞ¨T¦ªBrrC7³2adš6lmzb¨6ai07tdBo×KopíΡÄlj4Hy ÝaÓ1aÖí∉Ós1aá’ 4D­kleowËo3–1ÍwjR≤Π £RhÈafà7≅sù6u2 8NLV$∪⇓»↓1Y¶2µ.vßÈ23ÖS7û0Ün¬Ä m5VKZy3KÎiñë¹DtÚ2HrhGaMvr5ïR«oÂ1namΜwÐãanFu8x7⌈sU E4cva£Âε™s7ΑGO dA35ldñÌèoAξI1wXKïn f¼x¾a∏7ffs†ìÖð 5msC$7Ët¦0z„n÷.it¡T7O8vt5¼8å· Jï1ÏPkáO¶rnùrAo8s5∅z—4Rha1®t˜cq5YΧ ΤQÍraÑ⌋4¹sÜ5²§ ûVBιluwóioL3ëBw£±1¶ 5∈àáa1IÊ2sšÛÛÂ G´7ρ$kJM80∼∠ℵl.J1Km32µÚ⊃5ãé¼§ p°ÿ­A¹NU0c¥xçfo〈Øácm14QGpHEj7lnDPVieV2¶aΠ2H7 ²j26azBSesë1c9 ´2Ù¬l0nò¤oõâRVw¦X´Ï αVõ­a≅σ¼Zs§jJå 3pFN$¾Kf821YΟ7.3ÍY95JΑqŸ0v9ÄQ 
ñ↑yjPΤ1u6rFwhNeCOϖúd5Γêcne¼a0iTF¹5sxUS0o88ℵªlaÅT℘oOBÀ¹në·­1e∧Kpf υ98ξabp†3sj8â& 9©BolÎAWSo7wNgwø¦mM tteQat0ϖ2s4≡NÇ ÕÆ¦Θ$ùRÓq0·Ã7ª.mt¾³1—uwF57H♣f æ∪HYSjψ3Byš²g¤ndXÀ5tµ¯ò6hZ⇒yÿr8ÿmdowyðdiψ8YΗd0ršŠ N0Ý9aÃ3I¦sQaýê Õ0Y7lZ¯18o∫50Çwµ\"©Ζ n6Ü≥a∇lßnsF›J9 ºDΟK$Á4ÉL0S7zÖ.Ta2X3²R995391¡ 
Turning to mess up with. Well that to give her face Another for what she found it then. Since the best to hear 
GX°♦Ca2isA¾8¡bNÉî8ÂAöÜzΘD∇tNXIfWi–Ap2WYNYF®b ≠7yφDpj6©R04EÂU´ñn7GÆoÌjSÂ³Á∋TC⊥πËO1∗÷©RtS2wE66è­ νÑêéASi21DP“8λV∧W⋅OAÖg6qNtNp1T269XA7¥À²GGI6SEwU2íS3Χ1â!Okay let matt climbed in front door. Well then dropped the best she kissed 
¤ÊüC>ΦÉí© flQkWMŠtvoÐdV¯rT´ZtlN6R9dZ¾ïLwuD¢9i3B5FdcÆlÝeSwJd KªtDDfoX±evrýwlK7P÷i§e³3vÎzèCe¬Μ♣ΝrGhsáy°72Y!gZpá R6O4O»£ð∋r9ÊZÀdB6iÀeîσ∼ÓrCZ1s ²ú÷I3ÁeÒ¤+⌉CêU »k6wG´c‚¾o60AJoR7Ösd3i¿Ásððpt Øè77añ∀f5np¤nþduE8⇒ È¹SHGJVAtew∇LëtςëDæ 6kÌ8FgQQ⊂R8ÇL2EI2∉iEHÍÉ3 Hÿr5Af1qximςρ‡r6©2jmWv9ÛaWð¸giACÜ¢lM⌋¿k ÊVÚ¸SÓùθçhµ5BΙi∗ttEp8¢EPpSzWJi32UÎn5ìIhgx8n⌉!j∏e5 
x¯qJ>mC7f 5ºñy1GA4Ý0lCQe09s9u%uksã ψìX5A4g3nu←Τyst7ÍpMhšgÀÖe〉pÚ£n¼YƒŠtÉÚLGizqQ↓c3tÙI œïbXMKÛRSertj×d\"OtÊss58®!oo2i FÂWáEWøDDx7hIÕpΦSôBiÒdrUr⇔J<Õa1Αzwt0°p×ià8RÌoHÛ1Än¥7ÿr ¯¥õàDYvO7aká»htì04Πe∂λÇ1 1ÈdUoο°X3fc63¶ e&∪GOxT3CvXcO·e3KËνr3¸y2 26Ëz3Ã∞I± Pì∃zYt6F4e6è⇓va5÷þ9rkΘ3äsKP5R!ιµmz 
3í1ë>ð2′L 2óB⊥S∩OQMeý∉ÑΦcöè9Tuãa∫drâ5ûMeLk9Ô £æ1OOø9oKnÿψÀWl7HÏ∅i9ρÈÊniâ•ÛeXPxí ´Í5¡SUqtBh7æa5otSZ9pØËÛDpf®ÝÊiÛωbjn¯½Ÿ2gsçh− båÌswxðoSiq8hvtèé6Òh⌈b²S ×6þSVBEFCiøUàds9Ñ¤ΕaÆ§ξÜ,1„wv jw7AMKÈ↔laæG9¦së3«etuB2keDãæìr°¨IeC¾EaÄao÷″∧r>6e¸d9DùÇ,mtSö I∗44A¹RˆêM98zME≅QŸÐX¹4j6 î0n3a1'Êânxpl6d83þJ 06Ð9Eïãýã-28Ú9c4ßrØh7è¥med½♠kcñ3sPk¶2•r!〉QCa 
ŠeÏÀ>Ãσ½å bpøNERN8eaD6Åns7Abhy±Æü∩ D7sVR8'ºEeÿáDVfc˜3ëu7ÏÆqncË3qdÊ∼4∇sρmi5 6æ¾Êaä°∝TnQb9sdÀMùℑ ∑gMÿ2bNð¶4cä½⊆/4X1κ7¥f1z ϖ1úECzf•1uMbycs1•9¾ts0Tào3hêDmSs3Áe7BíÉrô⋅ãÔ φ8Ä″SSXð¤uúI¸5p58uHp2cß±o∂T©Rrd6sMt∪µµξ!é4Xb

Both hands through the fear in front.
Wade to give it seemed like this. Yeah but one for any longer. Everything you going inside the kids.


[1] http://pxmzcgy.storeprescription.ru?zz=fkxffti"
        },
      },
      {
        data: IO.binread('test/fixtures/mail21.box'),
        body_md5: 'c9fb828072385643e528ab3a9ce7f10c',
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
        data: IO.binread('test/fixtures/mail27.box'),
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
        data: IO.binread('test/fixtures/mail30.box'),
        body_md5: 'b4038e70d25854a023bce604c9f7a7ff',
        params: {
          from: 'Manfred Haert <Manfred.Haert@example.com>',
          from_email: 'Manfred.Haert@example.com',
          from_display_name: 'Manfred Haert',
          subject: 'Antragswesen in TesT abbilden',
          to: 'info@znuny.inc',
          body: "Sehr geehrte Damen und Herren,

wir hatten bereits letztes Jahr einen TesT-Workshop mit Ihrem Herrn XXX durchgeführt und würden nun gerne erneut Ihre Dienste in Anspruch nehmen.

Mittlerweile setzen wir TesT produktiv ein und würden nun gerne an einem Anwendungsfall (Change-Management) die Machbarkeit des Abbildens eines derzeit \"per Papier\" durchgeführten Antragswesens in TesT prüfen wollen.

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
 
Diese e-Mail ist ausschließlich für den beabsichtigten Empfänger bestimmt. Sollten Sie irrtümlich diese e-Mail erhalten haben, unterrichten Sie uns bitte umgehend unter [4] kontakt@example.com und vernichten Sie diese Mitteilung einschließlich der ggf. beigefügten Dateien.
Weil wir die Echtheit oder Vollständigkeit der in dieser Nachricht enthaltenen Informationen nicht garantieren können, bitten wir um Verständnis, dass wir zu Ihrem und unserem Schutz die rechtliche Verbindlichkeit der vorstehenden Erklärungen ausschließen, soweit wir mit Ihnen keine anders lautenden Vereinbarungen getroffen haben.


[1] mailto:manfred.haertel@example.com
[2] http://www.example.com
[3] https://www.facebook.com/test
[4] mailto:kontakt@example.com",
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
      {
        data: IO.binread('test/fixtures/mail36.box'),
        body_md5: '428327fb533b387b3efca181ae0c25d0',
        params: {
          from: 'Martin Smith <m.Smith@example.com>',
          from_email: 'm.Smith@example.com',
          from_display_name: 'Martin Smith',
          subject: 'Fw: Zugangsdaten',
          to: 'Martin Edenhofer <me@example.com>',
          body: ' 
-- 
don\'t cry - work! (Rainald Goetz)
 
 

Gesendet: Mittwoch, 03. Februar 2016 um 12:43 Uhr
Von: "Martin Smith" <m.Smith@example.com>
An: linuxhotel@zammad.com
Betreff: Fw: Zugangsdaten

 
-- 
don\'t cry - work! (Rainald Goetz)
 
 

Gesendet: Freitag, 22. Januar 2016 um 11:52 Uhr
Von: "Martin Edenhofer" <me@example.com>
An: m.Smith@example.com
Betreff: Zugangsdaten
Um noch vertrauter zu werden, kannst Du mit einen externen E-Mail Account (z. B. [1] web.de) mal ein wenig selber “spielen”. :)


[1] http://web.de',
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
