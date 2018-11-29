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
class TC_chart_subclasses < Test::Unit::TestCase
  def setup
    io = StringIO.new
    @workbook = WriteExcel.new(io)
  end

  def test_store_chart_type_of_column
    chart = Writeexcel::Chart.factory('Chart::Column', @workbook, nil, nil)
    expected = %w(
        17 10 06 00 00 00 96 00 00 00
      ).join(' ')
    got = unpack_record(chart.store_chart_type)
    assert_equal(expected, got)
  end

  def test_store_chart_type_of_bar
    chart = Writeexcel::Chart.factory('Chart::Bar', @workbook, nil, nil)
    expected = %w(
        17 10 06 00 00 00 96 00 01 00
      ).join(' ')
    got = unpack_record(chart.store_chart_type)
    assert_equal(expected, got)
  end

  def test_store_chart_type_of_line
    chart = Writeexcel::Chart.factory('Chart::Line', @workbook, nil, nil)
    expected = %w(
        18 10 02 00 00 00
      ).join(' ')
    got = unpack_record(chart.store_chart_type)
    assert_equal(expected, got)
  end

  def test_store_chart_type_of_area
    chart = Writeexcel::Chart.factory('Chart::Area', @workbook, nil, nil)
    expected = %w(
        1A 10 02 00 01 00
      ).join(' ')
    got = unpack_record(chart.store_chart_type)
    assert_equal(expected, got)
  end

  def test_store_chart_type_of_pie
    chart = Writeexcel::Chart.factory('Chart::Pie', @workbook, nil, nil)
    expected = %w(
        19 10 06 00 00 00 00 00 02 00
      ).join(' ')
    got = unpack_record(chart.store_chart_type)
    assert_equal(expected, got)
  end

  def test_store_chart_type_of_scatter
    chart = Writeexcel::Chart.factory('Chart::Scatter', @workbook, nil, nil)
    expected = %w(
        1B 10 06 00 64 00 01 00 00 00
      ).join(' ')
    got = unpack_record(chart.store_chart_type)
    assert_equal(expected, got)
  end

  def test_store_chart_type_of_stock
    chart = Writeexcel::Chart.factory('Chart::Stock', @workbook, nil, nil)
    expected = %w(
        18 10 02 00 00 00
      ).join(' ')
    got = unpack_record(chart.store_chart_type)
    assert_equal(expected, got)
  end
end
