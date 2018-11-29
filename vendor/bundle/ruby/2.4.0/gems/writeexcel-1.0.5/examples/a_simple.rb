#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-
#
# Example of how to use the WriteExcel module to write text and numbers
# to an Excel binary file.
#
# reverse('©'), March 2001, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
require 'writeexcel'

# Create a new workbook called simple.xls and add a worksheet
workbook  = WriteExcel.new('a_simple.xls');
worksheet = workbook.add_worksheet

# The general syntax is write(row, column, token). Note that row and
# column are zero indexed
#

# Write some text
worksheet.write(0, 0,  "Hi Excel!")


# Write some numbers
worksheet.write(2, 0,  3)          # Writes 3
worksheet.write(3, 0,  3.00000)    # Writes 3
worksheet.write(4, 0,  3.00001)    # Writes 3.00001
worksheet.write(5, 0,  3.14159)    # TeX revision no.?


# Write some formulas
worksheet.write(7, 0,  '=A3 + A6')
worksheet.write(8, 0,  '=IF(A5>3,"Yes", "No")')


# Write a hyperlink
worksheet.write(10, 0, 'http://www.perl.com/')

# File save
workbook.close
