#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-
###############################################################################
#
# Example of how to use the WriteExcel module to write hyperlinks
#
# See also hyperlink2.pl for worksheet URL examples.
#
# reverse('©'), March 2001, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
require 'writeexcel'

# Create a new workbook and add a worksheet
workbook  = WriteExcel.new("hyperlink.xls")
worksheet = workbook.add_worksheet('Hyperlinks')

# Format the first column
worksheet.set_column('A:A', 30)
worksheet.set_selection('B1')


# Add a sample format
format = workbook.add_format
format.set_size(12)
format.set_bold
format.set_color('red')
format.set_underline


# Write some hyperlinks
worksheet.write('A1', 'http://www.perl.com/'                )
worksheet.write('A3', 'http://www.perl.com/', 'Perl home'   )
worksheet.write('A5', 'http://www.perl.com/', nil, format)
worksheet.write('A7', 'mailto:jmcnamara@cpan.org', 'Mail me')

# Write a URL that isn't a hyperlink
worksheet.write_string('A9', 'http://www.perl.com/')

workbook.close
