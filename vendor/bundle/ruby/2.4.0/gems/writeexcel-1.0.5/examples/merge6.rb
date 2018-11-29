#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

###############################################################################
#
# Example of how to use the Spreadsheet::WriteExcel merge_cells() workbook
# method with Unicode strings.
#
#
# reverse('©'), December 2005, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'

# Create a new workbook and add a worksheet
workbook  = WriteExcel.new('merge6.xls')
worksheet = workbook.add_worksheet

# Increase the cell size of the merged cells to highlight the formatting.
(2..9).each { |i| worksheet.set_row(i, 36) }
worksheet.set_column('B:D', 25)

# Format for the merged cells.
format = workbook.add_format(
           :border      => 6,
           :bold        => 1,
           :color       => 'red',
           :size        => 20,
           :valign      => 'vcentre',
           :align       => 'left',
           :indent      => 1
  )

###############################################################################
#
# Write an Ascii string.
#

worksheet.merge_range('B3:D4', 'ASCII: A simple string', format)

###############################################################################
#
# Write a UTF-16 Unicode string.
#

# A phrase in Cyrillic encoded as UTF-16BE.
utf16_str = [
  '005500540046002d00310036003a0020' <<
  '042d0442043e002004440440043004370430002004' <<
  '3d043000200440044304410441043a043e043c0021'
].pack("H*")

# Note the extra parameter at the end to indicate UTF-16 encoding.
worksheet.merge_range('B6:D7', utf16_str, format, 1)

###############################################################################
#
# Write a UTF-8 Unicode string.
#

smiley = '☺'  # chr 0x263a in perl
worksheet.merge_range('B9:D10', "UTF-8: A Unicode smiley #{smiley}", format)

workbook.close
