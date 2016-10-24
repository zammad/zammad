# encoding: utf-8
# rubocop:disable all
require 'test_helper'

class AaaStringTest < ActiveSupport::TestCase

  test 'to_filename ref' do
    modul  = 'test'
    result = 'test'
    modul.to_filename
    assert_equal(result,  modul)

    modul  = 'Some::File'
    result = 'Some::File'
    modul.to_filename
    assert_equal(result,  modul)
  end

  test 'to_filename function' do
    modul  = 'test'
    result = 'test'
    assert_equal(result,  modul.to_filename)

    modul  = 'Some::File'
    result = 'some/file'
    assert_equal(result,  modul.to_filename)
  end

  test 'to_classname ref' do
    modul  = 'test'
    result = 'test'
    modul.to_filename
    assert_equal(result,  modul)

    modul  = 'some/file'
    result = 'some/file'
    modul.to_filename
    assert_equal(result,  modul)
  end

  test 'to_classname function' do
    modul  = 'test'
    result = 'Test'
    assert_equal(result,  modul.to_classname)

    modul  = 'some/file'
    result = 'Some::File'
    assert_equal(result,  modul.to_classname)

    modul  = 'some/files'
    result = 'Some::Files'
    assert_equal(result,  modul.to_classname)

    modul  = 'some_test/files'
    result = 'SomeTest::Files'
    assert_equal(result,  modul.to_classname)
  end

  test 'html2text ref' do
    html   = 'test'
    result = 'test'
    html.html2text
    assert_equal(result,  html)

    html   = '<div>test</div>'
    result = '<div>test</div>'
    html.html2text
    assert_equal(result,  html)
  end

  test 'html2text function' do

    html   = 'test'
    result = 'test'
    assert_equal(result, html.html2text)

    html   = '  test '
    result = 'test'
    assert_equal(result, html.html2text)

    html   = "\n\n  test \n\n\n"
    result = 'test'
    assert_equal(result, html.html2text)

    html   = '<div>test</div>'
    result = 'test'
    assert_equal(result, html.html2text)

    html   = '<div>test<br></div>'
    result = 'test'
    assert_equal(result, html.html2text)

    html   = "<div>test<br><br><br>\n<br>\n<br>\n</div>"
    result = 'test'
    assert_equal(result, html.html2text)

    html   = "<div>test<br><br> <br> \n<br> \n<br> \n</div>"
    result = 'test'
    assert_equal(result, html.html2text)

    html   = "<div>test<br><br>&nbsp;<br>&nbsp;\n<br>&nbsp;\n<br>&nbsp;\n</div>"
    result = 'test'
    assert_equal(result, html.html2text)

    html   = "<div>test<br><br>&nbsp;<br>&nbsp;\n<br>&nbsp;\n<br>&nbsp;\n</div>&nbsp;"
    result = 'test'
    assert_equal(result, html.html2text)

    html   = "<pre>test\n\ntest</pre>"
    result = "test\ntest"
    assert_equal(result, html.html2text)

    html   = "<code>test\n\ntest</code>"
    result = "test\ntest"
    assert_equal(result, html.html2text)

    html   = '<table><tr><td>test</td><td>col</td></td></tr><tr><td>test</td><td>4711</td></tr></table>'
    result = "test col\ntest 4711"
    assert_equal(result, html.html2text)

    html   = "<p><span>Was\nsoll verbessert werden:</span></p>"
    result = 'Was soll verbessert werden:'
    assert_equal(result, html.html2text)

    html = "<!-- some comment -->
    <div>
    test<br><br><br>\n<br>\n<br>\n
    </div>"
    result = 'test'
    assert_equal(result, html.html2text)

    html = "\n<div><a href=\"https://zammad.org\">Best Tool of the World</a>
     some other text</div>
    <div>"
    result = "[1] Best Tool of the Worldsome other text\n\n[1] https://zammad.org"
    assert_equal(result, html.html2text)

    html = "<!-- some comment -->
    <div>
    test<br><br><br>\n<hr/>\n<br>\n
    </div>"
    result = "test\n\n___"
    assert_equal(result, html.html2text)

    html = "test<br><br><br>--<br>abc</div>"
    result = "test\n\n--\nabc"
    assert_equal(result, html.html2text)

    html = "Ihr RZ-Team<br />
