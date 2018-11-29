# -*- coding: utf-8 -*-
##########################################################################
# test_40_property_types.rb
#
# Tests for the basic property types used in OLE property sets.
#
# reverse('©'), September 2005, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
#########################################################################
require 'helper'

class TC_property_types < Test::Unit::TestCase

  def setup
    @smiley = '☺'   # chr 0x263A;    in perl
  end

  def test_pack_a_VT_I2
    caption    = " \tDoc properties: pack_VT_I2(1252)"
    target     = %w(
                    02 00 00 00 E4 04 00 00
                   ).join(' ')

    result     = unpack_record(pack_VT_I2(1252))
    assert_equal(target, result, caption)
  end

  def test_pack_a_VT_LPSTR_string_and_check_for_padding
    string     = ''
    codepage   = 0x04E4
    caption    = " \tDoc properties: _pack_VT_LPSTR('#{string}',\t#{codepage}')"
    target     = %w(
                     1E 00 00 00 01 00 00 00 00 00 00 00
                   ).join(' ')

    result     = unpack_record(pack_VT_LPSTR(string, codepage))
    assert_equal(target, result, caption)
  end

  def test_pack_a_VT_LPSTR_string_and_check_for_padding_2
    string     = 'a'
    codepage   = 0x04E4
    caption    = " \tDoc properties: _pack_VT_LPSTR('#{string}',\t#{codepage}')"
    target     = %w(
                    1E 00 00 00 02 00 00 00 61 00 00 00
                   ).join(' ')

    result     = unpack_record(pack_VT_LPSTR(string, codepage))
    assert_equal(target, result, caption)
  end

  def test_pack_a_VT_LPSTR_string_and_check_for_padding_3
    string     = 'bb'
    codepage   = 0x04E4
    caption    = " \tDoc properties: _pack_VT_LPSTR('#{string}',\t#{codepage}')"
    target     = %w(
                    1E 00 00 00 03 00 00 00 62 62 00 00
                   ).join(' ')

    result     = unpack_record(pack_VT_LPSTR(string, codepage))
    assert_equal(target, result, caption)
  end

  def test_pack_a_VT_LPSTR_string_and_check_for_padding_4
    string     = 'ccc'
    codepage   = 0x04E4
    caption    = " \tDoc properties: _pack_VT_LPSTR('#{string}',\t#{codepage}')"
    target     = %w(
                    1E 00 00 00 04 00 00 00 63 63 63 00
                   ).join(' ')

    result     = unpack_record(pack_VT_LPSTR(string, codepage))
    assert_equal(target, result, caption)
  end

  def test_pack_a_VT_LPSTR_string_and_check_for_padding_5
    string     = 'dddd'
    codepage   = 0x04E4
    caption    = " \tDoc properties: _pack_VT_LPSTR('#{string}',\t#{codepage}')"
    target     = %w(
                    1E 00 00 00 05 00 00 00 64 64 64 64 00 00 00 00
                   ).join(' ')

    result     = unpack_record(pack_VT_LPSTR(string, codepage))
    assert_equal(target, result, caption)
  end

  def test_pack_a_VT_LPSTR_string_and_check_for_padding_6
    string     = 'Username'
    codepage   = 0x04E4
    caption    = " \tDoc properties: _pack_VT_LPSTR('#{string}',\t#{codepage}')"
    target     = %w(
                    1E 00 00 00 09 00 00 00 55 73 65 72 6E 61 6D 65
                    00 00 00 00
                   ).join(' ')

    result     = unpack_record(pack_VT_LPSTR(string, codepage))
    assert_equal(target, result, caption)
  end

  def test_pack_a_VT_LPSTR_UTF8_string
    string     = @smiley
    codepage   = 0xFDE9
    caption    = " \tDoc properties: _pack_VT_LPSTR('#{@smiley}',\t#{codepage}')"
    target     = %w(
                    1E 00 00 00 04 00 00 00 E2 98 BA 00
                   ).join(' ')

    result     = unpack_record(pack_VT_LPSTR(string, codepage))
    assert_equal(target, result, caption)
  end

  def test_pack_a_VT_LPSTR_UTF8_string_2
    string     = "a" + @smiley
    codepage   = 0xFDE9
    caption    = " \tDoc properties: _pack_VT_LPSTR('a#{@smiley}',\t#{codepage}')"
    target     = %w(
                    1E 00 00 00 05 00 00 00 61 E2 98 BA 00 00 00 00
                   ).join(' ')

    result     = unpack_record(pack_VT_LPSTR(string, codepage))
    assert_equal(target, result, caption)
  end

  def test_pack_a_VT_LPSTR_UTF8_string_3
    string     = "aa" + @smiley
    codepage   = 0xFDE9
    caption    = " \tDoc properties: _pack_VT_LPSTR('#{string}',\t#{codepage}')"
    target     = %w(
                    1E 00 00 00 06 00 00 00 61 61 E2 98 BA 00 00 00
                   ).join(' ')

    result     = unpack_record( pack_VT_LPSTR(string, codepage) )
    assert_equal(target, result, caption)
  end

  def test_pack_a_VT_LPSTR_UTF8_string_4
    string     = "aaa" + @smiley
    codepage   = 0xFDE9
    caption    = " \tDoc properties: _pack_VT_LPSTR('#{string}',\t#{codepage}')"
    target     = %w(
                    1E 00 00 00 07 00 00 00 61 61 61 E2 98 BA 00 00
                   ).join(' ')

    result     = unpack_record( pack_VT_LPSTR(string, codepage) )
    assert_equal(target, result, caption)
  end

  def test_pack_a_VT_LPSTR_UTF8_string_5
    string     = "aaaa" + @smiley
    codepage   = 0xFDE9
    caption    = " \tDoc properties: _pack_VT_LPSTR('#{string}',\t#{codepage}')"
    target     = %w(
                    1E 00 00 00 08 00 00 00 61 61 61 61 E2 98 BA 00
                   ).join(' ')

    result     = unpack_record( pack_VT_LPSTR(string, codepage) )
    assert_equal(target, result, caption)
  end

  def test_pack_a_VT_FILETIME
    # Wed Aug 13 00:40:00 2008
    # $sec,$min,$hour,$mday,$mon,$year
    # We normalise the time using timegm() so that the tests don't fail due to
    # different timezones.
    filetime   = Time.gm(2008,8,13,0,40,0)

    caption    = " \tDoc properties: _pack_VT_FILETIME()"
    target     = %w(
                    40 00 00 00 00 70 EB 1D DD FC C8 01
                   ).join(' ')

    result     = unpack_record( pack_VT_FILETIME(filetime) )
    assert_equal(target, result, caption)
  end
end
