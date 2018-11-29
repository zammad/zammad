# -*- coding: utf-8 -*-
require 'helper'
require 'stringio'

###############################################################################
#
# A test for Spreadsheet::Writeexcel::Chart.
#
# Tests for the Excel Chart.pm format conversion methods.
#
# reverse('ｩ'), January 2010, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
class TC_ChartFormats < Test::Unit::TestCase
  def setup
    @io = StringIO.new
    @workbook = WriteExcel.new(@io)
    @chart = @workbook.add_chart(:type => 'Chart::Column')
  end

###############################################################################
#
# Test. User defined colour as string.
#
  def test_user_defined_color_as_string
    color    = 'red'
    caption1 = " \tChart: index   = get_color_indices(#{color})"
    caption2 = " \tChart: rgb     = get_color_indices(#{color})"

    expected_index = 0x0A
    expected_rgb   = 0x000000FF

    got_index, got_rgb = @chart.__send__("get_color_indices", color)

    assert_equal(expected_index, got_index, caption1)
    assert_equal(expected_rgb,   got_rgb,   caption2)

    color    = 'black'
    caption1 = " \tChart: index   = get_color_indices(#{color})"
    caption2 = " \tChart: rgb     = get_color_indices(#{color})"

    expected_index = 0x08
    expected_rgb   = 0x00000000

    got_index, got_rgb = @chart.__send__("get_color_indices", color)

    assert_equal(expected_index, got_index, caption1)
    assert_equal(expected_rgb,   got_rgb,   caption2)

    color    = 'white'
    caption1 = " \tChart: index   = get_color_indices(#{color})"
    caption2 = " \tChart: rgb     = get_color_indices(#{color})"

    expected_index = 0x09
    expected_rgb   = 0x00FFFFFF

    got_index, got_rgb = @chart.__send__("get_color_indices", color)

    assert_equal(expected_index, got_index, caption1)
    assert_equal(expected_rgb,   got_rgb,   caption2)
  end

  ###############################################################################
  #
  # Test. User defined colour as an index.
  #
  def test_user_defined_color_as_an_index
    color    = 0x0A
    caption1 = " \tChart: index   = get_color_indices(#{color})"
    caption2 = " \tChart: rgb     = get_color_indices(#{color})"

    expected_index = 0x0A
    expected_rgb   = 0x000000FF


    got_index, got_rgb = @chart.__send__("get_color_indices", color)

    assert_equal(expected_index, got_index, caption1)
    assert_equal(expected_rgb,   got_rgb,   caption2)
  end

  ###############################################################################
  #
  # Test. User defined colour as an out of range index.
  #
  def test_user_defined_color_as_an_out_of_range_index
    color    = 7
    caption1 = " \tChart: index   = get_color_indices(#{color})"
    caption2 = " \tChart: rgb     = get_color_indices(#{color})"

    expected_index = nil
    expected_rgb   = nil

    got_index, got_rgb = @chart.__send__("get_color_indices", color)

    assert_equal(expected_index, got_index, caption1)
    assert_equal(expected_rgb,   got_rgb,   caption2)

    color    = 64
    caption1 = " \tChart: index   = get_color_indices(#{color})"
    caption2 = " \tChart: rgb     = get_color_indices(#{color})"

    expected_index = nil
    expected_rgb   = nil

    got_index, got_rgb = @chart.__send__("get_color_indices", color)

    assert_equal(expected_index, got_index, caption1)
    assert_equal(expected_rgb,   got_rgb,   caption2)
  end

  ###############################################################################
  #
  # Test. User defined colour as an invalid string.
  #
  def test_user_defined_color_as_an_invalid_string
    color    = 'plaid'
    caption1 = " \tChart: index   = get_color_indices(#{color})"
    caption2 = " \tChart: rgb     = get_color_indices(#{color})"

    expected_index = nil
    expected_rgb   = nil

    got_index, got_rgb = @chart.__send__("get_color_indices", color)

    assert_equal(expected_index, got_index, caption1)
    assert_equal(expected_rgb,   got_rgb,   caption2)
  end

  ###############################################################################
  #
  # Test. User defined colour as an undef property.
  #
  def test_user_defined_color_as_an_nil_property
    color    = nil
    caption1 = " \tChart: index   = get_color_indices(#{color})"
    caption2 = " \tChart: rgb     = get_color_indices(#{color})"

    expected_index = nil
    expected_rgb   = nil

    got_index, got_rgb = @chart.__send__("get_color_indices", color)

    assert_equal(expected_index, got_index, caption1)
    assert_equal(expected_rgb,   got_rgb,   caption2)
  end

  ###############################################################################
  #
  # Test. Line patterns with indices.
  #
  def test_line_patterns_with_indices
    caption = " \tChart: pattern = _get_line_pattern()"

    values = {
        0     => 5,
        1     => 0,
        2     => 1,
        3     => 2,
        4     => 3,
        5     => 4,
        6     => 7,
        7     => 6,
        8     => 8,
        9     => 0,
        nil   => 0
    }

    expected = []
    got      = []

    values.each do |user, excel|
      got.push(@chart.__send__("get_line_pattern", user))
      expected.push(excel)
    end

    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test. Line patterns with names.
  #
  def test_line_patterns_with_names
    caption = " \tChart: pattern = _get_line_pattern()"

    values = {
        'solid'        => 0,
        'dash'         => 1,
        'dot'          => 2,
        'dash-dot'     => 3,
        'dash-dot-dot' => 4,
        'none'         => 5,
        'dark-gray'    => 6,
        'medium-gray'  => 7,
        'light-gray'   => 8,
        'DASH'         => 1,
        'fictional'    => 0
    }

    expected = []
    got      = []

    values.each do |user, excel|
      got.push(@chart.__send__("get_line_pattern", user))
      expected.push(excel)
    end

    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test. Line weights with indices.
  #
  def test_line_weights_with_indices
    caption = " \tChart: weight  = _get_line_weight()"

    values = {
        1     => -1,
        2     => 0,
        3     => 1,
        4     => 2,
        5     => 0,
        0     => 0,
        nil   => 0
    }

    expected = []
    got      = []

    values.each do |user, excel|
      got.push(@chart.__send__("get_line_weight", user))
      expected.push(excel)
    end

    assert_equal(expected, got, caption)
  end

  ###############################################################################
  #
  # Test. Line weights with names.
  #
  def test_line_weights_with_names
    caption = " \tChart: weight  = _get_line_weight()"

    values = {
        'hairline'  => -1,
        'narrow'    => 0,
        'medium'    => 1,
        'wide'      => 2,
        'WIDE'      => 2,
        'Fictional' => 0,
    }

    expected = []
    got      = []

    values.each do |user, excel|
      got.push(@chart.__send__("get_line_weight", user))
      expected.push(excel)
    end

    assert_equal(expected, got, caption)
  end
end
