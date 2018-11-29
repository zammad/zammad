#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

###############################################################################
#
# Simple example of how to add an externally created chart to a Spreadsheet::
# WriteExcel file.
#
#
# This example adds a line chart extracted from the file Chart1.xls as follows:
#
#   perl chartex.pl -c=demo5 Chart5.xls
#
#
# reverse('ｩ'), September 2004, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'

workbook  = WriteExcel.new("demo5.xls")
worksheet = workbook.add_worksheet

# Add the chart extracted using the chartex utility
worksheet.embed_chart('D3', 'demo501.bin')

# Link the chart to the worksheet data using a dummy formula.
worksheet.store_formula('=Sheet1!A1')


# Add some extra formats to cover formats used in the charts.
chart_font_1 = workbook.add_format(:font_only => 1)
chart_font_2 = workbook.add_format(:font_only => 1)

# Add all other formats.

# Add data to range that the chart refers to.
nums    = [0, 1, 2, 3, 4,  5,  6,  7,  8,  9,  10 ]
squares = [0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100]



worksheet.write_col('A1', nums)
worksheet.write_col('B1', squares)

workbook.close
