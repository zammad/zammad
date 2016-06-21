# encoding: utf-8
require 'test_helper'
# rubocop:disable TrailingWhitespace
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

    html   = "<pre>test\n\ntest</pre>"
    result = "test\ntest"
    assert_equal(result, html.html2text)

    html   = "<code>test\n\ntest</code>"
    result = "test\ntest"
    assert_equal(result, html.html2text)

    html   = '<table><tr><td>test</td><td>col</td></td></tr><tr><td>test</td><td>4711</td></tr></table>'
    result = "test col \ntest 4711"
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

    html = "\n<div><a href=\"http://zammad.org\">Best Tool of the World</a>
     some other text</div>
    <div>"
    result = "[1] Best Tool of the Worldsome other text\n\n\n[1] http://zammad.org"
    assert_equal(result, html.html2text)

    html = "<!-- some comment -->
    <div>
    test<br><br><br>\n<hr/>\n<br>\n
    </div>"
    result = "test\n\n___"
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

    html   = "<b\n>test</b>"
    result = '<b>test</b>'
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
    result = 'john.smith@example.com (mailto:john.smith2@example.com)'
    assert_equal(result, html.html2html_strict)

  end

end
