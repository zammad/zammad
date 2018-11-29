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
class TC_ChartAreaFormats < Test::Unit::TestCase
  def setup
    @io = StringIO.new
    @workbook = WriteExcel.new(@io)
    @chart = @workbook.add_chart(:type => 'Chart::Column')
    @chart.using_tmpfile = false
    @caption1 = " \tChart: chartarea format - line";
    @caption2 = " \tChart: chartarea format - area";
    @embed_caption1 = " \tChart: embedded chartarea format - line";
    @embed_caption2 = " \tChart: embedded chartarea format - area";
    @plotarea_caption1 = " \tChart: plotarea format - line";
    @plotarea_caption2 = " \tChart: plotarea format - area";
  end

  ###############################################################################
  #
  # 1. Test the chartarea format methods. See the set_*area() properties below.
  #
  def test_the_chartarea_format_methods
    reset_chart(@chart)

    @chart.set_chartarea(
      :color        => 'red',
      :line_color   => 'black',
      :line_pattern => 2,
      :line_weight  => 3
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 01 00 01 00 00 00 08 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF 00 00 00 00 00 00 00 01 00 00 00
      0A 00 08 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @caption1)
    assert_equal(expected_area, got_area, @caption2)


    reset_chart(@chart)

    @chart.set_chartarea(
      :color        => 'red'
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 05 00 FF FF 08 00 4D 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF 00 00 00 00 00 00 00 01 00 00 00
      0A 00 08 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @caption1)
    assert_equal(expected_area, got_area, @caption2)


    reset_chart(@chart)

    @chart.set_chartarea(
      :line_color        => 'red'
    )

    expected_line = %w(
      07 10 0C 00 FF 00 00 00 00 00 FF FF 00 00 0A 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF FF FF 00 00 00 00 00 00 00 00 00
      4E 00 4D 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @caption1)
    assert_equal(expected_area, got_area, @caption2)


    reset_chart(@chart)

    @chart.set_chartarea(
      :line_pattern      => 2
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 01 00 FF FF 00 00 4F 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF FF FF 00 00 00 00 00 00 00 00 00
      4E 00 4D 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @caption1)
    assert_equal(expected_area, got_area, @caption2)


    reset_chart(@chart)

    @chart.set_chartarea(
      :line_weight => 3
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 00 00 01 00 00 00 4F 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF FF FF 00 00 00 00 00 00 00 00 00
      4E 00 4D 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @caption1)
    assert_equal(expected_area, got_area, @caption2)


    reset_chart(@chart)

    @chart.set_chartarea(
      :color      => 'red',
      :line_color => 'black'
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 00 00 FF FF 00 00 08 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF 00 00 00 00 00 00 00 01 00 00 00
      0A 00 08 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @caption1)
    assert_equal(expected_area, got_area, @caption2)


    reset_chart(@chart)

    @chart.set_chartarea(
      :color        => 'red',
      :line_pattern => 2
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 01 00 FF FF 00 00 4F 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF 00 00 00 00 00 00 00 01 00 00 00
      0A 00 08 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @caption1)
    assert_equal(expected_area, got_area, @caption2)


    reset_chart(@chart)

    @chart.set_chartarea(
      :color       => 'red',
      :line_weight => 3
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 00 00 01 00 00 00 4F 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF 00 00 00 00 00 00 00 01 00 00 00
      0A 00 08 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @caption1)
    assert_equal(expected_area, got_area, @caption2)


    @chart.embedded = true

    reset_chart(@chart, true)

    @chart.set_chartarea(
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 00 00 00 00 09 00 4D 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF FF FF 00 00 00 00 00 01 00 01 00
      4E 00 4D 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @embed_caption1)
    assert_equal(expected_area, got_area, @embed_caption2)


    reset_chart(@chart, true)

    @chart.set_chartarea(
      :color        => 'red',
      :line_color   => 'black',
      :line_pattern => 2,
      :line_weight  => 3
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 01 00 01 00 00 00 08 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF 00 00 00 00 00 00 00 01 00 00 00
      0A 00 08 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @embed_caption1)
    assert_equal(expected_area, got_area, @embed_caption2)


    reset_chart(@chart, true)

    @chart.set_chartarea(
      :color        => 'red'
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 00 00 FF FF 09 00 4D 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF 00 00 00 00 00 00 00 01 00 00 00
      0A 00 08 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @embed_caption1)
    assert_equal(expected_area, got_area, @embed_caption2)


    reset_chart(@chart, true)

    @chart.set_chartarea(
      :line_color    => 'red'
    )

    expected_line = %w(
      07 10 0C 00 FF 00 00 00 00 00 FF FF 00 00 0A 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF FF FF 00 00 00 00 00 01 00 01 00
      4E 00 4D 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @embed_caption1)
    assert_equal(expected_area, got_area, @embed_caption2)


    reset_chart(@chart, true)

    @chart.set_chartarea(
      :line_pattern    => 2
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 01 00 FF FF 00 00 4F 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF FF FF 00 00 00 00 00 01 00 01 00
      4E 00 4D 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @embed_caption1)
    assert_equal(expected_area, got_area, @embed_caption2)


    reset_chart(@chart, true)

    @chart.set_chartarea(
      :line_weight    => 3
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 00 00 01 00 00 00 4F 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF FF FF 00 00 00 00 00 01 00 01 00
      4E 00 4D 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @embed_caption1)
    assert_equal(expected_area, got_area, @embed_caption2)


    reset_chart(@chart, true)

    @chart.set_chartarea(
      :color      => 'red',
      :line_color => 'black'
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 00 00 FF FF 00 00 08 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF 00 00 00 00 00 00 00 01 00 00 00
      0A 00 08 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @embed_caption1)
    assert_equal(expected_area, got_area, @embed_caption2)


    reset_chart(@chart, true)

    @chart.set_chartarea(
      :color        => 'red',
      :line_pattern => 2
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 01 00 FF FF 00 00 4F 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF 00 00 00 00 00 00 00 01 00 00 00
      0A 00 08 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @embed_caption1)
    assert_equal(expected_area, got_area, @embed_caption2)


    reset_chart(@chart, true)

    @chart.set_chartarea(
      :color       => 'red',
      :line_weight => 3
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 00 00 01 00 00 00 4F 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF 00 00 00 00 00 00 00 01 00 00 00
      0A 00 08 00
    ).join(' ')

    got_line, got_area = get_chartarea_formats(@chart)

    assert_equal(expected_line, got_line, @embed_caption1)
    assert_equal(expected_area, got_area, @embed_caption2)


    @chart.embedded = false

    reset_chart(@chart)

    @chart.set_plotarea(
    )

    expected_line = %w(
      07 10 0C 00 80 80 80 00 00 00 00 00 00 00 17 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 C0 C0 C0 00 00 00 00 00 01 00 00 00
      16 00 4F 00
    ).join(' ')

    got_line, got_area = get_plotarea_formats(@chart)

    assert_equal(expected_line, got_line, @plotarea_caption1)
    assert_equal(expected_area, got_area, @plotarea_caption2)


    reset_chart(@chart)

    @chart.set_plotarea(
      :color        => 'red',
      :line_color   => 'black',
      :line_pattern => 2,
      :line_weight  => 3
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 01 00 01 00 00 00 08 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF 00 00 00 00 00 00 00 01 00 00 00
      0A 00 08 00
    ).join(' ')

    got_line, got_area = get_plotarea_formats(@chart)

    assert_equal(expected_line, got_line, @plotarea_caption1)
    assert_equal(expected_area, got_area, @plotarea_caption2)


    reset_chart(@chart)

    @chart.set_plotarea(
      :color        => 'red'
    )

    expected_line = %w(
      07 10 0C 00 80 80 80 00 00 00 00 00 00 00 17 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF 00 00 00 00 00 00 00 01 00 00 00
      0A 00 08 00
    ).join(' ')

    got_line, got_area = get_plotarea_formats(@chart)

    assert_equal(expected_line, got_line, @plotarea_caption1)
    assert_equal(expected_area, got_area, @plotarea_caption2)


    reset_chart(@chart)

    @chart.set_plotarea(
      :line_color   => 'red'
    )

    expected_line = %w(
      07 10 0C 00 FF 00 00 00 00 00 00 00 00 00 0A 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 C0 C0 C0 00 00 00 00 00 01 00 00 00
      16 00 08 00
    ).join(' ')

    got_line, got_area = get_plotarea_formats(@chart)

    assert_equal(expected_line, got_line, @plotarea_caption1)
    assert_equal(expected_area, got_area, @plotarea_caption2)


    reset_chart(@chart)

    @chart.set_plotarea(
      :line_pattern => 2
    )

    expected_line = %w(
      07 10 0C 00 80 80 80 00 01 00 00 00 00 00 17 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 C0 C0 C0 00 00 00 00 00 01 00 00 00
      16 00 08 00
    ).join(' ')

    got_line, got_area = get_plotarea_formats(@chart)

    assert_equal(expected_line, got_line, @plotarea_caption1)
    assert_equal(expected_area, got_area, @plotarea_caption2)


    reset_chart(@chart)

    @chart.set_plotarea(
      :line_weight => 3
    )

    expected_line = %w(
      07 10 0C 00 80 80 80 00 00 00 01 00 00 00 17 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 C0 C0 C0 00 00 00 00 00 01 00 00 00
      16 00 08 00
    ).join(' ')

    got_line, got_area = get_plotarea_formats(@chart)

    assert_equal(expected_line, got_line, @plotarea_caption1)
    assert_equal(expected_area, got_area, @plotarea_caption2)


    reset_chart(@chart)

    @chart.set_plotarea(
      :color      => 'red',
      :line_color => 'black'
    )

    expected_line = %w(
      07 10 0C 00 00 00 00 00 00 00 00 00 00 00 08 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF 00 00 00 00 00 00 00 01 00 00 00
      0A 00 08 00
    ).join(' ')

    got_line, got_area = get_plotarea_formats(@chart)

    assert_equal(expected_line, got_line, @plotarea_caption1)
    assert_equal(expected_area, got_area, @plotarea_caption2)


    reset_chart(@chart)

    @chart.set_plotarea(
      :color        => 'red',
      :line_pattern => 2
    )

    expected_line = %w(
      07 10 0C 00 80 80 80 00 01 00 00 00 00 00 17 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF 00 00 00 00 00 00 00 01 00 00 00
      0A 00 08 00
    ).join(' ')

    got_line, got_area = get_plotarea_formats(@chart)

    assert_equal(expected_line, got_line, @plotarea_caption1)
    assert_equal(expected_area, got_area, @plotarea_caption2)


    reset_chart(@chart)

    @chart.set_plotarea(
      :color       => 'red',
      :line_weight => 3
    )

    expected_line = %w(
      07 10 0C 00 80 80 80 00 00 00 01 00 00 00 17 00
    ).join(' ')

    expected_area = %w(
      0A 10 10 00 FF 00 00 00 00 00 00 00 01 00 00 00
      0A 00 08 00
    ).join(' ')

    got_line, got_area = get_plotarea_formats(@chart)

    assert_equal(expected_line, got_line, @plotarea_caption1)
    assert_equal(expected_area, got_area, @plotarea_caption2)
  end


  ###############################################################################
  #
  # Reset the chart data for testing.
  #
  def reset_chart(chart, embedded = nil)
    # Reset the chart data.
    chart.data = ''
    chart.__send__("set_default_properties")

    if embedded
      chart.set_embedded_config_data
    end
  end

  ###############################################################################
  #
  # Extract Line and Area format records from the Chartarea Frame stream.
  #
  def get_chartarea_formats(chart)
    chart.__send__("store_chartarea_frame_stream")

    line = unpack_record(chart.data[12, 16])
    area = unpack_record(chart.data[28, 20])

    [line, area]
  end

  ###############################################################################
  #
  # Extract Line and Area format records from the Chartarea Frame stream.
  #
  def get_plotarea_formats(chart)
    chart.__send__("store_plotarea_frame_stream")

    line = unpack_record(chart.data[12, 16])
    area = unpack_record(chart.data[28, 20])

    [line, area]
  end
end
