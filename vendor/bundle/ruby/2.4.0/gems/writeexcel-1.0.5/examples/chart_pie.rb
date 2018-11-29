#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-
#
###############################################################################
#
# A simple demo of Pie chart in Spreadsheet::WriteExcel.
#
# reverse('ｩ'), December 2009, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
require 'writeexcel'

# Create a new workbook called simple.xls and add a worksheet
workbook  = WriteExcel.new('chart_pie.xls')
worksheet = workbook.add_worksheet
bold      = workbook.add_format(:bold => 1)

# Add the worksheet data that the charts will refer to.
headings = ['Category', 'Values']
data = [
    [ 'Apple', 'Cherry', 'Pecan' ],
    [ 60,       30,       10     ]
]

worksheet.write('A1', headings, bold)
worksheet.write('A2', data)


###############################################################################
#
# Example 1. A minimal chart.
#
chart1 = workbook.add_chart(:type => 'Chart::Pie')

# Add values only. Use the default categories.
chart1.add_series(:values => '=Sheet1!$B$2:$B$4')

###############################################################################
#
# Example 2. A minimal chart with user specified categories and a series name.
#
chart2 = workbook.add_chart(:type => 'Chart::Pie')

# Configure the series.
chart2.add_series(
  :categories => '=Sheet1!$A$2:$A$4',
  :values     => '=Sheet1!$B$2:$B$4',
  :name       => 'Pie sales data'
)

###############################################################################
#
# Example 3. Same as previous chart but with an added title.
#
chart3 = workbook.add_chart(:type => 'Chart::Pie')

# Configure the series.
chart3.add_series(
  :categories => '=Sheet1!$A$2:$A$4',
  :values     => '=Sheet1!$B$2:$B$4',
  :name       => 'Pie sales data'
)

# Add a title.
chart3.set_title(:name => 'Popular Pie Types')

###############################################################################
#
# Example 4. Same as previous chart with a user specified chart sheet name.
#
chart4 = workbook.add_chart(:name => 'Results Chart', :type => 'Chart::Pie')

# Configure the series.
chart4.add_series(
  :categories => '=Sheet1!$A$2:$A$4',
  :values     => '=Sheet1!$B$2:$B$4',
  :name       => 'Pie sales data'
)

# The other chart_*.rb examples add a second series in example 4 but additional
# series aren't plotted in a pie chart.

# Add a title.
chart4.set_title(:name => 'Popular Pie Types')

###############################################################################
#
# Example 5. Same as Example 3 but as an embedded chart.
#
chart5 = workbook.add_chart(:type => 'Chart::Pie', :embedded => 1)

# Configure the series.
chart5.add_series(
  :categories => '=Sheet1!$A$2:$A$4',
  :values     => '=Sheet1!$B$2:$B$4',
  :name       => 'Pie sales data'
)

# Add a title.
chart5.set_title(:name => 'Popular Pie Types')

# Insert the chart into the main worksheet.
worksheet.insert_chart('D2', chart5)

# File save
workbook.close
