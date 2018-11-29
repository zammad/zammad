# -*- coding: utf-8 -*-
###############################################################################
#
# Scatter - A writer class for Excel Scatter charts.
#
# Used in conjunction with WriteExcel::Chart.
#
# See formatting note in WriteExcel::Chart.
#
# Copyright 2000-2010, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'

module Writeexcel

class Chart

  # ==SYNOPSIS
  #
  # To create a simple Excel file with a Scatter chart using WriteExcel:
  #
  #     #!/usr/bin/ruby -w
  #
  #     require 'writeexcel'
  #
  #     workbook  = WriteExcel.new('chart.xls')
  #     worksheet = workbook.add_worksheet
  #
  #     chart     = workbook.add_chart(:type => 'Chart::Scatter')
  #
  #     # Configure the chart.
  #     chart.add_series(
  #       :categories => '=Sheet1!$A$2:$A$7',
  #       :values     => '=Sheet1!$B$2:$B$7'
  #    )
  #
  #     # Add the worksheet data the chart refers to.
  #     data = [
  #         [ 'Category', 2, 3, 4, 5, 6, 7 ],
  #         [ 'Value',    1, 4, 5, 2, 1, 5 ]
  #     ]
  #
  #     worksheet.write('A1', data)
  #
  #     workbook.close
  #
  # ==DESCRIPTION
  #
  # This module implements Scatter charts for WriteExcel.
  # The chart object is created via the Workbook add_chart() method:
  #
  #     chart = workbook.add_chart(:type => 'Chart::Scatter')
  #
  # Once the object is created it can be configured via the following
  # methods that are common to all chart classes:
  #
  #     chart.add_series
  #     chart.set_x_axis
  #     chart.set_y_axis
  #     chart.set_title
  #
  # These methods are explained in detail in Chart section of WriteExcel.
  # Class specific methods or settings, if any, are explained below.
  #
  # ==Scatter Chart Methods
  #
  # There aren't currently any scatter chart specific methods. See the TODO
  # section of Chart section in WriteExcel.
  #
  # ==EXAMPLE
  #
  # Here is a complete example that demonstrates most of the available
  # features when creating a chart.
  #
  #     #!/usr/bin/ruby -w
  #
  #     require 'writeexcel'
  #
  #     workbook  = WriteExcel.new('chart_scatter.xls')
  #     worksheet = workbook.add_worksheet
  #     bold      = workbook.add_format(:bold => 1)
  #
  #     # Add the worksheet data that the charts will refer to.
  #     headings = [ 'Number', 'Sample 1', 'Sample 2' ]
  #     data = [
  #         [ 2, 3, 4, 5, 6, 7 ],
  #         [ 1, 4, 5, 2, 1, 5 ],
  #         [ 3, 6, 7, 5, 4, 3 ]
  #     ]
  #
  #     worksheet.write('A1', headings, bold)
  #     worksheet.write('A2', data)
  #
  #     # Create a new chart object. In this case an embedded chart.
  #     chart = workbook.add_chart(:type => 'Chart::Scatter', :embedded => 1)
  #
  #     # Configure the first series. (Sample 1)
  #     chart.add_series(
  #       :name       => 'Sample 1',
  #       :categories => '=Sheet1!$A$2:$A$7',
  #       :values     => '=Sheet1!$B$2:$B$7'
  #    )
  #
  #     # Configure the second series. (Sample 2)
  #     chart.add_series(
  #       :name       => 'Sample 2',
  #       :categories => '=Sheet1!$A$2:$A$7',
  #       :values     => '=Sheet1!$C$2:$C$7'
  #    )
  #
  #     # Add a chart title and some axis labels.
  #     chart.set_title (:name => 'Results of sample analysis')
  #     chart.set_x_axis(:name => 'Test number')
  #     chart.set_y_axis(:name => 'Sample length (cm)')
  #
  #     # Insert the chart into the worksheet (with an offset).
  #     worksheet.insert_chart('D2', chart, 25, 10)
  #
  #     workbook.close
  #
  class Scatter < Chart
    ###############################################################################
    #
    # new()
    #
    #
    def initialize(*args)   # :nodoc:
      super
    end

    ###############################################################################
    #
    # _store_chart_type()
    #
    # Implementation of the abstract method from the specific chart class.
    #
    # Write the AREA chart BIFF record. Defines a area chart type.
    #
    def store_chart_type   # :nodoc:
      record       = 0x101B     # Record identifier.
      length       = 0x0006     # Number of bytes to follow.
      bubble_ratio = 0x0064     # Bubble ratio.
      bubble_type  = 0x0001     # Bubble type.
      grbit        = 0x0000     # Option flags.

      store_simple(record, length, bubble_ratio, bubble_type, grbit)
    end

    ###############################################################################
    #
    # _store_axis_category_stream(). Overridden.
    #
    # Write the AXIS chart substream for the chart category.
    #
    # For a Scatter chart the category stream is replace with a values stream. We
    # override this method and turn it into a values stream.
    #
    def store_axis_category_stream   # :nodoc:
      store_axis(0)

      store_begin
      store_valuerange
      store_tick
      store_end
    end

    ###############################################################################
    #
    # _store_marker_dataformat_stream(). Overridden.
    #
    # This is an implementation of the parent abstract method  to define
    # properties of markers, linetypes, pie formats and other.
    #
    def store_marker_dataformat_stream   # :nodoc:
      store_dataformat(0x0000, 0xFFFD, 0x0000)

      store_begin
      store_3dbarshape
      store_lineformat(0x00000000, 0x0005, 0xFFFF, 0x0008, 0x004D)
      store_areaformat(0x00FFFFFF, 0x0000, 0x01, 0x01, 0x4E, 0x4D)
      store_pieformat
      store_markerformat(0x00, 0x00, 0x02, 0x01, 0x4D, 0x4D, 0x3C)
      store_end
    end
  end
end  # class Chart

end  # module Writeexcel
