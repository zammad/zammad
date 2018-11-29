#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

##############################################################################
#
# A simple formatting example using Spreadsheet::WriteExcel.
#
# This program demonstrates the indentation cell format.
#
# reverse('©'), May 2004, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#


require 'writeexcel'

workbook  = WriteExcel.new('indent.xls')

worksheet = workbook.add_worksheet()
indent1   = workbook.add_format(:indent => 1)
indent2   = workbook.add_format(:indent => 2)

worksheet.set_column('A:A', 40)


worksheet.write('A1', "This text is indented 1 level",  indent1)
worksheet.write('A2', "This text is indented 2 levels", indent2)

workbook.close
