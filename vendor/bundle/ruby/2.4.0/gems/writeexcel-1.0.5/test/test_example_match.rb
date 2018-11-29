# -*- coding: utf-8 -*-
require 'helper'
require 'stringio'

class TC_example_match < Test::Unit::TestCase

  TEST_DIR    = File.expand_path(File.dirname(__FILE__))
  PERL_OUTDIR = File.join(TEST_DIR, 'perl_output')

  def setup
    @file  = StringIO.new
  end

  def test_a_simple
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet

    # The general syntax is write(row, column, token). Note that row and
    # column are zero indexed
    #

    # Write some text
    worksheet.write(0, 0,  "Hi Excel!")


    # Write some numbers
    worksheet.write(2, 0,  3)          # Writes 3
    worksheet.write(3, 0,  3.00000)    # Writes 3
    worksheet.write(4, 0,  3.00001)    # Writes 3.00001
    worksheet.write(5, 0,  3.14159)    # TeX revision no.?


    # Write some formulas
    worksheet.write(7, 0,  '=A3 + A6')
    worksheet.write(8, 0,  '=IF(A5>3,"Yes", "No")')


    # Write a hyperlink
    worksheet.write(10, 0, 'http://www.perl.com/')

    # File save
    workbook.close
    # do assertion
    compare_file("#{PERL_OUTDIR}/a_simple.xls", @file)
  end

  def test_autofilter
    workbook = WriteExcel.new(@file)

    worksheet1 = workbook.add_worksheet
    worksheet2 = workbook.add_worksheet
    worksheet3 = workbook.add_worksheet
    worksheet4 = workbook.add_worksheet
    worksheet5 = workbook.add_worksheet
    worksheet6 = workbook.add_worksheet

    bold       = workbook.add_format(:bold => 1)

    # Extract the data embedded at the end of this file.
    headings = %w(Region    Item      Volume    Month)
    data = get_data_for_autofilter

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

    # do assertion
    compare_file("#{PERL_OUTDIR}/autofilter.xls", @file)
  end

  def get_data_for_autofilter
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

  def test_regions
    workbook = WriteExcel.new(@file)

    # Add some worksheets
    north = workbook.add_worksheet("North")
    south = workbook.add_worksheet("South")
    east  = workbook.add_worksheet("East")
    west  = workbook.add_worksheet("West")

    # Add a Format
    format = workbook.add_format()
    format.set_bold()
    format.set_color('blue')

    # Add a caption to each worksheet
    workbook.sheets.each do |worksheet|
        worksheet.write(0, 0, "Sales", format)
    end

    # Write some data
    north.write(0, 1, 200000)
    south.write(0, 1, 100000)
    east.write(0, 1, 150000)
    west.write(0, 1, 100000)

    # Set the active worksheet
    south.activate()

    # Set the width of the first column
    south.set_column(0, 0, 20)

    # Set the active cell
    south.set_selection(0, 1)

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/regions.xls", @file)
  end

  def test_stats
    workbook = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet('Test data')

    # Set the column width for columns 1
    worksheet.set_column(0, 0, 20)

    # Create a format for the headings
    format = workbook.add_format
    format.set_bold

    # Write the sample data
    worksheet.write(0, 0, 'Sample', format)
    worksheet.write(0, 1, 1)
    worksheet.write(0, 2, 2)
    worksheet.write(0, 3, 3)
    worksheet.write(0, 4, 4)
    worksheet.write(0, 5, 5)
    worksheet.write(0, 6, 6)
    worksheet.write(0, 7, 7)
    worksheet.write(0, 8, 8)

    worksheet.write(1, 0, 'Length', format)
    worksheet.write(1, 1, 25.4)
    worksheet.write(1, 2, 25.4)
    worksheet.write(1, 3, 24.8)
    worksheet.write(1, 4, 25.0)
    worksheet.write(1, 5, 25.3)
    worksheet.write(1, 6, 24.9)
    worksheet.write(1, 7, 25.2)
    worksheet.write(1, 8, 24.8)

    # Write some statistical functions
    worksheet.write(4,  0, 'Count', format)
    worksheet.write(4,  1, '=COUNT(B1:I1)')

    worksheet.write(5,  0, 'Sum', format)
    worksheet.write(5,  1, '=SUM(B2:I2)')

    worksheet.write(6,  0, 'Average', format)
    worksheet.write(6,  1, '=AVERAGE(B2:I2)')

    worksheet.write(7,  0, 'Min', format)
    worksheet.write(7,  1, '=MIN(B2:I2)')

    worksheet.write(8,  0, 'Max', format)
    worksheet.write(8,  1, '=MAX(B2:I2)')

    worksheet.write(9,  0, 'Standard Deviation', format)
    worksheet.write(9,  1, '=STDEV(B2:I2)')

    worksheet.write(10, 0, 'Kurtosis', format)
    worksheet.write(10, 1, '=KURT(B2:I2)')

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/stats.xls", @file)
  end

  def test_hyperlink1
    # Create a new workbook and add a worksheet
    workbook  = WriteExcel.new(@file)
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

    # do assertion
    compare_file("#{PERL_OUTDIR}/hyperlink.xls", @file)
  end

  def test_hyperlink2
    # Create workbook1
    ireland   = WriteExcel.new(@file)
    ire_links = ireland.add_worksheet('Links')
    ire_sales = ireland.add_worksheet('Sales')
    ire_data  = ireland.add_worksheet('Product Data')

    file2 = StringIO.new
    italy     = WriteExcel.new(file2)
    ita_links = italy.add_worksheet('Links')
    ita_sales = italy.add_worksheet('Sales')
    ita_data  = italy.add_worksheet('Product Data')

    file3 = StringIO.new
    china     = WriteExcel.new(file3)
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

    # do assertion
    compare_file("#{PERL_OUTDIR}/Ireland.xls", @file)
    compare_file("#{PERL_OUTDIR}/Italy.xls", file2)
    compare_file("#{PERL_OUTDIR}/China.xls", file3)
  end

  def test_copyformat
    # Create workbook1
    workbook1       = WriteExcel.new(@file)
    worksheet1      = workbook1.add_worksheet
    format1a        = workbook1.add_format
    format1b        = workbook1.add_format

    # Create workbook2
    file2 = StringIO.new
    workbook2       = WriteExcel.new(file2)
    worksheet2      = workbook2.add_worksheet
    format2a        = workbook2.add_format
    format2b        = workbook2.add_format

    # Create a global format object that isn't tied to a workbook
    global_format   = Writeexcel::Format.new

    # Set the formatting
    global_format.set_color('blue')
    global_format.set_bold
    global_format.set_italic

    # Create another example format
    format1b.set_color('red')

    # Copy the global format properties to the worksheet formats
    format1a.copy(global_format)
    format2a.copy(global_format)

    # Copy a format from worksheet1 to worksheet2
    format2b.copy(format1b)

    # Write some output
    worksheet1.write(0, 0, "Ciao", format1a)
    worksheet1.write(1, 0, "Ciao", format1b)

    worksheet2.write(0, 0, "Hello", format2a)
    worksheet2.write(1, 0, "Hello", format2b)
    workbook1.close
    workbook2.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/workbook1.xls", @file)
    compare_file("#{PERL_OUTDIR}/workbook2.xls", file2)
  end

  def test_data_validate
    workbook  = WriteExcel.new(@file)
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
            :source          => '=E4:G4'
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

    # do assertion
    compare_file("#{PERL_OUTDIR}/data_validate.xls", @file)
  end

  def test_merge1
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet

    # Increase the cell size of the merged cells to highlight the formatting.
    worksheet.set_column('B:D', 20)
    worksheet.set_row(2, 30)

    # Create a merge format
    format = workbook.add_format(:center_across => 1)

    # Only one cell should contain text, the others should be blank.
    worksheet.write(2, 1, "Center across selection", format)
    worksheet.write_blank(2, 2,                 format)
    worksheet.write_blank(2, 3,                 format)

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/merge1.xls", @file)
  end

  def test_merge2
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet

    # Increase the cell size of the merged cells to highlight the formatting.
    worksheet.set_column(1, 2, 30)
    worksheet.set_row(2, 40)

    # Create a merged format
    format = workbook.add_format(
                                        :center_across   => 1,
                                        :bold            => 1,
                                        :size            => 15,
                                        :pattern         => 1,
                                        :border          => 6,
                                        :color           => 'white',
                                        :fg_color        => 'green',
                                        :border_color    => 'yellow',
                                        :align           => 'vcenter'
                                  )

    # Only one cell should contain text, the others should be blank.
    worksheet.write(2, 1, "Center across selection", format)
    worksheet.write_blank(2, 2,                      format)
    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/merge2.xls", @file)
  end

  def test_merge3
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet()

    # Increase the cell size of the merged cells to highlight the formatting.
    [1, 3,6,7].each { |row| worksheet.set_row(row, 30) }
    worksheet.set_column('B:D', 20)

    ###############################################################################
    #
    # Example 1: Merge cells containing a hyperlink using write_url_range()
    # and the standard Excel 5+ merge property.
    #
    format1 = workbook.add_format(
                                        :center_across   => 1,
                                        :border          => 1,
                                        :underline       => 1,
                                        :color           => 'blue'
                                 )

    # Write the cells to be merged
    worksheet.write_url_range('B2:D2', 'http://www.perl.com', format1)
    worksheet.write_blank('C2', format1)
    worksheet.write_blank('D2', format1)



    ###############################################################################
    #
    # Example 2: Merge cells containing a hyperlink using merge_range().
    #
    format2 = workbook.add_format(
                                        :border      => 1,
                                        :underline   => 1,
                                        :color       => 'blue',
                                        :align       => 'center',
                                        :valign      => 'vcenter'
                                 )

    # Merge 3 cells
    worksheet.merge_range('B4:D4', 'http://www.perl.com', format2)


    # Merge 3 cells over two rows
    worksheet.merge_range('B7:D8', 'http://www.perl.com', format2)

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/merge3.xls", @file)
  end

  def test_merge4
    # Create a new workbook and add a worksheet
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet

    # Increase the cell size of the merged cells to highlight the formatting.
    (1..11).each { |row| worksheet.set_row(row, 30) }
    worksheet.set_column('B:D', 20)

    ###############################################################################
    #
    # Example 1: Text centered vertically and horizontally
    #
    format1 = workbook.add_format(
                                        :border  => 6,
                                        :bold    => 1,
                                        :color   => 'red',
                                        :valign  => 'vcenter',
                                        :align   => 'center'
                                       )

    worksheet.merge_range('B2:D3', 'Vertical and horizontal', format1)


    ###############################################################################
    #
    # Example 2: Text aligned to the top and left
    #
    format2 = workbook.add_format(
                                        :border  => 6,
                                        :bold    => 1,
                                        :color   => 'red',
                                        :valign  => 'top',
                                        :align   => 'left'
                                      )

    worksheet.merge_range('B5:D6', 'Aligned to the top and left', format2)

    ###############################################################################
    #
    # Example 3:  Text aligned to the bottom and right
    #
    format3 = workbook.add_format(
                                        :border  => 6,
                                        :bold    => 1,
                                        :color   => 'red',
                                        :valign  => 'bottom',
                                        :align   => 'right'
                                      )

    worksheet.merge_range('B8:D9', 'Aligned to the bottom and right', format3)

    ###############################################################################
    #
    # Example 4:  Text justified (i.e. wrapped) in the cell
    #
    format4 = workbook.add_format(
                                        :border  => 6,
                                        :bold    => 1,
                                        :color   => 'red',
                                        :valign  => 'top',
                                        :align   => 'justify'
                                      )

    worksheet.merge_range('B11:D12', 'Justified: '+'so on and '*18, format4)

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/merge4.xls", @file)
  end

  def test_merge5
    # Create a new workbook and add a worksheet
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet


    # Increase the cell size of the merged cells to highlight the formatting.
    (3..8).each { |col| worksheet.set_row(col, 36) }
    [1, 3, 5].each { |n| worksheet.set_column(n, n, 15) }


    ###############################################################################
    #
    # Rotation 1, letters run from top to bottom
    #
    format1 = workbook.add_format(
                                        :border      => 6,
                                        :bold        => 1,
                                        :color       => 'red',
                                        :valign      => 'vcentre',
                                        :align       => 'centre',
                                        :rotation    => 270
                                      )


    worksheet.merge_range('B4:B9', 'Rotation 270', format1)


    ###############################################################################
    #
    # Rotation 2, 90° anticlockwise
    #
    format2 = workbook.add_format(
                                        :border      => 6,
                                        :bold        => 1,
                                        :color       => 'red',
                                        :valign      => 'vcentre',
                                        :align       => 'centre',
                                        :rotation    => 90
                                      )


    worksheet.merge_range('D4:D9', 'Rotation 90', format2)



    ###############################################################################
    #
    # Rotation 3, 90° clockwise
    #
    format3 = workbook.add_format(
                                        :border      => 6,
                                        :bold        => 1,
                                        :color       => 'red',
                                        :valign      => 'vcentre',
                                        :align       => 'centre',
                                        :rotation    => -90
                                      )


    worksheet.merge_range('F4:F9', 'Rotation -90', format3)

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/merge5.xls", @file)
  end

  def test_merge6
    # Create a new workbook and add a worksheet
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet

    # Increase the cell size of the merged cells to highlight the formatting.
    (2..9).each { |i| worksheet.set_row(i, 36) }
    worksheet.set_column('B:D', 25)

    # Format for the merged cells.
    format = workbook.add_format(
               :border      => 6,
               :bold        => 1,
               :color       => 'red',
               :size        => 20,
               :valign      => 'vcentre',
               :align       => 'left',
               :indent      => 1
      )

    ###############################################################################
    #
    # Write an Ascii string.
    #

    worksheet.merge_range('B3:D4', 'ASCII: A simple string', format)

    ###############################################################################
    #
    # Write a UTF-16 Unicode string.
    #

    # A phrase in Cyrillic encoded as UTF-16BE.
    utf16_str = [
      '005500540046002d00310036003a0020' <<
      '042d0442043e002004440440043004370430002004' <<
      '3d043000200440044304410441043a043e043c0021'
    ].pack("H*")

    # Note the extra parameter at the end to indicate UTF-16 encoding.
    worksheet.merge_range('B6:D7', utf16_str, format, 1)

    ###############################################################################
    #
    # Write a UTF-8 Unicode string.
    #

    smiley = '☺'  # chr 0x263a in perl
    worksheet.merge_range('B9:D10', "UTF-8: A Unicode smiley #{smiley}", format)

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/merge6.xls", @file)
  end

  def test_images
    # Create a new workbook called simple.xls and add a worksheet
    workbook   = WriteExcel.new(@file)
    worksheet1 = workbook.add_worksheet('Image 1')
    worksheet2 = workbook.add_worksheet('Image 2')
    worksheet3 = workbook.add_worksheet('Image 3')
    worksheet4 = workbook.add_worksheet('Image 4')

    # Insert a basic image
    worksheet1.write('A10', "Image inserted into worksheet.")
    worksheet1.insert_image('A1', File.join(TEST_DIR,'republic.png'))


    # Insert an image with an offset
    worksheet2.write('A10', "Image inserted with an offset.")
    worksheet2.insert_image('A1', File.join(TEST_DIR,'republic.png'), 32, 10)

    # Insert a scaled image
    worksheet3.write('A10', "Image scaled: width x 2, height x 0.8.")
    worksheet3.insert_image('A1', File.join(TEST_DIR,'republic.png'), 0, 0, 2, 0.8)

    # Insert an image over varied column and row sizes
    # This does not require any additional work

    # Set the cols and row sizes
    # NOTE: you must do this before you call insert_image()
    worksheet4.set_column('A:A', 5)
    worksheet4.set_column('B:B', nil, nil, 1) # Hidden
    worksheet4.set_column('C:D', 10)
    worksheet4.set_row(0, 30)
    worksheet4.set_row(3, 5)

    worksheet4.write('A10', "Image inserted over scaled rows and columns.")
    worksheet4.insert_image('A1', File.join(TEST_DIR,'republic.png'))

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/images.xls", @file)
  end

  def test_tab_colors
    workbook   = WriteExcel.new(@file)

    worksheet1 =  workbook.add_worksheet
    worksheet2 =  workbook.add_worksheet
    worksheet3 =  workbook.add_worksheet
    worksheet4 =  workbook.add_worksheet

    # Worsheet1 will have the default tab colour.
    worksheet2.set_tab_color('red')
    worksheet3.set_tab_color('green')
    worksheet4.set_tab_color(0x35) # Orange

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/tab_colors.xls", @file)
  end

  def test_stocks
    # Create a new workbook and add a worksheet
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet

    # Set the column width for columns 1, 2, 3 and 4
    worksheet.set_column(0, 3, 15)


    # Create a format for the column headings
    header = workbook.add_format
    header.set_bold
    header.set_size(12)
    header.set_color('blue')


    # Create a format for the stock price
    f_price = workbook.add_format
    f_price.set_align('left')
    f_price.set_num_format('$0.00')


    # Create a format for the stock volume
    f_volume = workbook.add_format
    f_volume.set_align('left')
    f_volume.set_num_format('#,##0')


    # Create a format for the price change. This is an example of a conditional
    # format. The number is formatted as a percentage. If it is positive it is
    # formatted in green, if it is negative it is formatted in red and if it is
    # zero it is formatted as the default font colour (in this case black).
    # Note: the [Green] format produces an unappealing lime green. Try
    # [Color 10] instead for a dark green.
    #
    f_change = workbook.add_format
    f_change.set_align('left')
    f_change.set_num_format('[Green]0.0%;[Red]-0.0%;0.0%')


    # Write out the data
    worksheet.write(0, 0, 'Company', header)
    worksheet.write(0, 1, 'Price',   header)
    worksheet.write(0, 2, 'Volume',  header)
    worksheet.write(0, 3, 'Change',  header)

    worksheet.write(1, 0, 'Damage Inc.'     )
    worksheet.write(1, 1, 30.25,     f_price)  # $30.25
    worksheet.write(1, 2, 1234567,   f_volume) # 1,234,567
    worksheet.write(1, 3, 0.085,     f_change) # 8.5% in green

    worksheet.write(2, 0, 'Dump Corp.'      )
    worksheet.write(2, 1, 1.56,      f_price)  # $1.56
    worksheet.write(2, 2, 7564,      f_volume) # 7,564
    worksheet.write(2, 3, -0.015,    f_change) # -1.5% in red

    worksheet.write(3, 0, 'Rev Ltd.'        )
    worksheet.write(3, 1, 0.13,      f_price)  # $0.13
    worksheet.write(3, 2, 321,       f_volume) # 321
    worksheet.write(3, 3, 0,         f_change) # 0 in the font color (black)

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/stocks.xls", @file)
  end

  def test_protection
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet

    # Create some format objects
    locked    = workbook.add_format(:locked => 1)
    unlocked  = workbook.add_format(:locked => 0)
    hidden    = workbook.add_format(:hidden => 1)

    # Format the columns
    worksheet.set_column('A:A', 42)
    worksheet.set_selection('B3:B3')

    # Protect the worksheet
    worksheet.protect

    # Examples of cell locking and hiding
    worksheet.write('A1', 'Cell B1 is locked. It cannot be edited.')
    worksheet.write('B1', '=1+2', locked)

    worksheet.write('A2', 'Cell B2 is unlocked. It can be edited.')
    worksheet.write('B2', '=1+2', unlocked)

    worksheet.write('A3', "Cell B3 is hidden. The formula isn't visible.")
    worksheet.write('B3', '=1+2', hidden)

    worksheet.write('A5', 'Use Menu->Tools->Protection->Unprotect Sheet')
    worksheet.write('A6', 'to remove the worksheet protection.   ')

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/protection.xls", @file)
  end

  def test_password_protection
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet

    # Create some format objects
    locked    = workbook.add_format(:locked => 1)
    unlocked  = workbook.add_format(:locked => 0)
    hidden    = workbook.add_format(:hidden => 1)

    # Format the columns
    worksheet.set_column('A:A', 42)
    worksheet.set_selection('B3:B3')

    # Protect the worksheet
    worksheet.protect('password')

    # Examples of cell locking and hiding
    worksheet.write('A1', 'Cell B1 is locked. It cannot be edited.')
    worksheet.write('B1', '=1+2', locked)

    worksheet.write('A2', 'Cell B2 is unlocked. It can be edited.')
    worksheet.write('B2', '=1+2', unlocked)

    worksheet.write('A3', "Cell B3 is hidden. The formula isn't visible.")
    worksheet.write('B3', '=1+2', hidden)

    worksheet.write('A5', 'Use Menu->Tools->Protection->Unprotect Sheet')
    worksheet.write('A6', 'to remove the worksheet protection.   ')
    worksheet.write('A7', 'The password is "password".   ')

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/password_protection.xls", @file)
  end

  def test_date_time
    # Create a new workbook and add a worksheet
    workbook  = WriteExcel.new(@file)
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

    # do assertion
    compare_file("#{PERL_OUTDIR}/date_time.xls", @file)
  end

  def test_diag_border
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet

    format1   = workbook.add_format(:diag_type     => 1)
    format2   = workbook.add_format(:diag_type     => 2)
    format3   = workbook.add_format(:diag_type     => 3)
    format4   = workbook.add_format(
                                  :diag_type       => 3,
                                  :diag_border     => 7,
                                  :diag_color      => 'red'
                )

    worksheet.write('B3',  'Text', format1)
    worksheet.write('B6',  'Text', format2)
    worksheet.write('B9',  'Text', format3)
    worksheet.write('B12', 'Text', format4)

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/diag_border.xls", @file)
  end

  def test_headers
    workbook  = WriteExcel.new(@file)
    preview   = "Select Print Preview to see the header and footer"


    ######################################################################
    #
    # A simple example to start
    #
    worksheet1  = workbook.add_worksheet('Simple')

    header1     = '&CHere is some centred text.'

    footer1     = '&LHere is some left aligned text.'


    worksheet1.set_header(header1)
    worksheet1.set_footer(footer1)

    worksheet1.set_column('A:A', 50)
    worksheet1.write('A1', preview)


    ######################################################################
    #
    # This is an example of some of the header/footer variables.
    #
    worksheet2  = workbook.add_worksheet('Variables')

    header2     = '&LPage &P of &N'+
                      '&CFilename: &F' +
                      '&RSheetname: &A'

    footer2     = '&LCurrent date: &D'+
                      '&RCurrent time: &T'

    worksheet2.set_header(header2)
    worksheet2.set_footer(footer2)


    worksheet2.set_column('A:A', 50)
    worksheet2.write('A1', preview)
    worksheet2.write('A21', "Next sheet")
    worksheet2.set_h_pagebreaks(20)


    ######################################################################
    #
    # This example shows how to use more than one font
    #
    worksheet3 = workbook.add_worksheet('Mixed fonts')

    header3    = '&C' +
                     '&"Courier New,Bold"Hello ' +
                     '&"Arial,Italic"World'

    footer3    = '&C' +
                     '&"Symbol"e' +
                     '&"Arial" = mc&X2'

    worksheet3.set_header(header3)
    worksheet3.set_footer(footer3)

    worksheet3.set_column('A:A', 50)
    worksheet3.write('A1', preview)


    ######################################################################
    #
    # Example of line wrapping
    #
    worksheet4 = workbook.add_worksheet('Word wrap')

    header4    = "&CHeading 1\nHeading 2\nHeading 3"

    worksheet4.set_header(header4)

    worksheet4.set_column('A:A', 50)
    worksheet4.write('A1', preview)


    ######################################################################
    #
    # Example of inserting a literal ampersand &
    #
    worksheet5 = workbook.add_worksheet('Ampersand')

    header5    = "&CCuriouser && Curiouser - Attorneys at Law"

    worksheet5.set_header(header5)

    worksheet5.set_column('A:A', 50)
    worksheet5.write('A1', preview)

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/headers.xls", @file)
  end

  def test_demo
    workbook   = WriteExcel.new(@file)
