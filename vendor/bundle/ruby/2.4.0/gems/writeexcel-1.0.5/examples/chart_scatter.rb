#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-
#
###############################################################################
#
# A simple demo of Scatter charts in Spreadsheet::WriteExcel.
#
# reverse('ｩ'), December 2009, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
require 'writeexcel'

# Create a new workbook called simple.xls and add a worksheet
workbook  = WriteExcel.new('chart_scatter.xls')
worksheet = workbook.add_worksheet
bold      = workbook.add_format(:bold => 1)

# Add the worksheet data that the charts will refer to.
headings = ['Category', 'Values 1', 'Values 2']
data = [
  [ 2, 3, 4, 5, 6, 7 ],
  [ 1, 4, 5, 2, 1, 5 ],
  [ 3, 6, 7, 5, 4, 3 ]
]

worksheet.write('A1', headings, bold)
worksheet.write('A2', data)


###############################################################################
#
# Example 1. A minimal chart.
#
chart1 = workbook.add_chart(:type => 'Chart::Scatter')

# Add values only. Use the default categories.
chart1.add_series(:values => '=Sheet1!$B$2:$B$7')

###############################################################################
#
# Example 2. A minimal chart with user specified categories (X axis)
#            and a series name.
#
chart2 = workbook.add_chart(:type => 'Chart::Scatter')

# Configure the series.
chart2.add_series(
  :categories => '=Sheet1!$A$2:$A$7',
  :values     => '=Sheet1!$B$2:$B$7',
  :name       => 'Test data series 1'
)

###############################################################################
#
# Example 3. Same as previous chart but with added title and axes labels.
#
chart3 = workbook.add_chart(:type => 'Chart::Scatter')

# Configure the series.
chart3.add_series(
  :categories => '=Sheet1!$A$2:$A$7',
  :values     => '=Sheet1!$B$2:$B$7',
  :name       => 'Test data series 1'
)

# Add some labels.
chart3.set_title(:name => 'Results of sample analysis')
chart3.set_x_axis(:name => 'Sample number')
chart3.set_y_axis(:name => 'Sample length (cm)')

###############################################################################
#
# Example 4. Same as previous chart but with an added series and with a
#            user specified chart sheet name.
#
chart4 = workbook.add_chart(:name => 'Results Chart', :type => 'Chart::Scatter')

# Configure the series.
chart4.add_series(
  :categories => '=Sheet1!$A$2:$A$7',
  :values     => '=Sheet1!$B$2:$B$7',
  :name       => 'Test data series 1'
)

# Add another series.
chart4.add_series(
  :categories => '=Sheet1!$A$2:$A$7',
  :values     => '=Sheet1!$C$2:$C$7',
  :name       => 'Test data series 2'
)

# Add some labels.
chart4.set_title(:name => 'Results of sample analysis')
chart4.set_x_axis(:name => 'Sample number')
chart4.set_y_axis(:name => 'Sample length (cm)')

###############################################################################
#
# Example 5. Same as Example 3 but as an embedded chart.
#
chart5 = workbook.add_chart(:type => 'Chart::Scatter', :embedded => 1)

# Configure the series.
chart5.add_series(
  :categories => '=Sheet1!$A$2:$A$7',
  :values     => '=Sheet1!$B$2:$B$7',
  :name       => 'Test data series 1'
)

# Add some labels.
chart5.set_title(:name => 'Results of sample analysis')
chart5.set_x_axis(:name => 'Sample number')
chart5.set_y_axis(:name => 'Sample length (cm)')

# Insert the chart into the main worksheet.
worksheet.insert_chart('E2', chart5)

# File save
workbook.close
