# -*- coding: utf-8 -*-
require 'helper'
require 'stringio'

###############################################################################
#
# A test for Chart.
#
# Tests for the Excel chart.rb methods.
#
# reverse(''), December 2009, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
class TC_ChartGeneric < Test::Unit::TestCase
  def setup
    io = StringIO.new
    workbook = WriteExcel.new(io)
    @chart = Writeexcel::Chart.new(workbook, '', 'chart')
  end

  ###############################################################################
  #
  # Test the _store_fbi method.
  #
  def test_store_fbi
    caption = " \tChart: _store_fbi()"
    expected = %w(
        60 10 0A 00 B8 38 A1 22 C8 00 00 00 05 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_fbi", 5, 10, 0x38B8, 0x22A1, 0x0000))
    assert_equal(expected, got, caption)

    expected = %w(
        60 10 0A 00 B8 38 A1 22 C8 00 00 00 06 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_fbi", 6, 10, 0x38B8, 0x22A1, 0x0000))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_chart method.
  #
  def test_store_chart
    caption = " \tChart: _store_chart()"
    expected = %w(
        02 10 10 00 00 00 00 00 00 00 00 00 E0 51 DD 02
        38 B8 C2 01
      ).join(' ')
    values = [0x0000, 0x0000, 0x02DD51E0, 0x01C2B838]
    got = unpack_record(@chart.__send__("store_chart", *values))
    assert_equal(expected, got, caption)
 end

  ###############################################################################
  #
  # Test the _store_series method.
  #
  def test_store_series
    caption = " \tChart: _store_series()"
    expected = %w(
        03 10 0C 00 01 00 01 00 08 00 08 00 01 00 00 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_series", 8, 8))
    assert_equal(expected, got, caption)
 end

  ###############################################################################
  #
  # Test the _store_begin method.
  #
  def test_store_begin
    caption = " \tChart: _store_begin()"
    expected = %w(
        33 10 00 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_begin"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_end method.
  #
  def test_store_end
    caption = " \tChart: _store_end()"
    expected = %w(
        34 10 00 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_end"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_ai method.
  #
  def test_store_ai
    caption = " \tChart: _store_ai()"
    values = [0, 1, '']
    expected = %w(
        51 10 08 00 00 01 00 00 00 00 00 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_ai", *values))
    assert_equal(expected, got, caption)

    values = [1, 2, ['3B00000000070000000000'].pack('H*')]
    expected = %w(
        51 10 13 00 01 02 00 00 00 00 0B 00 3B 00 00 00
        00 07 00 00 00 00 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_ai", *values))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_dataformat method.
  #
  def test_store_dataformat
    caption = " \tChart: _store_dataformat()"
    expected = %w(
        06 10 08 00 FF FF 00 00 00 00 00 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_dataformat", 0, 0, 0xFFFF))
    assert_equal(expected, got, caption)

    expected = %w(
        06 10 08 00 00 00 00 00 FD FF 00 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_dataformat", 0, 0xFFFD, 0))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_3dbarshape method.
  #
  def test_store_3dbarshape
    caption = " \tChart: _store_3dbarshape()"
    expected = %w(
        5F 10 02 00 00 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_3dbarshape"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_sertocrt method.
  #
  def test_store_sertocrt
    caption = " \tChart: _store_sertocrt()"
    expected = %w(
        45 10 02 00 00 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_sertocrt"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_shtprops method.
  #
  def test_store_shtprops
    caption = " \tChart: _store_shtprops()"
    expected = %w(
        44 10 04 00 0E 00 00 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_shtprops"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_defaulttext method.
  #
  def test_store_defaulttext
    caption = " \tChart: _store_defaulttext()"
    expected = %w(
        24 10 02 00 02 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_defaulttext"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_charttext method.
  #
  def test_store_charttext
    caption = " \tChart: _store_charttext()"
    expected = %w(
        25 10 20 00 02 02 01 00 00 00 00 00 46 FF FF FF
        06 FF FF FF 00 00 00 00 00 00 00 00 B1 00 4D 00
        00 00 00 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_charttext"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_fontx method.
  #
  def test_store_fontx
    caption = " \tChart: _store_fontx()"
    expected = %w(
        26 10 02 00 05 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_fontx", 5))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_axesused method.
  #
  def test_store_axesused
    caption = " \tChart: _store_axesused()"
    expected = %w(
        46 10 02 00 01 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_axesused", 1))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_axisparent method.
  #
  def test_store_axisparent
    caption = " \tChart: _store_axisparent()"
    expected = %w(
        41 10 12 00 00 00 F8 00 00 00 F5 01 00 00 7F 0E
        00 00 36 0B 00 00
      ).join(' ')
    values = [0, 0x00F8, 0x01F5, 0x0E7F, 0x0B36]
    got = unpack_record(@chart.__send__("store_axisparent", *values))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_axis method.
  #
  def test_store_axis
    caption = " \tChart: _store_axis()"
    expected = %w(
        1D 10 12 00 00 00 00 00 00 00 00 00 00 00 00 00
        00 00 00 00 00 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_axis", 0))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_catserrange method.
  #
  def test_store_catserrange
    caption = " \tChart: _store_catserrange()"
    expected = %w(
        20 10 08 00 01 00 01 00 01 00 01 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_catserrange"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_axcext method.
  #
  def test_store_axcext
    caption = " \tChart: _store_axcext()"
    expected = %w(
        62 10 12 00 00 00 00 00 01 00 00 00 01 00 00 00
        00 00 00 00 EF 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_axcext"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_tick method.
  #
  def test_store_tick
    caption = " \tChart: _store_tick()"
    expected = %w(
        1E 10 1E 00 02 00 03 01 00 00 00 00 00 00 00 00
        00 00 00 00 00 00 00 00 00 00 00 00 23 00 4D 00
        00 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_tick"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_valuerange method.
  #
  def test_store_valuerange
    caption = " \tChart: _store_valuerange()"
    expected = %w(
        1F 10 2A 00 00 00 00 00 00 00 00 00 00 00 00 00
        00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
        00 00 00 00 00 00 00 00 00 00 00 00 1F 01
      ).join(' ')
    got = unpack_record(@chart.__send__("store_valuerange"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_axislineformat method.
  #
  def test_store_axislineformat
    caption = " \tChart: _store_axislineformat()"
    expected = %w(
        21 10 02 00 01 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_axislineformat"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_lineformat method.
  #
  def test_store_lineformat
    caption = " \tChart: _store_lineformat()"
    expected = %w(
        07 10 0C 00 00 00 00 00 00 00 FF FF 09 00 4D 00
      ).join(' ')
    values = [0x00000000, 0x0000, 0xFFFF, 0x0009, 0x004D]
    got = unpack_record(@chart.__send__("store_lineformat", *values))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_frame method.
  #
  def test_store_frame
    caption = " \tChart: _store_frame()"
    expected = %w(
        32 10 04 00 00 00 03 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_frame", 0x00, 0x03))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_areaformat method.
  #
  def test_store_areaformat
    caption = " \tChart: _store_areaformat()"
    expected = %w(
        0A 10 10 00 C0 C0 C0 00 00 00 00 00 01 00 00 00
        16 00 4F 00
      ).join(' ')
    values = [0x00C0C0C0, 0x00, 0x01, 0x00, 0x16, 0x4F]
    got = unpack_record(@chart.__send__("store_areaformat", *values))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_chartformat method.
  #
  def test_store_chartformat
    caption = " \tChart: _store_chartformat()"
    expected = %w(
        14 10 14 00 00 00 00 00 00 00 00 00 00 00 00 00
        00 00 00 00 00 00 00 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_chartformat"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_legend method.
  #
  def test_store_legend
    caption = " \tChart: _store_legend()"
    expected = %w(
        15 10 14 00 F9 05 00 00 E9 0E 00 00 7D 04 00 00
        9C 00 00 00 00 01 0F 00
      ).join(' ')
    values = [0x05F9, 0x0EE9, 0x047D, 0x009C, 0x00, 0x01, 0x000F]
    got = unpack_record(@chart.__send__("store_legend", *values))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_pos method.
  #
  def test_store_pos
    caption = " \tChart: _store_pos()"
    expected = %w(
        4F 10 14 00 05 00 02 00 83 0E 00 00 F9 06 00 00
        00 00 00 00 00 00 00 00
      ).join(' ')
    values = [5, 2, 0x0E83, 0x06F9, 0, 0]
    got = unpack_record(@chart.__send__("store_pos", *values))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_text method.
  #
  def test_store_text
    caption = " \tChart: _store_text()"
    expected = %w(
        25 10 20 00 02 02 01 00 00 00 00 00 46 FF FF FF
        06 FF FF FF 00 00 00 00 00 00 00 00 B1 00 4D 00
        20 10 00 00
      ).join(' ')
    values = [0xFFFFFF46, 0xFFFFFF06, 0, 0, 0x00B1, 0x1020]
    got = unpack_record(@chart.__send__("store_text", *values))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_plotgrowth method.
  #
  def test_store_plotgrowth
    caption = " \tChart: _store_plotgrowth()"
    expected = %w(
        64 10 08 00 00 00 01 00 00 00 01 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_plotgrowth"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_seriestext method.
  #
  def test_store_seriestext
    caption = " \tChart: _store_seriestext()"
    expected = %w(
        0D 10 14 00 00 00 10 00 4E 61 6D 65
        20 66 6F 72 20 53 65 72
        69 65 73 31
      ).join(' ')
    str = 'Name for Series1'
    got = unpack_record(@chart.__send__("store_seriestext", str, 0))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_seriestext method.
  #
  def test_store_seriestext_utf16
    caption = " \tChart: _store_seriestext()"
    expected = %w(
        0D 10 24 00 00 00 10 01 4E 00 61 00 6D 00 65 00
        20 00 66 00 6F 00 72 00 20 00 53 00 65 00 72 00
        69 00 65 00 73 00 31 00
      ).join(' ')
    str = 'Name for Series1'.unpack('C*').pack('n*')
    got = unpack_record(@chart.__send__("store_seriestext", str, 1))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_objectlink method.
  #
  def test_store_objectlink
    caption = " \tChart: _store_objectlink()"
    expected = %w(
        27 10 06 00 01 00 00 00 00 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_objectlink", 1))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_pieformat method.
  #
  def test_store_pieformat
    caption = " \tChart: _store_pieformat()"
    expected = %w(
        0B 10 02 00 00 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_pieformat"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_markerformat method.
  #
  def test_store_markerformat
    caption = " \tChart: _store_markerformat()"
    expected = %w(
        09 10 14 00 00 00 00 00 00 00 00 00 02 00 01 00
        4D 00 4D 00 3C 00 00 00
      ).join(' ')
    values = [0x00, 0x00, 0x02, 0x01, 0x4D, 0x4D, 0x3C]
    got = unpack_record(@chart.__send__("store_markerformat", *values))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_dropbar method.
  #
  def test_store_dropbar
    caption = " \tChart: _store_dropbar()"
    expected = %w(
        3D 10 02 00 96 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_dropbar"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_chartline method.
  #
  def test_store_chartline
    caption = " \tChart: _store_chartline()"
    expected = %w(
        1C 10 02 00 01 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_chartline"))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_serparent method.
  #
  def test_store_serparent
    caption = " \tChart: _store_serparent()"
    expected = %w(
        4A 10 02 00 01 00
      ).join(' ')
    got = unpack_record(@chart.__send__("store_serparent", 1))
    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test the _store_serauxtrend method.
  #
  def test_store_serauxtrend
    caption = " \tChart: _store_serauxtrend()"
    expected = %w(
        4B 10 1C 00 00 01 FF FF FF FF 00 01 FF FF 00 00
        00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
      ).join(' ')
    values = [0x00, 0x01, 0x00, 0x00]
    got = unpack_record(@chart.__send__("store_serauxtrend", *values))
    assert_equal(expected, got, caption)
  end
end
