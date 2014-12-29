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


    html   = 'invalid <!DOCTYPE html><html><b>test</b></html>'
    result = Channel::EmailBuild.html_complete_check( html )

    assert( result !~ /^<\!DOCTYPE/, 'test 2')
    assert( result =~ /^.+?<\!DOCTYPE/, 'test 2')
    assert( result =~ /<html>/, 'test 2')
    assert( result !~ /font-family/, 'test 2')

  end
end