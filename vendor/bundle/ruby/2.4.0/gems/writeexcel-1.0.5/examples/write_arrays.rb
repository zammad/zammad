#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

#######################################################################
#
# Example of how to use the WriteExcel module to
# write 1D and 2D arrays of data.
#
require 'writeexcel'

workbook   = WriteExcel.new("write_arrays.xls")
worksheet1 = workbook.add_worksheet('Example 1')
worksheet2 = workbook.add_worksheet('Example 2')
worksheet3 = workbook.add_worksheet('Example 3')
worksheet4 = workbook.add_worksheet('Example 4')
worksheet5 = workbook.add_worksheet('Example 5')
worksheet6 = workbook.add_worksheet('Example 6')
worksheet7 = workbook.add_worksheet('Example 7')
worksheet8 = workbook.add_worksheet('Example 8')

format     = workbook.add_format(:color => 'red', :bold => 1)
format_cmd = workbook.add_format(:color => 'blue', :bold => 1)
# Data arrays used in the following examples.
# undef values are written as blank cells (with format if specified).
#
array   =   [ 'one', 'two', nil, 'four' ]

array2d =   [
                    ['maggie', 'milly', 'molly', 'may'  ],
                    [13,       14,      15,      16     ],
                    ['shell',  'star',  'crab',  'stone'],
            ]

# 1. Write a row of data using an array.
#
#    array[0]   array[1]   array[2]
worksheet1.write('A1', "worksheet1.write('A3', array)", format_cmd)
worksheet1.write('A3', array)

# 2. Write a data using an array of array.
#
#    array[0]
#    array[1]
#    array[2]
worksheet2.write('A1', "worksheet2.write('A3', [ array ])", format_cmd)
worksheet2.write('A3', [ array ])

# 3. Write a row of data using an explicit write_row() method call.
#    This is the same as calling write() in Ex. 1 above.
#
worksheet3.write('A1', "worksheet3.write_row('A3', array)", format_cmd)
worksheet3.write_row('A3', array)

# 4. Write a column of data using the write_col() method call.
#    This is same as Ex. 2 above.
worksheet4.write('A1', "worksheet4.write_col('A3', array)", format_cmd)
worksheet4.write_col('A3', array)

# 5. Write a 2D array in col-row order.
#    array[0][0]   array[1][0]  ...
#    array[0][1]   array[1][1]  ...
#    array[0][2]   array[1][2]  ...
worksheet5.write('A1', "worksheet5.write('A3', array2d)", format_cmd)
worksheet5.write('A3', array2d)

# 6. Write a 2D array in row-col order using array of 2D array.
#    array[0][0]   array[0][1]  ...
#    array[1][0]   array[1][1]  ...
#    array[2][0]   array[2][1]  ...
worksheet6.write('A1', "worksheet6.write('A3', [ array2d ] )", format_cmd)
worksheet6.write('A3', [ array2d ] )

# 7. Write a 2D array in row-col order using write_col().
#    This is same as Ex. 6 above.
worksheet7.write('A1', "worksheet7.write_col('A3', array2d)", format_cmd)
worksheet7.write_col('A3', array2d)

# 8. Write a row of data with formatting. The blank cell is also formatted.
worksheet8.write('A1', "worksheet8.write('A3', array, format)", format_cmd)
worksheet8.write('A3', array, format)

workbook.close
