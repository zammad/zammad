#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

###############################################################################
#
# WriteExcel example of writing dates and times using the
# write_date_time() Worksheet method.
#
# reverse('©'), August 2004, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'

# Create a new workbook and add a worksheet
workbook  = WriteExcel.new("date_time.xls")
worksheet = workbook.add_worksheet
bold      = workbook.add_format(:bold => 1)

# Expand the first column so that the date is visible.
worksheet.set_column("A:B", 30)

# Write the column headers
worksheet.write('A1', 'Formatted date', bold)
worksheet.write('B1', 'Format',         bold)

# Examples date and time formats. In the output file compare how changing
# the format codes change the appearance of the date.
#
date_formats = [
    'dd/mm/yy',
    'mm/dd/yy',
    '',
    'd mm yy',
    'dd mm yy',
    '',
    'dd m yy',
    'dd mm yy',
    'dd mmm yy',
    'dd mmmm yy',
    '',
    'dd mm y',
    'dd mm yyy',
    'dd mm yyyy',
    '',
    'd mmmm yyyy',
    '',
    'dd/mm/yy',
    'dd/mm/yy hh:mm',
    'dd/mm/yy hh:mm:ss',
    'dd/mm/yy hh:mm:ss.000',
    '',
    'hh:mm',
    'hh:mm:ss',
    'hh:mm:ss.000',
]

# Write the same date and time using each of the above formats. The empty
# string formats create a blank line to make the example clearer.
#
row = 0
date_formats.each do |date_format|
  row += 1
  next if date_format == ''

  # Create a format for the date or time.
  format =  workbook.add_format(
                              :num_format => date_format,
                              :align      => 'left'
                             )

  # Write the same date using different formats.
  worksheet.write_date_time(row, 0, '2004-08-01T12:30:45.123', format)
  worksheet.write(row, 1, date_format)
end

# The following is an example of an invalid date. It is written as a string instead
# of a number. This is also Excel's default behaviour.
#
row += 2
worksheet.write_date_time(row, 0, '2004-13-01T12:30:45.123')
worksheet.write(row, 1, 'Invalid date. Written as string.', bold)

workbook.close
