#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

################################################################################
#
# Demonstrates Spreadsheet::WriteExcel's named colors and the Excel color
# palette.
#
# The set_custom_color() Worksheet method can be used to override one of the
# built-in palette values with a more suitable colour. See the main docs.
#
# reverse('©'), March 2002, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'

workbook = WriteExcel.new("colors.xls")

# Some common formats
center  = workbook.add_format(:align => 'center')
heading = workbook.add_format(:align => 'center', :bold => 1)

######################################################################
#
# Demonstrate the named colors.
#

order = [
  0x21,
  0x0B,
  0x35,
  0x11,
  0x16,
  0x12,
  0x0D,
  0x10,
  0x17,
  0x09,
  0x0C,
  0x0F,
  0x0E,
  0x14,
  0x08,
  0x0A
]

colors = {
                0x08 => 'black',
                0x0C => 'blue',
                0x10 => 'brown',
                0x0F => 'cyan',
                0x17 => 'gray',
                0x11 => 'green',
                0x0B => 'lime',
                0x0E => 'magenta',
                0x12 => 'navy',
                0x35 => 'orange',
                0x21 => 'pink',
                0x14 => 'purple',
                0x0A => 'red',
                0x16 => 'silver',
                0x09 => 'white',
                0x0D => 'yellow',
        }

worksheet1 = workbook.add_worksheet('Named colors')

worksheet1.set_column(0, 3, 15)

worksheet1.write(0, 0, "Index", heading)
worksheet1.write(0, 1, "Index", heading)
worksheet1.write(0, 2, "Name",  heading)
worksheet1.write(0, 3, "Color", heading)

i = 1

# original was colors.each....
# order unmatch between perl and ruby (of cource, it's hash!)
# so i use order array to match perl's xls order.
#
order.each do |index|
  format = workbook.add_format(
      :fg_color => colors[index],
      :pattern  => 1,
      :border   => 1
  )

  worksheet1.write(i + 1, 0, index,                    center)
  worksheet1.write(i + 1, 1, sprintf("0x%02X", index), center)
  worksheet1.write(i + 1, 2, colors[index],            center)
  worksheet1.write(i + 1, 3, '',                       format)
  i += 1
end

######################################################################
#
# Demonstrate the standard Excel colors in the range 8..63.
#

worksheet2 = workbook.add_worksheet('Standard colors')

worksheet2.set_column(0, 3, 15)

worksheet2.write(0, 0, "Index", heading)
worksheet2.write(0, 1, "Index", heading)
worksheet2.write(0, 2, "Color", heading)
worksheet2.write(0, 3, "Name",  heading)

(8..63).each do |i|
  format = workbook.add_format(
      :fg_color => i,
      :pattern  => 1,
      :border   => 1
  )

  worksheet2.write((i - 7), 0, i,                    center)
  worksheet2.write((i - 7), 1, sprintf("0x%02X", i), center)
  worksheet2.write((i - 7), 2, '',                   format)

  # Add the  color names
  if colors.has_key?(i)
    worksheet2.write((i - 7), 3, colors[i], center)
  end
end

workbook.close
