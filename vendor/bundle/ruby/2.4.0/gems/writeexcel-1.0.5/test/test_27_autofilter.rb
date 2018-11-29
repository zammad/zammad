# -*- coding: utf-8 -*-
##########################################################################
# test_27_autofilter.rb
#
# Tests for the token extraction method used to parse autofilter expressions.
#
# reverse('©'), September 2005, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
#########################################################################
require 'helper'
require 'stringio'

class TC_27_autofilter < Test::Unit::TestCase

  def test_27_autofilter
    @tests.each do |test|
      expression = test[0]
      expected   = test[1]
      result     = @worksheet.__send__("extract_filter_tokens", expression)

      testname   = expression || 'none'

      assert_equal(expected, result, testname)
    end
  end

  def setup
    @workbook   = WriteExcel.new(StringIO.new)
    @worksheet  = @workbook.add_worksheet
    @tests = [
    [
        nil,
        [],
    ],

    [
        '',
        [],
    ],

    [
        '0 <  2000',
        [0, '<', 2000],
    ],

    [
        'x <  2000',
        ['x', '<', 2000],
    ],

    [
        'x >  2000',
        ['x', '>', 2000],
    ],

    [
        'x == 2000',
        ['x', '==', 2000],
    ],

    [
        'x >  2000 and x <  5000',
        ['x', '>',  2000, 'and', 'x', '<', 5000],
    ],

    [
        'x = "foo"',
        ['x', '=', 'foo'],
    ],

    [
        'x = foo',
        ['x', '=', 'foo'],
    ],

    [
        'x = "foo bar"',
        ['x', '=', 'foo bar'],
    ],

    [
        'x = "foo "" bar"',
        ['x', '=', 'foo " bar'],
    ],

    [
        'x = "foo bar" or x = "bar foo"',
        ['x', '=', 'foo bar', 'or', 'x', '=', 'bar foo'],
    ],

    [
        'x = "foo "" bar" or x = "bar "" foo"',
        ['x', '=', 'foo " bar', 'or', 'x', '=', 'bar " foo'],
    ],

    [
        'x = """"""""',
        ['x', '=', '"""'],
    ],

    [
        'x = Blanks',
        ['x', '=', 'Blanks'],
    ],

    [
        'x = NonBlanks',
        ['x', '=', 'NonBlanks'],
    ],

    [
        'top 10 %',
        ['top', 10, '%'],
    ],

    [
        'top 10 items',
        ['top', 10, 'items'],
    ],

      ]
  end
end
