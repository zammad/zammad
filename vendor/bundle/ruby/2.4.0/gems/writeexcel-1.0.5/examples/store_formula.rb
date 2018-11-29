#!/usr/bin/env ruby

require 'writeexcel'

# Create a new workbook called simple.xls and add a worksheet
workbook  = WriteExcel.new('store_formula.xls')
worksheet = workbook.add_worksheet()

formula = worksheet.store_formula('=A1 * 3 + 50')
(0 .. 999).each do |row|
  worksheet.repeat_formula(row, 1, formula, nil, 'A1', "A#{row + 1}")
end

workbook.close
