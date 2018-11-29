# -*- coding: utf-8 -*-
###############################################################################
#
# Bar - A writer class for Excel Bar charts.
#
# Used in conjunction with Chart.
#
# See formatting note in Chart.
#
# Copyright 2000-2010, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel/chart'

module Writeexcel

class Chart

  #
  # ==SYNOPSIS
  #
  # To create a simple Excel file with a Bar chart using WriteExcel:
  #
  #    #!/usr/bin/ruby -w
  #
  #    require 'writeexcel'
  #
  #    workbook  = WriteExcel.new('chart.xls')
  #    worksheet = workbook.add_worksheet
  #
  #    chart     = workbook.add_chart(:type => 'Chart::Bar')
  #
  #    # Configure the chart.
  #    chart.add_series(
  #      :categories => '=Sheet1!$A$2:$A$7',
  #      :values     => '=Sheet1!$B$2:$B$7',
  #   )
  #
  #    # Add the worksheet data the chart refers to.
  #    data = [
  #        [ 'Category', 2, 3, 4, 5, 6, 7 ],
  #        [ 'Value',    1, 4, 5, 2, 1, 5 ]
  #    ]
  #
  #    worksheet.write('A1', data)
  #
  #    workbook.close
  #
  # ==DESCRIPTION
  #
  # This module implements Bar charts for WriteExcel. The chart object is
  #  created via the Workbook add_chart method:
  #
  #    chart = workbook.add_chart(:type => 'Chart::Bar')
  #
  # Once the object is created it can be configured via the following methods
  # that are common to all chart classes:
  #
  #    chart.add_series
  #    chart.set_x_axis
  #    chart.set_y_axis
  #    chart.set_title
  #
  # These methods are explained in detail in Chart section of WriteExcel.
  # Class specific methods or settings, if any, are explained below.
  #
  # ==Bar Chart Methods
  #
  # There aren't currently any bar chart specific methods. See the TODO
  # section of Chart of Writeexcel.
  #
  # ==EXAMPLE
  #
  # Here is a complete example that demonstrates most of the available
  # features when creating a chart.
  #
  #    #!/usr/bin/ruby -w
  #
  #    require 'writeexcel'
  #
  #    workbook  = WriteExcel.new('chart_bar.xls')
  #    worksheet = workbook.add_worksheet
  #    bold      = workbook.add_format(:bold => 1)
  #
  #    # Add the worksheet data that the charts will refer to.
  #    headings = [ 'Number', 'Sample 1', 'Sample 2' ]
  #    data = [
  #        [ 2, 3, 4, 5, 6, 7 ],
  #        [ 1, 4, 5, 2, 1, 5 ],
  #        [ 3, 6, 7, 5, 4, 3 ]
  #    ]
  #
  #    worksheet.write('A1', headings, bold)
  #    worksheet.write('A2', data)
  #
  #    # Create a new chart object. In this case an embedded chart.
  #    chart = workbook.add_chart(:type => 'Chart::Bar', :embedded => 1)
  #
  #    # Configure the first series. (Sample 1)
  #    chart.add_series(
  #      :name       => 'Sample 1',
  #      :categories => '=Sheet1!$A$2:$A$7',
  #      :values     => '=Sheet1!$B$2:$B$7',
  #   )
  #
  #    # Configure the second series. (Sample 2)
  #    chart.add_series(
  #      :name       => 'Sample 2',
  #      :categories => '=Sheet1!$A$2:$A$7',
  #      :values     => '=Sheet1!$C$2:$C$7',
  #   )
  #
  #    # Add a chart title and some axis labels.
  #    chart.set_title (:name => 'Results of sample analysis')
  #    chart.set_x_axis(:name => 'Test number')
  #    chart.set_y_axis(:name => 'Sample length (cm)')
  #
  #    # Insert the chart into the worksheet (with an offset).
  #    worksheet.insert_chart('D2', chart, 25, 10)
  #
  #    workbook.close
  #
  class Bar < Chart
    ###############################################################################
    #
    # new()
    #
    #
    def initialize(*args)   # :nodoc:
      super
      @config[:x_axis_text]     = [ 0x2D,   0x6D9,  0x5F,   0x1CC, 0x281,  0x0, 90 ]
      @config[:x_axis_text_pos] = [ 2,      2,      0,      0,     0x17,   0x2A ]
      @config[:y_axis_text]     = [ 0x078A, 0x0DFC, 0x011D, 0x9C,  0x0081, 0x0000 ]
      @config[:y_axis_text_pos] = [ 2,      2,      0,      0,     0x45,   0x17 ]
    end

    ###############################################################################
    #
    # _store_chart_type()
    #
    # Implementation of the abstract method from the specific chart class.
    #
    # Write the BAR chart BIFF record. Defines a bar or column chart type.
    #
    def store_chart_type  # :nodoc:
      record    = 0x1017     # Record identifier.
      length    = 0x0006     # Number of bytes to follow.
      pcOverlap = 0x0000     # Space between bars.
      pcGap     = 0x0096     # Space between cats.
      grbit     = 0x0001     # Option flags.

      store_simple(record, length, pcOverlap, pcGap, grbit)
    end

    ###############################################################################
    #
    # _set_embedded_config_data()
    #
    # Override some of the default configuration data for an embedded chart.
    #
    def set_embedded_config_data   # :nodoc:
      # Set the parent configuration first.
      super

      # The axis positions are reversed for a bar chart so we change the config.
      @config[:x_axis_text]     = [ 0x57,   0x5BC,  0xB5,   0x214, 0x281, 0x0, 90 ]
      @config[:x_axis_text_pos] = [ 2,      2,      0,      0,     0x17,  0x2A ]
      @config[:y_axis_text]     = [ 0x074A, 0x0C8F, 0x021F, 0x123, 0x81,  0x0000 ]
      @config[:y_axis_text_pos] = [ 2,      2,      0,      0,     0x45,  0x17 ]
    end
  end
end  # class Chart

end  # module Writeexcel
