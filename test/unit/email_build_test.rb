# encoding: utf-8
require 'test_helper'

class EmailBuildTest < ActiveSupport::TestCase
  test 'document complete check' do

    html   = '<b>test</b>'
    result = Channel::EmailBuild.html_complete_check( html )

    assert( result =~ /^<\!DOCTYPE/, 'test 1')
    assert( result !~ /^.+?<\!DOCTYPE/, 'test 1')
    assert( result =~ /<html>/, 'test 1')
    assert( result =~ /font-family/, 'test 1')
    assert( result =~ /<b>test<\/b>/, 'test 1')


    html   = 'invalid <!DOCTYPE html><html><b>test</b></html>'
    result = Channel::EmailBuild.html_complete_check( html )

    assert( result !~ /^<\!DOCTYPE/, 'test 2')
    assert( result =~ /^.+?<\!DOCTYPE/, 'test 2')
    assert( result =~ /<html>/, 'test 2')
    assert( result !~ /font-family/, 'test 2')
    assert( result =~ /<b>test<\/b>/, 'test 2')

  end

  test 'html email check' do
    html = '<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
  <head>
  <body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;">
    <div>&gt; Welcome!</div><div>&gt;</div><div>&gt; Thank you for installing Zammad.</div><div>&gt;</div>
  </body>
</html>'
    mail = Channel::EmailBuild.build(
      :from         => 'sender@example.com',
      :to           => 'recipient@example.com',
      :body         => html,
      :content_type => 'text/html',
    )

    should = '> Welcome!
>
> Thank you for installing Zammad.
>
'
    assert_equal( should, mail.text_part.body.to_s )
    assert_equal( html, mail.html_part.body.to_s )

  end


  test 'html2text' do
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
>
'
    assert_equal( should, html.html2text )


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


  end
end