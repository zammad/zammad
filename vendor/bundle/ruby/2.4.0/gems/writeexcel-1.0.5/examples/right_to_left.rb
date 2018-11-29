#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

#######################################################################
#
# Example of how to change the default worksheet direction from
# left-to-right to right-to-left as required by some eastern verions
# of Excel.
#
# reverse('©'), January 2006, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'

workbook   = WriteExcel.new("right_to_left.xls")
worksheet1 = workbook.add_worksheet
worksheet2 = workbook.add_worksheet

worksheet2.right_to_left

worksheet1.write(0, 0, 'Hello')  #  A1, B1, C1, ...
worksheet2.write(0, 0, 'Hello')  # ..., C1, B1, A1

workbook.close
