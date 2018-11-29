#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

###############################################################################
#
# Example of how to use the format copying method with WriteExcel #
# reverse('©'), March 2001, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
require 'writeexcel'

# Create workbook1
workbook1       = WriteExcel.new("workbook1.xls")
worksheet1      = workbook1.add_worksheet
format1a        = workbook1.add_format
format1b        = workbook1.add_format

# Create workbook2
workbook2       = WriteExcel.new("workbook2.xls")
worksheet2      = workbook2.add_worksheet
format2a        = workbook2.add_format
format2b        = workbook2.add_format

# Create a global format object that isn't tied to a workbook
global_format   = Format.new

# Set the formatting
global_format.set_color('blue')
global_format.set_bold
global_format.set_italic

# Create another example format
format1b.set_color('red')

# Copy the global format properties to the worksheet formats
format1a.copy(global_format)
format2a.copy(global_format)

# Copy a format from worksheet1 to worksheet2
format2b.copy(format1b)

# Write some output
worksheet1.write(0, 0, "Ciao", format1a)
worksheet1.write(1, 0, "Ciao", format1b)

worksheet2.write(0, 0, "Hello", format2a)
worksheet2.write(1, 0, "Hello", format2b)
workbook1.close
workbook2.close
