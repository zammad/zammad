# -*- coding: utf-8 -*-
###############################################################################
#
# Stock - A writer class for Excel Stock charts.
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
  # To create a simple Excel file with a Stock chart using WriteExcel:
  #
  #     #!/usr/bin/ruby -w
  #
  #     require 'writeexcel'
  #
  #     workbook  = WriteExcel.new('chart.xls')
  #     worksheet = workbook.add_worksheet
  #
  #     chart     = workbook.add_chart(:type => 'Chart::Stock')
  #
  #     # Add a series for each Open-High-Low-Close.
  #     chart.add_series(:categories => '=Sheet1!$A$2:$A$6', :values => '=Sheet1!$B$2:$B$6')
  #     chart.add_series(:categories => '=Sheet1!$A$2:$A$6', :values => '=Sheet1!$C$2:$C$6')
  #     chart.add_series(:categories => '=Sheet1!$A$2:$A$6', :values => '=Sheet1!$D$2:$D$6')
  #     chart.add_series(:categories => '=Sheet1!$A$2:$A$6', :values => '=Sheet1!$E$2:$E$6')
  #
  #     # Add the worksheet data the chart refers to.
  #     # ... See the full example below.
  #
  #     workbook.close
  #
  # ==DESCRIPTION
  #
  # This module implements Stock charts for WriteExcel. The chart object
  # is created via the Workbook add_chart() method:
  #
  #     chart = workbook.add_chart(:type => 'Chart::Stock')
  #
  # Once the object is created it can be configured via the following methods
  # that are common to all chart classes:
  #
  #     chart.add_series
  #     chart.set_x_axis
  #     chart.set_y_axis
  #     chart.set_title
  #
  # These methods are explained in detail in Chart section of WriteExcel.
  # Class specific methods or settings, if any, are explained below.
  #
  # ==Stock Chart Methods
  #
  # There aren't currently any stock chart specific methods.
  # See the TODO section of Chart section in WriteExcel.
  #
  # The default Stock chart is an Open-High-Low-Close chart.
  # A series must be added for each of these data sources.
  #
  # The default Stock chart is in black and white. User defined colours
  # will be added at a later stage.
  #
  # ==EXAMPLE
  #
  # Here is a complete example that demonstrates most of the available features
  # when creating a Stock chart.
  #
  #     #!/usr/bin/ruby -w
  #
  #     require 'writeexcel'
  #
  #     workbook    = WriteExcel.new('chart_stock_ex.xls')
  #     worksheet   = workbook.add_worksheet
  #     bold        = workbook.add_format(:bold => 1)
  #     date_format = workbook.add_format(:num_format => 'dd/mm/yyyy')
  #
  #     # Add the worksheet data that the charts will refer to.
  #     headings = [ 'Date', 'Open', 'High', 'Low', 'Close' ]
  #     data = [
  #         [ '2009-08-23', 110.75, 113.48, 109.05, 109.40 ],
  #         [ '2009-08-24', 111.24, 111.60, 103.57, 104.87 ],
  #         [ '2009-08-25', 104.96, 108.00, 103.88, 106.00 ],
  #         [ '2009-08-26', 104.95, 107.95, 104.66, 107.91 ],
  #         [ '2009-08-27', 108.10, 108.62, 105.69, 106.15 ]
  #    ]
  #
  #     worksheet.write('A1', headings, bold)
  #
  #     row = 1
  #     data.each do |d|
  #         worksheet.write(row, 0, d[0], date_format)
  #         worksheet.write(row, 1, d[1])
  #         worksheet.write(row, 2, d[2])
  #         worksheet.write(row, 3, d[3])
  #         worksheet.write(row, 4, d[4])
  #         row += 1
  #     end
  #
  #     # Create a new chart object. In this case an embedded chart.
  #     chart = workbook.add_chart(:type => 'Chart::Stock', ::embedded => 1)
  #
  #     # Add a series for each of the Open-High-Low-Close columns.
  #     chart.add_series(
  #       :categories => '=Sheet1!$A$2:$A$6',
  #       :values     => '=Sheet1!$B$2:$B$6',
  #       :name       => 'Open'
  #    )
  #
  #     chart.add_series(
  #       :categories => '=Sheet1!$A$2:$A$6',
  #       :values     => '=Sheet1!$C$2:$C$6',
  #       :name       => 'High'
  #    )
  #
  #     chart.add_series(
  #       :categories => '=Sheet1!$A$2:$A$6',
  #       :values     => '=Sheet1!$D$2:$D$6',
  #       :name       => 'Low'
  #    )
  #
  #     chart.add_series(
  #       :categories => '=Sheet1!$A$2:$A$6',
  #       :values     => '=Sheet1!$E$2:$E$6',
  #       :name       => 'Close'
  #    )
  #
  #     # Add a chart title and some axis labels.
  #     chart.set_title(:name => 'Open-High-Low-Close')
  #     chart.set_x_axis(:name => 'Date')
  #     chart.set_y_axis(:name => 'Share price')
  #
  #     # Insert the chart into the worksheet (with an offset).
  #     worksheet.insert_chart('F2', chart, 25, 10)
  #
  #     workbook.close
  #
  class Stock < Chart
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
    # Write the LINE chart BIFF record. A stock chart uses the same LINE record
    # as a line chart but with additional DROPBAR and CHARTLINE records to define
    # the stock style.
    #
    def store_chart_type   # :nodoc:
      record = 0x1018     # Record identifier.
      length = 0x0002     # Number of bytes to follow.
      grbit  = 0x0000     # Option flags.

      store_simple(record, length, grbit)
    end

    ###############################################################################
    #
    # _store_marker_dataformat_stream(). Overridden.
    #
    # This is an implementation of the parent abstract method to define
    # properties of markers, linetypes, pie formats and other.
    #
    def store_marker_dataformat_stream   # :nodoc:
      store_dropbar
      store_begin
      store_lineformat(0x00000000, 0x0000, 0xFFFF, 0x0001, 0x004F)
      store_areaformat(0x00FFFFFF, 0x0000, 0x01, 0x01, 0x09, 0x08)
      store_end

      store_dropbar
      store_begin
      store_lineformat(0x00000000, 0x0000, 0xFFFF, 0x0001, 0x004F)
      store_areaformat(0x0000, 0x00FFFFFF, 0x01, 0x01, 0x08, 0x09)
      store_end

      store_chartline
      store_lineformat(0x00000000, 0x0000, 0xFFFF, 0x0000, 0x004F)


      store_dataformat(0x0000, 0xFFFD, 0x0000)
      store_begin
      store_3dbarshape
      store_lineformat(0x00000000, 0x0005, 0xFFFF, 0x0000, 0x004F)
      store_areaformat(0x00000000, 0x0000, 0x00, 0x01, 0x4D, 0x4D)
      store_pieformat
      store_markerformat(0x00, 0x00, 0x00, 0x00, 0x4D, 0x4D, 0x3C)
      store_end
    end
  end
end  # class Chart

end  # module Writeexcel
