# -*- coding: utf-8 -*-
require 'helper'

class TC_BIFFWriter < Test::Unit::TestCase

  def test_IEEE_double
    teststr = [1.2345].pack("d")
    hexdata = [0x8D, 0x97, 0x6E, 0x12, 0x83, 0xC0, 0xF3, 0x3F]
    number  = hexdata.pack("C8")

    assert(number == teststr || number == teststr.reverse, "Not Little/Big endian. Give up.")
  end
end
