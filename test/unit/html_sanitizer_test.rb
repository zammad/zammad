# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'test_helper'

class HtmlSanitizerTest < ActiveSupport::TestCase

  setup do
    @processing_timeout = HtmlSanitizer.const_get(:PROCESSING_TIMEOUT)

    # XSS processing may run into a timeout on slow CI systems, so turn the timeout off for the test.
    silence_warnings do
      HtmlSanitizer.const_set(:PROCESSING_TIMEOUT, nil)
    end
  end

  teardown do
    silence_warnings do
      HtmlSanitizer.const_set(:PROCESSING_TIMEOUT, @processing_timeout)
    end
  end

  test 'xss' do
    assert_equal(HtmlSanitizer.strict('<b>123</b>'), '<b>123</b>')
    assert_equal(HtmlSanitizer.strict('<script><b>123</b></script>'), '')
    assert_equal(HtmlSanitizer.strict('<script><style><b>123</b></style></script>'), '')
    assert_equal(HtmlSanitizer.strict('<abc><i><b>123</b><bbb>123</bbb></i></abc>'), '<i><b>123</b>123</i>')
    assert_equal(HtmlSanitizer.strict('<abc><i><b>123</b><bbb>123<i><ccc>abc</ccc></i></bbb></i></abc>'), '<i><b>123</b>123<i>abc</i></i>')
    assert_equal(HtmlSanitizer.strict('<not_existing>123</not_existing>'), '123')
    assert_equal(HtmlSanitizer.strict('<script type="text/javascript">alert("XSS!");</script>'), '')
    assert_equal(HtmlSanitizer.strict('<SCRIPT SRC=http://xss.rocks/xss.js></SCRIPT>'), '')
    assert_equal(HtmlSanitizer.strict('<IMG SRC="javascript:alert(\'XSS\');">'), '')
    assert_equal(HtmlSanitizer.strict('<IMG SRC=javascript:alert(\'XSS\')>'), '')
    assert_equal(HtmlSanitizer.strict('<IMG SRC=JaVaScRiPt:alert(\'XSS\')>'), '')
    assert_equal(HtmlSanitizer.strict('<IMG SRC=`javascript:alert("RSnake says, \'XSS\'")`>'), '')
    assert_equal(HtmlSanitizer.strict('<IMG """><SCRIPT>alert("XSS")</SCRIPT>">'), '<img>"&gt;')
    assert_equal(HtmlSanitizer.strict('<IMG SRC=# onmouseover="alert(\'xxs\')">'), '<img src="#">')
    assert_equal(HtmlSanitizer.strict('<IMG SRC="jav  ascript:alert(\'XSS\');">'), '')
    assert_equal(HtmlSanitizer.strict('<IMG SRC="jav&#x09;ascript:alert(\'XSS\');">'), '')
    assert_equal(HtmlSanitizer.strict('<IMG SRC="jav&#x0A;ascript:alert(\'XSS\');">'), '')
    assert_equal(HtmlSanitizer.strict('<IMG SRC="jav&#x0D;ascript:alert(\'XSS\');">'), '')
    assert_equal(HtmlSanitizer.strict('<IMG SRC=" &#14;  javascript:alert(\'XSS\');">'), '<img src="">')
    assert_equal(HtmlSanitizer.strict('<SCRIPT/XSS SRC="http://xss.rocks/xss.js"></SCRIPT>'), '')
    assert_equal(HtmlSanitizer.strict('<BODY onload!#$%&()*~+-_.,:;?@[/|\]^`=alert("XSS")>'), '')
    assert_equal(HtmlSanitizer.strict('<SCRIPT/SRC="http://xss.rocks/xss.js"></SCRIPT>'), '')
    assert_equal(HtmlSanitizer.strict('<<SCRIPT>alert("XSS");//<</SCRIPT>'), '&lt;')
    assert_equal(HtmlSanitizer.strict('<SCRIPT SRC=http://xss.rocks/xss.js?< B >'), '')
    assert_equal(HtmlSanitizer.strict('<SCRIPT SRC=//xss.rocks/.j>'), '')
    assert_equal(HtmlSanitizer.strict('<IMG SRC="javascript:alert(\'XSS\')"'), '')
    assert_equal(HtmlSanitizer.strict('<IMG SRC="javascript:alert(\'XSS\')" abc<b>123</b>'), '123')
    assert_equal(HtmlSanitizer.strict('<iframe src=http://xss.rocks/scriptlet.html <'), '')
    assert_equal(HtmlSanitizer.strict('</script><script>alert(\'XSS\');</script>'), '')
    assert_equal(HtmlSanitizer.strict('<STYLE>li {list-style-image: url("javascript:alert(\'XSS\')");}</STYLE><UL><LI>XSS</br>'), '<ul><li>XSS</li></ul>')
    assert_equal(HtmlSanitizer.strict('<IMG SRC=\'vbscript:msgbox("XSS")\'>'), '')
    assert_equal(HtmlSanitizer.strict('<IMG SRC="livescript:[code]">'), '')
    assert_equal(HtmlSanitizer.strict('<svg/onload=alert(\'XSS\')>'), '')
    assert_equal(HtmlSanitizer.strict('<BODY ONLOAD=alert(\'XSS\')>'), '')
    assert_equal(HtmlSanitizer.strict('<LINK REL="stylesheet" HREF="javascript:alert(\'XSS\');">'), '')
    assert_equal(HtmlSanitizer.strict('<STYLE>@import\'http://xss.rocks/xss.css\';</STYLE>'), '')
    assert_equal(HtmlSanitizer.strict('<META HTTP-EQUIV="Link" Content="<http://xss.rocks/xss.css>; REL=stylesheet">'), '')
    assert_equal(HtmlSanitizer.strict('<IMG STYLE="java/*XSS*/script:(alert(\'XSS\'), \'\')">'), '<img>')
    assert_equal(HtmlSanitizer.strict('<IMG src="java/*XSS*/script:(alert(\'XSS\'), \'\')">'), '')
    assert_equal(HtmlSanitizer.strict('<IFRAME SRC="javascript:alert(\'XSS\');"></IFRAME>'), '')
    assert_equal(HtmlSanitizer.strict('<TABLE><TD BACKGROUND="javascript:alert(\'XSS\')">'), '<table><td></td></table>')
    assert_equal(HtmlSanitizer.strict('<DIV STYLE="background-image: url(javascript:alert(\'XSS\'), \'\')">'), '<div></div>')
    assert_equal(HtmlSanitizer.strict('<a href="/some/path">test</a>'), '<a href="/some/path">test</a>')
    assert_equal(HtmlSanitizer.strict('<a href="https://some/path">test</a>'), '<a href="https://some/path" rel="nofollow noreferrer noopener" target="_blank" title="https://some/path">test</a>')
    assert_equal(HtmlSanitizer.strict('<a href="https://some/path">test</a>', true), '<a href="https://some/path" rel="nofollow noreferrer noopener" target="_blank" title="https://some/path">test</a>')
    assert_equal(HtmlSanitizer.strict('<XML ID="xss"><I><B><IMG SRC="javas<!-- -->cript:alert(\'XSS\')"></B></I></XML>'), '<i><b></b></i>')
    assert_equal(HtmlSanitizer.strict('<IMG SRC="javas<!-- -->cript:alert(\'XSS\')">'), '')
    assert_equal(HtmlSanitizer.strict(' <HEAD><META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=UTF-7"> </HEAD>+ADw-SCRIPT+AD4-alert(\'XSS\');+ADw-/SCRIPT+AD4-'), '  +ADw-SCRIPT+AD4-alert(\'XSS\');+ADw-/SCRIPT+AD4-')
    assert_equal(HtmlSanitizer.strict('<SCRIPT a=">" SRC="httx://xss.rocks/xss.js"></SCRIPT>'), '')
    assert_equal(HtmlSanitizer.strict('<A HREF="h
tt  p://6 6.000146.0x7.147/">XSS</A>'), '<a href="h%0Att%20%20p://6%206.000146.0x7.147/" rel="nofollow noreferrer noopener" target="_blank" title="h%0Att%20%20p://6%206.000146.0x7.147/">XSS</a>')
    assert_equal(HtmlSanitizer.strict('<A HREF="h
tt  p://6 6.000146.0x7.147/">XSS</A>', true), '<a href="http://h%0Att%20%20p://6%206.000146.0x7.147/" rel="nofollow noreferrer noopener" target="_blank" title="http://h%0Att%20%20p://6%206.000146.0x7.147/">XSS</a>')
    assert_equal(HtmlSanitizer.strict('<A HREF="//www.google.com/">XSS</A>'), '<a href="//www.google.com/" rel="nofollow noreferrer noopener" target="_blank" title="//www.google.com/">XSS</a>')
    assert_equal(HtmlSanitizer.strict('<A HREF="//www.google.com/">XSS</A>', true), '<a href="//www.google.com/" rel="nofollow noreferrer noopener" target="_blank" title="//www.google.com/">XSS</a>')
    assert_equal(HtmlSanitizer.strict('<form id="test"></form><button form="test" formaction="javascript:alert(1)">X</button>'), 'X')
    assert_equal(HtmlSanitizer.strict('<maction actiontype="statusline#http://google.com" xlink:href="javascript:alert(2)">CLICKME</maction>'), 'CLICKME')
    assert_equal(HtmlSanitizer.strict('<a xlink:href="javascript:alert(2)">CLICKME</a>'), 'CLICKME')
    assert_equal(HtmlSanitizer.strict('<a xlink:href="javascript:alert(2)">CLICKME</a>', true), 'CLICKME')
    assert_equal(HtmlSanitizer.strict('<!--<img src="--><img src=x onerror=alert(1)//">'), '<img src="x">')
    assert_equal(HtmlSanitizer.strict('<![><img src="]><img src=x onerror=alert(1)//">'), '&lt;![&gt;<img src="%5D&gt;&lt;img%20src=x%20onerror=alert(1)//">')
    assert_equal(HtmlSanitizer.strict('<svg><![CDATA[><image xlink:href="]]><img src=xx:x onerror=alert(2)//"></svg>'), '&lt;![CDATA[&gt;')
    assert_equal(HtmlSanitizer.strict('<abc><img src="</abc><img src=x onerror=alert(1)//">'), '<img src="&lt;/abc&gt;&lt;img%20src=x%20onerror=alert(1)//">')
    assert_equal(HtmlSanitizer.strict('<object data="data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg=="></object>'), '')
    assert_equal(HtmlSanitizer.strict('<embed src="data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg=="></embed>'), '')
    assert_equal(HtmlSanitizer.strict('<img[a][b]src=x[d]onerror[c]=[e]"alert(1)">'), '<img>')
    assert_equal(HtmlSanitizer.strict('<a href="[a]java[b]script[c]:alert(1)">XXX</a>'), '<a href="%5Ba%5Djava%5Bb%5Dscript%5Bc%5D:alert(1)">XXX</a>')
    assert_equal(HtmlSanitizer.strict('<a href="[a]java[b]script[c]:alert(1)">XXX</a>', true), '<a href="http://%5Ba%5Djava%5Bb%5Dscript%5Bc%5D:alert(1)" rel="nofollow noreferrer noopener" target="_blank" title="http://%5Ba%5Djava%5Bb%5Dscript%5Bc%5D:alert(1)">XXX</a>')
    assert_equal(HtmlSanitizer.strict('<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>'), '')
    assert_equal(HtmlSanitizer.strict('<a style="position:fixed;top:0;left:0;width: 260px;height:100vh;background-color:red;display: block;" href="http://example.com"></a>'), '<a href="http://example.com" rel="nofollow noreferrer noopener" target="_blank" title="http://example.com"></a>')
    assert_equal(HtmlSanitizer.strict('<a style="position:fixed;top:0;left:0;width: 260px;height:100vh;background-color:red;display: block;" href="http://example.com"></a>', true), '<a href="http://example.com" rel="nofollow noreferrer noopener" target="_blank" title="http://example.com"></a>')
    assert_equal(HtmlSanitizer.strict('<div>
<style type="text/css">#outlook A {
.content { WIDTH: 100%; MAX-WIDTH: 740px }
A { COLOR: #666666; TEXT-DECORATION: none }
A:link { COLOR: #666666; TEXT-DECORATION: none }
A:hover { COLOR: #666666; TEXT-DECORATION: none }
A:active { COLOR: #666666; TEXT-DECORATION: none }
A:focus { COLOR: #666666; TEXT-DECORATION: none }
BODY { FONT-FAMILY: Calibri, Arial, Verdana, sans-serif }
</style>
<!--[if (gte mso 9)|(IE)]>
<META name=GENERATOR content="MSHTML 9.00.8112.16800"></HEAD>
<BODY bgColor=#ffffff>
<DIV><FONT size=2 face=Arial></FONT>&nbsp;</DIV>
<BLOCKQUOTE
style="BORDER-LEFT: #000000 2px solid; PADDING-LEFT: 5px; PADDING-RIGHT: 0px; MARGIN-LEFT: 5px; MARGIN-RIGHT: 0px">
  <DIV style="FONT: 10pt arial">----- Original Message ----- </DIV>
  <DIV style="FONT: 10pt arial"><B>To:</B> <A title=smith.test@example.dk
  href="mailto:smith.test@example.dk">smith.test@example.dk</A> </DIV>
  <DIV style="FONT: 10pt arial"><B>Sent:</B> Friday, November 10, 2017 9:11
  PM</DIV>
  <DIV style="FONT: 10pt arial"><B>Subject:</B> Din bestilling hos
  example.dk - M123 - KD1234</DIV>
  <div>&nbsp;</div>
<![endif]-->test 123
<blockquote></div>'), '<div>

test 123
<blockquote></blockquote>
</div>')
    assert_equal(HtmlSanitizer.strict('<style><!--
/* Font Definitions */
@font-face
  {font-family:"Cambria Math";
  panose-1:2 4 5 3 5 4 6 3 2 4;}
  {page:WordSection1;}</style><!--[if gte mso 9]><xml>
<o:shapedefaults v:ext="edit" spidmax="1026" />
</xml><![endif]--><!--[if gte mso 9]><xml>
<o:shapelayout v:ext="edit">
<o:idmap v:ext="edit" data="1" />
</o:shapelayout></xml><![endif]-->
<div>123</div>
<a href="#DAB4FAD8-2DD7-40BB-A1B8-4E2AA1F9FDF2" width="1" height="1">abc</a></div>'), '
<div>123</div>
<a href="#DAB4FAD8-2DD7-40BB-A1B8-4E2AA1F9FDF2">abc</a>')
    assert_equal(HtmlSanitizer.strict('<table><tr style="font-size: 0"><td>123</td></tr></table>'), '<table><tr><td>123</td></tr></table>')
    assert_equal(HtmlSanitizer.strict('<table><tr style="font-size: 0px"><td>123</td></tr></table>'), '<table><tr><td>123</td></tr></table>')
    assert_equal(HtmlSanitizer.strict('<table><tr style="font-size: 0pt"><td>123</td></tr></table>'), '<table><tr><td>123</td></tr></table>')
    assert_equal(HtmlSanitizer.strict('<table><tr style="font-size:0"><td>123</td></tr></table>'), '<table><tr><td>123</td></tr></table>')
    assert_equal(HtmlSanitizer.strict('<table><tr style="font-Size:0px"><td>123</td></tr></table>'), '<table><tr><td>123</td></tr></table>')
    assert_equal(HtmlSanitizer.strict('<table><tr style="font-size:0em"><td>123</td></tr></table>'), '<table><tr><td>123</td></tr></table>')
    assert_equal(HtmlSanitizer.strict('<table><tr style=" Font-size:0%"><td>123</td></tr></table>'), '<table><tr><td>123</td></tr></table>')
    assert_equal(HtmlSanitizer.strict('<table><tr style="font-size:0%;display: none;"><td>123</td></tr></table>'), '<table><tr><td>123</td></tr></table>')
    assert_equal(HtmlSanitizer.strict('<table><tr style="font-size:0%;visibility:hidden;"><td>123</td></tr></table>'), '<table><tr><td>123</td></tr></table>')
    assert_equal(HtmlSanitizer.strict('<table><tr style="font-size:0%;visibility:hidden;"><td>123</td></tr></table>'), '<table><tr><td>123</td></tr></table>')
    assert_equal(HtmlSanitizer.strict('<a href="/some/path%20test.pdf">test</a>'), '<a href="/some/path%20test.pdf">test</a>')
    assert_equal(HtmlSanitizer.strict('<a href="https://somehost.domain/path%20test.pdf">test</a>'), '<a href="https://somehost.domain/path%20test.pdf" rel="nofollow noreferrer noopener" target="_blank" title="https://somehost.domain/path%20test.pdf">test</a>')
    assert_equal(HtmlSanitizer.strict('<a href="https://somehost.domain/zaihan%20test">test</a>'), '<a href="https://somehost.domain/zaihan%20test" rel="nofollow noreferrer noopener" target="_blank" title="https://somehost.domain/zaihan%20test">test</a>')

    api_path            = Rails.configuration.api_path
    http_type           = Setting.get('http_type')
    fqdn                = Setting.get('fqdn')
    attachment_url      = "#{http_type}://#{fqdn}#{api_path}/ticket_attachment/239/986/1653"
    attachment_url_good = "#{attachment_url}?disposition=attachment"
    attachment_url_evil = "#{attachment_url}?disposition=inline"
    assert_equal(HtmlSanitizer.strict("<a href=\"#{attachment_url_evil}\">Evil link</a>"), "<a href=\"#{attachment_url_good}\" rel=\"nofollow noreferrer noopener\" target=\"_blank\" title=\"#{attachment_url_good}\">Evil link</a>")

    assert_equal(HtmlSanitizer.strict("<a href=\"#{attachment_url_good}\">Good link</a>"), "<a href=\"#{attachment_url_good}\" rel=\"nofollow noreferrer noopener\" target=\"_blank\" title=\"#{attachment_url_good}\">Good link</a>")
    assert_equal(HtmlSanitizer.strict("<a href=\"#{attachment_url}\">No disposition</a>"), "<a href=\"#{attachment_url}\" rel=\"nofollow noreferrer noopener\" target=\"_blank\" title=\"#{attachment_url}\">No disposition</a>")

    different_fqdn_url = attachment_url_evil.gsub(fqdn, 'some.other.tld')
    assert_equal(HtmlSanitizer.strict("<a href=\"#{different_fqdn_url}\">Different FQDN</a>"), "<a href=\"#{different_fqdn_url}\" rel=\"nofollow noreferrer noopener\" target=\"_blank\" title=\"#{different_fqdn_url}\">Different FQDN</a>")

    attachment_url_evil_other = "#{attachment_url}?disposition=some_other"
    assert_equal(HtmlSanitizer.strict("<a href=\"#{attachment_url_evil_other}\">Evil link</a>"), "<a href=\"#{attachment_url_good}\" rel=\"nofollow noreferrer noopener\" target=\"_blank\" title=\"#{attachment_url_good}\">Evil link</a>")

    assert_equal(HtmlSanitizer.strict('<a href="mailto:testäöü@example.com" id="123">test</a>'), '<a href="mailto:test%C3%A4%C3%B6%C3%BC@example.com">test</a>')

    assert_equal(HtmlSanitizer.strict('<pre><code>apt-get update
Get:1 http://security.ubuntu.com/ubuntu focal-security InRelease [114 kB]
Hit:2 http://de.archive.ubuntu.com/ubuntu focal InRelease
Hit:3 http://de.archive.ubuntu.com/ubuntu focal-updates InRelease
Get:4 http://10.10.21.205:3207/dprepo/ubuntu experimental/20.04_x86_64/ InR=
elease [3820 B]
Hit:5 http://de.archive.ubuntu.com/ubuntu focal-backports InRelease
Get:6 http://10.10.21.205:3207/dprepo/ubuntu 20.04_x86_64/ InRelease [3781 =
B]
Get:7 http://10.10.21.205:3207/dprepo/ubuntu experimental/20.04_x86_64/ Sou=
rces [2710 B]
Get:8 http://10.10.21.205:3207/dprepo/ubuntu experimental/20.04_x86_64/ Pac=
kages [6507 B]
Get:9 http://10.10.21.205:3207/dprepo/ubuntu 20.04_x86_64/ Sources [9066 B]
Get:10 http://10.10.21.205:3207/dprepo/ubuntu 20.04_x86_64/ Packages [23.8 =
kB]
Get:11 http://security.ubuntu.com/ubuntu focal-security/main amd64 DEP-11 M=
etadata [40.6 kB]
Get:12 http://security.ubuntu.com/ubuntu focal-security/universe amd64 DEP-=
11 Metadata [66.3 kB]
Get:13 http://security.ubuntu.com/ubuntu focal-security/multiverse amd64 DE=
P-11 Metadata [2464 B]
Fetched 273 kB in 1s (288 kB/s)
Reading package lists...
Batterie-Status pr&uuml;fen
Reading package lists...
Building dependency tree...</code></pre>'), '<pre><code>apt-get update
Get:1 http://security.ubuntu.com/ubuntu focal-security InRelease [114 kB]
Hit:2 http://de.archive.ubuntu.com/ubuntu focal InRelease
Hit:3 http://de.archive.ubuntu.com/ubuntu focal-updates InRelease
Get:4 http://10.10.21.205:3207/dprepo/ubuntu experimental/20.04_x86_64/ InR=
elease [3820 B]
Hit:5 http://de.archive.ubuntu.com/ubuntu focal-backports InRelease
Get:6 http://10.10.21.205:3207/dprepo/ubuntu 20.04_x86_64/ InRelease [3781 =
B]
Get:7 http://10.10.21.205:3207/dprepo/ubuntu experimental/20.04_x86_64/ Sou=
rces [2710 B]
Get:8 http://10.10.21.205:3207/dprepo/ubuntu experimental/20.04_x86_64/ Pac=
kages [6507 B]
Get:9 http://10.10.21.205:3207/dprepo/ubuntu 20.04_x86_64/ Sources [9066 B]
Get:10 http://10.10.21.205:3207/dprepo/ubuntu 20.04_x86_64/ Packages [23.8 =
kB]
Get:11 http://security.ubuntu.com/ubuntu focal-security/main amd64 DEP-11 M=
etadata [40.6 kB]
Get:12 http://security.ubuntu.com/ubuntu focal-security/universe amd64 DEP-=
11 Metadata [66.3 kB]
Get:13 http://security.ubuntu.com/ubuntu focal-security/multiverse amd64 DE=
P-11 Metadata [2464 B]
Fetched 273 kB in 1s (288 kB/s)
Reading package lists...
Batterie-Status prüfen
Reading package lists...
Building dependency tree...</code></pre>')
  end
end
