#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

###############################################################################
#
# Example of creating a WriteExcel that is larger than the
# default 7MB limit.
#
# It is exactly that same as any other WriteExcel program except
# that is requires that the OLE::Storage module is installed.
#
# reverse('©'), Jan 2007, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
require 'writeexcel'

workbook  = WriteExcel.new('bigfile.xls')
worksheet = workbook.add_worksheet

worksheet.set_column(0, 50, 18)

0.upto(50) do |col|
  0.upto(6000) do |row|
    worksheet.write(row, col, "Row: #{row} Col: #{col}")
  end
end

workbook.close
