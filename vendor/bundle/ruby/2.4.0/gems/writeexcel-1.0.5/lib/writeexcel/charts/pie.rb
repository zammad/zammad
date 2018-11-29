# -*- coding: utf-8 -*-
###############################################################################
#
# Pie - A writer class for Excel Pie charts.
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
  # To create a simple Excel file with a Pie chart using WriteExcel:
  #
  #     #!/usr/bin/ruby -w
  #
  #     require 'writeexcel'
  #
  #     workbook  = WriteExcel.new('chart.xls')
  #     worksheet = workbook.add_worksheet
  #
  #     chart     = workbook.add_chart(:type => 'Chart::Pie')
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
  # This module implements Pie charts for WriteExcel. The chart
  # object is created via the Workbook add_chart() method:
  #
  #     chart = workbook.add_chart(:type => 'Chart::Pie')
  #
  # Once the object is created it can be configured via the following methods
  # that are common to all chart classes:
  #
  #     chart.add_series
  #     chart.set_title
  #
  # These methods are explained in detail in Chart section of WriteExcel.
  # Class specific methods or settings, if any, are explained below.
  #
  # ==Pie Chart Methods
  #
  # There aren't currently any pie chart specific methods. See the TODO
  # section of Chart section in WriteExcel.
  #
  # A Pie chart doesn't have an X or Y axis so the following common chart
  # methods are ignored.
  #
  #     chart.set_x_axis
  #     chart.set_y_axis
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
  #     workbook  = WriteExcel.new('chart_pie.xls')
  #     worksheet = workbook.add_worksheet
  #     bold      = workbook.add_format(:bold => 1)
  #
  #     # Add the worksheet data that the charts will refer to.
  #     headings = [ 'Category', 'Values' ]
  #     data = [
  #         [ 'Apple', 'Cherry', 'Pecan' ],
  #         [ 60,       30,       10     ],
  #     ]
  #
  #     worksheet.write('A1', headings, bold)
  #     worksheet.write('A2', data)
  #
  #     # Create a new chart object. In this case an embedded chart.
  #     chart = workbook.add_chart(:type => 'Chart::Pie', :embedded => 1)
  #
  #     # Configure the series.
  #     chart.add_series(
  #       :name       => 'Pie sales data',
  #       :categories => '=Sheet1!$A$2:$A$4',
  #       :values     => '=Sheet1!$B$2:$B$4',
  #    )
  #
  #     # Add a title.
  #     chart.set_title(:name => 'Popular Pie Types')
  #
  #
  #     # Insert the chart into the worksheet (with an offset).
  #     worksheet.insert_chart('C2', chart, 25, 10)
  #
  #     workbook.close
  #
  class Pie < Chart
    ###############################################################################
    #
    # new()
    #
    #
    def initialize(*args)   # :nodoc:
      super
      @vary_data_color = 1
    end

    ###############################################################################
    #
    # _store_chart_type()
    #
    # Implementation of the abstract method from the specific chart class.
    #
    # Write the Pie chart BIFF record.
    #
    def store_chart_type   # :nodoc:
      record = 0x1019     # Record identifier.
      length = 0x0006     # Number of bytes to follow.
      angle  = 0x0000     # Angle.
      donut  = 0x0000     # Donut hole size.
      grbit  = 0x0002     # Option flags.

      store_simple(record, length, angle, donut, grbit)
    end

    ###############################################################################
    #
    # _store_axisparent_stream(). Overridden.
    #
    # Write the AXISPARENT chart substream.
    #
    # A Pie chart has no X or Y axis so we override this method to remove them.
    #
    def store_axisparent_stream   # :nodoc:
      store_axisparent(*@config[:axisparent])

      store_begin
      store_pos(*@config[:axisparent_pos])

      store_chartformat_stream
      store_end
    end
  end
end  # class Chart

end  # module Writeexcel
