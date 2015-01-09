# encoding: utf-8
require 'test_helper'

class AaaStringTest < ActiveSupport::TestCase

  test 'to_filename ref' do
    modul  = 'test'
    result = 'test'
    modul.to_filename
    assert_equal( result,  modul )

    modul  = 'Some::File'
    result = 'Some::File'
    modul.to_filename
    assert_equal( result,  modul )
  end

  test 'to_filename function' do
    modul  = 'test'
    result = 'test'
    assert_equal( result,  modul.to_filename )

    modul  = 'Some::File'
    result = 'some/file'
    assert_equal( result,  modul.to_filename )
  end

  test 'html2text ref' do
    html   = 'test'
    result = 'test'
    html.html2text
    assert_equal( result,  html )

    html   = '<div>test</div>'
    result = '<div>test</div>'
    html.html2text
    assert_equal( result,  html )
  end

  test 'html2text function' do

    html   = 'test'
    result = 'test'
    assert_equal( result, html.html2text )

    html   = '  test '
    result = 'test'
    assert_equal( result, html.html2text )

    html   = "\n\n  test \n\n\n"
    result = 'test'
    assert_equal( result, html.html2text )

    html   = '<div>test</div>'
    result = 'test'
    assert_equal( result, html.html2text )

    html   = '<div>test<br></div>'
    result = 'test'
    assert_equal( result, html.html2text )

    html   = "<div>test<br><br><br>\n<br>\n<br>\n</div>"
    result = 'test'
    assert_equal( result, html.html2text )

    html   = "<pre>test\n\ntest</pre>"
    result = "test\ntest"
    assert_equal( result, html.html2text )

    html   = "<code>test\n\ntest</code>"
    result = "test\ntest"
    assert_equal( result, html.html2text )

    html   = "<table><tr><td>test</td><td>col</td></td></tr><tr><td>test</td><td>4711</td></tr></table>"
    result = "test col  \ntest 4711"
    assert_equal( result, html.html2text )


    html   = "<!-- some comment -->
    <div>
    test<br><br><br>\n<br>\n<br>\n
    </div>"
    result = 'test'
    assert_equal( result, html.html2text )

    html   = "\n<div><a href=\"http://zammad.org\">Best Tool of the World</a>
     some other text</div>
    <div>"
    result = "[1] Best Tool of the Worldsome other text\n\n\n[1] http://zammad.org"
    assert_equal( result, html.html2text )

    html   = "<!-- some comment -->
    <div>
    test<br><br><br>\n<hr/>\n<br>\n
    </div>"
    result = "test\n\n___"
    assert_equal( result, html.html2text )

    html = ' line&nbsp;1<br>
you<br/>
-----&amp;'
    should = 'line 1
you
-----&'
    assert_equal( should, html.html2text )


    html = ' <ul><li>#1</li><li>#2</li></ul>'
    should = '* #1
* #2'
    assert_equal( should, html.html2text )

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
    assert_equal( should, html.html2text )

  end
end