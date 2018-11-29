#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

###############################################################################
#
# Example of how to use the WriteExcel merge_range() workbook
# method with complex formatting.
#
# reverse('©'), September 2002, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'

# Create a new workbook and add a worksheet
workbook  = WriteExcel.new('merge4.xls')
worksheet = workbook.add_worksheet

# Increase the cell size of the merged cells to highlight the formatting.
(1..11).each { |row| worksheet.set_row(row, 30) }
worksheet.set_column('B:D', 20)

###############################################################################
#
# Example 1: Text centered vertically and horizontally
#
format1 = workbook.add_format(
                                    :border  => 6,
                                    :bold    => 1,
                                    :color   => 'red',
                                    :valign  => 'vcenter',
                                    :align   => 'center'
                                   )

worksheet.merge_range('B2:D3', 'Vertical and horizontal', format1)


###############################################################################
#
# Example 2: Text aligned to the top and left
#
format2 = workbook.add_format(
                                    :border  => 6,
                                    :bold    => 1,
                                    :color   => 'red',
                                    :valign  => 'top',
                                    :align   => 'left'
                                  )

worksheet.merge_range('B5:D6', 'Aligned to the top and left', format2)

###############################################################################
#
# Example 3:  Text aligned to the bottom and right
#
format3 = workbook.add_format(
                                    :border  => 6,
                                    :bold    => 1,
                                    :color   => 'red',
                                    :valign  => 'bottom',
                                    :align   => 'right'
                                  )

worksheet.merge_range('B8:D9', 'Aligned to the bottom and right', format3)

###############################################################################
#
# Example 4:  Text justified (i.e. wrapped) in the cell
#
format4 = workbook.add_format(
                                    :border  => 6,
                                    :bold    => 1,
                                    :color   => 'red',
                                    :valign  => 'top',
                                    :align   => 'justify'
                                  )

worksheet.merge_range('B11:D12', 'Justified: '+'so on and '*18, format4)

workbook.close
