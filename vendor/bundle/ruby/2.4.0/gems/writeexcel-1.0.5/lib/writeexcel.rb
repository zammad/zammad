# -*- coding: utf-8 -*-
###############################################################################
#
# WriteExcel.
#
# WriteExcel - Write to a cross-platform Excel binary file.
#
# Copyright 2000-2010, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
require 'writeexcel/biffwriter'
require 'writeexcel/olewriter'
require 'writeexcel/formula'
require 'writeexcel/format'
require 'writeexcel/worksheet'
require "writeexcel/workbook"
require 'writeexcel/chart'
require 'writeexcel/charts/area'
require 'writeexcel/charts/bar'
require 'writeexcel/charts/column'
require 'writeexcel/charts/external'
require 'writeexcel/charts/line'
require 'writeexcel/charts/pie'
require 'writeexcel/charts/scatter'
require 'writeexcel/charts/stock'
require 'writeexcel/storage_lite'
require 'writeexcel/compatibility'
require 'writeexcel/debug_info'
#
# = WriteExcel - Write to a cross-platform Excel binary file.
#
# == Contents
#     SYSNOPSYS
#     DESCRIPTION
#     QUICK START
#     WORKBOOK METHODS
#     WORKSHEET METHODS
#     PAGE SET-UP METHODS
#     CELL FORMATTING
#     FORMAT METHODS
#     COLOURS IN EXCEL
#     DATE AND TIME IN EXCEL
#     OUTLINES AND GROUPING IN EXCEL
#     DATA VALIDATION IN EXCEL
#     FORMULAS AND FUNCTIONS IN EXCEL
#     CHART
#
# == Synopsis
#
# To write a string, a formatted string, a number and a formula to the first
# worksheet in an Excel workbook called ruby.xls:
#
#     require 'WriteExcel'
#
#     # Create a new Excel workbook
#     workbook = WriteExcel.new('ruby.xls')
#
#     # Add a worksheet
#     worksheet = workbook.add_worksheet
#
#     #  Add and define a format
#     format = workbook.add_format # Add a format
#     format.set_bold()
#     format.set_color('red')
#     format.set_align('center')
#
#     # Write a formatted and unformatted string, row and column notation.
#     col = row = 0
#     worksheet.write(row, col, 'Hi Excel!', format)
#     worksheet.write(1,   col, 'Hi Excel!')
#
#     # Write a number and a formula using A1 notation
#     worksheet.write('A3', 1.2345)
#     worksheet.write('A4', '=SIN(PI()/4)')
#
#     # Save to ruby.xls
#     workbook.close
#
# == Description
#
# WriteExcel can be used to create a cross-platform Excel binary file.
# Multiple worksheets can be added to a workbook and formatting can be applied
# to cells. Text, numbers, formulas, hyperlinks and images can be written to
# the cells.
#
# The Excel file produced by this gem is compatible with 97, 2000, 2002, 2003
# and 2007.
#
# WriteExcel will work on the majority of Windows, UNIX and Mac platforms.
# Generated files are also compatible with the Linux/UNIX spreadsheet
# applications Gnumeric and OpenOffice.org.
#
# This module cannot be used to write to an existing Excel file
#
# This library is converted from  Spreadsheet::WriteExcel module of Perl.
# http://search.cpan.org/~jmcnamara/Spreadsheet-WriteExcel-2.37/
#
# == Quick Start
#
# WriteExcel tries to provide an interface to as many of Excel's features as
# possible. As a result there is a lot of documentation to accompany the
# interface and it can be difficult at first glance to see what it important
# and what is not. So for those of you who prefer to assemble Ikea furniture
# first and then read the instructions, here are four easy steps:
#
# 1. Create a new Excel workbook (i.e. file) using new().
#
# 2. Add a worksheet to the new workbook using add_worksheet().
#
# 3. Write to the worksheet using write().
#
# 4. Save to file.
#
# Like this:
#
#     require 'WriteExcel'                     # Step 0
#
#     workbook  = WriteExcel.new('ruby.xls')   # Step 1
#     worksheet = workbook.add_worksheet       # Step 2
#     worksheet.write('A1', 'Hi Excel!')       # Step 3
#     workbook.close                           # Step 4
#
# This will create an Excel file called ruby.xls with a single worksheet and the
# text 'Hi Excel!' in the relevant cell. And that's it. Okay, so there is
# actually a zeroth step as well, but use WriteExcel goes without saying. There
# are also many examples that come with the distribution and which you can
# use to get you started. See EXAMPLES.
#
# = Workbook methods
#
# The WriteExcel module provides an object oriented interface
# to a new Excel workbook. The following methods are available through
# a new workbook.
#
#     new()
#     add_worksheet()
#     add_format()
#     add_chart()
#     add_chart_ext()
#     close()
#     compatibility_mode()
#     set_properties()
#     define_name()
#     set_tempdir()
#     set_custom_color()
#     sheets()
#     set_1904()
#     set_codepage()
#
# = Worksheet methods
#
# A new worksheet is created by calling the add_worksheet() method from
# a workbook object:
#
#     worksheet1 = workbook.add_worksheet
#     worksheet2 = workbook.add_worksheet
#
# The following methods are available through a new worksheet:
#
#     write()
#     write_number()
#     write_string()
#     write_utf16be_string()
#     write_utf16le_string()
#     keep_leading_zeros()
#     write_blank()
#     write_row()
#     write_col()
#     write_date_time()
#     write_url()
#     write_url_range()
#     write_formula()
#     store_formula()
#     repeat_formula()
#     write_comment()
#     show_comments()
#     add_write_handler()  (* not implemented yet)
#     insert_image()
#     insert_chart()
#     data_validation()
#     get_name()
#     activate()
#     select()
#     hide()
#     set_first_sheet()
#     protect()
#     set_selection()
#     set_row()
#     set_column()
#     outline_settings()
#     freeze_panes()
#     split_panes()
#     merge_range()
#     set_zoom()
#     right_to_left()
#     hide_zero()
#     set_tab_color()
#     autofilter()
#
# == Cell notation
# WriteExcel supports two forms of notation to designate the position of cells:
# Row-column notation and A1 notation.
#
# Row-column notation uses a zero based index for both row and column while A1
# notation uses the standard Excel alphanumeric sequence of column letter and
# 1-based row. For example:
#
#    (0, 0)      # The top left cell in row-column notation.
#    ('A1')      # The top left cell in A1 notation.
#
#    (1999, 29)  # Row-column notation.
#    ('AD2000')  # The same cell in A1 notation.
#
# Row-column notation is useful if you are referring to cells
# programmatically:
#
#    (0 .. 10).each do |i|
#        worksheet.write(i, 0, 'Hello')  # Cells A1 to A10
#    end
#
# A1 notation is useful for setting up a worksheet manually and for working
# with formulas:
#
#    worksheet.write('H1', 200)
#    worksheet.write('H2', '=H1+1')
#
# In formulas and applicable methods you can also use the A:A column notation:
#
#    worksheet.write('A1', '=SUM(B:B)')
#
# For simplicity, the parameter lists for the worksheet method calls in the
# following sections are given in terms of row-column notation. In all cases
# it is also possible to use A1 notation.
#
# Note: in Excel it is also possible to use a R1C1 notation. This is not
# supported by WriteExcel.
#
# ==PAGE SET-UP METHODS
#
# Page set-up methods affect the way that a worksheet looks when it is printed.
# They control features such as page headers and footers and margins. These
# methods are really just standard worksheet methods. They are documented
# here in a separate section for the sake of clarity.
#
# The following methods are available for page set-up:
#
#     set_landscape()
#     set_portrait()
#     set_page_view()
#     set_paper()
#     center_horizontally()
#     center_vertically()
#     set_margins()
#     set_header()
#     set_footer()
#     repeat_rows()
#     repeat_columns()
#     hide_gridlines()
#     print_row_col_headers()
#     print_area()
#     print_across()
#     fit_to_pages()
#     set_start_page()
#     set_print_scale()
#     set_h_pagebreaks()
#     set_v_pagebreaks()
#
# A common requirement when working with WriteExcel is to apply the same page
# set-up features to all of the worksheets in a workbook. To do this you can use
# the sheets() method of the workbook class to access the array of worksheets
# in a workbook:
#
#     workbook.sheets.each do |worksheet|
#        worksheet.set_landscape
#     end
#
# ==CELL FORMATTING
#
# This section describes the methods and properties that are available for
# formatting cells in Excel. The properties of a cell that can be formatted
# include: fonts, colours, patterns, borders, alignment and number formatting.
#
# ===Creating and using a Format object
#
# Cell formatting is defined through a Format object. Format objects are
# created by calling the workbook add_format() method as follows:
#
#     format1 = workbook.add_format                   # Set properties later
#     format2 = workbook.add_format(property hash..)  # Set at creation
#
# The format object holds all the formatting properties that can be applied
# to a cell, a row or a column. The process of setting these properties is
# discussed in the next section.
#
# Once a Format object has been constructed and it properties have been set
# it can be passed as an argument to the worksheet write methods as follows:
#
#     worksheet.write(0, 0, 'One', format)
#     worksheet.write_string(1, 0, 'Two', format)
#     worksheet.write_number(2, 0, 3, format)
#     worksheet.write_blank(3, 0, format)
#
# Formats can also be passed to the worksheet set_row() and set_column()
# methods to define the default property for a row or column.
#
#     worksheet.set_row(0, 15, format)
#     worksheet.set_column(0, 0, 15, format)
#
# ===Format methods and Format properties
#
# The following table shows the Excel format categories, the formatting
# properties that can be applied and the equivalent object method:
#
#     Category   Description       Property        Method Name
#     --------   -----------       --------        -----------
#     Font       Font type         font            set_font()
#                Font size         size            set_size()
#                Font color        color           set_color()
#                Bold              bold            set_bold()
#                Italic            italic          set_italic()
#                Underline         underline       set_underline()
#                Strikeout         font_strikeout  set_font_strikeout()
#                Super/Subscript   font_script     set_font_script()
#                Outline           font_outline    set_font_outline()
#                Shadow            font_shadow     set_font_shadow()
#
#     Number     Numeric format    num_format      set_num_format()
#
#     Protection Lock cells        locked          set_locked()
#                Hide formulas     hidden          set_hidden()
#
#     Alignment  Horizontal align  align           set_align()
#                Vertical align    valign          set_align()
#                Rotation          rotation        set_rotation()
#                Text wrap         text_wrap       set_text_wrap()
#                Justify last      text_justlast   set_text_justlast()
#                Center across     center_across   set_center_across()
#                Indentation       indent          set_indent()
#                Shrink to fit     shrink          set_shrink()
#
#     Pattern    Cell pattern      pattern         set_pattern()
#                Background color  bg_color        set_bg_color()
#                Foreground color  fg_color        set_fg_color()
#
#     Border     Cell border       border          set_border()
#                Bottom border     bottom          set_bottom()
#                Top border        top             set_top()
#                Left border       left            set_left()
#                Right border      right           set_right()
#                Border color      border_color    set_border_color()
#                Bottom color      bottom_color    set_bottom_color()
#                Top color         top_color       set_top_color()
#                Left color        left_color      set_left_color()
#                Right color       right_color     set_right_color()
#
# There are two ways of setting Format properties: by using the object method
# interface or by setting the property directly. For example, a typical use of
# the method interface would be as follows:
#
#     format = workbook.add_format
#     format.set_bold
#     format.set_color('red')
#
# By comparison the properties can be set directly by passing a hash of
# properties to the Format constructor:
#
#     format = workbook.add_format(:bold => 1, :color => 'red')
#
# or after the Format has been constructed by means of the
# set_format_properties() method as follows:
#
#     format = workbook.add_format
#     format.set_format_properties(:bold => 1, :color => 'red')
#
# You can also store the properties in one or more named hashes and pass them
# to the required method:
#
#     font    = {
#                  :font  => 'Arial',
#                  :size  => 12,
#                  :color => 'blue',
#                  :bold  => 1
#               }
#
#     shading = {
#                  :bg_color => 'green',
#                  :pattern  => 1
#               }
#
#     format1 = workbook.add_format(font)           # Font only
#     format2 = workbook.add_format(font, shading)  # Font and shading
#
# The provision of two ways of setting properties might lead you to wonder
# which is the best way. The method mechanism may be better is you prefer
# setting properties via method calls (which the author did when they were
# code was first written) otherwise passing properties to the constructor has
# proved to be a little more flexible and self documenting in practice. An
# additional advantage of working with property hashes is that it allows you to
# share formatting between workbook objects as shown in the example above.
#
#--
#
# did not converted ???
#
# The Perl/Tk style of adding properties is also supported:
#
#     %font    = (
#                     -font      => 'Arial',
#                     -size      => 12,
#                     -color     => 'blue',
#                     -bold      => 1,
#                   )
#++
#
# ===Working with formats
#
# The default format is Arial 10 with all other properties off.
#
# Each unique format in WriteExcel must have a corresponding
# Format object. It isn't possible to use a Format with a write() method and
# then redefine the Format for use at a later stage. This is because a Format
# is applied to a cell not in its current state but in its final state.
# Consider the following example:
#
#     format = workbook.add_format
#     format.set_bold
#     format.set_color('red')
#     worksheet.write('A1', 'Cell A1', format)
#     format.set_color('green')
#     worksheet.write('B1', 'Cell B1', format)
#
# Cell A1 is assigned the Format _format_ which is initially set to the colour
# red. However, the colour is subsequently set to green. When Excel displays
# Cell A1 it will display the final state of the Format which in this case
# will be the colour green.
#
# In general a method call without an argument will turn a property on,
# for example:
#
#     format1 = workbook.add_format
#     format1.set_bold     # Turns bold on
#     format1.set_bold(1)  # Also turns bold on
#     format1.set_bold(0)  # Turns bold off
#
# ==FORMAT METHODS
#
# The Format object methods are described in more detail in the following
# sections. In addition, there is a Ruby program called formats.rb in the
# examples directory of the WriteExcel distribution. This program creates an
# Excel workbook called formats.xls which contains examples of almost all
# the format types.
#
# The following Format methods are available:
#
#     set_font()
#     set_size()
#     set_color()
#     set_bold()
#     set_italic()
#     set_underline()
#     set_font_strikeout()
#     set_font_script()
#     set_font_outline()
#     set_font_shadow()
#     set_num_format()
#     set_locked()
#     set_hidden()
#     set_align()
#     set_rotation()
#     set_text_wrap()
#     set_text_justlast()
#     set_center_across()
#     set_indent()
#     set_shrink()
#     set_pattern()
#     set_bg_color()
#     set_fg_color()
#     set_border()
#     set_bottom()
#     set_top()
#     set_left()
#     set_right()
#     set_border_color()
#     set_bottom_color()
#     set_top_color()
#     set_left_color()
#     set_right_color()
#
# The above methods can also be applied directly as properties. For example
# format.set_bold is equivalent to workbook.add_format(:bold => 1).
#
# ==COLOURS IN EXCEL
#
# Excel provides a colour palette of 56 colours. In WriteExcel these colours
# are accessed via their palette index in the range 8..63. This index is used
# to set the colour of fonts, cell patterns and cell borders. For example:
#
#     format = workbook.add_format(
#                   :color => 12, # index for blue
#                   :font  => 'Arial',
#                   :size  => 12,
#                   :bold  => 1
#                 )
#
# The most commonly used colours can also be accessed by name. The name acts
# as a simple alias for the colour index:
#
#     black     =>    8
#     blue      =>   12
#     brown     =>   16
#     cyan      =>   15
#     gray      =>   23
#     green     =>   17
#     lime      =>   11
#     magenta   =>   14
#     navy      =>   18
#     orange    =>   53
#     pink      =>   33
#     purple    =>   20
#     red       =>   10
#     silver    =>   22
#     white     =>    9
#     yellow    =>   13
#
# For example:
#
#     font = workbook.add_format(:color => 'red')
#
# Users of VBA in Excel should note that the equivalent colour indices are in
# the range 1..56 instead of 8..63.
#
# If the default palette does not provide a required colour you can override
# one of the built-in values. This is achieved by using the set_custom_color()
# workbook method to adjust the RGB (red green blue) components of the colour:
#
#     ferrari = workbook.set_custom_color(40, 216, 12, 12)
#
#     format  = workbook.add_format(
#                   :bg_color => ferrari,
#                   :pattern  => 1,
#                   :border   => 1
#                 )
#
#     worksheet.write_blank('A1', format)
#
# You may also find the following links helpful:
#
# A detailed look at Excel's colour palette:
# http://www.mvps.org/dmcritchie/excel/colors.htm
#
# A decimal RGB chart: http://www.hypersolutions.org/pages/rgbdec.html
#
# A hex RGB chart: : http://www.hypersolutions.org/pages/rgbhex.html
#
# ==DATES AND TIME IN EXCEL
#
# There are two important things to understand about dates and times in Excel:
#
# 1. A date/time in Excel is a real number plus an Excel number format.
#
# 2. WriteExcel doesn't automatically convert date/time strings in write() to
#    an Excel date/time.
#
# These two points are explained in more detail below along with some
# suggestions on how to convert times and dates to the required format.
#
# ===An Excel date/time is a number plus a format
#
# If you write a date string with write() then all you will get is a string:
#
#     worksheet.write('A1', '02/03/04')  # !! Writes a string not a date. !!
#
# Dates and times in Excel are represented by real numbers, for example
# "Jan 1 2001 12:30 AM" is represented by the number 36892.521.
#
# The integer part of the number stores the number of days since the epoch
# and the fractional part stores the percentage of the day.
#
# A date or time in Excel is just like any other number. To have the number
# display as a date you must apply an Excel number format to it. Here are
# some examples.
#
#     #!/usr/bin/ruby -w
#
#     require 'writeexcel'
#
#     workbook  = WriteExcel.new('date_examples.xls')
#     worksheet = workbook.add_worksheet
#
#     worksheet.set_column('A:A', 30)  # For extra visibility.
#
#     number    = 39506.5
#
#     worksheet.write('A1', number)            #     39506.5
#
#     format2 = workbook.add_format(:num_format => 'dd/mm/yy')
#     worksheet.write('A2', number , format2); #     28/02/08
#
#     format3 = workbook.add_format(:num_format => 'mm/dd/yy')
#     worksheet.write('A3', number , format3); #     02/28/08
#
#     format4 = workbook.add_format(:num_format => 'd-m-yyyy')
#     worksheet.write('A4', .number , format4) #     28-2-2008
#
#     format5 = workbook.add_format(:num_format => 'dd/mm/yy hh:mm')
#     worksheet.write('A5', number , format5)  #     28/02/08 12:00
#
#     format6 = workbook.add_format(:num_format => 'd mmm yyyy')
#     worksheet.write('A6', number , format6)  #     28 Feb 2008
#
#     format7 = workbook.add_format(:num_format => 'mmm d yyyy hh:mm AM/PM')
#     worksheet.write('A7', number , format7)  #     Feb 28 2008 12:00 PM
#
# ===WriteExcel doesn't automatically convert date/time strings
#
# WriteExcel doesn't automatically convert input date strings into Excel's
# formatted date numbers due to the large number of possible date formats
# and also due to the possibility of misinterpretation.
#
# For example, does 02/03/04 mean March 2 2004, February 3 2004 or even March
# 4 2002.
#
# Therefore, in order to handle dates you will have to convert them to numbers
#  and apply an Excel format. Some methods for converting dates are listed in
# the next section.
#
# The most direct way is to convert your dates to the ISO8601
# yyyy-mm-ddThh:mm:ss.sss date format and use the write_date_time() worksheet
# method:
#
#     worksheet.write_date_time('A2', '2001-01-01T12:20', format)
#
# See the write_date_time() section of the documentation for more details.
#
# A general methodology for handling date strings with write_date_time() is:
#
#     1. Identify incoming date/time strings with a regex.
#     2. Extract the component parts of the date/time using the same regex.
#     3. Convert the date/time to the ISO8601 format.
#     4. Write the date/time using write_date_time() and a number format.
#
# Here is an example:
#
#     #!/usr/bin/ruby -w
#
#     require 'writeexcel'
#
#     workbook    = WriteExcel.new('example.xls')
#     worksheet   = workbook.add_worksheet
#
#     # Set the default format for dates.
#     date_format = workbook.add_format(:num_format => 'mmm d yyyy')
#
#     # Increase column width to improve visibility of data.
#     worksheet.set_column('A:C', 20)
#
#     data = [
#       %w(Item    Cost    Date),
#       %w(Book    10      1/9/2007),
#       %w(Beer    4       12/9/2007),
#       %w(Bed     500     5/10/2007)
#     ]
#
#     # Simulate reading from a data source.
#     row = 0
#
#     data.each do |row_data|
#       col  = 0
#       row_data.each do |item|
#
#         # Match dates in the following formats: d/m/yy, d/m/yyyy
#         if item =~ %r[^(\d{1,2})/(\d{1,2})/(\d{4})$]
#           # Change to the date format required by write_date_time().
#           date = sprintf "%4d-%02d-%02dT", $3, $2, $1
#           worksheet.write_date_time(row, col, date, date_format)
#         else
#           # Just plain data
#           worksheet.write(row, col, item)
#         end
#         col += 1
#       end
#       row += 1
#     end
#
#--
# For a slightly more advanced solution you can modify the write() method to
# handle date formats of your choice via the add_write_handler() method. See
# the add_write_handler() section of the docs and the write_handler3.rb and
# write_handler4.rb programs in the examples directory of the distro.
#++
#
# ==OUTLINES AND GROUPING IN EXCEL
#
# Excel allows you to group rows or columns so that they can be hidden or
# displayed with a single mouse click. This feature is referred to as outlines.
#
# Outlines can reduce complex data down to a few salient sub-totals or
# summaries.
#
# This feature is best viewed in Excel but the following is an ASCII
# representation of what a worksheet with three outlines might look like. Rows
# 3-4 and rows 7-8 are grouped at level 2. Rows 2-9 are grouped at level 1.
# The lines at the left hand side are called outline level bars.
#
#             ------------------------------------------
#      1 2 3 |   |   A   |   B   |   C   |   D   |  ...
#             ------------------------------------------
#       _    | 1 |   A   |       |       |       |  ...
#      |  _  | 2 |   B   |       |       |       |  ...
#      | |   | 3 |  (C)  |       |       |       |  ...
#      | |   | 4 |  (D)  |       |       |       |  ...
#      | -   | 5 |   E   |       |       |       |  ...
#      |  _  | 6 |   F   |       |       |       |  ...
#      | |   | 7 |  (G)  |       |       |       |  ...
#      | |   | 8 |  (H)  |       |       |       |  ...
#      | -   | 9 |   I   |       |       |       |  ...
#      -     | . |  ...  |  ...  |  ...  |  ...  |  ...
#
# Clicking the minus sign on each of the level 2 outlines will collapse and
# hide the data as shown in the next figure. The minus sign changes to a plus
# sign to indicate that the data in the outline is hidden.
#
#             ------------------------------------------
#      1 2 3 |   |   A   |   B   |   C   |   D   |  ...
#             ------------------------------------------
#       _    | 1 |   A   |       |       |       |  ...
#      |     | 2 |   B   |       |       |       |  ...
#      | +   | 5 |   E   |       |       |       |  ...
#      |     | 6 |   F   |       |       |       |  ...
#      | +   | 9 |   I   |       |       |       |  ...
#      -     | . |  ...  |  ...  |  ...  |  ...  |  ...
#
# Clicking on the minus sign on the level 1 outline will collapse the
# remaining rows as follows:
#
#             ------------------------------------------
#      1 2 3 |   |   A   |   B   |   C   |   D   |  ...
#             ------------------------------------------
#            | 1 |   A   |       |       |       |  ...
#      +     | . |  ...  |  ...  |  ...  |  ...  |  ...
#
# Grouping in WriteExcel is achieved by setting the outline level via the
# set_row() and set_column() worksheet methods:
#
#     set_row(row, height, format, hidden, level, collapsed)
#     set_column(first_col, last_col, width, format, hidden, level, collapsed)
#
# The following example sets an outline level of 1 for rows 1 and 2
# (zero-indexed) and columns B to G. The parameters _height_ and _format_ are
# assigned default values since they are undefined:
#
#     worksheet.set_row(1, nil, nil, 0, 1)
#     worksheet.set_row(2, nil, nil, 0, 1)
#     worksheet.set_column('B:G', nil, nil, 0, 1)
#
# Excel allows up to 7 outline levels. Therefore the _level_ parameter should
# be in the range 0 <= _level_ <= 7.
#
# Rows and columns can be collapsed by setting the _hidden_ flag for the hidden
# rows/columns and setting the _collapsed_ flag for the row/column that has
# the collapsed + symbol:
#
#     worksheet.set_row(1, nil, nil, 1, 1)
#     worksheet.set_row(2, nil, nil, 1, 1)
#     worksheet.set_row(3, nil, nil, 0, 0, 1)         # Collapsed flag.
#
#     worksheet.set_column('B:G', nil, nil, 1, 1)
#     worksheet.set_column('H:H', nil, nil, 0, 0, 1)  # Collapsed flag.
#
# Note: Setting the _collapsed_ flag is particularly important for
# compatibility with OpenOffice.org and Gnumeric.
#
# For a more complete example see the outline.rb
# and outline_collapsed.rb
# programs in the examples directory of the distro.
#
# Some additional outline properties can be set via the outline_settings()
# worksheet method, see above.
#
# ==DATA VALIDATION IN EXCEL
#
# Data validation is a feature of Excel which allows you to restrict the data
# that a users enters in a cell and to display help and warning messages. It
# also allows you to restrict input to values in a drop down list.
#
# A typical use case might be to restrict data in a cell to integer values in
# a certain range, to provide a help message to indicate the required value and
# to issue a warning if the input data doesn't meet the stated criteria.
# In WriteExcel we could do that as follows:
#
#     worksheet.data_validation('B3',
#         {
#             :validate        => 'integer',
#             :criteria        => 'between',
#             :minimum         => 1,
#             :maximum         => 100,
#             :input_title     => 'Input an integer:',
#             :input_message   => 'Between 1 and 100',
#             :error_message   => 'Sorry, try again.'
#         })
#
# The above example would look like this in Excel:
#    http://homepage.eircom.net/~jmcnamara/perl/data_validation.jpg.
#
# For more information on data validation see the following Microsoft
# support article "Description and examples of data validation in Excel":
#    http://support.microsoft.com/kb/211485.
#
# ==FORMULAS AND FUNCTIONS IN EXCEL
#
# ===Caveats
#
# The first thing to note is that there are still some outstanding issues
# with the implementation of formulas and functions:
#
#     1. Writing a formula is much slower than writing the equivalent string.
#     2. You cannot use array constants, i.e. {1;2;3}, in functions.
#     3. Unary minus isn't supported.
#     4. Whitespace is not preserved around operators.
#     5. Named ranges are not supported.
#     6. Array formulas are not supported.
#
# However, these constraints will be removed in future versions. They are
# here because of a trade-off between features and time. Also, it is possible
# to work around issue 1 using the store_formula() and repeat_formula()
# methods as described later in this section.
#
# ===Introduction
#
# The following is a brief introduction to formulas and functions in Excel
# and WriteExcel.
#
# A formula is a string that begins with an equals sign:
#
#     '=A1+B1'
#     '=AVERAGE(1, 2, 3)'
#
# The formula can contain numbers, strings, boolean values, cell references,
# cell ranges and functions. Named ranges are not supported. Formulas should
# be written as they appear in Excel, that is cells and functions must be
# in uppercase.
#
# Cells in Excel are referenced using the A1 notation system where the
# column is designated by a letter and the row by a number. Columns
# range from A to IV i.e. 0 to 255, rows range from 1 to 65536.
#--
# The WriteExcel::Utility module that is included in the distro
# contains helper functions for dealing with A1 notation, for example:
#
#     use Spreadsheet::WriteExcel::Utility;
#
#     ($row, $col) = xl_cell_to_rowcol('C2');  # (1, 2)
#     $str         = xl_rowcol_to_cell(1, 2);  # C2
#++
#
# The Excel $ notation in cell references is also supported. This allows you
# to specify whether a row or column is relative or absolute. This only has
# an effect if the cell is copied. The following examples show relative and
# absolute values.
#
#     '=A1'   # Column and row are relative
#     '=$A1'  # Column is absolute and row is relative
#     '=A$1'  # Column is relative and row is absolute
#     '=$A$1' # Column and row are absolute
#
# Formulas can also refer to cells in other worksheets of the current
# workbook. For example:
#
#     '=Sheet2!A1'
#     '=Sheet2!A1:A5'
#     '=Sheet2:Sheet3!A1'
#     '=Sheet2:Sheet3!A1:A5'
#     q{='Test Data'!A1}
#     q{='Test Data1:Test Data2'!A1}
#
# The sheet reference and the cell reference are separated by ! the exclamation
# mark symbol. If worksheet names contain spaces, commas o parentheses then Excel
# requires that the name is enclosed in single quotes as shown in the last two
# examples above. In order to avoid using a lot of escape characters you can
# use the quote operator %q{} to protect the quotes. Only valid sheet names that
# have been added using the add_worksheet() method can be used in formulas.
# You cannot reference external workbooks.
#
# The following table lists the operators that are available in Excel's formulas.
# The majority of the operators are the same as Perl's, differences are indicated:
#
#     Arithmetic operators:
#     =====================
#     Operator  Meaning                   Example
#        +      Addition                  1+2
#        -      Subtraction               2-1
#        *      Multiplication            2*3
#        /      Division                  1/4
#        ^      Exponentiation            2^3      # Equivalent to **
#        -      Unary minus               -(1+2)   # Not yet supported
#        %      Percent (Not modulus)     13%      # Not supported, [1]
#
#     Comparison operators:
#     =====================
#     Operator  Meaning                   Example
#         =     Equal to                  A1 =  B1 # Equivalent to ==
#         <>    Not equal to              A1 <> B1 # Equivalent to !=
#         >     Greater than              A1 >  B1
#         <     Less than                 A1 <  B1
#         >=    Greater than or equal to  A1 >= B1
#         <=    Less than or equal to     A1 <= B1
#
#     String operator:
#     ================
#     Operator  Meaning                   Example
#         &     Concatenation             "Hello " & "World!" # [2]
#
#     Reference operators:
#     ====================
#     Operator  Meaning                   Example
#         :     Range operator            A1:A4               # [3]
#         ,     Union operator            SUM(1, 2+2, B3)     # [4]
#
#     Notes:
#     [1]: You can get a percentage with formatting and modulus with MOD().
#     [2]: Equivalent to ("Hello " . "World!") in Perl.
#     [3]: This range is equivalent to cells A1, A2, A3 and A4.
#     [4]: The comma behaves like the list separator in Perl.
#
# The range and comma operators can have different symbols in non-English
# versions of Excel. These will be supported in a later version of WriteExcel.
# European users of Excel take note:
#
#     worksheet.write('A1', '=SUM(1; 2; 3)')  # Wrong!!
#     worksheet.write('A1', '=SUM(1, 2, 3)')  # Okay
#
# The following table lists all of the core functions supported by
# Excel 5 and WriteExcel. Any additional functions that are available through
# the "Analysis ToolPak" or other add-ins are not supported. These functions
# have all been tested to verify that they work.
#
#     ABS           DB            INDIRECT      NORMINV       SLN
#     ACOS          DCOUNT        INFO          NORMSDIST     SLOPE
#     ACOSH         DCOUNTA       INT           NORMSINV      SMALL
#     ADDRESS       DDB           INTERCEPT     NOT           SQRT
#     AND           DEGREES       IPMT          NOW           STANDARDIZE
#     AREAS         DEVSQ         IRR           NPER          STDEV
#     ASIN          DGET          ISBLANK       NPV           STDEVP
#     ASINH         DMAX          ISERR         ODD           STEYX
#     ATAN          DMIN          ISERROR       OFFSET        SUBSTITUTE
#     ATAN2         DOLLAR        ISLOGICAL     OR            SUBTOTAL
#     ATANH         DPRODUCT      ISNA          PEARSON       SUM
#     AVEDEV        DSTDEV        ISNONTEXT     PERCENTILE    SUMIF
#     AVERAGE       DSTDEVP       ISNUMBER      PERCENTRANK   SUMPRODUCT
#     BETADIST      DSUM          ISREF         PERMUT        SUMSQ
#     BETAINV       DVAR          ISTEXT        PI            SUMX2MY2
#     BINOMDIST     DVARP         KURT          PMT           SUMX2PY2
#     CALL          ERROR.TYPE    LARGE         POISSON       SUMXMY2
#     CEILING       EVEN          LEFT          POWER         SYD
#     CELL          EXACT         LEN           PPMT          T
#     CHAR          EXP           LINEST        PROB          TAN
#     CHIDIST       EXPONDIST     LN            PRODUCT       TANH
#     CHIINV        FACT          LOG           PROPER        TDIST
#     CHITEST       FALSE         LOG10         PV            TEXT
#     CHOOSE        FDIST         LOGEST        QUARTILE      TIME
#     CLEAN         FIND          LOGINV        RADIANS       TIMEVALUE
#     CODE          FINV          LOGNORMDIST   RAND          TINV
#     COLUMN        FISHER        LOOKUP        RANK          TODAY
#     COLUMNS       FISHERINV     LOWER         RATE          TRANSPOSE
#     COMBIN        FIXED         MATCH         REGISTER.ID   TREND
#     CONCATENATE   FLOOR         MAX           REPLACE       TRIM
#     CONFIDENCE    FORECAST      MDETERM       REPT          TRIMMEAN
#     CORREL        FREQUENCY     MEDIAN        RIGHT         TRUE
#     COS           FTEST         MID           ROMAN         TRUNC
#     COSH          FV            MIN           ROUND         TTEST
#     COUNT         GAMMADIST     MINUTE        ROUNDDOWN     TYPE
#     COUNTA        GAMMAINV      MINVERSE      ROUNDUP       UPPER
#     COUNTBLANK    GAMMALN       MIRR          ROW           VALUE
#     COUNTIF       GEOMEAN       MMULT         ROWS          VAR
#     COVAR         GROWTH        MOD           RSQ           VARP
#     CRITBINOM     HARMEAN       MODE          SEARCH        VDB
#     DATE          HLOOKUP       MONTH         SECOND        VLOOKUP
#     DATEVALUE     HOUR          N             SIGN          WEEKDAY
#     DAVERAGE      HYPGEOMDIST   NA            SIN           WEIBULL
#     DAY           IF            NEGBINOMDIST  SINH          YEAR
#     DAYS360       INDEX         NORMDIST      SKEW          ZTEST
#
#--
# You can also modify the module to support function names in the following
# languages: German, French, Spanish, Portuguese, Dutch, Finnish, Italian and
# Swedish. See the function_locale.pl program in the examples directory of the distro.
#++
#
# For a general introduction to Excel's formulas and an explanation of the
# syntax of the function refer to the Excel help files or the following:
# http://office.microsoft.com/en-us/assistance/CH062528031033.aspx.
#
# If your formula doesn't work in WriteExcel try the following:
#
#     1. Verify that the formula works in Excel (or Gnumeric or OpenOffice.org).
#     2. Ensure that it isn't on the Caveats list shown above.
#     3. Ensure that cell references and formula names are in uppercase.
#     4. Ensure that you are using ':' as the range operator, A1:A4.
#     5. Ensure that you are using ',' as the union operator, SUM(1,2,3).
#     6. Ensure that the function is in the above table.
#
# If you go through steps 1-6 and you still have a problem, mail me.
#
# ===Improving performance when working with formulas
#
# Writing a large number of formulas with WriteExcel can be slow.
# This is due to the fact that each formula has to be parsed and with the
# current implementation this is computationally expensive.
#
# However, in a lot of cases the formulas that you write will be quite
# similar, for example:
#
#     worksheet.write_formula('B1',    '=A1 * 3 + 50',    format)
#     worksheet.write_formula('B2',    '=A2 * 3 + 50',    format)
#     ...
#     ...
#     worksheet.write_formula('B99',   '=A999 * 3 + 50',  format)
#     worksheet.write_formula('B1000', '=A1000 * 3 + 50', format)
#
# In this example the cell reference changes in iterations from A1 to A1000.
# The parser treats this variable as a token and arranges it according to
# predefined rules. However, since the parser is oblivious to the value of
# the token, it is essentially performing the same calculation 1000 times.
# This is inefficient.
#
# The way to avoid this inefficiency and thereby speed up the writing of
# formulas is to parse the formula once and then repeatedly substitute
# similar tokens.
#
# A formula can be parsed and stored via the store_formula() worksheet method.
# You can then use the repeat_formula() method to substitute _pattern_,
# _replace_ pairs in the stored formula:
#
#     formula = worksheet.store_formula('=A1 * 3 + 50')
#
#     (0...1000).each do |row|
#       worksheet.repeat_formula(row, 1, formula, format, 'A1', 'A' + (row +1).to_s)
#     end
#
# On an arbitrary test machine this method was 10 times faster than the
# brute force method shown above.
#
# It should be noted however that the overall speed of direct formula parsing
# will be improved in a future version.
#
# ==Chart
#
# ===Synopsis(Chart)
#
# To create a simple Excel file with a chart using WriteExcel:
#
#     #!/usr/bin/ruby -w
#
#     require 'writeexcel'
#
#     workbook  = WriteExcel.new('chart.xls')
#     worksheet = workbook.add_worksheet
#
#     chart     = workbook.add_chart(:type => 'Chart::Column')
#
#     # Configure the chart.
#     chart.add_series(
#       :categories => '=Sheet1!$A$2:$A$7',
#       :values     => '=Sheet1!$B$2:$B$7'
#     )
#
#     # Add the data to the worksheet the chart refers to.
#     data = [
#        [ 'Category', 2, 3, 4, 5, 6, 7 ],
#        [ 'Value',    1, 4, 5, 2, 1, 5 ]
#     ]
#
#     worksheet.write('A1', data)
#
#     workbook.close
#
# ===DESCRIPTION(Chart)
#
# The Chart module is an abstract base class for modules that implement charts
# in WriteExcel. The information below is applicable to all of the available
# subclasses.
#
# The Chart module isn't used directly, a chart object is created via the
# Workbook add_chart() method where the chart type is specified:
#
#    chart = workbook.add_chart(:type => 'Chart::Column')
#
# Currently the supported chart types are:
#
#    * 'Chart::Column': Creates a column style (histogram) chart. See Column.
#    * 'Chart::Bar': Creates a Bar style (transposed histogram) chart. See Bar.
#    * 'Chart::Line': Creates a Line style chart. See Line.
#    * 'Chart::Area': Creates an Area (filled line) style chart. See Area.
#    * 'Chart::Scatter': Creates an Scatter style chart. See Scatter.
#    * 'Chart::Stock': Creates an Stock style chart. See Stock.
#
# More chart types will be supported in time. See the "TODO" section.
#
# === Chart names and links
#
# The add_series()), set_x_axis(), set_y_axis() and set_title() methods all
# support a name property. In general these names can be either a static
# string or a link to a worksheet cell. If you choose to use the name_formula
# property to specify a link then you should also the name property.
# This isn't strictly required by Excel but some third party applications
# expect it to be present.
#
#     chartl.set_title(
#       :name          => 'Year End Results',
#       :name_formula  => '=Sheet1!$C$1'
#     )
#
# These links should be used sparingly since they aren't commonly
# used in Excel charts.
#
# === Chart names and Unicode
#
# The add_series()), set_x_axis(), set_y_axis() and set_title() methods all
# support a name property. These names can be UTF8 strings.
#
# This methodology is explained in the "UNICODE IN EXCEL" section of WriteExcel
# but is semi-deprecated. If you are using Unicode the easiest option is to
# just use UTF8.
#
# === TODO(Chart)
#
# Charts in WriteExcel are a work in progress. More chart types and
# features will be added in time. Please be patient. Even a small feature
# can take a week or more to implement, test and document.
#
# Features that are on the TODO list and will be added are:
#
#     * Additional chart types. Stock, Pie and Scatter charts are next in line.
#       Send an email if you are interested in other types and they will be
#       added to the queue.
#     * Colours and formatting options. For now you will have to make do
#       with the default Excel colours and formats.
#     * Axis controls, gridlines.
#     * Embedded data in charts for third party application support.
#
# == KNOWN ISSUES(Chart)
#
#     * Currently charts don't contain embedded data from which the charts
#       can be rendered. Excel and most other third party applications ignore
#       this and read the data via the links that have been specified. However,
#       some applications may complain or not render charts correctly. The
#       preview option in Mac OS X is an known example. This will be fixed
#       in a later release.
#     * When there are several charts with titles set in a workbook some of
#       the titles may display at a font size of 10 instead of the default
#       12 until another chart with the title set is viewed.
#
class WriteExcel < Workbook
  if RUBY_VERSION < '1.9'
    $KCODE = 'u'
  end
end