worksheet  = workbook.add_worksheet('Demo')
worksheet2 = workbook.add_worksheet('Another sheet')
worksheet3 = workbook.add_worksheet('And another')

bold       = workbook.add_format(:bold => 1)

#######################################################################
#
# Write a general heading
#
worksheet.set_column('A:A', 36, bold)
worksheet.set_column('B:B', 20       )
worksheet.set_row(0,     40       )

heading  = workbook.add_format(
                                :bold    => 1,
                                :color   => 'blue',
                                :size    => 16,
                                :merge   => 1,
                                :align  => 'vcenter'
                              )

headings = ['Features of Spreadsheet::WriteExcel', '']
worksheet.write_row('A1', headings, heading)


#######################################################################
#
# Some text examples
#
text_format  = workbook.add_format(
                                    :bold    => 1,
                                    :italic  => 1,
                                    :color   => 'red',
                                    :size    => 18,
                                    :font    =>'Lucida Calligraphy'
                                  )

# A phrase in Cyrillic
unicode = [
            "042d0442043e002004440440043004370430002004"+
            "3d043000200440044304410441043a043e043c0021"
          ].pack('H*')

worksheet.write('A2', "Text")
worksheet.write('B2', "Hello Excel")
worksheet.write('A3', "Formatted text")
worksheet.write('B3', "Hello Excel", text_format)
worksheet.write('A4', "Unicode text")
worksheet.write_utf16be_string('B4', unicode)


