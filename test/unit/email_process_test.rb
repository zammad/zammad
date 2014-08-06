# encoding: utf-8
require 'test_helper'

class EmailProcessTest < ActiveSupport::TestCase
  test 'process simple' do
    files = [
      {
        :data => 'From: me@example.com
To: customer@example.com
Subject: some subject

Some Text',
        :trusted => false,
        :success => true,
      },
      {
        :data => "From: me@example.com
To: customer@example.com
Subject: äöü some subject

Some Textäöü",
        :trusted => false,
        :success => true,
        :result => {
          0 => {
            :priority => '2 normal',
            :title    => 'äöü some subject',
          },
          1 => {
            :body     => 'Some Textäöü',
            :sender   => 'Customer',
            :type     => 'email',
            :internal => false,
          },
        },
      },
      {
        :data => "From: me@example.com
To: customer@example.com
Subject: äöü some subject

Some Textäöü".encode("ISO-8859-1"),
        :success => true,
        :result => {
          0 => {
            :priority   => '2 normal',
            :title      => '', # should be äöü some subject, but can not be parsed from mime tools
          },
          1 => {
            :body       => 'Some Textäöü',
            :sender     => 'Customer',
            :type       => 'email',
            :internal   => false,
          },
        },
      },
      {
        :data => "From: me@example.com
To: customer@example.com
Subject: Subject: =?utf-8?B?44CQ5LiT5Lia5Li65oKo5rOo5YaM6aaZ5riv5Y+K5rW35aSW5YWs5Y+477yI5aW95aSE5aSa5aSa77yJ?=
        =?utf-8?B?44CR44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA44CA?=
        =?utf-8?B?44CA44CA44CA44CA44CA44CA44CA44CA5Lq654mpICAgICAgICAgIA==?=
        =?utf-8?B?ICAgICAgICAgIOS6kuiBlOe9keS6i+eZvuW6puaWsOmXu+eLrOWutg==?=
        =?utf-8?B?5Ye65ZOB5Lyg5aqS5o2i5LiA5om55o235YWL5oi057u05pav5p2v5Yaz6LWb5YmN5Lu75ZG95Li05pe2?=
        =?utf-8?B?6aKG6ZifIOWJjemihumYn+WboOeXheS9j+mZouacgOaWsDrnm5bkuJbmsb3ovaborq8gMQ==?=
        =?utf-8?B?MeaciDbml6XvvIzpgJrnlKjmsb3ovablrqPluIPku4rlubQxMOaciOS7veWcqOWNjumUgA==?=
        =?utf-8?B?6YePLi4u5YeP5oyB5LiJ54m557Si6YGTIOWtn+WHr+WwhuWFqOWKm+WPkeWxlea5mOmEgg==?=
        =?utf-8?B?5oOF5rGf6Z2S5pGE5b2x5L2c5ZOB56eR5oqA5pel5oql6K6vIO+8iOiusOiAhei/h+WbveW/oCA=?=
        =?utf-8?B?6YCa6K6v5ZGY6ZmI6aOe54eV77yJ5rGf6IuP55yB5peg57q/55S156eR5a2m56CU56m25omA5pyJ6ZmQ?=
        =?utf-8?B?5YWs5Y+46Zmi5aOr5bel5L2c56uZ5pel5YmN5q2j5byP5bu6Li4uW+ivpue7hl0=?=

Some Text",
        :trusted => false,
        :success => true,
        :result => {
          0 => {
            :priority   => '2 normal',
            :title      => '【专业为您注册香港及海外公司（好处多多）】　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　',
          },
          1 => {
            :body       => 'Some Text',
            :sender     => 'Customer',
            :type       => 'email',
          },
        },
      },
      {
        :data    => IO.read('test/fixtures/mail21.box'),
        :success => true,
        :result  => {
          0 => {
            :priority   => '2 normal',
            :title      => 'World Best DRUGS Mall For a Reasonable Price.',
          },
          1 => {
            :body       => '_________________________________________________________________________________Please beth saw his head

92hH3&yuml;oI221G1&iquest;iH16u-2&loz;NQ422U1awAq&sup1;JLZ&mu;2IicgT1&zeta;2Y7&sube;t 63&lsquo;M236E2&Yacute;&rarr;DA2&dagger;I048CvJ9A&uarr;3iTc4&Eacute;I&Upsilon;vXO502N1FJS&eth;1r 154F1HPO11CRxZp tL&icirc;T9&ouml;XH1b3Es1W mN2Bg3&otilde;EbP&OElig;S2f&tau;T&oacute;Y4 sU2P2&zeta;&Delta;RFkcI21&trade;C&Oacute;Z3E&Lambda;Rq!Cass is good to ask what that

86&Euml;[1]2u2C&nbsp;L&nbsp;I C1K&nbsp;&nbsp;&nbsp;H E&nbsp;R E28MLuke had been thinking about that.
Shannon said nothing in fact they. Matt placed the sofa with amy smiled. Since the past him with more. Maybe he checked the phone. Neither did her name only. Ryan then went inside matt.
Maybe we can have anything you sure.

&aacute;&bull;XMY2&Aring;EE12N&deg;kP\'d&Auml;1S4&rceil;d &radic;p&uml;H&Sigma;>jE4y4AC22L2&ldquo;vT&and;4tHX1X:

x5VV"1ti21aa&Phi;3fg&brvbar;z2r1&deg;haeJw n1Va879s&AElig;3j f1&iuml;l29lo5F1w&nu;11 &kappa;&psi;&rsaquo;a9f4sLsL 2Vo$v3x1&cedil;nz.u2&brvbar;1H4s3527
yoQC1FMiMzda1Z&epsilon;l&Yacute;HNi1c2s2&ndash;&piv; DYha&atilde;7Ns421 n3dl1X1o11&para;wpN&uarr; YQ7a239s1q2 QyL$fc21&Nu;S5.5Wy621d5&Auml;1H

17<V401i421a&theta;1Tg21Gr9E2a&Rho;Bw &rarr;2&Ouml;SRSLu72lpL6Ve191r1HL FEpA229cP&not;lt&Ograve;cDib2XvTtFel3&reg;+bVM 252aXWas4&ordm;2 &mu;2Kl&prod;7mo&radic;23wSg1 &iota;&pound;Ca11Xso18 1L2$&hellip;412Jo&uarr;.0&Lambda;a53i&egrave;55W2
23IV4&loz;9iF2Va2&Otilde;&oacute;g8&sup3;9r&weierp;buaf12 fc7Pg3&sube;rz&ccedil;8o2&minus;&sdot;f&yuml;&ge;ZeaP&Ntilde;s5&lArr;Tsi&Psi;&ni;i92uoU8Rn&Psi;&rceil;&bull;aw1flf22 TQNaU&rsaquo;&eacute;svDu B1Il6&Theta;lo&ang;HfwNX8 36Xa&sim;&alpha;1sT1d &Scaron;HG$2&otilde;13QW1.&permil;&rsaquo;Y52g80&brvbar;ao

LKNV0&Auml;wiM4xafsJgFJ2r27&rdquo;a&lArr;M2 &ang;O5SQ2Mut21p2&Aring;&Atilde;e&uml;2HrZ41 1U&Lambda;F&uml;Tso2wXr24Icky2e1qY 074a2l&lfloor;s2H1 42pl24Xob0aw4F&Ocirc; 28&there4;a70lsA30 &szlig;WF$Z&cedil;v4AEG.2612t9p5&para;1Q
M91C&epsilon;92i0qPa1A2lW5Pi5Vusi8&euml; 2O0SE2Eu2&isin;2p2Y3eTs6r622 l12Ay2jcQpet13&otilde;iiqXvPVOe81V+1&ldquo;G 126a1&Pi;7sJ2g 1J2l&hearts;&Scaron;1o2olwBV2 &rarr;Ama&eta;2&macr;sa22 H22$2Ef2&isin;n5.&OElig;8H95119&sup;&fnof;2

Up dylan in love and found herself. Sorry for beth smiled at some time
Whatever you on one who looked. Except for another man and ready.

&Uacute;2eAC2&oslash;N&Euml;1UT3L&spades;IC&euml;9-B&OElig;fAo&Oacute;CL5&Beta;2LH&omicron;NE5&part;7RScdGX11Ip&Sigma;uCCw&or;/D16A1v2S0d&sub;T1&apos;BHf2&Delta;M227A63B:

2U2V51Ue212nRm2t22Oo&gamma;12ly&frac14;Wi6pxn&Agrave;Z1 c2Sa8&iuml;1sG2&sub; &Mu;Jll1&pound;&bdquo;onb2w&rceil;&ouml;1 vY8a&Theta;mgs024 &aring;&yen;G$1592KkU11b0.&frac12;&Acirc;&real;54&Egrave;h0&ordm;1h
Zf1A0j&cedil;dc1&xi;v&trade;Xpagl2ib8YrSf0 1Wia141s1&times;7 TAwll1dom1Gw2&iquest;z &Beta;21a&circ;y2sN8&eta; 3oo$D012&Lambda;p14c2z.PA&empty;9&upsih;7354&uacute;9

R2&iacute;Nn&uml;2aYR&oslash;s&cong;&larr;&Iacute;oP&Agrave;ynC&Chi;1ef2ox2&cup;h E18aN22si&yuml;5 f47l147oF1jwG2&Eacute; 108a1edsj&Ucirc;S &iquest;e1$K&egrave;R1LD272o&egrave;.41O99&Yacute;192&piv;n
12&crarr;S&iota;3&rdquo;p&Yacute;2&oline;iEuer&Gamma;y0iY30v&Tau;A6a2"Y 465a1m6sg1s C&forall;il&Alpha;2&Pi;or6yw712 1K&Omega;a232s&nabla;&Delta;1 9&Chi;9$MWN2P02822&beta;.2&cap;S93220RQ&rsquo;

Have anything but matty is taking care. Voice sounded in name only the others
Mouth shut and while he returned with. Herself with one who is your life

2&sup2;2Gu8NEZ3FNFs2E1RnR&Ccedil;C9AK4xL151 25bH97CE&laquo;20A2q&cent;L1k&rarr;T&ordf;JkHe3&scaron;:Taking care about matt li ed ryan. Knowing he should be there.

Ks&pound;T2bIr74Ea2DZm&oelig;H1a17od1&cup;vo2ozlP3S 23&lsaquo;azy&prop;s&Uacute;1Q 42&sup1;ll21ovh7w2D2 1Qwa&uArr;c&Beta;s&uml;wH I&micro;e$&lArr;J517T2.t5f361B062&Psi;
5z&weierp;Z4nGi289t&larr;f4hvn2rb&Yuml;To1s9m12qand1xxO6 I2&cup;ak&frac12;0s21M 2&Eta;&iexcl;l22&frac34;orztw170 &mdash;&clubs;&cong;ar6qsvDv 76T$3&times;D0er&Iacute;.d107WoI51K2

&upsih;a9P&apos;1&macr;rP74o2&psi;2z&chi;f2a&Atilde;2&ntilde;c3qY &rarr;&reg;7aaRgsN1k 1&permil;&Sigma;l2p1o7R&sub;w&AElig;2e 3Iha&clubs;d&tilde;s3g7 23M$&equiv;&sdot;10AY4.Uq&radic;321k5SU&Mu;
Zr2A8&Ouml;6cZ&Yuml;do&Rho;eumpq1pAoUl2I2ieY2aK>&part; 3n6ax1Qs20b &deg;H&auml;l91&Ntilde;o&Iuml;6aw&equiv;d2 &Eta;&Aring;2a1&Oacute;vs&sup;17 C&sube;1$2Bz2sl2.&int;Pb5&Oslash;Mx0oQd

Z&Iota;&mu;PCqmr&micro;p0eA&Phi;&hearts;d&ocirc;&oline;&Omega;n&ang;2si4y2s28&laquo;o6&forall;ClDe&Igrave;oPbqnd1Jel&egrave;2 2&circ;5aWl&lang;sbP2 2&sup2;2l8&cent;OoH&cedil;ew&rsquo;90 &Upsilon;66a21dsh6K r61$7Ey0Wc2.&pound;&mdash;012C857A&thorn;
i1&sigma;S&euro;53yx&micro;2n80nt&Rho;&Pi;mh&ccedil;&equiv;hrB1do&micro;S1ih2rdOKK 712a&larr;2Is2&rceil;V Cssl1&acute;RoT1Qwy&Eacute;&Delta; &bull;&prod;&infin;a2YGs18E 1&pi;x$04&ograve;0gMF.bTQ3&Iacute;x6582&sigmaf;

Maybe even though she followed.
Does this mean you talking about. Whatever else to sit on them back

&larr;4BC32hAGAWNr2jAG&upsilon;&raquo;D1f4I2m&radic;AHM9N&rang;12 &sbquo;1HD19&Uuml;R23&or;U90IG199S1&cup;&rdquo;T123O2&deg;cR0E&uArr;E211 42aA&Prime;X&Nu;D14&image;VAK8A1d9Nr1DT112A5khGA3mE98&Ocirc;S9KC!5TU

AMm>EjL w&lowast;LW&upsilon;IaoKd1r&Theta;22l2I&Kappa;d&ecirc;5PwO4Hi2y6d&Ouml;H&lfloor;e&Atilde;&igrave;g j14Dr15e700lH12iJ12vY&hellip;2e1mhr114yr&AElig;2!&sum;&eta;2 21&upsilon;O&Delta;f&delta;rKZwd4KVeB12r&real;01 P&Zeta;2341o+A7Y 126GM17oGO&ordm;os7&sum;d272s18P &omicron;&diams;QaRn&ndash;n5b2d02w 2r&upsih;GI2&image;em0&forall;t1b2 20rF4O7R221E12&sube;ES&Upsilon;4 KF0A212i5&iuml;crt&sube;&euro;mRJ7aN&Lambda;2in26l5bQ 1&upsih;tSZbwh3&para;3ig&spades;9p2&Prime;2p&times;12iK11nsWsgdXW!tBO

m0W>Y2&Acirc; b1u1x&Delta;d03&macr;&not;0vHK%21&oacute; 674Aj32uQ&larr;&Iuml;t&Egrave;H1houqey1Yn221t&rfloor;BZi1V2c1Tn >Z&Gamma;M222e311d2s5s22&rsaquo;!102 2&iexcl;2Em21x2V2p1&or;6i2d&acirc;rB9ra72mtSzIiMlVo0NLng&Beta;&ucirc; 22LD7&uArr;maNx3tU&zeta;&cup;etc2 902o123fv49 w&cong;1O0giv12YeX2NryfT 3fP3xZ2 F2&Atilde;Y8q1eE1&Uuml;a&acirc;yfr&Mu;pls92&Acirc;!q&kappa;2

&icirc;5A>&forall;p&fnof; Z&micro;&Iacute;S&delta;32em2sc&oplus;7vu41Jr&Ograve;1we2yh qa&rho;O2p&frac14;n&Sigma;xZlrN1i&spades;2cnl4jeN1Q y2&cong;Sb63h17&rang;of1yp&Aring;A1p&thorn;h0i&Ocirc;cbnec4gI21 h2Uw23&lsaquo;i92ktS12h6V1 g1sV&OElig;2uipV1se2&sdot;a42V,T6D 228M&Rho;Y1a&sup;&ordm;&Epsilon;s5&ugrave;2t9IDeFD&image;rXpOCe&ldquo;&mu;an1Mr11Kd122,e27 DfmA21NM92hEU2&or;X&sigma;&psi;G 4j0a181nhTAdmT2 192E&nu;&mu;r-U4fc121h8&ordf;&cedil;eoycc9xjk&frasl;ko!29K

12&hellip;>J6&Aacute; 1&rang;8E&Ouml;22a141s117y3&acirc;8 1f2R6olewtzfw&sup1;su&yacute;oQn&dArr;&sup3;&sup3;d24Gs&cent;7&laquo; AlDa1H1n9Ejdtg&rsaquo; 12&theta;2&epsilon;1&supe;41&Prime;A/42v72z&rarr; 231C622u56Xs9&frasl;1t&sum;&Iota;iox&Eacute;jm2R2e1W2rH25 o&yen;2S&ge;gmuX2gp3yip&middot;12oD13rc3&mu;tks&cup;!sWK

When she were there you here. Lott to need for amy said.
Once more than ever since matt. Lott said turning o ered. Tell you so matt kept going.
Homegrown dandelions by herself into her lips. Such an excuse to stop thinking about. Leave us and be right.

[2]

Это сообщение свободно от вирусов и вредоносного ПО благодаря [3]avast! Antivirus защита активна.



[1] http://piufup.medicatingsafemart.ru
[2] http://www.avast.com/
[3] http://www.avast.com/
',
            :sender     => 'Customer',
            :type       => 'email',
            :internal   => false,
          },
        },
      },
      {
        :data    => IO.read('test/fixtures/mail22.box'),
        :success => true,
        :result  => {
          0 => {
            :priority   => '2 normal',
            :title      => 'P..E..N-I..S__-E N L A R-G E-M..E..N T-___P..I-L-L..S...Info.',
          },
          1 => {
            :body       => "Puzzled by judith bronte dave. Melvin will want her way through with.
Continued adam helped charlie cried. Soon joined the master bathroom. Grinned adam rubbed his arms she nodded.
Freemont and they talked with beppe.
Thinking of bed and whenever adam.
Mike was too tired man to hear.I10PQSHEJl2Nwf&tilde;2113S173 &Icirc;1mEbb5N371L&piv;C7AlFnR1&diams;HG64B242&brvbar;M2242zk&Iota;N&rceil;7&rceil;TBN&ETH; T2xPI&ograve;gI2&Atilde;lL2&Otilde;ML&perp;22Sa&Psi;RBreathed adam gave the master bedroom door.
Better get charlie took the wall.
Charlotte clark smile he saw charlie.
Dave and leaned her tears adam.Maybe we want any help me that.
Next morning charlie gazed at their father.
Well as though adam took out here. Melvin will be more money. Called him into this one last night.
Men joined the pickup truck pulled away. Chuck could make sure that.[1]&dagger;p1C?L&thinsp;I?C&ensp;K?88&ensp;5 E R?EEOD !Chuckled adam leaned forward and le? charlie.
Just then returned to believe it here.
Freemont and pulling out several minutes.


[1] &#104;&#116;&#116;&#112;&#58;&#47;&#47;&#1072;&#1086;&#1089;&#1082;&#46;&#1088;&#1092;?jmlfwnwe&ucwkiyyc
",
            :sender     => 'Customer',
            :type       => 'email',
            :internal   => false,
          },
        },
      },
    ]
    process(files)
  end
  test 'process trusted' do
    files = [
      {
        :data => 'From: me@example.com
To: customer@example.com
Subject: some subject
X-Zammad-Ignore: true

Some Text',
        :trusted => true,
        :success => false,
      },
      {
        :data => 'From: me@example.com
To: customer@example.com
Subject: some subject
X-Zammad-Ticket-priority: 3 high
X-Zammad-Article-sender: System
x-Zammad-Article-type: phone
x-Zammad-Article-Internal: true

Some Text',
        :trusted => true,
        :success => true,
        :result => {
          0 => {
            :priority     => '3 high',
            :title        => 'some subject',
          },
          1 => {
            :sender       => 'System',
            :type         => 'phone',
            :internal     => true,
          },
        },
      },
    ]
    process(files)
  end

  test 'process not trusted' do
    files = [
      {
        :data => 'From: me@example.com
To: customer@example.com
Subject: some subject
X-Zammad-Ticket-Priority: 3 high
X-Zammad-Article-Sender: System
x-Zammad-Article-Type: phone
x-Zammad-Article-Internal: true

Some Text',
        :trusted => false,
        :success => true,
        :result => {
          0 => {
            :priority     => '2 normal',
            :title        => 'some subject',
          },
          1 => {
            :sender       => 'Customer',
            :type         => 'email',
            :internal     => false,
          },
        },
      },
    ]
    process(files)
  end

  test 'process with postmaster filter' do
    group = Group.create_if_not_exists(
      :name          => 'Test Group',
      :created_by_id => 1,
      :updated_by_id => 1,
    )
    PostmasterFilter.destroy_all
    PostmasterFilter.create(
      :name => 'not used',
      :match => {
        :from => 'nobody@example.com',
      },
      :perform => {
        'X-Zammad-Ticket-priority' => '3 high',
      },
      :channel       => 'email',
      :active        => true,
      :created_by_id => 1,
      :updated_by_id => 1,
    )
    PostmasterFilter.create(
      :name => 'used',
      :match => {
        :from => 'me@example.com',
      },
      :perform => {
        'X-Zammad-Ticket-group_id' => group.id,
        'x-Zammad-Article-Internal' => true,
      },
      :channel       => 'email',
      :active        => true,
      :created_by_id => 1,
      :updated_by_id => 1,
    )
    PostmasterFilter.create(
      :name => 'used x-any-recipient',
      :match => {
        'x-any-recipient' => 'any@example.com',
      },
      :perform => {
        'X-Zammad-Ticket-group_id' => 2,
        'x-Zammad-Article-Internal' => true,
      },
      :channel       => 'email',
      :active        => true,
      :created_by_id => 1,
      :updated_by_id => 1,
    )
    files = [
      {
        :data => 'From: me@example.com
To: customer@example.com
Subject: some subject

Some Text',
        :trusted => false,
        :success => true,
        :result => {
          0 => {
            :group        => group.name,
            :priority     => '2 normal',
            :title        => 'some subject',
          },
          1 => {
            :sender       => 'Customer',
            :type         => 'email',
            :internal     => true,
          },
        },
      },
      {
        :data => 'From: somebody@example.com
To: bod@example.com
Cc: any@example.com
Subject: some subject

Some Text',
        :trusted => false,
        :success => true,
        :result => {
          0 => {
            :group          => 'Twitter',
            :priority       => '2 normal',
            :title          => 'some subject',
          },
          1 => {
            :sender         => 'Customer',
            :type           => 'email',
            :internal       => true,
          },
        },
      },
    ]
    process(files)
    PostmasterFilter.destroy_all
  end

  def process(files)
    files.each { |file|
      parser = Channel::EmailParser.new
      result = parser.process( { :trusted => file[:trusted] }, file[:data] )
      if file[:success]
        if result && result.class == Array && result[1]
          assert( true )
          if file[:result]
            [ 0, 1, 2 ].each { |level|
              if file[:result][level]
                file[:result][level].each { |key, value|
                  if result[level].send(key).respond_to?('name')
                    assert_equal( value.to_s, result[level].send(key).name )
                  else
                    assert_equal( value, result[level].send(key))
                  end
                }
              end
            }
          end
        else
          assert( false, 'ticket not created', file )
        end
      elsif !file[:success]
        if result && result.class == Array && result[1]
        puts result.inspect
          assert( false, 'ticket should not be created but is created' )
        else
          assert( true, 'ticket not created - nice' )
        end
      else
        assert( false, 'UNKNOWN!' )
      end
    }
  end
end