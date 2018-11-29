# -*- coding: utf-8 -*-
  #!/usr/bin/ruby -w

######################################################################
#
# Example of writing repeated formulas.
#
# reverse('©'), August 2002, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'

workbook  = WriteExcel.new("repeat.xls")
worksheet = workbook.add_worksheet

limit = 1000

# Write a column of numbers
0.upto(limit) do |row|
  worksheet.write(row, 0,  row)
end

# Store a formula
formula = worksheet.store_formula('=A1*5+4')

# Write a column of formulas based on the stored formula
0.upto(limit) do |row|
  worksheet.repeat_formula(row, 1, formula, nil,
                                      /A1/, 'A'+(row+1).to_s)
end

# Direct formula writing. As a speed comparison uncomment the
# following and run the program again

#for row (0..limit) {
#    worksheet.write_formula(row, 2, '=A'.(row+1).'*5+4')
#}

workbook.close
