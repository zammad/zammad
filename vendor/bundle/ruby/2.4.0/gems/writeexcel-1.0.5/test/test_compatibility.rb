# -*- coding: utf-8 -*-
require 'helper'
require 'nkf'

class TC_Compatibility < Test::Unit::TestCase
  def test_ord
    a = 'a'
    abc = 'abc'
    assert_equal(97, a.ord, "#{a}.ord faild\n")
    assert_equal(97, abc.ord, "#{abc}.ord faild\n")
  end
end
