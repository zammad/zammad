# -*- coding: utf-8 -*-
  #!/usr/bin/ruby -w

###############################################################################
#
# Example of formatting using the WriteExcel module
#
# This example shows how to use a conditional numerical format
# with colours to indicate if a share price has gone up or down.
#
# reverse('©'), March 2001, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'

# Create a new workbook and add a worksheet
workbook  = WriteExcel.new("stocks.xls")
worksheet = workbook.add_worksheet

# Set the column width for columns 1, 2, 3 and 4
worksheet.set_column(0, 3, 15)


# Create a format for the column headings
header = workbook.add_format
header.set_bold
header.set_size(12)
header.set_color('blue')


# Create a format for the stock price
f_price = workbook.add_format
f_price.set_align('left')
f_price.set_num_format('$0.00')


# Create a format for the stock volume
f_volume = workbook.add_format
f_volume.set_align('left')
f_volume.set_num_format('#,##0')


# Create a format for the price change. This is an example of a conditional
# format. The number is formatted as a percentage. If it is positive it is
# formatted in green, if it is negative it is formatted in red and if it is
# zero it is formatted as the default font colour (in this case black).
# Note: the [Green] format produces an unappealing lime green. Try
# [Color 10] instead for a dark green.
#
f_change = workbook.add_format
f_change.set_align('left')
f_change.set_num_format('[Green]0.0%;[Red]-0.0%;0.0%')


# Write out the data
worksheet.write(0, 0, 'Company', header)
worksheet.write(0, 1, 'Price',   header)
worksheet.write(0, 2, 'Volume',  header)
worksheet.write(0, 3, 'Change',  header)

worksheet.write(1, 0, 'Damage Inc.'     )
worksheet.write(1, 1, 30.25,     f_price)  # $30.25
worksheet.write(1, 2, 1234567,   f_volume) # 1,234,567
worksheet.write(1, 3, 0.085,     f_change) # 8.5% in green

worksheet.write(2, 0, 'Dump Corp.'      )
worksheet.write(2, 1, 1.56,      f_price)  # $1.56
worksheet.write(2, 2, 7564,      f_volume) # 7,564
worksheet.write(2, 3, -0.015,    f_change) # -1.5% in red

worksheet.write(3, 0, 'Rev Ltd.'        )
worksheet.write(3, 1, 0.13,      f_price)  # $0.13
worksheet.write(3, 2, 321,       f_volume) # 321
worksheet.write(3, 3, 0,         f_change) # 0 in the font color (black)


workbook.close
