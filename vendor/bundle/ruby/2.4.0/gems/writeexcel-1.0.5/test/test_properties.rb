# -*- coding: utf-8 -*-

require 'helper'
require 'stringio'

class TestProperties < Test::Unit::TestCase
  def setup
    @workbook = WriteExcel.new(StringIO.new)
  end

  def test_pack_VT_FILETIME
    filetime =
    assert_equal(
                 '40 00 00 00 00 FD 2D ED CE 48 CE 01',
                 unpack_record(pack_VT_FILETIME(Time.gm(2013, 5, 4, 13, 54, 42)))
                 )
  end

  def test_create_summary_property_set
    assert_equal(
                 'FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2 F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00 08 01 00 00 07 00 00 00 01 00 00 00 40 00 00 00 02 00 00 00 48 00 00 00 03 00 00 00 70 00 00 00 04 00 00 00 94 00 00 00 05 00 00 00 AC 00 00 00 06 00 00 00 D0 00 00 00 0C 00 00 00 FC 00 00 00 02 00 00 00 E4 04 00 00 1E 00 00 00 1F 00 00 00 54 68 69 73 20 69 73 20 61 6E 20 65 78 61 6D 70 6C 65 20 73 70 72 65 61 64 73 68 65 65 74 00 00 1E 00 00 00 19 00 00 00 57 69 74 68 20 64 6F 63 75 6D 65 6E 74 20 70 72 6F 70 65 72 74 69 65 73 00 00 00 00 1E 00 00 00 0F 00 00 00 48 69 64 65 6F 20 4E 41 4B 41 4D 55 52 41 00 00 1E 00 00 00 1C 00 00 00 53 61 6D 70 6C 65 2C 20 45 78 61 6D 70 6C 65 2C 20 50 72 6F 70 65 72 74 69 65 73 00 1E 00 00 00 21 00 00 00 43 72 65 61 74 65 64 20 77 69 74 68 20 52 75 62 79 20 61 6E 64 20 57 72 69 74 65 45 78 63 65 6C 00 00 00 00 40 00 00 00 00 62 93 81 C5 48 CE 01',
                 unpack_record(create_summary_property_set(
                                       [
                                        [1, "VT_I2", 1252],
                                        [2, "VT_LPSTR", "This is an example spreadsheet"],
                                        [3, "VT_LPSTR", "With document properties"],
                                        [4, "VT_LPSTR", "Hideo NAKAMURA"],
                                        [5, "VT_LPSTR", "Sample, Example, Properties"],
                                        [6, "VT_LPSTR", "Created with Ruby and WriteExcel"],
                                        [12, "VT_FILETIME", Time.gm(2013, 5, 4, 12, 47, 16)]
                                       ]
                                             ))
                 )
  end
end