<br />
<!--[if gte mso 9]><xml> <o:DocumentProperties>  <o:Author>test</o:Author> =
 <o:Template>A75DB76E.dotm</o:Template>  <o:LastAuthor>test</o:LastAuthor> =
 <o:Revision>5</o:Revision>  <o:Created>2011-05-18T07:08:00Z</o:Created>  <=
o:LastSaved>2011-07-04T17:59:00Z</o:LastSaved>  <o:Pages>1</o:Pages>  <o:Wo=
rds>189</o:Words>  <o:Characters>1192</o:Characters>  <o:Lines>9</o:Lines> =
 <o:Paragraphs>2</o:Paragraphs>  <o:CharactersWithSpaces>1379</o:Characters=
WithSpaces>  <o:Version>11.5606</o:Version> </o:DocumentProperties></xml><!=
[endif]-->"
    result = 'Ihr RZ-Team'
    assert_equal(result, html.html2text)

html = '<html>
<head>
<title>Neues Fax von 1234-93900</title>
</head>
<body style="margin: 0px;padding: 0px;font-family: Arial, sans-serif;font-size: 12px;">
<table cellpadding="0" cellspacing="0" width="100%" height="100%" bgcolor="#d9e7f0" id="mailbg" style="empty-cells:show;font-size: 12px;line-height: 18px;color: #000000;font-family: Arial, sans-serif;width: 100%;height: 100%;background-color: #d9e7f0;padding: 0px;margin: 0px;">
<tr>
<td valign="top">
<center>
<br><br>
<table width="560" cellpadding="0" cellspacing="0" bgcolor="#FFFFFF" id="mailcontainer" style="empty-cells:show;font-size: 12px;line-height: 18px;color: #000000;font-family: Arial, sans-serif;width: 560px;margin: 0px auto;padding: 0px;background-color: #FFFFFF;">
<tr>
<td colspan="3" width="560" id="mail_header" valign="top" style="width: 560px;background-color: #FFFFFF;font-family: Arial, sans-serif;color: #000000;padding: 0px;margin: 0px;">
<table width="560" cellpadding="0" cellspacing="0" style="empty-cells:show;font-size: 12px;line-height: 18px;color: #000000;font-family: Arial, sans-serif;">
<tr>
<td height="10" colspan="4" style="font-size:0px;line-height: 0px;padding:0px;height:10px;"><img src="http://www.example.docm/static/example.docm/mailtemplates/de_DE/team/img/tpl_header.gif" style="padding: 0px;margin: 0px;"></td>
</tr>
<tr>
<td height="12" colspan="4"><span style="font-size:0px;line-height:0px;"> </span></td>
</tr>
<tr>
<td height="27" width="30"> </td>
<td height="27" width="397"><span class="mailtitle" style="font-family: Arial, sans-serif;color: #000000;font-size: 18px;line-height: 18px;font-weight: normal;">Neues Fax</span></td>
<td height="27" width="103"><img src="http://www.example.docm/static/example.docm/mailtemplates/de_DE/team/img/tpl_logo-example.gif" style="padding: 0px;margin: 0px;"></td>
<td height="27" width="30"></td>
</tr>
<tr>
<td height="20" colspan="4"><span style="font-size:0px;line-height:0px;"> </span></td>
</tr>
<tr>
<td height="1" colspan="4" style="font-size:0px;line-height: 0px;padding:0px;"><img src="http://www.example.docm/static/example.docm/mailtemplates/de_DE/team/img/tpl_line-grey.gif" style="padding: 0px;margin: 0px;"></td>
</tr>
</table>
</td>
</tr>
<tr>
<td colspan="3" width="560"> </td>
</tr>
<tr>
<td width="30"> </td>
<td width="500" height="30" valign="middle" align="right"><span class="accountno" style="font-family: Arial, sans-serif;font-size: 10px;color: #666666;">Ihre Kundennummer: 12345678</span></td>
<td width="30"> </td>
</tr>'
    result = 'Neues Fax von 1234-93900

 Neues Fax

 Ihre Kundennummer: 12345678'
    assert_equal(result, html.html2text)

    html = ' line&nbsp;1<br>
