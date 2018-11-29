#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

#######################################################################
#
# Example of how to set Excel worksheet tab colours.
#
# reverse('©'), May 2006, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'

workbook   = WriteExcel.new('tab_colors.xls')

worksheet1 =  workbook.add_worksheet
worksheet2 =  workbook.add_worksheet
worksheet3 =  workbook.add_worksheet
worksheet4 =  workbook.add_worksheet

# Worsheet1 will have the default tab colour.
worksheet2.set_tab_color('red')
worksheet3.set_tab_color('green')
worksheet4.set_tab_color(0x35) # Orange

workbook.close

workbook.close
