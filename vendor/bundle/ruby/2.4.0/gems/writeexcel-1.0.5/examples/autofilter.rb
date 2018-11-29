#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

#######################################################################
#
# Example of how to create autofilters with WriteExcel.
#
# reverse('©'), September 2007, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
require 'writeexcel'

def get_data
  [
    ['East',      'Apple',     9000,      'July'],
    ['East',      'Apple',     5000,      'July'],
    ['South',     'Orange',    9000,      'September'],
    ['North',     'Apple',     2000,      'November'],
    ['West',      'Apple',     9000,      'November'],
    ['South',     'Pear',      7000,      'October'],
    ['North',     'Pear',      9000,      'August'],
    ['West',      'Orange',    1000,      'December'],
    ['West',      'Grape',     1000,      'November'],
    ['South',     'Pear',      10000,     'April'],
    ['West',      'Grape',     6000,      'January'],
    ['South',     'Orange',    3000,      'May'],
    ['North',     'Apple',     3000,      'December'],
    ['South',     'Apple',     7000,      'February'],
    ['West',      'Grape',     1000,      'December'],
    ['East',      'Grape',     8000,      'February'],
    ['South',     'Grape',     10000,     'June'],
    ['West',      'Pear',      7000,      'December'],
    ['South',     'Apple',     2000,      'October'],
    ['East',      'Grape',     7000,      'December'],
    ['North',     'Grape',     6000,      'April'],
    ['East',      'Pear',      8000,      'February'],
    ['North',     'Apple',     7000,      'August'],
    ['North',     'Orange',    7000,      'July'],
    ['North',     'Apple',     6000,      'June'],
    ['South',     'Grape',     8000,      'September'],
    ['West',      'Apple',     3000,      'October'],
    ['South',     'Orange',    10000,     'November'],
    ['West',      'Grape',     4000,      'July'],
    ['North',     'Orange',    5000,      'August'],
    ['East',      'Orange',    1000,      'November'],
    ['East',      'Orange',    4000,      'October'],
    ['North',     'Grape',     5000,      'August'],
    ['East',      'Apple',     1000,      'December'],
    ['South',     'Apple',     10000,     'March'],
    ['East',      'Grape',     7000,      'October'],
    ['West',      'Grape',     1000,      'September'],
    ['East',      'Grape',     10000,     'October'],
    ['South',     'Orange',    8000,      'March'],
    ['North',     'Apple',     4000,      'July'],
    ['South',     'Orange',    5000,      'July'],
    ['West',      'Apple',     4000,      'June'],
    ['East',      'Apple',     5000,      'April'],
    ['North',     'Pear',      3000,      'August'],
    ['East',      'Grape',     9000,      'November'],
    ['North',     'Orange',    8000,      'October'],
    ['East',      'Apple',     10000,     'June'],
    ['South',     'Pear',      1000,      'December'],
    ['North',     'Grape',     10000,     'July'],
    ['East',      'Grape',     6000,      'February'],
  ]
end

#######################################################################
#
#  Main
#

xlsfile = 'autofilter.xls'

workbook = WriteExcel.new(xlsfile)

worksheet1 = workbook.add_worksheet
worksheet2 = workbook.add_worksheet
worksheet3 = workbook.add_worksheet
worksheet4 = workbook.add_worksheet
worksheet5 = workbook.add_worksheet
worksheet6 = workbook.add_worksheet

bold       = workbook.add_format(:bold => 1)

# Extract the data embedded at the end of this file.
headings = %w(Region    Item      Volume    Month)
data = get_data

# Set up several sheets with the same data.
workbook.sheets.each do |worksheet|
    worksheet.set_column('A:D', 12)
    worksheet.set_row(0, 20, bold)
    worksheet.write('A1', headings)
end

###############################################################################
#
# Example 1. Autofilter without conditions.
#

worksheet1.autofilter('A1:D51')
worksheet1.write('A2', [data])

###############################################################################
#
#
# Example 2. Autofilter with a filter condition in the first column.
#

# The range in this example is the same as above but in row-column notation.
worksheet2.autofilter(0, 0, 50, 3)

# The placeholder "Region" in the filter is ignored and can be any string
# that adds clarity to the expression.
#
worksheet2.filter_column(0, 'Region eq East')

#
# Hide the rows that don't match the filter criteria.
#
row = 1

data.each do |row_data|
    region = row_data[0]

    if region == 'East'
        # Row is visible.
    else
        # Hide row.
        worksheet2.set_row(row, nil, nil, 1)
    end

    worksheet2.write(row, 0, row_data)
    row += 1
end


###############################################################################
#
#
# Example 3. Autofilter with a dual filter condition in one of the columns.
#

worksheet3.autofilter('A1:D51')

worksheet3.filter_column('A', 'x eq East or x eq South')

#
# Hide the rows that don't match the filter criteria.
#
row = 1

data.each do |row_data|
    region = row_data[0]

    if region == 'East' || region == 'South'
        # Row is visible.
    else
        # Hide row.
        worksheet3.set_row(row, nil, nil, 1)
    end

    worksheet3.write(row, 0, row_data)
    row += 1
end


###############################################################################
#
#
# Example 4. Autofilter with filter conditions in two columns.
#

worksheet4.autofilter('A1:D51')

worksheet4.filter_column('A', 'x eq East')
worksheet4.filter_column('C', 'x > 3000 and x < 8000' )

#
# Hide the rows that don't match the filter criteria.
#
row = 1

data.each do |row_data|
    region = row_data[0]
    volume = row_data[2]

    if region == 'East' && volume >  3000   && volume < 8000
        # Row is visible.
    else
        # Hide row.
        worksheet4.set_row(row, nil, nil, 1)
    end

    worksheet4.write(row, 0, row_data)
    row += 1
end


###############################################################################
#
#
# Example 5. Autofilter with filter for blanks.
#

# Create a blank cell in our test data.
data[5][0] = ''

worksheet5.autofilter('A1:D51')
worksheet5.filter_column('A', 'x == Blanks')

#
# Hide the rows that don't match the filter criteria.
#
row = 1

data.each do |row_data|
    region = row_data[0]

    if region == ''
        # Row is visible.
    else
        # Hide row.
        worksheet5.set_row(row, nil, nil, 1)
    end

    worksheet5.write(row, 0, row_data)
    row += 1
end


###############################################################################
#
#
# Example 6. Autofilter with filter for non-blanks.
#

worksheet6.autofilter('A1:D51')
worksheet6.filter_column('A', 'x == NonBlanks')

#
# Hide the rows that don't match the filter criteria.
#
row = 1

data.each do |row_data|
    region = row_data[0]

    if region != ''
        # Row is visible.
    else
        # Hide row.
        worksheet6.set_row(row, nil, nil, 1)
    end

    worksheet6.write(row, 0, row_data)
    row += 1
end

workbook.close