you<br/>
-----&amp;'
    should = 'line 1
you
-----&'
    assert_equal( should, html.html2text)

    html = ' <ul><li>#1</li><li>#2</li></ul>'
    should = '* #1
* #2'
    assert_equal( should, html.html2text)

    html = '<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
  <head>
  <body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;">
    <div>&gt; Welcome!</div><div>&gt;</div><div>&gt; Thank you for installing Zammad.</div><div>&gt;</div>
  </body>
</html>'
    should = '> Welcome!
>
> Thank you for installing Zammad.
>'
    assert_equal( should, html.html2text)

    html = '      <style type="text/css">
    body {
      width:90% !important;
      -webkit-text-size-adjust:90%;
      -ms-text-size-adjust:90%;
      font-family:\'helvetica neue\', helvetica, arial, geneva, sans-serif; f=
ont-size: 12px;;
    }
    img {
      outline:none; text-decoration:none; -ms-interpolation-mode: bicubic;
    }
    a img {
      border:none;
    }
    table td {
      border-collapse: collapse;
    }
    table {
      border-collapse: collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;
    }
    p, table, div, td {
      max-width: 600px;
    }
    p {
      margin: 0;
    }
    blockquote, pre {
      margin: 0px;
      padding: 8px 12px 8px 12px;
    }

    </style><p>some other content</p>'
    should = 'some other content'
    assert_equal( should, html.html2text)

    html = '        IT-Infrastruktur</span><br>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
      <meta name="Generator" content="Microsoft Word 14 (filtered
        medium)">
      <!--[if !mso]><style>v\:* {behavior:url(#default#VML);}
o\:* {behavior:url(#default#VML);}
w\:* {behavior:url(#default#VML);}
.shape {behavior:url(#default#VML);}
</style><![endif]-->
      <style><!--

@font-face
    {font-family:calibri;
    panose-1:2 15 5 2 2 2 4 3 2 4;}
@font-face
    {font-family:tahoma;
    panose-1:2 11 6 4 3 5 4 4 2 4;}

p.msonormal, li.msonormal, div.msonormal
    {margin:0cm;
    margin-bottom:.0001pt;
    font-size:11.0pt;
    font-family:"calibri","sans-serif";
    mso-fareast-language:en-us;}
a:link, span.msohyperlink
    {mso-style-priority:99;
    color:blue;
    text-decoration:underline;}
a:visited, span.msohyperlinkfollowed
    {mso-style-priority:99;
    color:purple;
    text-decoration:underline;}
p.msoacetate, li.msoacetate, div.msoacetate
    {mso-style-priority:99;
    mso-style-link:"sprechblasentext zchn";
    margin:0cm;
    margin-bottom:.0001pt;
    font-size:8.0pt;
    font-family:"tahoma","sans-serif";
    mso-fareast-language:en-us;}
span.e-mailformatvorlage17
    {mso-style-type:personal;
    font-family:"calibri","sans-serif";
    color:windowtext;}
span.sprechblasentextzchn
    {mso-style-name:"sprechblasentext zchn";
    mso-style-priority:99;
    mso-style-link:sprechblasentext;
    font-family:"tahoma","sans-serif";}
.msochpdefault
    {mso-style-type:export-only;
    font-family:"calibri","sans-serif";
    mso-fareast-language:en-us;}
@page wordsection1
    {size:612.0pt 792.0pt;
    margin:70.85pt 70.85pt 2.0cm 70.85pt;}
div.wordsection1
    {page:wordsection1;}
--></style><!--[if gte mso 9]><xml>
<o:shapedefaults v:ext="edit" spidmax="1026" />
</xml><![endif]--><!--[if gte mso 9]><xml>
<o:shapelayout v:ext="edit">
<o:idmap v:ext="edit" data="1" />
</o:shapelayout></xml><![endif]-->'
    should = 'IT-Infrastruktur'
    assert_equal( should, html.html2text)

    html = "<h1>some head</h1>
    some content
    <blockquote>
    <p>line 1</p>
    <p>line 2</p>
    </blockquote>
    <p>some text later</p>"
    result = 'some head
some content
> line 1
> line 2

some text later'
    assert_equal(result, html.html2text)

    html = "<h1>some head</h1>
    some content
    <blockquote>
    line 1<br/>
    line 2<br>
    </blockquote>
    <p>some text later</p>"
    result = 'some head
some content
> line 1
> line 2

some text later'
    assert_equal(result, html.html2text)

    html = "<h1>some head</h1>
    some content
    <blockquote>
    <div><div>line 1</div><br></div>
    <div><div>line 2</div><br></div>
    </blockquote>
    some text later"
    result = 'some head
some content
> line 1
>
> line 2
some text later'
    assert_equal(result, html.html2text)

    html   = "<p>Best regards,</p>
<p><i>Your Team Team</i></p>
<p>P.S.: You receive this e-mail because you are listed in our database as person who ordered a Team license. Please click <a href=\"http://www.teamviewer.example/en/company/unsubscribe.aspx?id=1009645&ident=xxx\">here</a> to unsubscribe from further e-mails.</p>
-----------------------------
<br />"
    result = 'Best regards,
Your Team Team
P.S.: You receive this e-mail because you are listed in our database as person who ordered a Team license. Please click [1] here to unsubscribe from further e-mails.
-----------------------------

[1] http://www.teamviewer.example/en/company/unsubscribe.aspx?id=1009645&ident=xxx'
    assert_equal(result, html.html2text)

    html   = "<div><br>Dave and leaned her
days adam.</div><span style=\"color:#F7F3FF; font-size:8px\">Maybe we
want any help me that.<br>Next morning charlie saw at their
father.<br>Well as though adam took out here. Melvin will be more money.
Called him into this one last thing.<br>Men-----------------------
<br />"
    result = 'Dave and leaned her days adam.
Maybe we want any help me that.
Next morning charlie saw at their father.
Well as though adam took out here. Melvin will be more money. Called him into this one last thing.
Men-----------------------'
    assert_equal(result, html.html2text)

  end

  test 'html2html_strict function' do

    html   = 'test'
    result = 'test'
    assert_equal(result, html.html2html_strict)

    html   = '  test '
    result = 'test'
    assert_equal(result, html.html2html_strict)

    html   = "\n\n  test \n\n\n"
    result = 'test'
    assert_equal(result, html.html2html_strict)

    html   = '<b>test</b>'
    result = '<b>test</b>'
    assert_equal(result, html.html2html_strict)

    html   = '<B>test</B>'
    result = '<B>test</B>'
    assert_equal(result, html.html2html_strict)

    html   = '<i>test</i>'
    result = '<i>test</i>'
    assert_equal(result, html.html2html_strict)

    html   = '<h1>test</h1>'
    result = '<h1>test</h1>'
    assert_equal(result, html.html2html_strict)

    html   = '<h2>test</h2>'
    result = '<h2>test</h2>'
    assert_equal(result, html.html2html_strict)

    html   = '<h3>test</h3>'
    result = '<h3>test</h3>'
    assert_equal(result, html.html2html_strict)

    html   = '<a href="http://example.com">http://example.com</a>'
    result = '<a href="http://example.com" target="_blank">http://example.com</a>'
    assert_equal(result, html.html2html_strict)

    html   = '<A href="http://example.com?a=1;">http://example.com?a=1;</A>'
    result = '<a href="http://example.com?a=1;" target="_blank">http://example.com?a=1;</a>'
    assert_equal(result, html.html2html_strict)

    html   = '<a href="http://web.de">web.de</a>'
    result = '<a href="http://web.de" target="_blank">web.de</a>'
    assert_equal(result, html.html2html_strict)

    html   = '<a id="123" href="http://web.de">web.de</a>'
    result = '<a href="http://web.de" target="_blank">web.de</a>'
    assert_equal(result, html.html2html_strict)

    html   = '<br>https://www.facebook.com/test<br>'
    result = '<a href="https://www.facebook.com/test" target="_blank">https://www.facebook.com/test</a>'
    assert_equal(result, html.html2html_strict)

    html   = 'some text http://example.com some other text'
    result = 'some text <a href="http://example.com" target="_blank">http://example.com</a> some other text'
    assert_equal(result, html.html2html_strict)

    html   = 'some text www.example.com some other text'
    result = 'some text <a href="http://www.example.com" target="_blank">http://www.example.com</a> some other text'
    assert_equal(result, html.html2html_strict)

    html   = '<a href="http://example.com">http://what-different.example.com</a>'
    result = 'http://example.com (<a href="http://what-different.example.com" target="_blank">http://what-different.example.com</a>)'
    result = 'http://example.com (<a href="http://what-different.example.com" target="_blank">http://what-different.example.com</a>)'
    assert_equal(result, html.html2html_strict)

    html   = '<a href="http://example.com">http://EXAMPLE.com</a>'
    result = '<a href="http://example.com" target="_blank">http://EXAMPLE.com</a>'
    assert_equal(result, html.html2html_strict)

    html   = '<a href="http://example.com" class="abc">http://example.com</a>'
    result = '<a href="http://example.com" target="_blank">http://example.com</a>'
    assert_equal(result, html.html2html_strict)

    html   = '<a href="http://example.com/" class="abc">http://example.com</a>'
    result = '<a href="http://example.com/" target="_blank">http://example.com</a>'
    assert_equal(result, html.html2html_strict)

    html   = "<a href=\"http://example.com/\n\" class=\"abc\">http://example.com</a>"
    result = '<a href="http://example.com/" target="_blank">http://example.com</a>'
    assert_equal(result, html.html2html_strict)

    html   = "<a href=\"http://example.com/\n \" class=\"abc\n\"\n>http://example.com</a>"
    result = '<a href="http://example.com/" target="_blank">http://example.com</a>'
    assert_equal(result, html.html2html_strict)

    html   = "<div>http://example.com</div>"
    result = '<a href="http://example.com" target="_blank">http://example.com</a>'
    assert_equal(result, html.html2html_strict)

    html   = "<div>http://example.com.</div>"
    result = '<a href="http://example.com" target="_blank">http://example.com</a>.'
    assert_equal(result, html.html2html_strict)

    html   = "<div>http://example.com, and so on</div>"
    result = '<a href="http://example.com" target="_blank">http://example.com</a>, and so on'
    assert_equal(result, html.html2html_strict)

    html   = "<div>http://example.com?lala=me, and so on</div>"
    result = '<a href="http://example.com?lala=me" target="_blank">http://example.com?lala=me</a>, and so on'
    assert_equal(result, html.html2html_strict)

    html   = "<a href=\"http://facebook.de/examplesrbog\"><span lang=\"EN-US\" style='color:blue'>http://facebook.de/examplesrbog</span></a>"
    result = "<a href=\"http://facebook.de/examplesrbog\" target=\"_blank\">http://facebook.de/examplesrbog</a>"
    assert_equal(result, html.html2html_strict)

    html   = "Damit Sie keinen Tag versäumen, empfehlen wir Ihnen den <a href=\"http://newsletters.cylex.de/\" class=\"\">Link des Adventkalenders</a> in<br class=\"\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Ihrer Lesezeichen-Symbolleiste zu ergänzen.</p><div class=\"\">&nbsp;"
    result = "Damit Sie keinen Tag versäumen, empfehlen wir Ihnen den Link des Adventkalenders (<a href=\"http://newsletters.cylex.de/\" target=\"_blank\">http://newsletters.cylex.de/</a>) in<br>      Ihrer Lesezeichen-Symbolleiste zu ergänzen."
    assert_equal(result, html.html2html_strict)

    html   = '<b >test</b>'
    result = '<b>test</b>'
    assert_equal(result, html.html2html_strict)

    html   = '<b >test</b >'
    result = '<b>test</b>'
    assert_equal(result, html.html2html_strict)

    html   = '<b >test< /b >'
    result = '<b>test</b>'
    assert_equal(result, html.html2html_strict)

    html   = "<b\n>test<\n/b>"
    result = '<b>test</b>'
    assert_equal(result, html.html2html_strict)

    html   = "<b id=123 classs=\"\nsome_class\">test</b>"
    result = '<b>test</b>'
    assert_equal(result, html.html2html_strict)

    html   = "<b id=123 classs=\"\nsome_class\"\n>test<\n/b>"
    result = '<b>test</b>'
    assert_equal(result, html.html2html_strict)

    html   = "<ul id=123 classs=\"\nsome_class\"\n><li>test</li>\n<li class=\"asasd\">test</li><\n/ul>"
    result = '<ul><li>test</li><li>test</li></ul>'
    assert_equal(result, html.html2html_strict)

    html   = '<html><head><base href="x-msg://2849/"></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><span class="Apple-style-span" style="border-collapse: separate; font-family: Helvetica; font-style: normal; font-variant: normal; font-weight: normal; letter-spacing: normal; line-height: normal; orphans: 2; text-align: -webkit-auto; text-indent: 0px; text-transform: none; white-space: normal; widows: 2; word-spacing: 0px; -webkit-border-horizontal-spacing: 0px; -webkit-border-vertical-spacing: 0px; -webkit-text-decorations-in-effect: none; -webkit-text-size-adjust: auto; -webkit-text-stroke-width: 0px; font-size: medium; "><div lang="DE" link="blue" vlink="purple"><div class="Section1" style="page: Section1; "><div style="margin-top: 0cm; margin-right: 0cm; margin-left: 0cm; margin-bottom: 0.0001pt; font-size: 11pt; font-family: Calibri, sans-serif; "><span style="font-size: 10pt; font-family: Arial, sans-serif; ">Hallo Martin,<o:p></o:p></span></div>'
    result = 'Hallo Martin,'
    assert_equal(result, html.html2html_strict)

    html   = '<a href="mailto:john.smith@example.com" style="color: blue; text-decoration: underline; ">john.smith@example.com</a>'
    result = 'john.smith@example.com'
    assert_equal(result, html.html2html_strict)

    html   = '<a href="MAILTO:john.smith@example.com" style="color: blue; text-decoration: underline; ">john.smith@example.com</a>'
    result = 'john.smith@example.com'
    assert_equal(result, html.html2html_strict)

    html   = '<a href="mailto:john.smith2@example.com" style="color: blue; text-decoration: underline; ">john.smith@example.com</a>'
    #result = 'john.smith@example.com (mailto:john.smith2@example.com)'
    result = 'john.smith@example.com'
    assert_equal(result, html.html2html_strict)

  end

  test 'signature_identify function' do
    marker_template = '######SIGNATURE_MARKER######'

    source = 'test'
    result = 'test'
    assert_equal(result, source.signature_identify(true))

    source = "test\n--\nend"
    result = "test\n#{marker_template}--\nend"
    assert_equal(result, source.signature_identify(true))

    source = "On 01/04/15 10:55, Bob Smith wrote:"
    result = "#{marker_template}On 01/04/15 10:55, Bob Smith wrote:"
    assert_equal(result, source.signature_identify(true))

    source = "Am 03.04.2015 um 20:58 schrieb Martin Edenhofer <me@znuny.ink>:"
    result = "#{marker_template}Am 03.04.2015 um 20:58 schrieb Martin Edenhofer <me@znuny.ink>:"
    assert_equal(result, source.signature_identify(true))

    source = "\ntest 123 \n1\n2\n3\n4\n5\n6\n7\n8\n9\n--\nBob Smith\n"
    result = "\ntest 123 \n1\n2\n3\n4\n5\n6\n7\n8\n9\n#{marker_template}--\nBob Smith\n"
    assert_equal(result, source.signature_identify(true))

    source = "test 123 \n--no not match--\n--\nBob Smith\n"
    result = "test 123 \n--no not match--\n#{marker_template}--\nBob Smith\n"
    assert_equal(result, source.signature_identify(true))

    source = "test 123 \n--no not match--\n -- \nBob Smith\n"
    result = "test 123 \n--no not match--\n#{marker_template} -- \nBob Smith\n"
    assert_equal(result, source.signature_identify(true))

    source = "test 123 \n\n--\nBob Smith\n\n\n\n\n--\nBob Smith\n"
    result = "test 123 \n#{marker_template}\n--\nBob Smith\n\n\n\n\n--\nBob Smith\n"
    assert_equal(result, source.signature_identify(true))

    source = "test 123\ntest 123\n--\nBob Smith\n"
    result = "test 123\ntest 123\n#{marker_template}--\nBob Smith\n"
    assert_equal(result, source.signature_identify(true))

    source = "test 123\ntest 123\n--\nBob Smith\n\n"
    result = "test 123\ntest 123\n#{marker_template}--\nBob Smith\n\n"
    assert_equal(result, source.signature_identify(true))

    # apple
    # en
    source = "test 123 \n--no not match--\nBob Smith\nOn 01/04/15 10:55, Bob Smith wrote:\nlalala\n--\nsome test"
    result = "test 123 \n--no not match--\nBob Smith\n#{marker_template}On 01/04/15 10:55, Bob Smith wrote:\nlalala\n#{marker_template}--\nsome test"
    assert_equal(result, source.signature_identify(true))

    # de
    source = "test 123 \n\n--no not match--\n\nBob Smith\nAm 03.04.2015 um 20:58 schrieb Bob Smith <bob@example.com>:\nlalala"
    result = "test 123 \n\n--no not match--\n\nBob Smith\n#{marker_template}Am 03.04.2015 um 20:58 schrieb Bob Smith <bob@example.com>:\nlalala"
    assert_equal(result, source.signature_identify(true))

    # ms
    # en
    source = "test 123 \n\n--no not match--\n\nBob Smith\nFrom: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]\nSent: Donnerstag, 2. April 2015 10:00\nlalala</div>"
    result = "test 123 \n\n--no not match--\n\nBob Smith\n#{marker_template}From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]\nSent: Donnerstag, 2. April 2015 10:00\nlalala</div>"
    assert_equal(result, source.signature_identify(true))

    # de
    source = "test 123 \n\n--no not match--\n\nBob Smith\nVon: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]\nGesendet: Donnerstag, 2. April 2015 10:00\nBetreff: lalala\n"
    result = "test 123 \n\n--no not match--\n\nBob Smith\n#{marker_template}Von: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]\nGesendet: Donnerstag, 2. April 2015 10:00\nBetreff: lalala\n"
    assert_equal(result, source.signature_identify(true))

    # fr
    source = "\ntest 123 \n\n--no not match--\n\nBob Smith\nDe : Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]\nEnvoyé : mercredi 29 avril 2015 17:31\nObjet : lalala\n"
    result = "\ntest 123 \n\n--no not match--\n\nBob Smith\n#{marker_template}De : Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]\nEnvoyé : mercredi 29 avril 2015 17:31\nObjet : lalala\n"
    assert_equal(result, source.signature_identify(true))


    marker_template = '<span class="js-signatureMarker"></span>'
    html   = "<br>lalala<br>--<br>Max Mix"
    result = "lalala<br>#{marker_template}--<br>Max Mix"
    assert_equal(result, html.html2html_strict(true))

    html   = "den.<br><br><b>Von:</b> Fritz Bauer [mailto:me@example.com]<br><b>Gesendet:</b> Donnerstag, 3. Mai 2012 11:51<br><b>An:</b> John Smith<br><b>Cc:</b> Smith, John Marian; johnel.fratczak@example.com; ole.brei@example.com; Günther John | Example GmbH; bkopon@example.com; john.heisterhagen@team.example.com; sven.rocked@example.com; michael.house@example.com; tgutzeit@example.com<br><b>Betreff:</b> Re: OTRS::XXX Erweiterung - Anhänge an CI's<br><br>Hallo,<br><br>ich versuche an den Punkten"
    result = "den.<br>#{marker_template}<br><b>Von:</b> Fritz Bauer [mailto:me@example.com]<br><b>Gesendet:</b> Donnerstag, 3. Mai 2012 11:51<br><b>An:</b> John Smith<br><b>Cc:</b> Smith, John Marian; johnel.fratczak@example.com; ole.brei@example.com; Günther John | Example GmbH; bkopon@example.com; john.heisterhagen@team.example.com; sven.rocked@example.com; michael.house@example.com; tgutzeit@example.com<br><b>Betreff:</b> Re: OTRS::XXX Erweiterung - Anhänge an CI&#39;s<br><br>Hallo,<br><br>ich versuche an den Punkten"
    assert_equal(result, html.html2html_strict(true))

  end

end