#######################################################################
#
# Some numeric examples
#
num1_format  = workbook.add_format(:num_format => '$#,##0.00')
num2_format  = workbook.add_format(:num_format => ' d mmmm yyy')

worksheet.write('A5', "Numbers")
worksheet.write('B5', 1234.56)
worksheet.write('A6', "Formatted numbers")
worksheet.write('B6', 1234.56, num1_format)
worksheet.write('A7', "Formatted numbers")
worksheet.write('B7', 37257, num2_format)


#######################################################################
#
# Formulae
#
worksheet.set_selection('B8')
worksheet.write('A8', 'Formulas and functions, "=SIN(PI()/4)"')
worksheet.write('B8', '=SIN(PI()/4)')


#######################################################################
#
# Hyperlinks
#
worksheet.write('A9', "Hyperlinks")
worksheet.write('B9',  'http://www.perl.com/' )


#######################################################################
#
# Images
#
worksheet.write('A10', "Images")
worksheet.insert_image('B10', "#{TEST_DIR}/republic.png", 16, 8)


#######################################################################
#
# Misc
#
worksheet.write('A18', "Page/printer setup")
worksheet.write('A19', "Multiple worksheets")

workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/demo.xls", @file)
  end

  def test_unicode_cyrillic
    # Create a Russian worksheet name in utf8.
    sheet   = [0x0421, 0x0442, 0x0440, 0x0430, 0x043D, 0x0438,
                         0x0446, 0x0430].pack("U*")

    # Create a Russian string.
    str     = [0x0417, 0x0434, 0x0440, 0x0430, 0x0432, 0x0441,
                       0x0442, 0x0432, 0x0443, 0x0439, 0x0020, 0x041C,
                       0x0438, 0x0440, 0x0021].pack("U*")

    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet(sheet + '1')

    worksheet.set_column('A:A', 18)
    worksheet.write('A1', str)

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/unicode_cyrillic.xls", @file)
  end

  def test_defined_name
    workbook   = WriteExcel.new(@file)
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

    # do assertion
    compare_file("#{PERL_OUTDIR}/defined_name.xls", @file)
  end

  def test_chart_area
workbook  = WriteExcel.new(@file)
worksheet = workbook.add_worksheet
bold      = workbook.add_format(:bold => 1)

# Add the data to the worksheet that the charts will refer to.
headings = [ 'Category', 'Values 1', 'Values 2' ]
data = [
    [ 2, 3, 4, 5, 6, 7 ],
    [ 1, 4, 5, 2, 1, 5 ],
    [ 3, 6, 7, 5, 4, 3 ]
]

worksheet.write('A1', headings, bold)
worksheet.write('A2', data)


###############################################################################
#
# Example 1. A minimal chart.
#
chart1 = workbook.add_chart(:type => 'Chart::Area')

# Add values only. Use the default categories.
chart1.add_series( :values => '=Sheet1!$B$2:$B$7' )

###############################################################################
#
# Example 2. A minimal chart with user specified categories (X axis)
#            and a series name.
#
chart2 = workbook.add_chart(:type => 'Chart::Area')

# Configure the series.
chart2.add_series(
    :categories => '=Sheet1!$A$2:$A$7',
    :values     => '=Sheet1!$B$2:$B$7',
    :name       => 'Test data series 1'
)

###############################################################################
#
# Example 3. Same as previous chart but with added title and axes labels.
#
chart3 = workbook.add_chart(:type => 'Chart::Area')

# Configure the series.
chart3.add_series(
    :categories => '=Sheet1!$A$2:$A$7',
    :values     => '=Sheet1!$B$2:$B$7',
    :name       => 'Test data series 1'
)

# Add some labels.
chart3.set_title( :name => 'Results of sample analysis' )
chart3.set_x_axis( :name => 'Sample number' )
chart3.set_y_axis( :name => 'Sample length (cm)' )

###############################################################################
#
# Example 4. Same as previous chart but with an added series
#
chart4 = workbook.add_chart(:name => 'Results Chart', :type => 'Chart::Area')

# Configure the series.
chart4.add_series(
    :categories => '=Sheet1!$A$2:$A$7',
    :values     => '=Sheet1!$B$2:$B$7',
    :name       => 'Test data series 1'
)

# Add another series.
chart4.add_series(
    :categories => '=Sheet1!$A$2:$A$7',
    :values     => '=Sheet1!$C$2:$C$7',
    :name       => 'Test data series 2'
)

# Add some labels.
chart4.set_title( :name => 'Results of sample analysis' )
chart4.set_x_axis( :name => 'Sample number' )
chart4.set_y_axis( :name => 'Sample length (cm)' )

###############################################################################
#
# Example 5. Same as Example 3 but as an embedded chart.
#
chart5 = workbook.add_chart(:type => 'Chart::Area', :embedded => 1)

# Configure the series.
chart5.add_series(
  :categories => '=Sheet1!$A$2:$A$7',
  :values     => '=Sheet1!$B$2:$B$7',
  :name       => 'Test data series 1'
)

# Add some labels.
chart5.set_title(:name => 'Results of sample analysis' )
chart5.set_x_axis(:name => 'Sample number')
chart5.set_y_axis(:name => 'Sample length (cm)')

# Insert the chart into the main worksheet.
worksheet.insert_chart('E2', chart5)

# File save
workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/chart_area.xls", @file)
  end

  def test_chart_bar
workbook  = WriteExcel.new(@file)
worksheet = workbook.add_worksheet
bold      = workbook.add_format(:bold => 1)

# Add the data to the worksheet that the charts will refer to.
headings = [ 'Category', 'Values 1', 'Values 2' ]
data = [
    [ 2, 3, 4, 5, 6, 7 ],
    [ 1, 4, 5, 2, 1, 5 ],
    [ 3, 6, 7, 5, 4, 3 ]
]

worksheet.write('A1', headings, bold)
worksheet.write('A2', data)


###############################################################################
#
# Example 1. A minimal chart.
#
chart1 = workbook.add_chart(:type => 'Chart::Bar')

