#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

###############################################################################
#
# Example of how to use the WriteExcel merge_cells() workbook
# method with complex formatting and rotation.
#
#
# reverse('©'), September 2002, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'

# Create a new workbook and add a worksheet
workbook  = WriteExcel.new('merge5.xls')
worksheet = workbook.add_worksheet


# Increase the cell size of the merged cells to highlight the formatting.
(3..8).each { |col| worksheet.set_row(col, 36) }
[1, 3, 5].each { |n| worksheet.set_column(n, n, 15) }


###############################################################################
#
# Rotation 1, letters run from top to bottom
#
format1 = workbook.add_format(
                                    :border      => 6,
                                    :bold        => 1,
                                    :color       => 'red',
                                    :valign      => 'vcentre',
                                    :align       => 'centre',
                                    :rotation    => 270
                                  )


worksheet.merge_range('B4:B9', 'Rotation 270', format1)


###############################################################################
#
# Rotation 2, 90° anticlockwise
#
format2 = workbook.add_format(
                                    :border      => 6,
                                    :bold        => 1,
                                    :color       => 'red',
                                    :valign      => 'vcentre',
                                    :align       => 'centre',
                                    :rotation    => 90
                                  )


worksheet.merge_range('D4:D9', 'Rotation 90°', format2)



###############################################################################
#
# Rotation 3, 90° clockwise
#
format3 = workbook.add_format(
                                    :border      => 6,
                                    :bold        => 1,
                                    :color       => 'red',
                                    :valign      => 'vcentre',
                                    :align       => 'centre',
                                    :rotation    => -90
                                  )


worksheet.merge_range('F4:F9', 'Rotation -90°', format3)

workbook.close
