#!/usr/bin/ruby
# -*- coding: utf-8 -*-
###############################################################################
#
# Example of how to use the WriteExcel module to write internal and internal
# hyperlinks.
#
# If you wish to run this program and follow the hyperlinks you should create
# the following directory structure:
#
#     C:\ -- Temp --+-- Europe
#                   |
#                   \-- Asia
#
#
# See also hyperlink1.rb for web URL examples.
#
# reverse('©'), March 2002, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
require 'writeexcel'

# Create three workbooks:
#   C:\Temp\Europe\Ireland.xls
#   C:\Temp\Europe\Italy.xls
#   C:\Temp\Asia\China.xls
#
ireland   = WriteExcel.new('C:\Temp\Europe\Ireland.xls')
ire_links = ireland.add_worksheet('Links')
ire_sales = ireland.add_worksheet('Sales')
ire_data  = ireland.add_worksheet('Product Data')

italy     = WriteExcel.new('C:\Temp\Europe\Italy.xls')
ita_links = italy.add_worksheet('Links')
ita_sales = italy.add_worksheet('Sales')
ita_data  = italy.add_worksheet('Product Data')

china     = WriteExcel.new('C:\Temp\Asia\China.xls')
cha_links = china.add_worksheet('Links')
cha_sales = china.add_worksheet('Sales')
cha_data  = china.add_worksheet('Product Data')

# Add a format
format = ireland.add_format(:color => 'green', :bold => 1)
ire_links.set_column('A:B', 25)


###############################################################################
#
# Examples of internal links
#
ire_links.write('A1', 'Internal links', format)

# Internal link
ire_links.write('A2', 'internal:Sales!A2')

# Internal link to a range
ire_links.write('A3', 'internal:Sales!A3:D3')

# Internal link with an alternative string
ire_links.write('A4', 'internal:Sales!A4', 'Link')

# Internal link with a format
ire_links.write('A5', 'internal:Sales!A5', format)

# Internal link with an alternative string and format
ire_links.write('A6', 'internal:Sales!A6', 'Link', format)

# Internal link (spaces in worksheet name)
ire_links.write('A7', "internal:'Product Data'!A7")


###############################################################################
#
# Examples of external links
#
ire_links.write('B1', 'External links', format)

# External link to a local file
ire_links.write('B2', 'external:Italy.xls')

# External link to a local file with worksheet
ire_links.write('B3', 'external:Italy.xls#Sales!B3')

# External link to a local file with worksheet and alternative string
ire_links.write('B4', 'external:Italy.xls#Sales!B4', 'Link')

# External link to a local file with worksheet and format
ire_links.write('B5', 'external:Italy.xls#Sales!B5', format)

# External link to a remote file, absolute path
ire_links.write('B6', 'external:c:/Temp/Asia/China.xls')

# External link to a remote file, relative path
ire_links.write('B7', 'external:../Asia/China.xls')

# External link to a remote file with worksheet
ire_links.write('B8', 'external:c:/Temp/Asia/China.xls#Sales!B8')

# External link to a remote file with worksheet (with spaces in the name)
ire_links.write('B9', "external:c:/Temp/Asia/China.xls#'Product Data'!B9")


###############################################################################
#
# Some utility links to return to the main sheet
#
ire_sales.write('A2', 'internal:Links!A2', 'Back')
ire_sales.write('A3', 'internal:Links!A3', 'Back')
ire_sales.write('A4', 'internal:Links!A4', 'Back')
ire_sales.write('A5', 'internal:Links!A5', 'Back')
ire_sales.write('A6', 'internal:Links!A6', 'Back')
ire_data.write('A7', 'internal:Links!A7', 'Back')

ita_links.write('A1', 'external:Ireland.xls#Links!B2', 'Back')
ita_sales.write('B3', 'external:Ireland.xls#Links!B3', 'Back')
ita_sales.write('B4', 'external:Ireland.xls#Links!B4', 'Back')
ita_sales.write('B5', 'external:Ireland.xls#Links!B5', 'Back')
cha_links.write('A1', 'external:../Europe/Ireland.xls#Links!B6', 'Back')
cha_sales.write('B8', 'external:../Europe/Ireland.xls#Links!B8', 'Back')
cha_data.write('B9', 'external:../Europe/Ireland.xls#Links!B9', 'Back')

ireland.close
italy.close
china.close

