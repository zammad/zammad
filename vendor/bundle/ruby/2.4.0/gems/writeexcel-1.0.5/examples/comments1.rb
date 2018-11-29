#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

###############################################################################
#
# This example demonstrates writing cell comments.
#
# A cell comment is indicated in Excel by a small red triangle in the upper
# right-hand corner of the cell.
#
# For more advanced comment options see comments2.pl.
#
# reverse('©'), November 2005, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'

workbook  = WriteExcel.new("comments1.xls")
worksheet = workbook.add_worksheet

worksheet.write('A1', 'Hello')
worksheet.write_comment('A1', 'This is a comment')

workbook.close
