#!/usr/bin/ruby
# -*- coding: utf-8 -*-
#
###############################################################################
#
# Chart legend visible/invisible sample.
#
# copyright 2013 Hideo NAKAMURA, cxn03651@msj.biglobe.ne.jp
#
require 'writeexcel'

# Create a new workbook called chart_legend.xls and add a worksheet
workbook  = WriteExcel.new('chart_legend.xls')
worksheet = workbook.add_worksheet
bold      = workbook.add_format(:bold => 1)

# Add the worksheet data that the charts will refer to.
headings = [ 'Category', 'Values 1', 'Values 2' ]
data = [
    [ 2, 3, 4, 5, 6, 7 ],
    [ 1, 4, 5, 2, 1, 5 ],
    [ 3, 6, 7, 5, 4, 3 ]
]

worksheet.write('A1', headings, bold)
worksheet.write('A2', data)

#
# chart with legend
#
chart1 = workbook.add_chart(:type => 'Chart::Area', :embedded => 1)
chart1.add_series( :values => '=Sheet1!$B$2:$B$7' )
worksheet.insert_chart('E2', chart1)

#
# chart without legend
#
chart2 = workbook.add_chart(:type => 'Chart::Area', :embedded => 1)
chart2.add_series( :values => '=Sheet1!$B$2:$B$7' )
chart2.set_legend(:position => 'none')
worksheet.insert_chart('E27', chart2)

workbook.close