# Add values only. Use the default categories.
chart1.add_series( :values => '=Sheet1!$B$2:$B$7' )

###############################################################################
#
# Example 2. A minimal chart with user specified categories (X axis)
#            and a series name.
#
chart2 = workbook.add_chart(:type => 'Chart::Bar')

# Configure the series.
chart2.add_series(
    :categories => '=Sheet1!$A$2:$A$7',
    :values     => '=Sheet1!$B$2:$B$7',
    :name       => 'Test data series 1'
)

###############################################################################
#
# Example 3. Same as previous chart but with added title and axes labels.
#
chart3 = workbook.add_chart(:type => 'Chart::Bar')

# Configure the series.
chart3.add_series(
    :categories => '=Sheet1!$A$2:$A$7',
    :values     => '=Sheet1!$B$2:$B$7',
    :name       => 'Test data series 1'
)

# Add some labels.
chart3.set_title( :name => 'Results of sample analysis' )
chart3.set_x_axis( :name => 'Sample number' )
chart3.set_y_axis( :name => 'Sample length (cm)' )

###############################################################################
#
# Example 4. Same as previous chart but with an added series
#
chart4 = workbook.add_chart(:name => 'Results Chart', :type => 'Chart::Bar')

# Configure the series.
chart4.add_series(
    :categories => '=Sheet1!$A$2:$A$7',
    :values     => '=Sheet1!$B$2:$B$7',
    :name       => 'Test data series 1'
)

# Add another series.
chart4.add_series(
    :categories => '=Sheet1!$A$2:$A$7',
    :values     => '=Sheet1!$C$2:$C$7',
    :name       => 'Test data series 2'
)

# Add some labels.
chart4.set_title( :name => 'Results of sample analysis' )
chart4.set_x_axis( :name => 'Sample number' )
chart4.set_y_axis( :name => 'Sample length (cm)' )

###############################################################################
#
# Example 5. Same as Example 3 but as an embedded chart.
#
chart5 = workbook.add_chart(:type => 'Chart::Bar', :embedded => 1)

# Configure the series.
chart5.add_series(
  :categories => '=Sheet1!$A$2:$A$7',
  :values     => '=Sheet1!$B$2:$B$7',
  :name       => 'Test data series 1'
)

# Add some labels.
chart5.set_title(:name => 'Results of sample analysis' )
chart5.set_x_axis(:name => 'Sample number')
chart5.set_y_axis(:name => 'Sample length (cm)')

# Insert the chart into the main worksheet.
worksheet.insert_chart('E2', chart5)

# File save
workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/chart_bar.xls", @file)
  end

  def test_chart_column
workbook  = WriteExcel.new(@file)
worksheet = workbook.add_worksheet
bold      = workbook.add_format(:bold => 1)

# Add the data to the worksheet that the charts will refer to.
headings = [ 'Category', 'Values 1', 'Values 2' ]
data = [
    [ 2, 3, 4, 5, 6, 7 ],
    [ 1, 4, 5, 2, 1, 5 ],
    [ 3, 6, 7, 5, 4, 3 ]
]

worksheet.write('A1', headings, bold)
worksheet.write('A2', data)


###############################################################################
#
# Example 1. A minimal chart.
#
chart1 = workbook.add_chart(:type => 'Chart::Column')

# Add values only. Use the default categories.
chart1.add_series( :values => '=Sheet1!$B$2:$B$7' )

###############################################################################
#
# Example 2. A minimal chart with user specified categories (X axis)
#            and a series name.
#
chart2 = workbook.add_chart(:type => 'Chart::Column')

# Configure the series.
chart2.add_series(
    :categories => '=Sheet1!$A$2:$A$7',
    :values     => '=Sheet1!$B$2:$B$7',
    :name       => 'Test data series 1'
)

###############################################################################
#
# Example 3. Same as previous chart but with added title and axes labels.
#
chart3 = workbook.add_chart(:type => 'Chart::Column')

# Configure the series.
chart3.add_series(
    :categories => '=Sheet1!$A$2:$A$7',
    :values     => '=Sheet1!$B$2:$B$7',
    :name       => 'Test data series 1'
)

# Add some labels.
chart3.set_title( :name => 'Results of sample analysis' )
chart3.set_x_axis( :name => 'Sample number' )
chart3.set_y_axis( :name => 'Sample length (cm)' )

###############################################################################
#
# Example 4. Same as previous chart but with an added series
#
chart4 = workbook.add_chart(:name => 'Results Chart', :type => 'Chart::Column')

# Configure the series.
chart4.add_series(
    :categories => '=Sheet1!$A$2:$A$7',
    :values     => '=Sheet1!$B$2:$B$7',
    :name       => 'Test data series 1'
)

# Add another series.
chart4.add_series(
    :categories => '=Sheet1!$A$2:$A$7',
    :values     => '=Sheet1!$C$2:$C$7',
    :name       => 'Test data series 2'
)

# Add some labels.
chart4.set_title( :name => 'Results of sample analysis' )
chart4.set_x_axis( :name => 'Sample number' )
chart4.set_y_axis( :name => 'Sample length (cm)' )

###############################################################################
#
# Example 5. Same as Example 3 but as an embedded chart.
#
chart5 = workbook.add_chart(:type => 'Chart::Column', :embedded => 1)

# Configure the series.
chart5.add_series(
  :categories => '=Sheet1!$A$2:$A$7',
  :values     => '=Sheet1!$B$2:$B$7',
  :name       => 'Test data series 1'
)

# Add some labels.
chart5.set_title(:name => 'Results of sample analysis' )
chart5.set_x_axis(:name => 'Sample number')
chart5.set_y_axis(:name => 'Sample length (cm)')

# Insert the chart into the main worksheet.
worksheet.insert_chart('E2', chart5)

# File save
workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/chart_column.xls", @file)
  end

  def test_chart_line
workbook  = WriteExcel.new(@file)
worksheet = workbook.add_worksheet
bold      = workbook.add_format(:bold => 1)

# Add the data to the worksheet that the charts will refer to.
headings = [ 'Category', 'Values 1', 'Values 2' ]
data = [
    [ 2, 3, 4, 5, 6, 7 ],
    [ 1, 4, 5, 2, 1, 5 ],
    [ 3, 6, 7, 5, 4, 3 ]
]

worksheet.write('A1', headings, bold)
worksheet.write('A2', data)


###############################################################################
#
# Example 1. A minimal chart.
#
chart1 = workbook.add_chart(:type => 'Chart::Line')

# Add values only. Use the default categories.
chart1.add_series( :values => '=Sheet1!$B$2:$B$7' )

###############################################################################
#
# Example 2. A minimal chart with user specified categories (X axis)
#            and a series name.
#
chart2 = workbook.add_chart(:type => 'Chart::Line')

# Configure the series.
chart2.add_series(
    :categories => '=Sheet1!$A$2:$A$7',
    :values     => '=Sheet1!$B$2:$B$7',
    :name       => 'Test data series 1'
)

###############################################################################
#
# Example 3. Same as previous chart but with added title and axes labels.
#
chart3 = workbook.add_chart(:type => 'Chart::Line')

# Configure the series.
chart3.add_series(
    :categories => '=Sheet1!$A$2:$A$7',
    :values     => '=Sheet1!$B$2:$B$7',
    :name       => 'Test data series 1'
)

# Add some labels.
chart3.set_title( :name => 'Results of sample analysis' )
chart3.set_x_axis( :name => 'Sample number' )
chart3.set_y_axis( :name => 'Sample length (cm)' )

###############################################################################
#
# Example 4. Same as previous chart but with an added series
#
chart4 = workbook.add_chart(:name => 'Results Chart', :type => 'Chart::Line')

# Configure the series.
chart4.add_series(
    :categories => '=Sheet1!$A$2:$A$7',
    :values     => '=Sheet1!$B$2:$B$7',
    :name       => 'Test data series 1'
)

# Add another series.
chart4.add_series(
    :categories => '=Sheet1!$A$2:$A$7',
    :values     => '=Sheet1!$C$2:$C$7',
    :name       => 'Test data series 2'
)

# Add some labels.
chart4.set_title( :name => 'Results of sample analysis' )
chart4.set_x_axis( :name => 'Sample number' )
chart4.set_y_axis( :name => 'Sample length (cm)' )

###############################################################################
#
# Example 5. Same as Example 3 but as an embedded chart.
#
chart5 = workbook.add_chart(:type => 'Chart::Line', :embedded => 1)

# Configure the series.
chart5.add_series(
  :categories => '=Sheet1!$A$2:$A$7',
  :values     => '=Sheet1!$B$2:$B$7',
  :name       => 'Test data series 1'
)

# Add some labels.
chart5.set_title(:name => 'Results of sample analysis' )
chart5.set_x_axis(:name => 'Sample number')
chart5.set_y_axis(:name => 'Sample length (cm)')

# Insert the chart into the main worksheet.
worksheet.insert_chart('E2', chart5)

