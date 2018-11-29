#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

###############################################################################
#
# This is a simple example of how to use functions with the
# WriteExcel module.
#
# reverse('©'), March 2001, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'
xlsfile = 'stats.xls'

workbook = WriteExcel.new(xlsfile)
worksheet = workbook.add_worksheet('Test data')

# Set the column width for columns 1
worksheet.set_column(0, 0, 20)


# Create a format for the headings
format = workbook.add_format
format.set_bold


# Write the sample data
worksheet.write(0, 0, 'Sample', format)
worksheet.write(0, 1, 1)
worksheet.write(0, 2, 2)
worksheet.write(0, 3, 3)
worksheet.write(0, 4, 4)
worksheet.write(0, 5, 5)
worksheet.write(0, 6, 6)
worksheet.write(0, 7, 7)
worksheet.write(0, 8, 8)

worksheet.write(1, 0, 'Length', format)
worksheet.write(1, 1, 25.4)
worksheet.write(1, 2, 25.4)
worksheet.write(1, 3, 24.8)
worksheet.write(1, 4, 25.0)
worksheet.write(1, 5, 25.3)
worksheet.write(1, 6, 24.9)
worksheet.write(1, 7, 25.2)
worksheet.write(1, 8, 24.8)

# Write some statistical functions
worksheet.write(4,  0, 'Count', format)
worksheet.write(4,  1, '=COUNT(B1:I1)')

worksheet.write(5,  0, 'Sum', format)
worksheet.write(5,  1, '=SUM(B2:I2)')

worksheet.write(6,  0, 'Average', format)
worksheet.write(6,  1, '=AVERAGE(B2:I2)')

worksheet.write(7,  0, 'Min', format)
worksheet.write(7,  1, '=MIN(B2:I2)')

worksheet.write(8,  0, 'Max', format)
worksheet.write(8,  1, '=MAX(B2:I2)')

worksheet.write(9,  0, 'Standard Deviation', format)
worksheet.write(9,  1, '=STDEV(B2:I2)')

worksheet.write(10, 0, 'Kurtosis', format)
worksheet.write(10, 1, '=KURT(B2:I2)')

workbook.close

