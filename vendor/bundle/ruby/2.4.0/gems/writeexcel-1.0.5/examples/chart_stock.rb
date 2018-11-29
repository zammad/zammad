#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-
#
###############################################################################
#
# A simple demo of Stock charts in Spreadsheet::WriteExcel.
#
# reverse('©'), January 2010, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
require 'writeexcel'

workbook  = WriteExcel.new('chart_stock.xls')
worksheet = workbook.add_worksheet

###############################################################################
#
# Set up the data worksheet that the charts will refer to. We read the example
# data from the __DATA__ section at the end of the file. This simulates
# reading the data from a database or other source.
#
# The default Excel Stock chart is an Open-High-Low-Close chart. Therefore
# we will need data for each of those series.
#
# The layout of the __DATA__ section is similar to the layout of the worksheet.
#

# Add some formats.
bold        = workbook.add_format(:bold       => 1)
date_format = workbook.add_format(:num_format => 'dd/mm/yyyy')

# Increase the width of the column used for date to make it clearer.
worksheet.set_column('A:A', 12)

stock_data = [
  %w(Date        Open    High    Low     Close),
  ['2009-08-19', 100.00, 104.06, 95.96, 100.34],
  ['2009-08-20', 101.01, 109.08, 100.50, 108.31],
  ['2009-08-23', 110.75, 113.48, 109.05, 109.40],
  ['2009-08-24', 111.24, 111.60, 103.57, 104.87],
  ['2009-08-25', 104.96, 108.00, 103.88, 106.00],
  ['2009-08-26', 104.95, 107.95, 104.66, 107.91],
  ['2009-08-27', 108.10, 108.62, 105.69, 106.15],
  ['2009-08-30', 105.28, 105.49, 102.01, 102.01],
  ['2009-08-31', 102.30, 103.71, 102.16, 102.37]
]

# Write the data to the worksheet.
row = 0
col = 0

headers = stock_data.shift
worksheet.write(row, col, headers, bold)
row += 1

stock_data.each do |data|
  date = data.shift
  worksheet.write(row, col, date, date_format)
  worksheet.write(row, col + 1, data)
  row += 1
end

###############################################################################
#
# Example 1. A default Open-High-Low-Close chart with series names, axes labels
#            and a title.
#

chart1 = workbook.add_chart(:type => 'Chart::Stock')

# Add a series for each of the Open-High-Low-Close columns. The categories are
# the dates in the first column.

chart1.add_series(
  :categories => '=Sheet1!$A$2:$A$10',
  :values     => '=Sheet1!$B$2:$B$10',
  :name       => 'Open'
)

chart1.add_series(
  :categories => '=Sheet1!$A$2:$A$10',
  :values     => '=Sheet1!$C$2:$C$10',
  :name       => 'High'
)

chart1.add_series(
  :categories => '=Sheet1!$A$2:$A$10',
  :values     => '=Sheet1!$D$2:$D$10',
  :name       => 'Low'
)

chart1.add_series(
  :categories => '=Sheet1!$A$2:$A$10',
  :values     => '=Sheet1!$E$2:$E$10',
  :name       => 'Close'
)

# Add a chart title and axes labels.
chart1.set_title(:name => 'Open-High-Low-Close')
chart1.set_x_axis(:name => 'Date')
chart1.set_y_axis(:name => 'Share price')

###############################################################################
#
# Example 2. Same as the previous as an embedded chart.
#

chart2 = workbook.add_chart(:type => 'Chart::Stock', :embedded => 1)

# Add a series for each of the Open-High-Low-Close columns. The categories are
# the dates in the first column.

chart2.add_series(
  :categories => '=Sheet1!$A$2:$A$10',
  :values     => '=Sheet1!$B$2:$B$10',
  :name       => 'Open'
)

chart2.add_series(
  :categories => '=Sheet1!$A$2:$A$10',
  :values     => '=Sheet1!$C$2:$C$10',
  :name       => 'High'
)

chart2.add_series(
  :categories => '=Sheet1!$A$2:$A$10',
  :values     => '=Sheet1!$D$2:$D$10',
  :name       => 'Low'
)

chart2.add_series(
  :categories => '=Sheet1!$A$2:$A$10',
  :values     => '=Sheet1!$E$2:$E$10',
  :name       => 'Close'
)

# Add a chart title and axes labels.
chart2.set_title(:name => 'Open-High-Low-Close')
chart2.set_x_axis(:name => 'Date')
chart2.set_y_axis(:name => 'Share price')

# Insert the chart into the main worksheet.
worksheet.insert_chart('G2', chart2)

# File save
workbook.close
