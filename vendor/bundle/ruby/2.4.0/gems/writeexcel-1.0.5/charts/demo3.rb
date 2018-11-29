#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

###############################################################################
#
# Simple example of how to add an externally created chart to a Spreadsheet::
# WriteExcel file.
#
#
# This example adds an "Open-high-low-close" stock chart extracted from the
# file Chart3.xls as follows:
#
#   perl chartex.pl -c=demo3 Chart3.xls
#
#
# reverse('ｩ'), September 2004, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'

workbook  = WriteExcel.new("demo3.xls")
worksheet = workbook.add_worksheet

# Add the chart extracted using the chartex utility
chart     = workbook.add_chart_ext('demo301.bin', 'Chart1')

# Link the chart to the worksheet data using a dummy formula.
worksheet.store_formula('=Sheet1!A1')

# Add some extra formats to cover formats used in the charts.
chart_font_1 = workbook.add_format(:font_only => 1)
chart_font_2 = workbook.add_format(:font_only => 1)
chart_font_3 = workbook.add_format(:font_only => 1)
chart_font_4 = workbook.add_format(:font_only => 1)
chart_font_5 = workbook.add_format(:font_only => 1)

# Add all other formats (if any).
bold      = workbook.add_format(:bold => 1)
date_format = workbook.add_format(:num_format => 'dd/mm/yyyy')

# Adjust column widths and add some headers
worksheet.set_column('A:A', 12)

worksheet.write('A1', 'Date',  bold)
worksheet.write('B1', 'Open',  bold)
worksheet.write('C1', 'High',  bold)
worksheet.write('D1', 'Low',   bold)
worksheet.write('E1', 'Close', bold)

# Add data to range that the chart refers to.
dates = [

   "2004-08-19T",
   "2004-08-20T",
   "2004-08-23T",
   "2004-08-24T",
   "2004-08-25T",
   "2004-08-26T",
   "2004-08-27T",
   "2004-08-30T",
   "2004-08-31T",
   "2004-09-01T",
   "2004-09-02T",
   "2004-09-03T",
   "2004-09-07T",
   "2004-09-08T",
   "2004-09-09T",
   "2004-09-10T",
   "2004-09-13T",
   "2004-09-14T",
   "2004-09-15T",
   "2004-09-16T",
   "2004-09-17T",
   "2004-09-20T",
   "2004-09-21T"
]

# Open-High-Low-Close prices
prices = [

    [100.00, 104.06,  95.96, 100.34],
    [101.01, 109.08, 100.50, 108.31],
    [110.75, 113.48, 109.05, 109.40],
    [111.24, 111.60, 103.57, 104.87],
    [104.96, 108.00, 103.88, 106.00],
    [104.95, 107.95, 104.66, 107.91],
    [108.10, 108.62, 105.69, 106.15],
    [105.28, 105.49, 102.01, 102.01],
    [102.30, 103.71, 102.16, 102.37],
    [102.70, 102.97,  99.67, 100.25],
    [ 99.19, 102.37,  98.94, 101.51],
    [100.95, 101.74,  99.32, 100.01],
    [101.01, 102.00,  99.61, 101.58],
    [100.74, 103.03, 100.50, 102.30],
    [102.53, 102.71, 101.00, 102.31],
    [101.60, 106.56, 101.30, 105.33],
    [106.63, 108.41, 106.46, 107.50],
    [107.45, 112.00, 106.79, 111.49],
    [110.56, 114.23, 110.20, 112.00],
    [112.34, 115.80, 111.65, 113.97],
    [114.42, 117.49, 113.55, 117.49],
    [116.95, 121.60, 116.77, 119.36],
    [119.81, 120.42, 117.51, 117.84]
]

row = 1

dates.each do |d|
  worksheet.write_date_time(row, 0, d, date_format)
  row += 1
end
worksheet.write_col('B2', prices)

workbook.close
