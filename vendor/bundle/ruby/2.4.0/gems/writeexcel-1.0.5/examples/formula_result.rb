#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

#######################################################################
#
# Example of how to write Spreadsheet::WriteExcel formulas with a user
# specified result.
#
# This is generally only required when writing a spreadsheet for an
# application other than Excel where the formula isn't evaluated.
#
# reverse('©'), August 2005, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'

workbook  = WriteExcel.new('formula_result.xls')
worksheet = workbook.add_worksheet()
format    = workbook.add_format(:color => 'blue')

worksheet.write('A1', '=1+2')
worksheet.write('A2', '=1+2',                     format, 4)
worksheet.write('A3', '="ABC"',                   nil,    'DEF')
worksheet.write('A4', '=IF(A1 > 1, TRUE, FALSE)', nil,    'TRUE')
worksheet.write('A5', '=1/0',                     nil,    '#DIV/0!')

workbook.close
