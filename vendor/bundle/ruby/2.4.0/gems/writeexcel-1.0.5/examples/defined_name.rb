#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

###############################################################################
#
# Example of how to create defined names in a WriteExcel file.
#
# reverse('ｩ'), September 2008, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'

workbook   = WriteExcel.new('defined_name.xls')
worksheet1 = workbook.add_worksheet
worksheet2 = workbook.add_worksheet

workbook.define_name('Exchange_rate', '=0.96')
workbook.define_name('Sales',         '=Sheet1!$G$1:$H$10')
workbook.define_name('Sheet2!Sales',  '=Sheet2!$G$1:$G$10')

workbook.sheets.each do |worksheet|
  worksheet.set_column('A:A', 45)
  worksheet.write('A2', 'This worksheet contains some defined names,')
  worksheet.write('A3', 'See the Insert -> Name -> Define dialog.')
end

worksheet1.write('A4', '=Exchange_rate')

workbook.close
