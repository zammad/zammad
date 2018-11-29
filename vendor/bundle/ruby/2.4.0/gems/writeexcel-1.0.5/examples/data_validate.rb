#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

###############################################################################
#
# Example of how to add data validation and dropdown lists to a
# WriteExcel file.
#
# reverse('©'), August 2008, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'

workbook  = WriteExcel.new('data_validate.xls')
worksheet = workbook.add_worksheet

# Add a format for the header cells.
header_format = workbook.add_format(
                                            :border      => 1,
                                            :bg_color    => 43,
                                            :bold        => 1,
                                            :text_wrap   => 1,
                                            :valign      => 'vcenter',
                                            :indent      => 1
                                         )

# Set up layout of the worksheet.
worksheet.set_column('A:A', 64)
worksheet.set_column('B:B', 15)
worksheet.set_column('D:D', 15)
worksheet.set_row(0, 36)
worksheet.set_selection('B3')


# Write the header cells and some data that will be used in the examples.
row = 0
heading1 = 'Some examples of data validation in WriteExcel'
heading2 = 'Enter values in this column'
heading3 = 'Sample Data'

worksheet.write('A1', heading1, header_format)
worksheet.write('B1', heading2, header_format)
worksheet.write('D1', heading3, header_format)

worksheet.write('D3', ['Integers',   1, 10])
worksheet.write('D4', ['List data', 'open', 'high', 'close'])
worksheet.write('D5', ['Formula',   '=AND(F5=50,G5=60)', 50, 60])


#
# Example 1. Limiting input to an integer in a fixed range.
#
txt = 'Enter an integer between 1 and 10'
row += 2

worksheet.write(row, 0, txt)
worksheet.data_validation(row, 1,
    {
        :validate        => 'integer',
        :criteria        => 'between',
        :minimum         => 1,
        :maximum         => 10
    })


#
# Example 2. Limiting input to an integer outside a fixed range.
#
txt = 'Enter an integer that is not between 1 and 10 (using cell references)'
row += 2

worksheet.write(row, 0, txt)
worksheet.data_validation(row, 1,
    {
        :validate        => 'integer',
        :criteria        => 'not between',
        :minimum         => '=E3',
        :maximum         => '=F3'
    })


#
# Example 3. Limiting input to an integer greater than a fixed value.
#
txt = 'Enter an integer greater than 0'
row += 2

worksheet.write(row, 0, txt)
worksheet.data_validation(row, 1,
    {
        :validate        => 'integer',
        :criteria        => '>',
        :value           => 0
    })


#
# Example 4. Limiting input to an integer less than a fixed value.
#
txt = 'Enter an integer less than 10'
row += 2

worksheet.write(row, 0, txt)
worksheet.data_validation(row, 1,
    {
        :validate        => 'integer',
        :criteria        => '<',
        :value           => 10
    })


#
# Example 5. Limiting input to a decimal in a fixed range.
#
txt = 'Enter a decimal between 0.1 and 0.5'
row += 2

worksheet.write(row, 0, txt)
worksheet.data_validation(row, 1,
    {
        :validate        => 'decimal',
        :criteria        => 'between',
        :minimum         => 0.1,
        :maximum         => 0.5
    })


#
# Example 6. Limiting input to a value in a dropdown list.
#
txt = 'Select a value from a drop down list'
row += 2
worksheet.write(row, 0, txt)
worksheet.data_validation(row, 1,
    {
        :validate        => 'list',
        :source          => ['open', 'high', 'close']
    })


#
# Example 6. Limiting input to a value in a dropdown list.
#
txt = 'Select a value from a drop down list (using a cell range)'
row += 2

worksheet.write(row, 0, txt)
worksheet.data_validation(row, 1,
    {
        :validate        => 'list',
        :source          => '=$E$4:$G$4'
    })


#
# Example 7. Limiting input to a date in a fixed range.
#
txt = 'Enter a date between 1/1/2008 and 12/12/2008'
row += 2

worksheet.write(row, 0, txt)
worksheet.data_validation(row, 1,
    {
        :validate        => 'date',
        :criteria        => 'between',
        :minimum         => '2008-01-01T',
        :maximum         => '2008-12-12T'
    })


#
# Example 8. Limiting input to a time in a fixed range.
#
txt = 'Enter a time between 6:00 and 12:00'
row += 2

worksheet.write(row, 0, txt)
worksheet.data_validation(row, 1,
    {
        :validate        => 'time',
        :criteria        => 'between',
        :minimum         => 'T06:00',
        :maximum         => 'T12:00'
    })


#
# Example 9. Limiting input to a string greater than a fixed length.
#
txt = 'Enter a string longer than 3 characters'
row += 2

worksheet.write(row, 0, txt)
worksheet.data_validation(row, 1,
    {
        :validate        => 'length',
        :criteria        => '>',
        :value           => 3
    })


#
# Example 10. Limiting input based on a formula.
#
txt = 'Enter a value if the following is true "=AND(F5=50,G5=60)"'
row += 2

worksheet.write(row, 0, txt)
worksheet.data_validation(row, 1,
    {
        :validate        => 'custom',
        :value           => '=AND(F5=50,G5=60)'
    })


#
# Example 11. Displaying and modify data validation messages.
#
txt = 'Displays a message when you select the cell'
row += 2

worksheet.write(row, 0, txt)
worksheet.data_validation(row, 1,
    {
        :validate      => 'integer',
        :criteria      => 'between',
        :minimum       => 1,
        :maximum       => 100,
        :input_title   => 'Enter an integer:',
        :input_message => 'between 1 and 100'
    })


#
# Example 12. Displaying and modify data validation messages.
#
txt = 'Display a custom error message when integer isn\'t between 1 and 100'
row += 2

worksheet.write(row, 0, txt)
worksheet.data_validation(row, 1,
    {
        :validate      => 'integer',
        :criteria      => 'between',
        :minimum       => 1,
        :maximum       => 100,
        :input_title   => 'Enter an integer:',
        :input_message => 'between 1 and 100',
        :error_title   => 'Input value is not valid!',
        :error_message => 'It should be an integer between 1 and 100'
    })


#
# Example 13. Displaying and modify data validation messages.
#
txt = 'Display a custom information message when integer isn\'t between 1 and 100'
row += 2

worksheet.write(row, 0, txt)
worksheet.data_validation(row, 1,
    {
        :validate      => 'integer',
        :criteria      => 'between',
        :minimum       => 1,
        :maximum       => 100,
        :input_title   => 'Enter an integer:',
        :input_message => 'between 1 and 100',
        :error_title   => 'Input value is not valid!',
        :error_message => 'It should be an integer between 1 and 100',
        :error_type    => 'information'
    })

workbook.close
