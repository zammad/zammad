# -*- coding: utf-8 -*-
require 'helper'

class TC_Formula < Test::Unit::TestCase

  def setup
    @formula = Writeexcel::Formula.new(0)
  end

  def test_scan
    # scan must return array of token info
    string01 = '1 + 2 * LEN("String")'
    expected01 = [
      [:NUMBER, '1'],
      ['+',     '+'],
      [:NUMBER, '2'],
      ['*',     '*'],
      [:FUNC,   'LEN'],
      ['(',     '('],
      [:STRING, '"String"'],
      [')',     ')'],
      [:EOL,    nil]
    ]
    assert_kind_of(Array, @formula.scan(string01))
    assert_equal(expected01, @formula.scan(string01))

    string02 = 'IF(A1>=0,SIN(0),COS(90))'
    expected02 = [
      [:FUNC,   'IF'],
      ['(',     '('],
      [:REF2D,  'A1'],
      [:GE,     '>='],
      [:NUMBER, '0'],
      [',',     ','],
      [:FUNC,   'SIN'],
      ['(',     '('],
      [:NUMBER, '0'],
      [')',     ')'],
      [',',     ','],
      [:FUNC,   'COS'],
      ['(',     '('],
      [:NUMBER, '90'],
      [')',     ')'],
      [')',     ')'],
      [:EOL,    nil]
    ]
    assert_kind_of(Array, @formula.scan(string02))
    assert_equal(expected02, @formula.scan(string02))
  end

  def test_reverse
    testcase = [
      [ [0,1,2,3,4], [0,[1,[2,3,[4]]]]      ],
      [ [0,1,2,3,4,5], [[0,1,[2,3]],[4,5]]  ]
    ]
    testcase.each do |t|
      assert_equal(t[0], @formula.reverse(t[1]))
    end
  end

end