# File save
workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/chart_line.xls", @file)
  end

  def test_chess
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet()

    # Some row and column formatting
    worksheet.set_column('B:I', 10)

    (1..8).each { |i| worksheet.set_row(i, 50) }

    # Define the property hashes
    #
    black = {
              'fg_color'  => 'black',
              'pattern'   => 1,
            }

    top     = { 'top'    => 6 }
    bottom  = { 'bottom' => 6 }
    left    = { 'left'   => 6 }
    right   = { 'right'  => 6 }

    # Define the formats
    #
    format01 = workbook.add_format(top.merge(left))
    format02 = workbook.add_format(top.merge(black))
    format03 = workbook.add_format(top)
    format04 = workbook.add_format(top.merge(right).merge(black))

    format05 = workbook.add_format(left)
    format06 = workbook.add_format(black)
    format07 = workbook.add_format
    format08 = workbook.add_format(right.merge(black))
    format09 = workbook.add_format(right)
    format10 = workbook.add_format(left.merge(black))

    format11 = workbook.add_format(bottom.merge(left).merge(black))
    format12 = workbook.add_format(bottom)
    format13 = workbook.add_format(bottom.merge(black))
    format14 = workbook.add_format(bottom.merge(right))


    # Draw the pattern
    worksheet.write('B2', '', format01)
    worksheet.write('C2', '', format02)
    worksheet.write('D2', '', format03)
    worksheet.write('E2', '', format02)
    worksheet.write('F2', '', format03)
    worksheet.write('G2', '', format02)
    worksheet.write('H2', '', format03)
    worksheet.write('I2', '', format04)

    worksheet.write('B3', '', format10)
    worksheet.write('C3', '', format07)
    worksheet.write('D3', '', format06)
    worksheet.write('E3', '', format07)
    worksheet.write('F3', '', format06)
    worksheet.write('G3', '', format07)
    worksheet.write('H3', '', format06)
    worksheet.write('I3', '', format09)

    worksheet.write('B4', '', format05)
    worksheet.write('C4', '', format06)
    worksheet.write('D4', '', format07)
    worksheet.write('E4', '', format06)
    worksheet.write('F4', '', format07)
    worksheet.write('G4', '', format06)
    worksheet.write('H4', '', format07)
    worksheet.write('I4', '', format08)

    worksheet.write('B5', '', format10)
    worksheet.write('C5', '', format07)
    worksheet.write('D5', '', format06)
    worksheet.write('E5', '', format07)
    worksheet.write('F5', '', format06)
    worksheet.write('G5', '', format07)
    worksheet.write('H5', '', format06)
    worksheet.write('I5', '', format09)

    worksheet.write('B6', '', format05)
    worksheet.write('C6', '', format06)
    worksheet.write('D6', '', format07)
    worksheet.write('E6', '', format06)
    worksheet.write('F6', '', format07)
    worksheet.write('G6', '', format06)
    worksheet.write('H6', '', format07)
    worksheet.write('I6', '', format08)

    worksheet.write('B7', '', format10)
    worksheet.write('C7', '', format07)
    worksheet.write('D7', '', format06)
    worksheet.write('E7', '', format07)
    worksheet.write('F7', '', format06)
    worksheet.write('G7', '', format07)
    worksheet.write('H7', '', format06)
    worksheet.write('I7', '', format09)

    worksheet.write('B8', '', format05)
    worksheet.write('C8', '', format06)
    worksheet.write('D8', '', format07)
    worksheet.write('E8', '', format06)
    worksheet.write('F8', '', format07)
    worksheet.write('G8', '', format06)
    worksheet.write('H8', '', format07)
    worksheet.write('I8', '', format08)

    worksheet.write('B9', '', format11)
    worksheet.write('C9', '', format12)
    worksheet.write('D9', '', format13)
    worksheet.write('E9', '', format12)
    worksheet.write('F9', '', format13)
    worksheet.write('G9', '', format12)
    worksheet.write('H9', '', format13)
    worksheet.write('I9', '', format14)

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/chess.xls", @file)
  end

  def test_colors
    workbook = WriteExcel.new(@file)

    # Some common formats
    center  = workbook.add_format(:align => 'center')
    heading = workbook.add_format(:align => 'center', :bold => 1)

    ######################################################################
    #
    # Demonstrate the named colors.
    #

    order = [
      0x21,
      0x0B,
      0x35,
      0x11,
      0x16,
      0x12,
      0x0D,
      0x10,
      0x17,
      0x09,
      0x0C,
      0x0F,
      0x0E,
      0x14,
      0x08,
      0x0A
    ]

    colors = {
                    0x08 => 'black',
                    0x0C => 'blue',
                    0x10 => 'brown',
                    0x0F => 'cyan',
                    0x17 => 'gray',
                    0x11 => 'green',
                    0x0B => 'lime',
                    0x0E => 'magenta',
                    0x12 => 'navy',
                    0x35 => 'orange',
                    0x21 => 'pink',
                    0x14 => 'purple',
                    0x0A => 'red',
                    0x16 => 'silver',
                    0x09 => 'white',
                    0x0D => 'yellow',
            }

    worksheet1 = workbook.add_worksheet('Named colors')

    worksheet1.set_column(0, 3, 15)

    worksheet1.write(0, 0, "Index", heading)
    worksheet1.write(0, 1, "Index", heading)
    worksheet1.write(0, 2, "Name",  heading)
    worksheet1.write(0, 3, "Color", heading)

    i = 1

    # original was colors.each....
    # order unmatch between perl and ruby (of cource, it's hash!)
    # so i use order array to match perl's xls order.
    #
    order.each do |index|
      format = workbook.add_format(
          :fg_color => colors[index],
          :pattern  => 1,
          :border   => 1
      )

      worksheet1.write(i + 1, 0, index,                    center)
      worksheet1.write(i + 1, 1, sprintf("0x%02X", index), center)
      worksheet1.write(i + 1, 2, colors[index],            center)
      worksheet1.write(i + 1, 3, '',                       format)
      i += 1
    end

    ######################################################################
    #
    # Demonstrate the standard Excel colors in the range 8..63.
    #

    worksheet2 = workbook.add_worksheet('Standard colors')

    worksheet2.set_column(0, 3, 15)

    worksheet2.write(0, 0, "Index", heading)
    worksheet2.write(0, 1, "Index", heading)
    worksheet2.write(0, 2, "Color", heading)
    worksheet2.write(0, 3, "Name",  heading)

    (8..63).each do |i|
      format = workbook.add_format(
          :fg_color => i,
          :pattern  => 1,
          :border   => 1
      )

      worksheet2.write((i - 7), 0, i,                    center)
      worksheet2.write((i - 7), 1, sprintf("0x%02X", i), center)
      worksheet2.write((i - 7), 2, '',                   format)

      # Add the  color names
      if colors.has_key?(i)
        worksheet2.write((i - 7), 3, colors[i], center)
      end
    end

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/colors.xls", @file)
  end

  def test_comments0
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet

    worksheet.write(0, 0, 'Hello a1')
    worksheet.write(0, 1, 'Hello b1')
    worksheet.write(1, 0, 'Hello a2')
    worksheet.write(1, 1, 'Hello b2')

    worksheet.write_comment('A1', 'This is a comment a1', :author=>'arr')
    worksheet.write_comment('A2', 'This is a comment a2', :author=>'arr')
    worksheet.write_comment('B1', 'This is a comment b1', :author=>'arr')
    worksheet.write_comment('B2', 'This is a comment b2', :author=>'arr')

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/comments0.xls", @file)
  end

  def test_comments1
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet

    worksheet.write('A1', 'Hello')
    worksheet.write_comment('A1', 'This is a comment')

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/comments1.xls", @file)
  end

  def test_comments2
    workbook   = WriteExcel.new(@file)
    text_wrap  = workbook.add_format(:text_wrap => 1, :valign => 'top')
    worksheet1 = workbook.add_worksheet
    worksheet2 = workbook.add_worksheet
    worksheet3 = workbook.add_worksheet
    worksheet4 = workbook.add_worksheet
    worksheet5 = workbook.add_worksheet
    worksheet6 = workbook.add_worksheet
    worksheet7 = workbook.add_worksheet
    worksheet8 = workbook.add_worksheet

    # Variables that we will use in each example.
    cell_text = ''
    comment   = ''

    ###############################################################################
    #
    # Example 1. Demonstrates a simple cell comment without formatting and Unicode
    #            comments encoded as UTF-16 and as UTF-8.
    #

    # Set up some formatting.
    worksheet1.set_column('C:C', 25)
    worksheet1.set_row(2, 50)
    worksheet1.set_row(5, 50)

    # Simple ascii string.
    cell_text = 'Hold the mouse over this cell to see the comment.'

    comment   = 'This is a comment.'

    worksheet1.write('C3', cell_text, text_wrap)
    worksheet1.write_comment('C3', comment)

    # UTF-16 string.
    cell_text = 'This is a UTF-16 comment.'

    comment   = [0x263a].pack("n")

    worksheet1.write('C6', cell_text, text_wrap)
    worksheet1.write_comment('C6', comment, :encoding => 1)

    # UTF-8 string.
    worksheet1.set_row(8, 50)
    cell_text = 'This is a UTF-8 string.'
    comment   = '☺'  # chr 0x263a in perl.

    worksheet1.write('C9', cell_text, text_wrap)
    worksheet1.write_comment('C9', comment)

    ###############################################################################
    #
    # Example 2. Demonstrates visible and hidden comments.
    #

    # Set up some formatting.
    worksheet2.set_column('C:C', 25)
    worksheet2.set_row(2, 50)
    worksheet2.set_row(5, 50)


    cell_text = 'This cell comment is visible.'

    comment   = 'Hello.'

    worksheet2.write('C3', cell_text, text_wrap)
    worksheet2.write_comment('C3', comment, :visible => 1)


    cell_text = "This cell comment isn't visible (the default)."

    comment   = 'Hello.'

    worksheet2.write('C6', cell_text, text_wrap)
    worksheet2.write_comment('C6', comment)

    ###############################################################################
    #
    # Example 3. Demonstrates visible and hidden comments set at the worksheet
    #            level.
    #

    # Set up some formatting.
    worksheet3.set_column('C:C', 25)
    worksheet3.set_row(2, 50)
    worksheet3.set_row(5, 50)
    worksheet3.set_row(8, 50)

    # Make all comments on the worksheet visible.
    worksheet3.show_comments

    cell_text = 'This cell comment is visible, explicitly.'

    comment   = 'Hello.'

    worksheet3.write('C3', cell_text, text_wrap)
    worksheet3.write_comment('C3', comment, :visible => 1)


    cell_text = 'This cell comment is also visible because ' +
                'we used show_comments().'

    comment   = 'Hello.'

    worksheet3.write('C6', cell_text, text_wrap)
    worksheet3.write_comment('C6', comment)


    cell_text = 'However, we can still override it locally.'

    comment   = 'Hello.'

    worksheet3.write('C9', cell_text, text_wrap)
    worksheet3.write_comment('C9', comment, :visible => 0)

    ###############################################################################
    #
    # Example 4. Demonstrates changes to the comment box dimensions.
    #

    # Set up some formatting.
    worksheet4.set_column('C:C', 25)
    worksheet4.set_row(2,  50)
    worksheet4.set_row(5,  50)
    worksheet4.set_row(8,  50)
    worksheet4.set_row(15, 50)

    worksheet4.show_comments

    cell_text = 'This cell comment is default size.'

    comment   = 'Hello.'

    worksheet4.write('C3', cell_text, text_wrap)
    worksheet4.write_comment('C3', comment)


    cell_text = 'This cell comment is twice as wide.'

    comment   = 'Hello.'

    worksheet4.write('C6', cell_text, text_wrap)
    worksheet4.write_comment('C6', comment, :x_scale => 2)


    cell_text = 'This cell comment is twice as high.'

    comment   = 'Hello.'

    worksheet4.write('C9', cell_text, text_wrap)
    worksheet4.write_comment('C9', comment, :y_scale => 2)


    cell_text = 'This cell comment is scaled in both directions.'

    comment   = 'Hello.'

    worksheet4.write('C16', cell_text, text_wrap)
    worksheet4.write_comment('C16', comment, :x_scale => 1.2, :y_scale => 0.8)


    cell_text = 'This cell comment has width and height specified in pixels.'

    comment   = 'Hello.'

    worksheet4.write('C19', cell_text, text_wrap)
    worksheet4.write_comment('C19', comment, :width => 200, :height => 20)

    ###############################################################################
    #
    # Example 5. Demonstrates changes to the cell comment position.
    #

    worksheet5.set_column('C:C', 25)
    worksheet5.set_row(2, 50)
    worksheet5.set_row(5, 50)
    worksheet5.set_row(8, 50)
    worksheet5.set_row(11, 50)

    worksheet5.show_comments

    cell_text = 'This cell comment is in the default position.'

    comment   = 'Hello.'

    worksheet5.write('C3', cell_text, text_wrap)
    worksheet5.write_comment('C3', comment)


    cell_text = 'This cell comment has been moved to another cell.'

    comment   = 'Hello.'

    worksheet5.write('C6', cell_text, text_wrap)
    worksheet5.write_comment('C6', comment, :start_cell => 'E4')


    cell_text = 'This cell comment has been moved to another cell.'

    comment   = 'Hello.'

    worksheet5.write('C9', cell_text, text_wrap)
    worksheet5.write_comment('C9', comment, :start_row => 8, :start_col => 4)


    cell_text = 'This cell comment has been shifted within its default cell.'

    comment   = 'Hello.'

    worksheet5.write('C12', cell_text, text_wrap)
    worksheet5.write_comment('C12', comment, :x_offset => 30, :y_offset => 12)

    ###############################################################################
    #
    # Example 6. Demonstrates changes to the comment background colour.
    #

    worksheet6.set_column('C:C', 25)
    worksheet6.set_row(2, 50)
    worksheet6.set_row(5, 50)
    worksheet6.set_row(8, 50)

    worksheet6.show_comments

    cell_text = 'This cell comment has a different colour.'

    comment   = 'Hello.'

    worksheet6.write('C3', cell_text, text_wrap)
    worksheet6.write_comment('C3', comment, :color => 'green')


    cell_text = 'This cell comment has the default colour.'

    comment   = 'Hello.'

    worksheet6.write('C6', cell_text, text_wrap)
    worksheet6.write_comment('C6', comment)

    cell_text = 'This cell comment has a different colour.'

    comment   = 'Hello.'

    worksheet6.write('C9', cell_text, text_wrap)
    worksheet6.write_comment('C9', comment, :color => 0x35)

    ###############################################################################
    #
    # Example 7. Demonstrates how to set the cell comment author.
    #

    worksheet7.set_column('C:C', 30)
    worksheet7.set_row(2,  50)
    worksheet7.set_row(5,  50)
    worksheet7.set_row(8,  50)
    worksheet7.set_row(11, 50)

    author = ''
    cell   = 'C3'

    cell_text = "Move the mouse over this cell and you will see 'Cell commented "+
                "by #{author}' (blank) in the status bar at the bottom"

    comment   = 'Hello.'

    worksheet7.write(cell, cell_text, text_wrap)
    worksheet7.write_comment(cell, comment)

    author    = 'Perl'
    cell      = 'C6'
    cell_text = "Move the mouse over this cell and you will see 'Cell commented " +
                "by #{author}' in the status bar at the bottom"

    comment   = 'Hello.'

    worksheet7.write(cell, cell_text, text_wrap)
    worksheet7.write_comment(cell, comment, :author => author)

    author    = [0x20AC].pack("n")  # UTF-16 Euro
    cell      = 'C9'
    cell_text = "Move the mouse over this cell and you will see 'Cell commented " +
                "by Euro' in the status bar at the bottom"

    comment   = 'Hello.'

    worksheet7.write(cell, cell_text, text_wrap)
    worksheet7.write_comment(cell, comment, :author  => author,
                                            :author_encoding => 1)

    # UTF-8 string.
    author    = '☺'    # smiley
    cell      = 'C12'
    cell_text = "Move the mouse over this cell and you will see 'Cell commented " +
                "by #{author}' in the status bar at the bottom"
    comment   = 'Hello.'

    worksheet7.write(cell, cell_text, text_wrap)
    worksheet7.write_comment(cell, comment, :author => author)

    ###############################################################################
    #
    # Example 8. Demonstrates the need to explicitly set the row height.
    #

    # Set up some formatting.
    worksheet8.set_column('C:C', 25)
    worksheet8.set_row(2, 80)

    worksheet8.show_comments

    cell_text = 'The height of this row has been adjusted explicitly using '  +
                'set_row(). The size of the comment box is adjusted '         +
                'accordingly by WriteExcel.'

    comment   = 'Hello.'

    worksheet8.write('C3', cell_text, text_wrap)
    worksheet8.write_comment('C3', comment)

    cell_text = 'The height of this row has been adjusted by Excel due to the '  +
                'text wrap property being set. Unfortunately this means that '   +
                'the height of the row is unknown to WriteExcel at run time '    +
                "and thus the comment box is stretched as well.\n\n"             +
                'Use set_row() to specify the row height explicitly to avoid '     +
                'this problem.'

    comment   = 'Hello.'

    worksheet8.write('C6', cell_text, text_wrap)
    worksheet8.write_comment('C6', comment)

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/comments2.xls", @file)
  end

  def test_formula_result
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet()
    format    = workbook.add_format(:color => 'blue')

    worksheet.write('A1', '=1+2')
    worksheet.write('A2', '=1+2',                     format, 4)
    worksheet.write('A3', '="ABC"',                   nil,    'DEF')
    worksheet.write('A4', '=IF(A1 > 1, TRUE, FALSE)', nil,    'TRUE')
    worksheet.write('A5', '=1/0',                     nil,    '#DIV/0!')

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/formula_result.xls", @file)
  end

  def test_indent
    workbook  = WriteExcel.new(@file)

    worksheet = workbook.add_worksheet()
    indent1   = workbook.add_format(:indent => 1)
    indent2   = workbook.add_format(:indent => 2)

    worksheet.set_column('A:A', 40)

    worksheet.write('A1', "This text is indented 1 level",  indent1)
    worksheet.write('A2', "This text is indented 2 levels", indent2)

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/indent.xls", @file)
  end

  def test_outline
    # Create a new workbook and add some worksheets
    workbook   = WriteExcel.new(@file)
    worksheet1 = workbook.add_worksheet('Outlined Rows')
    worksheet2 = workbook.add_worksheet('Collapsed Rows')
    worksheet3 = workbook.add_worksheet('Outline Columns')
    worksheet4 = workbook.add_worksheet('Outline levels')

    # Add a general format
    bold = workbook.add_format(:bold => 1)



    ###############################################################################
    #
    # Example 1: Create a worksheet with outlined rows. It also includes SUBTOTAL()
    # functions so that it looks like the type of automatic outlines that are
    # generated when you use the Excel Data->SubTotals menu item.
    #


    # For outlines the important parameters are $hidden and $level. Rows with the
    # same $level are grouped together. The group will be collapsed if $hidden is
    # non-zero. $height and $XF are assigned default values if they are undef.
    #
    # The syntax is: set_row($row, $height, $XF, $hidden, $level, $collapsed)
    #
    worksheet1.set_row(1,  nil, nil, 0, 2)
    worksheet1.set_row(2,  nil, nil, 0, 2)
    worksheet1.set_row(3,  nil, nil, 0, 2)
    worksheet1.set_row(4,  nil, nil, 0, 2)
    worksheet1.set_row(5,  nil, nil, 0, 1)

    worksheet1.set_row(6,  nil, nil, 0, 2)
    worksheet1.set_row(7,  nil, nil, 0, 2)
    worksheet1.set_row(8,  nil, nil, 0, 2)
    worksheet1.set_row(9,  nil, nil, 0, 2)
    worksheet1.set_row(10, nil, nil, 0, 1)


    # Add a column format for clarity
    worksheet1.set_column('A:A', 20)

    # Add the data, labels and formulas
    worksheet1.write('A1',  'Region', bold)
    worksheet1.write('A2',  'North')
    worksheet1.write('A3',  'North')
    worksheet1.write('A4',  'North')
    worksheet1.write('A5',  'North')
    worksheet1.write('A6',  'North Total', bold)

    worksheet1.write('B1',  'Sales',  bold)
    worksheet1.write('B2',  1000)
    worksheet1.write('B3',  1200)
    worksheet1.write('B4',  900)
    worksheet1.write('B5',  1200)
    worksheet1.write('B6',  '=SUBTOTAL(9,B2:B5)', bold)

    worksheet1.write('A7',  'South')
    worksheet1.write('A8',  'South')
    worksheet1.write('A9',  'South')
    worksheet1.write('A10', 'South')
    worksheet1.write('A11', 'South Total', bold)

    worksheet1.write('B7',  400)
    worksheet1.write('B8',  600)
    worksheet1.write('B9',  500)
    worksheet1.write('B10', 600)
    worksheet1.write('B11', '=SUBTOTAL(9,B7:B10)', bold)

    worksheet1.write('A12', 'Grand Total', bold)
    worksheet1.write('B12', '=SUBTOTAL(9,B2:B10)', bold)


    ###############################################################################
    #
    # Example 2: Create a worksheet with outlined rows. This is the same as the
    # previous example except that the rows are collapsed.
    # Note: We need to indicate the row that contains the collapsed symbol '+'
    # with the optional parameter, $collapsed.

    # The group will be collapsed if $hidden is non-zero.
    # The syntax is: set_row($row, $height, $XF, $hidden, $level, $collapsed)
    #
    worksheet2.set_row(1,  nil, nil, 1, 2)
    worksheet2.set_row(2,  nil, nil, 1, 2)
    worksheet2.set_row(3,  nil, nil, 1, 2)
    worksheet2.set_row(4,  nil, nil, 1, 2)
    worksheet2.set_row(5,  nil, nil, 1, 1)

    worksheet2.set_row(6,  nil, nil, 1, 2)
    worksheet2.set_row(7,  nil, nil, 1, 2)
    worksheet2.set_row(8,  nil, nil, 1, 2)
    worksheet2.set_row(9,  nil, nil, 1, 2)
    worksheet2.set_row(10, nil, nil, 1, 1)
    worksheet2.set_row(11, nil, nil, 0, 0, 1)


    # Add a column format for clarity
    worksheet2.set_column('A:A', 20)

    # Add the data, labels and formulas
    worksheet2.write('A1',  'Region', bold)
    worksheet2.write('A2',  'North')
    worksheet2.write('A3',  'North')
    worksheet2.write('A4',  'North')
    worksheet2.write('A5',  'North')
    worksheet2.write('A6',  'North Total', bold)

    worksheet2.write('B1',  'Sales',  bold)
    worksheet2.write('B2',  1000)
    worksheet2.write('B3',  1200)
    worksheet2.write('B4',  900)
    worksheet2.write('B5',  1200)
    worksheet2.write('B6',  '=SUBTOTAL(9,B2:B5)', bold)

    worksheet2.write('A7',  'South')
    worksheet2.write('A8',  'South')
    worksheet2.write('A9',  'South')
    worksheet2.write('A10', 'South')
    worksheet2.write('A11', 'South Total', bold)

    worksheet2.write('B7',  400)
    worksheet2.write('B8',  600)
    worksheet2.write('B9',  500)
    worksheet2.write('B10', 600)
    worksheet2.write('B11', '=SUBTOTAL(9,B7:B10)', bold)

    worksheet2.write('A12', 'Grand Total', bold)
    worksheet2.write('B12', '=SUBTOTAL(9,B2:B10)', bold)



    ###############################################################################
    #
    # Example 3: Create a worksheet with outlined columns.
    #
    data = [
                ['Month', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', ' Total'],
                ['North', 50,    20,    15,    25,    65,    80,    '=SUM(B2:G2)'],
                ['South', 10,    20,    30,    50,    50,    50,    '=SUM(B3:G3)'],
                ['East',  45,    75,    50,    15,    75,    100,   '=SUM(B4:G4)'],
                ['West',  15,    15,    55,    35,    20,    50,    '=SUM(B5:G6)']
            ]

    # Add bold format to the first row
    worksheet3.set_row(0, nil, bold)

    # Syntax: set_column(col1, col2, width, XF, hidden, level, collapsed)
    worksheet3.set_column('A:A', 10, bold      )
    worksheet3.set_column('B:G', 5,  nil, 0, 1)
    worksheet3.set_column('H:H', 10)

    # Write the data and a formula
    worksheet3.write_col('A1', data)
    worksheet3.write('H6', '=SUM(H2:H5)', bold)



    ###############################################################################
    #
    # Example 4: Show all possible outline levels.
    #
    levels = [
      "Level 1", "Level 2", "Level 3", "Level 4",
      "Level 5", "Level 6", "Level 7", "Level 6",
      "Level 5", "Level 4", "Level 3", "Level 2", "Level 1"
    ]

    worksheet4.write_col('A1', levels)

    worksheet4.set_row(0,  nil, nil, nil, 1)
    worksheet4.set_row(1,  nil, nil, nil, 2)
    worksheet4.set_row(2,  nil, nil, nil, 3)
    worksheet4.set_row(3,  nil, nil, nil, 4)
    worksheet4.set_row(4,  nil, nil, nil, 5)
    worksheet4.set_row(5,  nil, nil, nil, 6)
    worksheet4.set_row(6,  nil, nil, nil, 7)
    worksheet4.set_row(7,  nil, nil, nil, 6)
    worksheet4.set_row(8,  nil, nil, nil, 5)
    worksheet4.set_row(9,  nil, nil, nil, 4)
    worksheet4.set_row(10, nil, nil, nil, 3)
    worksheet4.set_row(11, nil, nil, nil, 2)
    worksheet4.set_row(12, nil, nil, nil, 1)

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/outline.xls", @file)
  end

  def test_outline_collapsed
    # Create a new workbook and add some worksheets
    workbook   = WriteExcel.new(@file)
    worksheet1 = workbook.add_worksheet('Outlined Rows')
    worksheet2 = workbook.add_worksheet('Collapsed Rows 1')
    worksheet3 = workbook.add_worksheet('Collapsed Rows 2')
    worksheet4 = workbook.add_worksheet('Collapsed Rows 3')
    worksheet5 = workbook.add_worksheet('Outline Columns')
    worksheet6 = workbook.add_worksheet('Collapsed Columns')

    # Add a general format
    bold = workbook.add_format(:bold => 1)

    #
    # This function will generate the same data and sub-totals on each worksheet.
    #
    def create_sub_totals(worksheet, bold)
      # Add a column format for clarity
      worksheet.set_column('A:A', 20)

      # Add the data, labels and formulas
      worksheet.write('A1',  'Region', bold)
      worksheet.write('A2',  'North')
      worksheet.write('A3',  'North')
      worksheet.write('A4',  'North')
      worksheet.write('A5',  'North')
      worksheet.write('A6',  'North Total', bold)

      worksheet.write('B1',  'Sales',  bold)
      worksheet.write('B2',  1000)
      worksheet.write('B3',  1200)
      worksheet.write('B4',  900)
      worksheet.write('B5',  1200)
      worksheet.write('B6',  '=SUBTOTAL(9,B2:B5)', bold)

      worksheet.write('A7',  'South')
      worksheet.write('A8',  'South')
      worksheet.write('A9',  'South')
      worksheet.write('A10', 'South')
      worksheet.write('A11', 'South Total', bold)

      worksheet.write('B7',  400)
      worksheet.write('B8',  600)
      worksheet.write('B9',  500)
      worksheet.write('B10', 600)
      worksheet.write('B11', '=SUBTOTAL(9,B7:B10)', bold)

      worksheet.write('A12', 'Grand Total', bold)
      worksheet.write('B12', '=SUBTOTAL(9,B2:B10)', bold)

    end


    ###############################################################################
    #
    # Example 1: Create a worksheet with outlined rows. It also includes SUBTOTAL()
    # functions so that it looks like the type of automatic outlines that are
    # generated when you use the Excel Data.SubTotals menu item.
    #

    # The syntax is: set_row(row, height, XF, hidden, level, collapsed)
    worksheet1.set_row(1,  nil, nil, 0, 2)
    worksheet1.set_row(2,  nil, nil, 0, 2)
    worksheet1.set_row(3,  nil, nil, 0, 2)
    worksheet1.set_row(4,  nil, nil, 0, 2)
    worksheet1.set_row(5,  nil, nil, 0, 1)

    worksheet1.set_row(6,  nil, nil, 0, 2)
    worksheet1.set_row(7,  nil, nil, 0, 2)
    worksheet1.set_row(8,  nil, nil, 0, 2)
    worksheet1.set_row(9,  nil, nil, 0, 2)
    worksheet1.set_row(10, nil, nil, 0, 1)

    # Write the sub-total data that is common to the row examples.
    create_sub_totals(worksheet1, bold)


    ###############################################################################
    #
    # Example 2: Create a worksheet with collapsed outlined rows.
    # This is the same as the example 1  except that the all rows are collapsed.
    # Note: We need to indicate the row that contains the collapsed symbol '+' with
    # the optional parameter, collapsed.

    worksheet2.set_row(1,  nil, nil, 1, 2)
    worksheet2.set_row(2,  nil, nil, 1, 2)
    worksheet2.set_row(3,  nil, nil, 1, 2)
    worksheet2.set_row(4,  nil, nil, 1, 2)
    worksheet2.set_row(5,  nil, nil, 1, 1)

    worksheet2.set_row(6,  nil, nil, 1, 2)
    worksheet2.set_row(7,  nil, nil, 1, 2)
    worksheet2.set_row(8,  nil, nil, 1, 2)
    worksheet2.set_row(9,  nil, nil, 1, 2)
    worksheet2.set_row(10, nil, nil, 1, 1)

    worksheet2.set_row(11, nil, nil, 0, 0, 1)

    # Write the sub-total data that is common to the row examples.
    create_sub_totals(worksheet2, bold)


    ###############################################################################
    #
    # Example 3: Create a worksheet with collapsed outlined rows.
    # Same as the example 1  except that the two sub-totals are collapsed.

    worksheet3.set_row(1,  nil, nil, 1, 2)
    worksheet3.set_row(2,  nil, nil, 1, 2)
    worksheet3.set_row(3,  nil, nil, 1, 2)
    worksheet3.set_row(4,  nil, nil, 1, 2)
    worksheet3.set_row(5,  nil, nil, 0, 1, 1)

    worksheet3.set_row(6,  nil, nil, 1, 2)
    worksheet3.set_row(7,  nil, nil, 1, 2)
    worksheet3.set_row(8,  nil, nil, 1, 2)
    worksheet3.set_row(9,  nil, nil, 1, 2)
    worksheet3.set_row(10, nil, nil, 0, 1, 1)


    # Write the sub-total data that is common to the row examples.
    create_sub_totals(worksheet3, bold)


    ###############################################################################
    #
    # Example 4: Create a worksheet with outlined rows.
    # Same as the example 1  except that the two sub-totals are collapsed.

    worksheet4.set_row(1,  nil, nil, 1, 2)
    worksheet4.set_row(2,  nil, nil, 1, 2)
    worksheet4.set_row(3,  nil, nil, 1, 2)
    worksheet4.set_row(4,  nil, nil, 1, 2)
    worksheet4.set_row(5,  nil, nil, 1, 1, 1)

    worksheet4.set_row(6,  nil, nil, 1, 2)
    worksheet4.set_row(7,  nil, nil, 1, 2)
    worksheet4.set_row(8,  nil, nil, 1, 2)
    worksheet4.set_row(9,  nil, nil, 1, 2)
    worksheet4.set_row(10, nil, nil, 1, 1, 1)

    worksheet4.set_row(11, nil, nil, 0, 0, 1)

    # Write the sub-total data that is common to the row examples.
    create_sub_totals(worksheet4, bold)



    ###############################################################################
    #
    # Example 5: Create a worksheet with outlined columns.
    #
    data = [
      ['Month', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',' Total'],
      ['North', 50,    20,    15,    25,    65,    80,   '=SUM(B2:G2)'],
      ['South', 10,    20,    30,    50,    50,    50,   '=SUM(B3:G3)'],
      ['East',  45,    75,    50,    15,    75,    100,  '=SUM(B4:G4)'],
      ['West',  15,    15,    55,    35,    20,    50,   '=SUM(B5:G6)']
    ]

    # Add bold format to the first row
    worksheet5.set_row(0, nil, bold)

    # Syntax: set_column(col1, col2, width, XF, hidden, level, collapsed)
    worksheet5.set_column('A:A', 10, bold      )
    worksheet5.set_column('B:G', 5,  nil, 0, 1)
    worksheet5.set_column('H:H', 10             )

    # Write the data and a formula
    worksheet5.write_col('A1', data)
    worksheet5.write('H6', '=SUM(H2:H5)', bold)


    ###############################################################################
    #
    # Example 6: Create a worksheet with collapsed outlined columns.
    # This is the same as the previous example except collapsed columns.

    # Add bold format to the first row
    worksheet6.set_row(0, nil, bold)

    # Syntax: set_column(col1, col2, width, XF, hidden, level, collapsed)
    worksheet6.set_column('A:A', 10, bold         )
    worksheet6.set_column('B:G', 5,  nil, 1, 1   )
    worksheet6.set_column('H:H', 10, nil, 0, 0, 1)

    # Write the data and a formula
    worksheet6.write_col('A1', data)
    worksheet6.write('H6', '=SUM(H2:H5)', bold)

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/outline_collapsed.xls", @file)
  end

  def test_panes
    workbook  = WriteExcel.new(@file)

    worksheet1 = workbook.add_worksheet('Panes 1')
    worksheet2 = workbook.add_worksheet('Panes 2')
    worksheet3 = workbook.add_worksheet('Panes 3')
    worksheet4 = workbook.add_worksheet('Panes 4')

    # Freeze panes
    worksheet1.freeze_panes(1, 0) # 1 row

    worksheet2.freeze_panes(0, 1) # 1 column
    worksheet3.freeze_panes(1, 1) # 1 row and column

    # Split panes.
    # The divisions must be specified in terms of row and column dimensions.
    # The default row height is 12.75 and the default column width is 8.43
    #
    worksheet4.split_panes(12.75, 8.43, 1, 1) # 1 row and column


    #######################################################################
    #
    # Set up some formatting and text to highlight the panes
    #

    header = workbook.add_format
    header.set_color('white')
    header.set_align('center')
    header.set_align('vcenter')
    header.set_pattern
    header.set_fg_color('green')

    center = workbook.add_format
    center.set_align('center')

    #######################################################################
    #
    # Sheet 1
    #

    worksheet1.set_column('A:I', 16)
    worksheet1.set_row(0, 20)
    worksheet1.set_selection('C3')

    (0..8).each { |i| worksheet1.write(0, i, 'Scroll down', header) }
    (1..100).each do |i|
     (0..8).each { |j| worksheet1.write(i, j, i + 1, center) }
    end

    #######################################################################
    #
    # Sheet 2
    #

    worksheet2.set_column('A:A', 16)
    worksheet2.set_selection('C3')

    (0..49).each do |i|
      worksheet2.set_row(i, 15)
      worksheet2.write(i, 0, 'Scroll right', header)
    end

    (0..49).each do |i|
      (1..25).each { |j| worksheet2.write(i, j, j, center) }
    end

    #######################################################################
    #
    # Sheet 3
    #

    worksheet3.set_column('A:Z', 16)
    worksheet3.set_selection('C3')

    (1..25).each { |i| worksheet3.write(0, i, 'Scroll down',  header) }

    (1..49).each { |i| worksheet3.write(i, 0, 'Scroll right', header) }

    (1..49).each do |i|
      (1..25).each { |j| worksheet3.write(i, j, j, center) }
    end

    #######################################################################
    #
    # Sheet 4
    #

    worksheet4.set_selection('C3')

    (1..25).each { |i| worksheet4.write(0, i, 'Scroll', center) }

    (1..49).each { |i| worksheet4.write(i, 0, 'Scroll', center) }

    (1..49).each do |i|
      (1..25).each { |j| worksheet4.write(i, j, j, center) }
    end

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/panes.xls", @file)
  end

  def test_right_to_left
    workbook   = WriteExcel.new(@file)
    worksheet1 = workbook.add_worksheet
    worksheet2 = workbook.add_worksheet

    worksheet2.right_to_left

    worksheet1.write(0, 0, 'Hello')  #  A1, B1, C1, ...
    worksheet2.write(0, 0, 'Hello')  # ..., C1, B1, A1

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/right_to_left.xls", @file)
  end

  def test_utf8
    workbook = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet('シート１')
    format = workbook.add_format(:font => 'ＭＳ 明朝')
    worksheet.set_footer('フッター')
    worksheet.set_header('ヘッダー')
    worksheet.write('A1', 'ＵＴＦ８文字列', format)
    worksheet.write('A2', '=CONCATENATE(A1,"の連結")', format)
    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/utf8.xls", @file)
  end

  def test_hide_zero
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet
    worksheet.write(0, 0, 'C2, E2 value is zero, not displayed')
    worksheet.write(1, 0, 1)
    worksheet.write(1, 1, 2)
    worksheet.write(1, 2, 0)
    worksheet.write(1, 3, 4)
    worksheet.write(1, 4, 0)

    worksheet.hide_zero
    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/hide_zero.xls", @file)
  end

  def test_set_first_sheet
    workbook = WriteExcel.new(@file)
    20.times { workbook.add_worksheet }
    worksheet21 = workbook.add_worksheet
    worksheet22 = workbook.add_worksheet

    worksheet21.set_first_sheet
    worksheet22.activate
    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/set_first_sheet.xls", @file)
  end

  def test_sheet_name
    workbook = WriteExcel.new(@file)

    worksheet = workbook.add_worksheet("Second")
    worksheet.write(0, 0, 2)

    worksheet = workbook.add_worksheet("First")
    worksheet.write(0, 0, 1)

    worksheet = workbook.add_worksheet("Third")
    worksheet.write(0, 0, "First :")
    worksheet.write_formula(0, 1, %q{='First'!A1})
    worksheet.write(1, 0, "Second :")
    worksheet.write_formula(1, 1, %q{='Second'!A1})
    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/sheet_name.xls", @file)
  end

  def test_store_formula
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet()

    formula = worksheet.store_formula('=A1 * 3 + 50')
    (0 .. 999).each do |row|
      worksheet.repeat_formula(row, 1, formula, nil, 'A1', "A#{row + 1}")
    end

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/store_formula.xls", @file)
  end

  def test_more_than_10_sheets_reference
    workbook  = WriteExcel.new(@file)

    worksheet1  = workbook.add_worksheet
    worksheet2  = workbook.add_worksheet
    worksheet3  = workbook.add_worksheet
    worksheet4  = workbook.add_worksheet
    worksheet5  = workbook.add_worksheet
    worksheet6  = workbook.add_worksheet
    worksheet7  = workbook.add_worksheet
    worksheet8  = workbook.add_worksheet
    worksheet9  = workbook.add_worksheet
    worksheet10 = workbook.add_worksheet
    worksheet11 = workbook.add_worksheet

    worksheet2.write(0, 0,  'worksheet2')
    worksheet3.write(0, 0,  'worksheet3')
    worksheet4.write(0, 0,  'worksheet4')
    worksheet5.write(0, 0,  'worksheet5')
    worksheet6.write(0, 0,  'worksheet6')
    worksheet7.write(0, 0,  'worksheet7')
    worksheet8.write(0, 0,  'worksheet8')
    worksheet9.write(0, 0,  'worksheet9')
    worksheet10.write(0, 0,  'worksheet10')
    worksheet11.write(0, 0,  'worksheet11')

    worksheet1.write(0, 2, '=Sheet2!A1')
    worksheet1.write(0, 3, '=Sheet3!A1')
    worksheet1.write(0, 4, '=Sheet4!A1')
    worksheet1.write(0, 5, '=Sheet5!A1')
    worksheet1.write(0, 6, '=Sheet6!A1')
    worksheet1.write(0, 7, '=Sheet7!A1')
    worksheet1.write(0, 8, '=Sheet8!A1')
    worksheet1.write(0, 9, '=Sheet9!A1')
    worksheet1.write(0, 10, '=Sheet10!A1')
    worksheet1.write(0, 11, '=Sheet11!A1')

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/more_than_10_sheets_reference.xls", @file)
  end

  def test_compatibility_mode_write_string
    workbook  = WriteExcel.new(@file)
    workbook.compatibility_mode

    worksheet = workbook.add_worksheet('DataSheet')
    worksheet.write_string(0,0,'Cell00')
    worksheet.write_string(0,1,'Cell01')
    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/compatibility_mode_write_string.xls", @file)
  end

  def test_compatibility_mode_write_number
    workbook  = WriteExcel.new(@file)
    workbook.compatibility_mode

    worksheet = workbook.add_worksheet('DataSheet')
    worksheet.write_number(0,0,100)
    worksheet.write_number(0,1,200)
    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/compatibility_mode_write_number.xls", @file)
  end

  def test_properties
    tz = ENV["TZ"]
    workbook  = WriteExcel.new(@file)

    #
    # adjust @localtime to target xls file.
    #
    ENV["TZ"] = "Japan"
    workbook.instance_variable_set(
                                   :@localtime,
                                   Time.gm(2013, 5, 5, 13, 37, 42).localtime
                                   )

    worksheet = workbook.add_worksheet

    workbook.set_properties(
                            :title    => 'This is an example spreadsheet',
                            :subject  => 'With document properties',
                            :author   => 'Hideo NAKAMURA',
                            :manager  => 'John McNamara',
                            :company  => 'Rubygem',
                            :category => 'Example spreadsheets',
                            :keywords => 'Sample, Example, Properties',
                            :comments => 'Created with Ruby and WriteExcel'
                            )


    worksheet.set_column('A:A', 50)
    worksheet.write('A1', 'Select File->Properties to see the file properties')

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/properties.xls", @file)

    ENV["TZ"] = tz
  end

  def test_chart_legend
    workbook  = WriteExcel.new(@file)
    worksheet = workbook.add_worksheet
    bold      = workbook.add_format(:bold => 1)

    # Add the worksheet data that the charts will refer to.
    headings = [ 'Category', 'Values 1', 'Values 2' ]
    data = [
            [ 2, 3, 4, 5, 6, 7 ],
            [ 1, 4, 5, 2, 1, 5 ],
            [ 3, 6, 7, 5, 4, 3 ]
           ]

    worksheet.write('A1', headings, bold)
    worksheet.write('A2', data)


    #
    # chart with legend
    #
    chart1 = workbook.add_chart(:type => 'Chart::Area', :embedded => 1)
    chart1.add_series( :values => '=Sheet1!$B$2:$B$7' )
    worksheet.insert_chart('E2', chart1)

    #
    # chart without legend
    #
    chart2 = workbook.add_chart(:type => 'Chart::Area', :embedded => 1)
    chart2.add_series( :values => '=Sheet1!$B$2:$B$7' )
    chart2.set_legend(:position => 'none')
    worksheet.insert_chart('E27', chart2)

    workbook.close

    # do assertion
    compare_file("#{PERL_OUTDIR}/chart_legend.xls", @file)
  end
end
