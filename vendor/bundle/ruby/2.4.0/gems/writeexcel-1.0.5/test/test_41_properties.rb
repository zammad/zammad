# -*- coding: utf-8 -*-
##########################################################################
# test_41_properties.rb
#
# Tests for OLE property sets.
#
# reverse('©'), September 2005, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
#########################################################################
require 'helper'

class TC_properties < Test::Unit::TestCase

  def setup
    @smiley = '☺'   # chr 0x263A;    in perl
  end

  def test_codepage_only
    properties = [[0x0001, 'VT_I2', 0x04E4]]
    caption    = " \tDoc properties: _create_property_set('Code page')"
    target     = %w(
                    FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                    00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                    F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                    18 00 00 00 01 00 00 00 01 00 00 00 10 00 00 00
                    02 00 00 00 E4 04 00 00
                   ).join(' ')

    result     = unpack_record( create_summary_property_set(properties))
    assert_equal(target, result, caption)
  end

  def test_same_as_previous_plus_title
    properties = [
             [0x0001, 'VT_I2',    0x04E4 ],
             [0x0002, 'VT_LPSTR', 'Title'],
                 ]
    caption    = " \tDoc properties: _create_property_set('+ Title')"
    target     = %w(
                    FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                    00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                    F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                    30 00 00 00 02 00 00 00 01 00 00 00 18 00 00 00
                    02 00 00 00 20 00 00 00 02 00 00 00 E4 04 00 00
                    1E 00 00 00 06 00 00 00 54 69 74 6C 65 00 00 00
                   ).join(' ')

    result     = unpack_record( create_summary_property_set(properties))
    assert_equal(target, result, caption)
  end

  def test_same_as_previous_plus_subject
    properties = [
             [0x0001, 'VT_I2',    0x04E4 ],
             [0x0002, 'VT_LPSTR', 'Title'],
             [0x0003, 'VT_LPSTR', 'Subject'],
                 ]
    caption    = " \tDoc properties: _create_property_set('+ Subject')"
    target     = %w(
                    FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                    00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                    F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                    48 00 00 00 03 00 00 00 01 00 00 00 20 00 00 00
                    02 00 00 00 28 00 00 00 03 00 00 00 38 00 00 00
                    02 00 00 00 E4 04 00 00 1E 00 00 00 06 00 00 00
                    54 69 74 6C 65 00 00 00 1E 00 00 00 08 00 00 00
                    53 75 62 6A 65 63 74 00
                   ).join(' ')

    result     = unpack_record( create_summary_property_set(properties))
    assert_equal(target, result, caption)
  end

  def test_same_as_previous_plus_author
    properties = [
             [0x0001, 'VT_I2',    0x04E4 ],
             [0x0002, 'VT_LPSTR', 'Title'],
             [0x0003, 'VT_LPSTR', 'Subject'],
             [0x0004, 'VT_LPSTR', 'Author' ],
                 ]
    caption    = " \tDoc properties: _create_property_set('+ Keywords')"
    target     = %w(
                    FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                    00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                    F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                    60 00 00 00 04 00 00 00 01 00 00 00 28 00 00 00
                    02 00 00 00 30 00 00 00 03 00 00 00 40 00 00 00
                    04 00 00 00 50 00 00 00 02 00 00 00 E4 04 00 00
                    1E 00 00 00 06 00 00 00 54 69 74 6C 65 00 00 00
                    1E 00 00 00 08 00 00 00 53 75 62 6A 65 63 74 00
                    1E 00 00 00 07 00 00 00 41 75 74 68 6F 72 00 00
                   ).join(' ')

    result     = unpack_record( create_summary_property_set(properties))
    assert_equal(target, result, caption)
  end

  def test_same_as_previous_plus_keywords
    properties = [
             [0x0001, 'VT_I2',    0x04E4 ],
             [0x0002, 'VT_LPSTR', 'Title'],
             [0x0003, 'VT_LPSTR', 'Subject'],
             [0x0004, 'VT_LPSTR', 'Author' ],
             [0x0005, 'VT_LPSTR', 'Keywords'],
                 ]
    caption    = " \tDoc properties: _create_property_set('+ Keywords')"
    target     = %w(
                    FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                    00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                    F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                    7C 00 00 00 05 00 00 00 01 00 00 00 30 00 00 00
                    02 00 00 00 38 00 00 00 03 00 00 00 48 00 00 00
                    04 00 00 00 58 00 00 00 05 00 00 00 68 00 00 00
                    02 00 00 00 E4 04 00 00 1E 00 00 00 06 00 00 00
                    54 69 74 6C 65 00 00 00 1E 00 00 00 08 00 00 00
                    53 75 62 6A 65 63 74 00 1E 00 00 00 07 00 00 00
                    41 75 74 68 6F 72 00 00 1E 00 00 00 09 00 00 00
                    4B 65 79 77 6F 72 64 73 00 00 00 00
                   ).join(' ')

    result     = unpack_record( create_summary_property_set(properties))
    assert_equal(target, result, caption)
  end

  def test_same_as_previous_plus_comments
    properties = [
             [0x0001, 'VT_I2',    0x04E4 ],
             [0x0002, 'VT_LPSTR', 'Title'],
             [0x0003, 'VT_LPSTR', 'Subject'],
             [0x0004, 'VT_LPSTR', 'Author' ],
             [0x0005, 'VT_LPSTR', 'Keywords'],
             [0x0006, 'VT_LPSTR', 'Comments'],
                 ]
    caption    = " \tDoc properties: _create_property_set('+ Comments')"
    target     = %w(
                    FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                    00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                    F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                    98 00 00 00 06 00 00 00 01 00 00 00 38 00 00 00
                    02 00 00 00 40 00 00 00 03 00 00 00 50 00 00 00
                    04 00 00 00 60 00 00 00 05 00 00 00 70 00 00 00
                    06 00 00 00 84 00 00 00 02 00 00 00 E4 04 00 00
                    1E 00 00 00 06 00 00 00 54 69 74 6C 65 00 00 00
                    1E 00 00 00 08 00 00 00 53 75 62 6A 65 63 74 00
                    1E 00 00 00 07 00 00 00 41 75 74 68 6F 72 00 00
                    1E 00 00 00 09 00 00 00 4B 65 79 77 6F 72 64 73
                    00 00 00 00 1E 00 00 00 09 00 00 00 43 6F 6D 6D
                    65 6E 74 73 00 00 00 00
                   ).join(' ')

    result     = unpack_record( create_summary_property_set(properties))
    assert_equal(target, result, caption)
  end

  def test_same_as_previous_plus_last_author
    properties = [
             [0x0001, 'VT_I2',    0x04E4 ],
             [0x0002, 'VT_LPSTR', 'Title'],
             [0x0003, 'VT_LPSTR', 'Subject'],
             [0x0004, 'VT_LPSTR', 'Author' ],
             [0x0005, 'VT_LPSTR', 'Keywords'],
             [0x0006, 'VT_LPSTR', 'Comments'],
             [0x0008, 'VT_LPSTR', 'Username'],
                 ]
    caption    = " \tDoc properties: _create_property_set('+ Comments')"
    target     = %w(
                    FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                    00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                    F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                    B4 00 00 00 07 00 00 00 01 00 00 00 40 00 00 00
                    02 00 00 00 48 00 00 00 03 00 00 00 58 00 00 00
                    04 00 00 00 68 00 00 00 05 00 00 00 78 00 00 00
                    06 00 00 00 8C 00 00 00 08 00 00 00 A0 00 00 00
                    02 00 00 00 E4 04 00 00 1E 00 00 00 06 00 00 00
                    54 69 74 6C 65 00 00 00 1E 00 00 00 08 00 00 00
                    53 75 62 6A 65 63 74 00 1E 00 00 00 07 00 00 00
                    41 75 74 68 6F 72 00 00 1E 00 00 00 09 00 00 00
                    4B 65 79 77 6F 72 64 73 00 00 00 00 1E 00 00 00
                    09 00 00 00 43 6F 6D 6D 65 6E 74 73 00 00 00 00
                    1E 00 00 00 09 00 00 00 55 73 65 72 6E 61 6D 65
                    00 00 00 00
                   ).join(' ')

    result     = unpack_record( create_summary_property_set(properties))
    assert_equal(target, result, caption)
  end

  def test_same_as_previous_plus_creation_date
    filetime = Time.gm(2008,8,19,23,20,13)
    properties = [
             [0x0001, 'VT_I2',    0x04E4 ],
             [0x0002, 'VT_LPSTR', 'Title'],
             [0x0003, 'VT_LPSTR', 'Subject'],
             [0x0004, 'VT_LPSTR', 'Author' ],
             [0x0005, 'VT_LPSTR', 'Keywords'],
             [0x0006, 'VT_LPSTR', 'Comments'],
             [0x0008, 'VT_LPSTR', 'Username'],
             [0x000C, 'VT_FILETIME', filetime ],
                 ]
    caption    = " \tDoc properties: _create_property_set('+ Comments')"
    target     = %w(
                    FE FF 00 00 05 01 02 00 00 00 00 00 00 00 00 00
                    00 00 00 00 00 00 00 00 01 00 00 00 E0 85 9F F2
                    F9 4F 68 10 AB 91 08 00 2B 27 B3 D9 30 00 00 00
                    C8 00 00 00 08 00 00 00 01 00 00 00 48 00 00 00
                    02 00 00 00 50 00 00 00 03 00 00 00 60 00 00 00
                    04 00 00 00 70 00 00 00 05 00 00 00 80 00 00 00
                    06 00 00 00 94 00 00 00 08 00 00 00 A8 00 00 00
                    0C 00 00 00 BC 00 00 00 02 00 00 00 E4 04 00 00
                    1E 00 00 00 06 00 00 00 54 69 74 6C 65 00 00 00
                    1E 00 00 00 08 00 00 00 53 75 62 6A 65 63 74 00
                    1E 00 00 00 07 00 00 00 41 75 74 68 6F 72 00 00
                    1E 00 00 00 09 00 00 00 4B 65 79 77 6F 72 64 73
                    00 00 00 00 1E 00 00 00 09 00 00 00 43 6F 6D 6D
                    65 6E 74 73 00 00 00 00 1E 00 00 00 09 00 00 00
                    55 73 65 72 6E 61 6D 65 00 00 00 00 40 00 00 00
                    80 74 89 21 52 02 C9 01
                   ).join(' ')

    result     = unpack_record( create_summary_property_set(properties))
    assert_equal(target, result, caption)
  end
end
