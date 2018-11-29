# -*- coding: utf-8 -*-
###############################################################################
#
# Worksheet - A writer class for Excel Worksheets.
#
#
# Used in conjunction with WriteExcel
#
# Copyright 2000-2010, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
require 'writeexcel/biffwriter'
require 'writeexcel/format'
require 'writeexcel/formula'
require 'writeexcel/compatibility'
require 'writeexcel/image'
require 'writeexcel/cell_range'
require 'writeexcel/embedded_chart'
require 'writeexcel/outline'
require 'writeexcel/col_info'
require 'writeexcel/comments'
require 'writeexcel/data_validations'
require 'writeexcel/convert_date_time'

class MaxSizeError < StandardError   #:nodoc:
end

module Writeexcel

#
# = class Worksheet
#
# A new worksheet is created by calling the add_worksheet() method from a workbook object:
#
# Examples:
#
#  workbook   = WriteExcel.new('file.xls')
#  worksheet1 = workbook.add_worksheet
#  worksheet2 = workbook.add_worksheet
#
class Worksheet < BIFFWriter
  require 'writeexcel/helper'
  include ConvertDateTime

  class ObjectIds
    attr_accessor :spid
    attr_reader :drawings_saved, :num_shapes, :max_spid

    def initialize(spid, drawings_saved, num_shapes, max_spid)
      @spid = spid
      @drawings_saved = drawings_saved
      @num_shapes = num_shapes
      @max_spid = max_spid
    end
  end

  RowMax   = 65536  # :nodoc:
  ColMax   = 256    # :nodoc:
  StrMax   = 0      # :nodoc:
  Buffer   = 4096   # :nodoc:

  attr_reader :title_range, :print_range, :filter_area, :object_ids
  #
  # Constructor. Creates a new Worksheet object from a BIFFwriter object
  #
  def initialize(workbook, name, name_utf16be)    # :nodoc:
    super()

    @workbook            = workbook
    @name                = name
    @name_utf16be        = name_utf16be

    @type                = 0x0000
    @ext_sheets          = []
    @using_tmpfile       = true
    @fileclosed          = false
    @offset              = 0
    @dimension           = CellDimension.new(self)
    @colinfo             = []
    @selection           = [0, 0]
    @panes               = []
    @active_pane         = 3
    @frozen_no_split     = 1
    @tab_color           = 0

    @first_row           = 0
    @first_col           = 0
    @display_formulas    = 0
    @display_headers     = 1

    @paper_size          = 0x0
    @orientation         = 0x1
    @margin_header       = 0.50
    @margin_footer       = 0.50
    @margin_left         = 0.75
    @margin_right        = 0.75
    @margin_top          = 1.00
    @margin_bottom       = 1.00

    @title_range         = TitleRange.new(self)
    @print_range         = PrintRange.new(self)

    @print_gridlines     = 1
    @screen_gridlines    = 1

    @page_order          = 0
    @black_white         = 0
    @draft_quality       = 0
    @print_comments      = 0
    @page_start          = 1
    @custom_start        = 0

    @fit_page            = 0
    @fit_width           = 0
    @fit_height          = 0

    @hbreaks             = []
    @vbreaks             = []

    @password            = nil

    @col_sizes           = {}
    @row_sizes           = {}

    @col_formats         = {}
    @row_formats         = {}

    @zoom                = 100
    @print_scale         = 100
    @page_view           = 0

    @leading_zeros       = false

    @outline             = Outline.new

    @write_match         = []

    @images              = Collection.new
    @charts              = Collection.new
    @comments            = Comments.new

    @num_images          = 0
    @image_mso_size      = 0

    @filter_area         = FilterRange.new(self)
    @filter_on           = 0
    @filter_cols         = []

    @db_indices          = []

    @validations         = DataValidations.new

    @table               = []
    @row_data            = {}
  end

  #
  # Add data to the beginning of the workbook (note the reverse order)
  # and to the end of the workbook.
  #
  def close #:nodoc:
    ################################################
    # Prepend in reverse order!!
    #

    # Prepend the sheet dimensions
    store_dimensions

    # Prepend the autofilter filters.
    store_autofilters

    # Prepend the sheet autofilter info.
    store_autofilterinfo

    # Prepend the sheet filtermode record.
    store_filtermode

    # Prepend the COLINFO records if they exist
    @colinfo.reverse.each do |colinfo|
      store_colinfo(colinfo)
    end

    # Prepend the DEFCOLWIDTH record
    store_defcol

    # Prepend the sheet password
    store_password

    # Prepend the sheet protection
    store_protect
    store_obj_protect

    # Prepend the page setup
    store_setup

    # Prepend the bottom margin
    store_margin_bottom

    # Prepend the top margin
    store_margin_top

    # Prepend the right margin
    store_margin_right

    # Prepend the left margin
    store_margin_left

    # Prepend the page vertical centering
    store_vcenter

    # Prepend the page horizontal centering
    store_hcenter

    # Prepend the page footer
    store_footer

    # Prepend the page header
    store_header

    # Prepend the vertical page breaks
    store_vbreak

    # Prepend the horizontal page breaks
    store_hbreak

    # Prepend WSBOOL
    store_wsbool

    # Prepend the default row height.
    store_defrow

    # Prepend GUTS
    store_guts

    # Prepend GRIDSET
    store_gridset

    # Prepend PRINTGRIDLINES
    store_print_gridlines

    # Prepend PRINTHEADERS
    store_print_headers

    #
    # End of prepend. Read upwards from here.
    ################################################
    # Append
    store_table
    store_images
    store_charts
    store_filters
    store_comments
    store_window2
    store_page_view
    store_zoom
    store_panes(*@panes) if @panes && !@panes.empty?
    store_selection(*@selection)
    store_validation_count
    store_validations
    store_tab_color
    store_eof

    # Prepend the BOF and INDEX records
    store_index
    store_bof(0x0010)
  end

  def cleanup  # :nodoc:
    super
  end

  #
  # The name() method is used to retrieve the name of a worksheet. For example:
  #
  #     workbook.sheets.each do |sheet|
  #         print sheet.name
  #     end
  #
  # For reasons related to the design of WriteExcel and to the internals of
  # Excel there is no set_name() method. The only way to set the worksheet
  # name is via the add_worksheet() method.
  #
  def name
    @name
  end

  #
  # Set this worksheet as a selected worksheet, i.e. the worksheet has its tab
  # highlighted.
  #
  # The select() method is used to indicate that a worksheet is selected in a
  # multi-sheet workbook:
  #
  #     worksheet1.activate
  #     worksheet2.select
  #     worksheet3.select
  #
  # A selected worksheet has its tab highlighted. Selecting worksheets is a way
  # of grouping them together so that, for example, several worksheets could be
  # printed in one go. A worksheet that has been activated via the activate()
  # method will also appear as selected.
  #
  def select
    @hidden   = false  # Selected worksheet can't be hidden.
    @selected = true
  end


  #
  # Set this worksheet as the active worksheet, i.e. the worksheet that is
  # displayed when the workbook is opened. Also set it as selected.
  #
  # The activate() method is used to specify which worksheet is initially
  # visible in a multi-sheet workbook:
  #
  #     worksheet1 = workbook.add_worksheet('To')
  #     worksheet2 = workbook.add_worksheet('the')
  #     worksheet3 = workbook.add_worksheet('wind')
  #
  #     worksheet3.activate
  #
  # This is similar to the Excel VBA activate method. More than one worksheet
  # can be selected via the select() method, see below, however only one
  # worksheet can be active.
  #
  # The default active worksheet is the first worksheet.
  #
  def activate
    @hidden   = false  # Active worksheet can't be hidden.
    @selected = true
    @workbook.worksheets.activesheet = self
  end


  #
  # Hide this worksheet.
  #
  # The hide() method is used to hide a worksheet:
  #
  #     worksheet2.hide
  #
  # You may wish to hide a worksheet in order to avoid confusing a user with
  # intermediate data or calculations.
  #
  # A hidden worksheet can not be activated or selected so this method is
  # mutually exclusive with the activate() and select() methods. In addition,
  # since the first worksheet will default to being the active worksheet,
  # you cannot hide the first worksheet without activating another sheet:
  #
  #     worksheet2.activate
  #     worksheet1.hide
  #
  def hide
    @hidden = true

    # A hidden worksheet shouldn't be active or selected.
    @selected  = false
    @workbook.worksheets.activesheet = @workbook.worksheets.first
    @workbook.worksheets.firstsheet  = @workbook.worksheets.first
  end


  #
  # Set this worksheet as the first visible sheet. This is necessary
  # when there are a large number of worksheets and the activated
  # worksheet is not visible on the screen.
  #
  # The activate() method determines which worksheet is initially selected.
  # However, if there are a large number of worksheets the selected worksheet
  # may not appear on the screen. To avoid this you can select which is the
  # leftmost visible worksheet using set_first_sheet
  #
  #     20.times { workbook.add_worksheet }
  #
  #     worksheet21 = workbook.add_worksheet
  #     worksheet22 = workbook.add_worksheet
  #
  #     worksheet21.set_first_sheet
  #     worksheet22.activate
  #
  # This method is not required very often. The default value is the first
  # worksheet.
  #
  def set_first_sheet
    @hidden = false        # Active worksheet can't be hidden.
    @workbook.worksheets.firstsheet = self
  end

  #
  # Set the worksheet protection flag to prevent accidental modification and to
  # hide formulas if the locked and hidden format properties have been set.
  #
  # The protect() method is used to protect a worksheet from modification:
  #
  #     worksheet.protect
  #
  # It can be turned off in Excel via the
  # Tools->Protection->Unprotect Sheet menu command.
  #
  # The protect() method also has the effect of enabling a cell's locked and
  # hidden properties if they have been set. A "locked" cell cannot be edited.
  # A "hidden" cell will display the results of a formula but not the formula
  # itself. In Excel a cell's locked property is on by default.
  #
  #     # Set some format properties
  #     unlocked  = workbook.add_format(:locked => 0)
  #     hidden    = workbook.add_format(:hidden => 1)
  #
  #     # Enable worksheet protection
  #     worksheet.protect
  #
  #     # This cell cannot be edited, it is locked by default
  #     worksheet.write('A1', '=1+2')
  #
  #     # This cell can be edited
  #     worksheet.write('A2', '=1+2', unlocked)
  #
  #     # The formula in this cell isn't visible
  #     worksheet.write('A3', '=1+2', hidden)
  #
  # See also the set_locked and set_hidden format methods in "CELL FORMATTING".
  #
  # You can optionally add a password to the worksheet protection:
  #
  #     worksheet.protect('drowssap')
  #
  # Note,
  #
  #  the worksheet level password in Excel provides very weak protection. It
  # does not encrypt your data in any way and it is very easy to deactivate.
  # Therefore, do not use the above method if you wish to protect sensitive
  # data or calculations. However, before you get worried, Excel's own
  # workbook level password protection does provide strong encryption in
  # Excel 97+. For technical reasons this will never be supported by
  # WriteExcel.
  #
  def protect(password = nil)
    @protect   = true
    @password  = encode_password(password) if password
  end

  #
  #          row       : Row Number
  #          height    : Format object
  #          format    : Format object
  #          hidden    : Hidden boolean flag
  #          level     : Outline level
  #          collapsed : Collapsed row
  #
  # This method is used to set the height and XF format for a row.
  # Writes the  BIFF record ROW.
  #
  # This method can be used to change the default properties of a row. All
  # parameters apart from _row_ are optional.
  #
  # The most common use for this method is to change the height of a row:
  #
  #     worksheet.set_row(0, 20) # Row 1 height set to 20
  #
  # If you wish to set the _format_ without changing the _height_ you can pass
  # nil as the _height_ parameter:
  #
  #     worksheet.set_row(0, nil, format)
  #
  # The _format_ parameter will be applied to any cells in the row that don't
  # have a format. For example
  #
  #     worksheet.set_row(0, nil, format1)      # Set the format for row 1
  #     worksheet.write('A1', 'Hello')          # Defaults to format1
  #     worksheet.write('B1', 'Hello', format2) # Keeps format2
  #
  # If you wish to define a row format in this way you should call the method
  # before any calls to write(). Calling it afterwards will overwrite any format
  # that was previously specified.
  #
  # The hidden parameter should be set to true if you wish to hide a row. This can
  # be used, for example, to hide intermediary steps in a complicated calculation:
  #
  #     worksheet.set_row(0, 20,  format, true)
  #     worksheet.set_row(1, nil, nil,    true)
  #
  # The level parameter is used to set the outline level of the row. Outlines
  # are described in "OUTLINES AND GROUPING IN EXCEL". Adjacent rows with the
  # same outline level are grouped together into a single outline.
  #
  # The following example sets an outline level of 1 for rows 1 and 2
  # (zero-indexed):
  #
  #     worksheet.set_row(1, nil, nil, false, 1)
  #     worksheet.set_row(2, nil, nil, false, 1)
  #
  # The hidden parameter can also be used to hide collapsed outlined rows when
  # used in conjunction with the level parameter.
  #
  #     worksheet.set_row(1, nil, nil, true, 1)
  #     worksheet.set_row(2, nil, nil, true, 1)
  #
  # For collapsed outlines you should also indicate which row has the
  # collapsed + symbol using the optional collapsed parameter.
  #
  #     worksheet.set_row(3, nil, nil, false, 0, true)
  #
  # For a more complete example see the outline.pl and outline_collapsed.rb
  # programs in the examples directory of the distro.
  #
  # Excel allows up to 7 outline levels. Therefore the level parameter should
  # be in the range 0 <= level <= 7.
  #
  def set_row(row, height = nil, format = nil, hidden = false, level = 0, collapsed = false)
    record      = 0x0208               # Record identifier
    length      = 0x0010               # Number of bytes to follow

    colMic      = 0x0000               # First defined column
    colMac      = 0x0000               # Last defined column
    # miyRw;                           # Row height
    irwMac      = 0x0000               # Used by Excel to optimise loading
    reserved    = 0x0000               # Reserved
    grbit       = 0x0000               # Option flags
    # ixfe;                            # XF index

    return unless row

    # Check that row and col are valid and store max and min values
    return -2 if check_dimensions(row, 0, 0, 1) != 0

    # Check for a format object
    if format.respond_to?(:xf_index)
      ixfe = format.xf_index
    else
      ixfe = 0x0F
    end

    # Set the row height in units of 1/20 of a point. Note, some heights may
    # not be obtained exactly due to rounding in Excel.
    #
    if height
      miyRw = height *20
    else
      miyRw = 0xff # The default row height
      height = 0
    end

    # Set the limits for the outline levels (0 <= x <= 7).
    level = 0 if level < 0
    level = 7 if level > 7

    @outline.row_level = level if level > @outline.row_level

    # Set the options flags.
    # 0x10: The fCollapsed flag indicates that the row contains the "+"
    #       when an outline group is collapsed.
    # 0x20: The fDyZero height flag indicates a collapsed or hidden row.
    # 0x40: The fUnsynced flag is used to show that the font and row heights
    #       are not compatible. This is usually the case for WriteExcel.
    # 0x80: The fGhostDirty flag indicates that the row has been formatted.
    #
    grbit |= level
    grbit |= 0x0010 if collapsed && collapsed != 0
    grbit |= 0x0020 if hidden && hidden != 0
    grbit |= 0x0040
    grbit |= 0x0080 if format
    grbit |= 0x0100

    header = [record, length].pack("vv")
    data   = [row, colMic, colMac, miyRw, irwMac, reserved, grbit, ixfe].pack("vvvvvvvv")

    # Store the data or write immediately depending on the compatibility mode.
    if compatibility?
      @row_data[row] = header + data
    else
      append(header, data)
    end

    # Store the row sizes for use when calculating image vertices.
    # Also store the column formats.
    @row_sizes[row]   = height
    @row_formats[row] = format if format
  end

  #
  # :call-seq:
  #   set_column(first_col, last_col, width, format, hidden, level, collapsed)
  #   set_column(A1_notation,         width, format, hidden, level, collapsed)
  #
  # Set the width of a single column or a range of columns.
  #--
  # See also: store_colinfo
  #++
  #
  # This method can be used to change the default properties of a single
  # column or a range of columns. All parameters apart from _first_col_ and
  # _last_col_ are optional.
  #
  # If set_column() is applied to a single column the value of _first_col_ and
  # _last_col_ should be the same. In the case where _last_col_ is zero it is
  # set to the same value as _first_col_.
  #
  # It is also possible, and generally clearer, to specify a column range
  # using the form of A1 notation used for columns. See the note about
  # "Cell notation".
  #
  # Examples:
  #
  #     worksheet.set_column(0, 0,  20) # Column  A   width set to 20
  #     worksheet.set_column(1, 3,  30) # Columns B-D width set to 30
  #     worksheet.set_column('E:E', 20) # Column  E   width set to 20
  #     worksheet.set_column('F:H', 30) # Columns F-H width set to 30
  #
  # The width corresponds to the column width value that is specified in Excel.
  # It is approximately equal to the length of a string in the default font
  # of Arial 10. Unfortunately, there is no way to specify "AutoFit" for a
  # column in the Excel file format. This feature is only available at
  # runtime from within Excel.
  #
  # As usual the _format_ parameter is optional, for additional information,
  # see "CELL FORMATTING". If you wish to set the format without changing the
  # width you can pass undef as the width parameter:
  #
  #     worksheet.set_column(0, 0, nil, format)
  #
  # The _format_ parameter will be applied to any cells in the column that
  # don't have a format. For example
  #
  #     worksheet.set_column('A:A', nil, format1)   # Set format for col 1
  #     worksheet.write('A1', 'Hello')              # Defaults to format1
  #     worksheet.write('A2', 'Hello', format2)     # Keeps format2
  #
  # If you wish to define a column format in this way you should call the
  # method before any calls to write(). If you call it afterwards it won't
  # have any effect.
  #
  # A default row format takes precedence over a default column format
  #
  #     worksheet.set_row(0, nil,        format1)   # Set format for row 1
  #     worksheet.set_column('A:A', nil, format2)   # Set format for col 1
  #     worksheet.write('A1', 'Hello')              # Defaults to format1
  #     worksheet.write('A2', 'Hello')              # Defaults to format2
  #
  # The _hidden_ parameter should be set to true if you wish to hide a column.
  # This can be used, for example, to hide intermediary steps in a complicated
  # calculation:
  #
  #     worksheet.set_column('D:D', 20,  format, true)
  #     worksheet.set_column('E:E', nil, nil,    true)
  #
  # The _level_ parameter is used to set the outline level of the column.
  # Outlines are described in "OUTLINES AND GROUPING IN EXCEL". Adjacent
  # columns with the same outline level are grouped together into a single
  # outline.
  #
  # The following example sets an outline level of 1 for columns B to G:
  #
  #     worksheet.set_column('B:G', nil, nil, true, 1)
  #
  # The _hidden_ parameter can also be used to hide collapsed outlined columns
  # when used in conjunction with the _level_ parameter.
  #
  #     worksheet.set_column('B:G', nil, nil, true, 1)
  #
  # For collapsed outlines you should also indicate which row has the
  # collapsed + symbol using the optional _collapsed_ parameter.
  #
  #     worksheet.set_column('H:H', nil, nil, true, 0, true)
  #
  # For a more complete example see the outline.pl and outline_collapsed.rb
  # programs in the examples directory of the distro.
  #
  # Excel allows up to 7 outline levels. Therefore the _level_ parameter
  # should be in the range 0 <= level <= 7.
  #
  def set_column(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    if args[0] =~ /^\D/
      row1, firstcol, row2, lastcol, *data = substitute_cellref(*args)
    else
      firstcol, lastcol, *data = args
    end

    # Ensure at least firstcol, lastcol and width
    return unless firstcol && lastcol && !data.empty?

    # Assume second column is the same as first if 0. Avoids KB918419 bug.
    lastcol = firstcol if lastcol == 0

    # Ensure 2nd col is larger than first. Also for KB918419 bug.
    firstcol, lastcol = lastcol, firstcol if firstcol > lastcol

    # Limit columns to Excel max of 255.
    firstcol = ColMax - 1 if firstcol > ColMax - 1
    lastcol  = ColMax - 1 if lastcol  > ColMax - 1

    @colinfo << ColInfo.new(firstcol, lastcol, *data)

    # Store the col sizes for use when calculating image vertices taking
    # hidden columns into account. Also store the column formats.
    #
    width, format, hidden = data

    width  ||= 0                    # Ensure width isn't undef.
    width = 0 if hidden && hidden != 0  # Set width to zero if col is hidden

    (firstcol .. lastcol).each do |col|
      @col_sizes[col]   = width
      @col_formats[col] = format if format
    end
  end

  #
  # :call-seq:
  #   set_selection(first_row, first_col[, last_row, last_col])
  #   set_selection('B3')
  #   set_selection('B3:C8')
  #
  # Set which cell or cells are selected in a worksheet: see also the
  # sub store_selection
  #
  # This method can be used to specify which cell or cells are selected in a
  # worksheet. The most common requirement is to select a single cell, in which
  # case _last_row_ and _last_col_ can be omitted. The active cell within a
  # selected range is determined by the order in which _first_ and _last_ are
  # specified. It is also possible to specify a cell or a range using
  # A1 notation. See the note about "Cell notation".
  #
  # Examples:
  #
  #     worksheet1.set_selection(3, 3)       # 1. Cell D4.
  #     worksheet2.set_selection(3, 3, 6, 6) # 2. Cells D4 to G7.
  #     worksheet3.set_selection(6, 6, 3, 3) # 3. Cells G7 to D4.
  #     worksheet4.set_selection('D4')       # Same as 1.
  #     worksheet5.set_selection('D4:G7')    # Same as 2.
  #     worksheet6.set_selection('G7:D4')    # Same as 3.
  #
  # The default cell selections is (0, 0), 'A1'.
  #
  def set_selection(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    @selection = args
  end

  #
  # :call-seq:
  #   outline_settings(visible, symbols_below, symbols_right, auto_style)
  #
  # This method sets the properties for outlining and grouping. The defaults
  # correspond to Excel's defaults.
  #
  # The outline_settings() method is used to control the appearance of
  # outlines in Excel. Outlines are described in
  # "OUTLINES AND GROUPING IN EXCEL".
  #
  # The _visible_ parameter is used to control whether or not outlines are
  # visible. Setting this parameter to false will cause all outlines on the
  # worksheet to be hidden. They can be unhidden in Excel by means of the
  # "Show Outline Symbols" command button. The default setting is true for
  # visible outlines.
  #
  #     worksheet.outline_settings(false)
  #
  # The _symbols__below parameter is used to control whether the row outline
  # symbol will appear above or below the outline level bar. The default
  # setting is 1 for symbols to appear below the outline level bar.
  #
  # The symbols_right parameter is used to control whether the column outline
  # symbol will appear to the left or the right of the outline level bar. The
  # default setting is 1 for symbols to appear to the right of the outline
  # level bar.
  #
  # The _auto_style_ parameter is used to control whether the automatic outline
  # generator in Excel uses automatic styles when creating an outline. This has
  # no effect on a file generated by WriteExcel but it does have an effect on
  # how the worksheet behaves after it is created. The default setting is 0 for
  # "Automatic Styles" to be turned off.
  #
  # The default settings for all of these parameters correspond to Excel's
  # default parameters.
  #
  # The worksheet parameters controlled by outline_settings() are rarely used.
  #
  def outline_settings(*args)
    @outline.visible = args[0] || 1
    @outline.below = args[1] || 1
    @outline.right = args[2] || 1
    @outline.style = args[3] || 0

    # Ensure this is a boolean value for Window2
    @outline.visible = true unless @outline.visible?
  end

  #
  # :call-seq:
  #    freeze_pane(row, col, top_row, left_col)
  #
  # Set panes and mark them as frozen.
  #--
  # See also store_panes().
  #++
  #
  # This method can be used to divide a worksheet into horizontal or vertical
  # regions known as panes and to also "freeze" these panes so that the
  # splitter bars are not visible. This is the same as the Window->Freeze Panes
  # menu command in Excel
  #
  # The parameters _row_ and _col_ are used to specify the location of the split.
  # It should be noted that the split is specified at the top or left of a
  # cell and that the method uses zero based indexing. Therefore to freeze the
  # first row of a worksheet it is necessary to specify the split at row 2
  # (which is 1 as the zero-based index). This might lead you to think that
  # you are using a 1 based index but this is not the case.
  #
  # You can set one of the _row_ and _col_ parameters as zero if you do not
  # want either a vertical or horizontal split.
  #
  # Examples:
  #
  #     worksheet.freeze_panes(1, 0)  # Freeze the first row
  #     worksheet.freeze_panes('A2')  # Same using A1 notation
  #     worksheet.freeze_panes(0, 1)  # Freeze the first column
  #     worksheet.freeze_panes('B1')  # Same using A1 notation
  #     worksheet.freeze_panes(1, 2)  # Freeze first row and first 2 columns
  #     worksheet.freeze_panes('C2')  # Same using A1 notation
  #
  # The parameters _top_row_ and _left_col_ are optional. They are used to
  # specify the top-most or left-most visible row or column in the scrolling
  # region of the panes. For example to freeze the first row and to have the
  # scrolling region begin at row twenty:
  #
  #     worksheet.freeze_panes(1, 0, 20, 0)
  #
  # You cannot use A1 notation for the _top_row_ and _left_col_ parameters.
  #
  # See also the panes.rb program in the examples directory of the distribution.
  #
  def freeze_panes(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    # Extra flag indicated a split and freeze.
    @frozen_no_split = 0 if args[4] && args[4] != 0

    @frozen = true
    @panes  = args
  end

  #
  # :call-seq:
  #   split_panes(y, x, top_row, left_col)
  #
  # Set panes and mark them as split.
  #--
  # See also store_panes().
  #++
  #
  # This method can be used to divide a worksheet into horizontal or vertical
  # regions known as panes. This method is different from the freeze_panes()
  # method in that the splits between the panes will be visible to the user
  # and each pane will have its own scroll bars.
  #
  # The parameters _y_ and _x_ are used to specify the vertical and horizontal
  # position of the split. The units for _y_ and _x_ are the same as those
  # used by Excel to specify row height and column width. However, the
  # vertical and horizontal units are different from each other. Therefore you
  # must specify the _y_ and _x_ parameters in terms of the row heights and
  # column widths that you have set or the default values which are 12.75 for
  # a row and 8.43 for a column.
  #
  # You can set one of the _y_ and _x_ parameters as zero if you do not want
  # either a vertical or horizontal split. The parameters _top_row_ and
  # _left_col_ are optional. They are used to specify the top-most or
  # left-most visible row or column in the bottom-right pane.
  #
  # Example:
  #
  #     worksheet.split_panes(12.75, 0,    1, 0)  # First row
  #     worksheet.split_panes(0,     8.43, 0, 1)  # First column
  #     worksheet.split_panes(12.75, 8.43, 1, 1)  # First row and column
  #
  # You cannot use A1 notation with this method.
  #
  # See also the freeze_panes() method and the panes.pl program in the examples
  # directory of the distribution.
  #
  # Note:
  #
  def split_panes(*args)
    @frozen            = false
    @frozen_no_split   = 0
    @panes             = args
  end

  # Older method name for backwards compatibility.
  # *thaw_panes = *split_panes;

  #
  # :call-seq:
  #   merge_range(first_row, first_col, last_row, last_col, token, format, utf_16_be)
  #
  # This is a wrapper to ensure correct use of the merge_cells method, i.e.,
  # write the first cell of the range, write the formatted blank cells in the
  # range and then call the merge_cells record. Failing to do the steps in
  # this order will cause Excel 97 to crash.
  #
  # Merging cells can be achieved by setting the merge property of a Format
  # object, see "CELL FORMATTING". However, this only allows simple Excel5
  # style horizontal merging which Excel refers to as "center across selection".
  #
  #
  # The merge_range() method allows you to do Excel97+ style formatting where
  # the cells can contain other types of alignment in addition to the merging:
  #
  #     format = workbook.add_format(
  #                              :border  => 6,
  #                              :valign  => 'vcenter',
  #                              :align   => 'center'
  #                            )
  #
  #     worksheet.merge_range('B3:D4', 'Vertical and horizontal', format)
  #
  # <em>WARNING.</em> The format object that is used with a merge_range()
  # method call is marked internally as being associated with a merged range.
  # It is a fatal error to use a merged format in a non-merged cell. Instead
  # you should use separate formats for merged and non-merged cells. This
  # restriction will be removed in a future release.
  #
  # The _utf_16_be_ parameter is optional, see below.
  #
  # merge_range() writes its _token_ argument using the worksheet write()
  # method. Therefore it will handle numbers, strings, formulas or urls as
  # required.
  #
  # Setting the merge property of the format isn't required when you are using
  # merge_range(). In fact using it will exclude the use of any other horizontal
  # alignment option.
  #
  # Your can specify UTF-16BE worksheet names using an additional optional
  # parameter:
  #
  #     str = [0x263a].pack('n')
  #     worksheet.merge_range('B3:D4', str, format, 1)   # Smiley
  #
  # The full possibilities of this method are shown in the merge3.rb to
  # merge65.rb programs in the examples directory of the distribution.
  #
  def merge_range(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    raise "Incorrect number of arguments" if args.size != 6 and args.size != 7
    raise "Format argument is not a format object" unless args[5].respond_to?(:xf_index)

    rwFirst  = args[0]
    colFirst = args[1]
    rwLast   = args[2]
    colLast  = args[3]
    string   = args[4]
    format   = args[5]
    encoding = args[6] ? 1 : 0

    merge_range_core(rwFirst, colFirst, rwLast, colLast, string, format, encoding) do |rwFirst, colFirst, string, format, encoding|
      if encoding != 0
        write_utf16be_string(rwFirst, colFirst, string, format)
      else
        write(rwFirst, colFirst, string, format)
      end
    end
  end

  #
  # :call-seq:
  #   merge_range_with_date_time(first_row, first_col, last_row, last_col, token, format)
  #
  # Write to meged cells, a datetime string in ISO8601 "yyyy-mm-ddThh:mm:ss.ss" format as a
  # number representing an Excel date. format is optional.
  #
  def merge_range_with_date_time(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    raise "Incorrect number of arguments" if args.size != 6 and args.size != 7
    raise "Format argument is not a format object" unless args[5].respond_to?(:xf_index)

    rwFirst  = args[0]
    colFirst = args[1]
    rwLast   = args[2]
    colLast  = args[3]
    string   = args[4]
    format   = args[5]
    encoding = nil

    merge_range_core(rwFirst, colFirst, rwLast, colLast, string, format, encoding) do |rwFirst, colFirst, string, format, encoding|
      write_date_time(rwFirst, colFirst, string, format)
    end
  end

  #
  # Set the worksheet zoom factor in the range 10 <= scale <= 400:
  #
  #     worksheet1.set_zoom(50)
  #     worksheet2.set_zoom(75)
  #     worksheet3.set_zoom(300)
  #     worksheet4.set_zoom(400)
  #
  # The default zoom factor is 100. You cannot zoom to "Selection" because
  # it is calculated by Excel at run-time.
  #
  # Note, set_zoom() does not affect the scale of the printed page. For that
  # you should use set_print_scale().
  #
  def set_zoom(scale = 100)
    # Confine the scale to Excel's range
    if scale < 10 or scale > 400
      #           carp "Zoom factor scale outside range: 10 <= zoom <= 400";
      scale = 100
    end

    @zoom = scale.to_i
  end

  #
  # Display the worksheet right to left for some eastern versions of Excel.
  #
  # The right_to_left() method is used to change the default direction of the
  # worksheet from left-to-right, with the A1 cell in the top left, to
  # right-to-left, with the he A1 cell in the top right.
  #
  #     worksheet.right_to_left
  #
  # This is useful when creating Arabic, Hebrew or other near or far eastern
  # worksheets that use right-to-left as the default direction.
  #
  def right_to_left
    @display_arabic = 1
  end

  #
  # Hide cell zero values.
  #
  # The hide_zero() method is used to hide any zero values that appear in
  # cells.
  #
  #     worksheet.hide_zero
  #
  # In Excel this option is found under Tools->Options->View.
  #
  def hide_zero
    @hide_zeros = true
  end

  #
  # Set the colour of the worksheet colour.
  #
  # The set_tab_color() method is used to change the colour of the worksheet
  # tab. This feature is only available in Excel 2002 and later. You can
  # use one of the standard colour names provided by the Format object or a
  # colour index. See "COLOURS IN EXCEL" and the set_custom_color() method.
  #
  #     worksheet1.set_tab_color('red')
  #     worksheet2.set_tab_color(0x0C)
  #
  # See the tab_colors.rb program in the examples directory of the distro.
  #
  def set_tab_color(color)
    color = Colors.new.get_color(color)
    color = 0 if color == 0x7FFF # Default color.
    @tab_color = color
  end

  #
  # :call-seq:
  #    autofilter(first_row, first_col, last_row, last_col)
  #    autofilter("A1:G10")
  #
  # Set the autofilter area in the worksheet.
  #
  #
  # This method allows an autofilter to be added to a worksheet. An
  # autofilter is a way of adding drop down lists to the headers of a 2D range
  # of worksheet data. This is turn allow users to filter the data based on
  # simple criteria so that some data is highlighted and some is hidden.
  #
  # To add an autofilter to a worksheet:
  #
  #     worksheet.autofilter(0, 0, 10, 3)
  #     worksheet.autofilter('A1:D11')    # Same as above in A1 notation.
  #
  # Filter conditions can be applied using the filter_column() method.
  #
  # See the autofilter.rb program in the examples directory of the distro
  # for a more detailed example.
  #
  def autofilter(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    return if args.size != 4 # Require 4 parameters

    row_min, col_min, row_max, col_max = args

    # Reverse max and min values if necessary.
    row_min, row_max = row_max, row_min if row_max < row_min
    col_min, col_max = col_max, col_min if col_max < col_min

    # Store the Autofilter information
    @filter_area.row_min = row_min
    @filter_area.row_max = row_max
    @filter_area.col_min = col_min
    @filter_area.col_max = col_max
  end

  #
  # :call-seq:
  #   filter_column(column, expression)
  #
  # Set the column filter criteria.
  #
  # The filter_column method can be used to filter columns in a autofilter
  # range based on simple conditions.
  #
  # NOTE:
  # It isn't sufficient to just specify the filter condition. You must also
  # hide any rows that don't match the filter condition. Rows are hidden using
  # the set_row() visible parameter. WriteExcel cannot do this
  # automatically since it isn't part of the file format. See the autofilter.rb
  # program in the examples directory of the distro for an example.
  #
  # The conditions for the filter are specified using simple expressions:
  #
  #     worksheet.filter_column('A', 'x > 2000')
  #     worksheet.filter_column('B', 'x > 2000 and x < 5000')
  #
  # The _column_ parameter can either be a zero indexed column number or a
  # string column name.
  #
  # The following operators are available:
  #
  #     Operator        Synonyms
  #        ==           =   eq  =~
  #        !=           <>  ne  !=
  #        >
  #        <
  #        >=
  #        <=
  #
  #        and          &&
  #        or           ||
  #
  # The operator synonyms are just syntactic sugar to make you more comfortable
  # using the expressions. It is important to remember that the expressions will
  # be interpreted by Excel and not by ruby.
  #
  # An expression can comprise a single statement or two statements separated by
  # the and and or operators. For example:
  #
  #     'x <  2000'
  #     'x >  2000'
  #     'x == 2000'
  #     'x >  2000 and x <  5000'
  #     'x == 2000 or  x == 5000'
  #
  # Filtering of blank or non-blank data can be achieved by using a value of
  # Blanks or NonBlanks in the expression:
  #
  #     'x == Blanks'
  #     'x == NonBlanks'
  #
  # Top 10 style filters can be specified using a expression like the
  # following:
  #
  #     Top|Bottom 1-500 Items|%
  #
  # For example:
  #
  #     'Top    10 Items'
  #     'Bottom  5 Items'
  #     'Top    25 %'
  #     'Bottom 50 %'
  #
  # Excel also allows some simple string matching operations:
  #
  #     'x =~ b*'   # begins with b
  #     'x !~ b*'   # doesn't begin with b
  #     'x =~ *b'   # ends with b
  #     'x !~ *b'   # doesn't end with b
  #     'x =~ *b*'  # contains b
  #     'x !~ *b*'  # doesn't contains b
  #
  # You can also use * to match any character or number and ? to match any
  # single character or number. No other regular expression quantifier is
  # supported by Excel's filters. Excel's regular expression characters can
  # be escaped using ~.
  #
  # The placeholder variable x in the above examples can be replaced by any
  # simple string. The actual placeholder name is ignored internally so the
  # following are all equivalent:
  #
  #     'x     < 2000'
  #     'col   < 2000'
  #     'Price < 2000'
  #
  # Also, note that a filter condition can only be applied to a column in a
  # range specified by the autofilter() Worksheet method.
  #
  # See the autofilter.rb program in the examples directory of the distro
  # for a more detailed example.
  #
  def filter_column(col, expression)
    raise "Must call autofilter() before filter_column()" if @filter_area.count == 0

    # Check for a column reference in A1 notation and substitute.
    # Convert col ref to a cell ref and then to a col number.
    dummy, col = substitute_cellref("#{col}1") if col =~ /^\D/

    # Reject column if it is outside filter range.
    unless @filter_area.inside?(col)
      raise "Column '#{col}' outside autofilter() column range " +
        "(#{@filter_area.col_min} .. #{@filter_area.col_max})"
    end

    tokens = extract_filter_tokens(expression)

    unless (tokens.size == 3 or tokens.size == 7)
      raise "Incorrect number of tokens in expression '#{expression}'"
    end

    @filter_cols[col] = parse_filter_expression(expression, tokens)
    @filter_on        = 1
  end

  #
  # Set the page orientation as portrait.
  #
  # This method is used to set the orientation of a worksheet's printed page
  # to portrait. The default worksheet orientation is portrait, so you won't
  # generally need to call this method.
  #
  def set_portrait
    @orientation = 1
  end


  #
  # Set the page orientation as landscape.
  #
  def set_landscape
    @orientation = 0
  end

  #
  # This method is used to display the worksheet in "Page View" mode. This
  # is currently only supported by Mac Excel, where it is the default.
  #
  def set_page_view
    @page_view = 1
  end


  #
  # Set the paper type. Ex. 1 = US Letter, 9 = A4
  #
  # This method is used to set the paper format for the printed output of a
  # worksheet. The following paper styles are available:
  #
  #     Index   Paper format            Paper size
  #     =====   ============            ==========
  #       0     Printer default         -
  #       1     Letter                  8 1/2 x 11 in
  #       2     Letter Small            8 1/2 x 11 in
  #       3     Tabloid                 11 x 17 in
  #       4     Ledger                  17 x 11 in
  #       5     Legal                   8 1/2 x 14 in
  #       6     Statement               5 1/2 x 8 1/2 in
  #       7     Executive               7 1/4 x 10 1/2 in
  #       8     A3                      297 x 420 mm
  #       9     A4                      210 x 297 mm
  #      10     A4 Small                210 x 297 mm
  #      11     A5                      148 x 210 mm
  #      12     B4                      250 x 354 mm
  #      13     B5                      182 x 257 mm
  #      14     Folio                   8 1/2 x 13 in
  #      15     Quarto                  215 x 275 mm
  #      16     -                       10x14 in
  #      17     -                       11x17 in
  #      18     Note                    8 1/2 x 11 in
  #      19     Envelope  9             3 7/8 x 8 7/8
  #      20     Envelope 10             4 1/8 x 9 1/2
  #      21     Envelope 11             4 1/2 x 10 3/8
  #      22     Envelope 12             4 3/4 x 11
  #      23     Envelope 14             5 x 11 1/2
  #      24     C size sheet            -
  #      25     D size sheet            -
  #      26     E size sheet            -
  #      27     Envelope DL             110 x 220 mm
  #      28     Envelope C3             324 x 458 mm
  #      29     Envelope C4             229 x 324 mm
  #      30     Envelope C5             162 x 229 mm
  #      31     Envelope C6             114 x 162 mm
  #      32     Envelope C65            114 x 229 mm
  #      33     Envelope B4             250 x 353 mm
  #      34     Envelope B5             176 x 250 mm
  #      35     Envelope B6             176 x 125 mm
  #      36     Envelope                110 x 230 mm
  #      37     Monarch                 3.875 x 7.5 in
  #      38     Envelope                3 5/8 x 6 1/2 in
  #      39     Fanfold                 14 7/8 x 11 in
  #      40     German Std Fanfold      8 1/2 x 12 in
  #      41     German Legal Fanfold    8 1/2 x 13 in
  #
  # Note, it is likely that not all of these paper types will be available to
  # the end user since it will depend on the paper formats that the user's
  # printer supports. Therefore, it is best to stick to standard paper types.
  #
  #     worksheet.set_paper(1)  # US Letter
  #     worksheet.set_paper(9)  # A4
  #
  # If you do not specify a paper type the worksheet will print using the
  # printer's default paper.
  #
  def set_paper(paper_size = 0)
    @paper_size = paper_size
  end

  #
  # Center the worksheet data horizontally between the margins on the printed page.
  #
  def center_horizontally
    @hcenter = 1
  end

  #
  # Center the worksheet data vertically between the margins on the printed page:
  #
  def center_vertically
    @vcenter = 1
  end

  #
  # Set all the page margins to the same value in inches.
  #
  # There are several methods available for setting the worksheet margins on
  # the printed page:
  #
  #     set_margins()        # Set all margins to the same value
  #     set_margins_LR()     # Set left and right margins to the same value
  #     set_margins_TB()     # Set top and bottom margins to the same value
  #     set_margin_left();   # Set left margin
  #     set_margin_right();  # Set right margin
  #     set_margin_top();    # Set top margin
  #     set_margin_bottom(); # Set bottom margin
  #
  # All of these methods take a distance in inches as a parameter.
  #
  # Note: 1 inch = 25.4mm. ;-) The default left and right margin is 0.75 inch.
  # The default top and bottom margin is 1.00 inch.
  #
  def set_margins(margin)
    set_margin_left(margin)
    set_margin_right(margin)
    set_margin_top(margin)
    set_margin_bottom(margin)
  end

  #
  # Set the left and right margins to the same value in inches.
  #
  def set_margins_LR(margin)
    set_margin_left(margin)
    set_margin_right(margin)
  end

  #
  # Set the top and bottom margins to the same value in inches.
  #
  def set_margins_TB(margin)
    set_margin_top(margin)
    set_margin_bottom(margin)
  end


  #
  # Set the left margin in inches.
  #
  def set_margin_left(margin = 0.75)
    @margin_left = margin
  end


  #
  # Set the right margin in inches.
  #
  def set_margin_right(margin = 0.75)
    @margin_right = margin
  end

  #
  # Set the top margin in inches.
  #
  def set_margin_top(margin = 1.00)
    @margin_top = margin
  end

  #
  # Set the bottom margin in inches.
  #
  def set_margin_bottom(margin = 1.00)
    @margin_bottom = margin
  end

  #
  # Set the page header caption and optional margin.
  #
  # Headers and footers are generated using a _string_ which is a combination
  # of plain text and control characters. The _margin_ parameter is optional.
  #
  # The available control character are:
  #
  #     Control             Category            Description
  #     =======             ========            ===========
  #     &L                  Justification       Left
  #     &C                                      Center
  #     &R                                      Right
  #
  #     &P                  Information         Page number
  #     &N                                      Total number of pages
  #     &D                                      Date
  #     &T                                      Time
  #     &F                                      File name
  #     &A                                      Worksheet name
  #     &Z                                      Workbook path
  #
  #     &fontsize           Font                Font size
  #     &"font,style"                           Font name and style
  #     &U                                      Single underline
  #     &E                                      Double underline
  #     &S                                      Strikethrough
  #     &X                                      Superscript
  #     &Y                                      Subscript
  #
  #     &&                  Miscellaneous       Literal ampersand &
  #
  # Text in headers and footers can be justified (aligned) to the left, center
  # and right by prefixing the text with the control characters &L, &C and &R.
  #
  # For example (with ASCII art representation of the results):
  #
  #     worksheet.set_header('&LHello')
  #
  #      ---------------------------------------------------------------
  #     |                                                               |
  #     | Hello                                                         |
  #     |                                                               |
  #
  #
  #     worksheet.set_header('&CHello')
  #
  #      ---------------------------------------------------------------
  #     |                                                               |
  #     |                          Hello                                |
  #     |                                                               |
  #
  #
  #     worksheet.set_header('&RHello')
  #
  #      ---------------------------------------------------------------
  #     |                                                               |
  #     |                                                         Hello |
  #     |                                                               |
  #
  # For simple text, if you do not specify any justification the text will be
  # centred. However, you must prefix the text with &C if you specify a font
  # name or any other formatting:
  #
  #     worksheet.set_header('Hello')
  #
  #      ---------------------------------------------------------------
  #     |                                                               |
  #     |                          Hello                                |
  #     |                                                               |
  #
  # You can have text in each of the justification regions:
  #
  #     worksheet.set_header('&LCiao&CBello&RCielo')
  #
  #      ---------------------------------------------------------------
  #     |                                                               |
  #     | Ciao                     Bello                          Cielo |
  #     |                                                               |
  #
  # The information control characters act as variables that Excel will update
  # as the workbook or worksheet changes. Times and dates are in the users
  # default format:
  #
  #     worksheet.set_header('&CPage &P of &N')
  #
  #      ---------------------------------------------------------------
  #     |                                                               |
  #     |                        Page 1 of 6                            |
  #     |                                                               |
  #
  #
  #     worksheet.set_header('&CUpdated at &T')
  #
  #      ---------------------------------------------------------------
  #     |                                                               |
  #     |                    Updated at 12:30 PM                        |
  #     |                                                               |
  #
  # You can specify the font size of a section of the text by prefixing it
  # with the control character &n where n is the font size:
  #
  #     worksheet1.set_header('&C&30Hello Big'  )
  #     worksheet2.set_header('&C&10Hello Small')
  #
  # You can specify the font of a section of the text by prefixing it with the
  # control sequence &"font,style" where fontname is a font name such as
  # "Courier New" or "Times New Roman" and style is one of the standard Windows
  # font descriptions: "Regular", "Italic", "Bold" or "Bold Italic":
  #
  #     worksheet1.set_header('&C&"Courier New,Italic"Hello')
  #     worksheet2.set_header('&C&"Courier New,Bold Italic"Hello')
  #     worksheet3.set_header('&C&"Times New Roman,Regular"Hello')
  #
  # It is possible to combine all of these features together to create
  # sophisticated headers and footers. As an aid to setting up complicated
  # headers and footers you can record a page set-up as a macro in Excel and
  # look at the format strings that VBA produces. Remember however that VBA uses
  # two double quotes "" to indicate a single double quote. For the last example
  # above the equivalent VBA code looks like this:
  #
  #     .LeftHeader   = ""
  #     .CenterHeader = "&""Times New Roman,Regular""Hello"
  #     .RightHeader  = ""
  #
  # To include a single literal ampersand & in a header or footer you should
  # use a double ampersand &&:
  #
  #     worksheet1.set_header('&CCuriouser && Curiouser - Attorneys at Law')
  #
  # As stated above the margin parameter is optional. As with the other margins
  # the value should be in inches. The default header and footer margin is 0.50
  # inch. The header and footer margin size can be set as follows:
  #
  #     worksheet.set_header('&CHello', 0.75)
  #
  # The header and footer margins are independent of the top and bottom margins.
  #
  # Note, the header or footer string must be less than 255 characters. Strings
  # longer than this will not be written and a warning will be generated.
  #
  #     worksheet.set_header("&C\x{263a}")
  #
  # See, also the headers.rb program in the examples directory of the
  # distribution.
  #
  def set_header(string = '', margin = 0.50, encoding = 0)
    set_header_footer_common(:header, string, margin, encoding)
  end

  #
  # Set the page footer caption and optional margin.
  #
  # The syntax of the set_footer()  method is the same as set_header(), see
  # there.
  #
  def set_footer(string = '', margin = 0.50, encoding = 0)
    set_header_footer_common(:footer, string, margin, encoding)
  end

  #
  # Set the rows to repeat at the top of each printed page.
  #--
  # See also the store_name_xxxx() methods in Workbook.rb.
  #++
  #
  # Set the number of rows to repeat at the top of each printed page.
  #
  # For large Excel documents it is often desirable to have the first row or
  # rows of the worksheet print out at the top of each page. This can be
  # achieved by using the repeat_rows() method. The parameters _first_row_ and
  # _last_row_ are zero based. The _last_row_ parameter is optional if you
  # only wish to specify one row:
  #
  #     worksheet1.repeat_rows(0)     # Repeat the first row
  #     worksheet2.repeat_rows(0, 1)  # Repeat the first two rows
  #
  def repeat_rows(first_row, last_row = nil)
    @title_range.row_min = first_row
    @title_range.row_max = last_row || first_row # Second row is optional
  end

  #
  # :call-seq:
  #   repeat_columns(firstcol[, lastcol])
  #   repeat_columns(A1_notation)
  #
  # Set the columns to repeat at the left hand side of each printed page.
  #--
  # See also the store_names() methods in Workbook.pm.
  #++
  #
  # For large Excel documents it is often desirable to have the first column
  # or columns of the worksheet print out at the left hand side of each page.
  # This can be achieved by using the repeat_columns() method. The parameters
  # _firstcolumn_ and _lastcolumn_ are zero based. The _last_column_
  # parameter is optional if you only wish to specify one column. You can also
  # specify the columns using A1 column notation, see the note about
  # "Cell notation".
  #
  #     worksheet1.repeat_columns(0)      # Repeat the first column
  #     worksheet2.repeat_columns(0, 1)   # Repeat the first two columns
  #     worksheet3.repeat_columns('A:A')  # Repeat the first column
  #     worksheet4.repeat_columns('A:B')  # Repeat the first two columns
  #
  def repeat_columns(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    if args[0] =~ /^\D/
      row1, firstcol, row2, lastcol = substitute_cellref(*args)
    else
      firstcol, lastcol = args
    end

    @title_range.col_min  = firstcol
    @title_range.col_max  = lastcol || firstcol # Second col is optional
  end

  #
  # :call-seq:
  #    hide_gridlines(option = 1)
  #
  # Set the option to hide gridlines on the screen and the printed page.
  #--
  # There are two ways of doing this in the Excel BIFF format: The first is by
  # setting the DspGrid field of the WINDOW2 record, this turns off the screen
  # and subsequently the print gridline. The second method is to via the
  # PRINTGRIDLINES and GRIDSET records, this turns off the printed gridlines
  # only. The first method is probably sufficient for most cases. The second
  # method is supported for backwards compatibility. Porters take note.
  #++
  #
  # This method is used to hide the gridlines on the screen and printed page.
  # Gridlines are the lines that divide the cells on a worksheet. Screen and
  # printed gridlines are turned on by default in an Excel worksheet. If you
  # have defined your own cell borders you may wish to hide the default
  # gridlines.
  #
  #     worksheet.hide_gridlines
  #
  # The following values of _option_ are valid:
  #
  #     0 : Don't hide gridlines
  #     1 : Hide printed gridlines only
  #     2 : Hide screen and printed gridlines
  #
  # If you don't supply an argument the default option is 1, i.e.
  # only the printed gridlines are hidden.
  #
  def hide_gridlines(option = 1)
    if option == 0
      @print_gridlines  = 1  # 1 = display, 0 = hide
      @screen_gridlines = 1
    elsif option == 1
      @print_gridlines  = 0
      @screen_gridlines = 1
    else
      @print_gridlines  = 0
      @screen_gridlines = 0
    end
  end

  #
  # Set the option to print the row and column headers on the printed page.
  # See also the store_print_headers() method.
  #
  # An Excel worksheet looks something like the following;
  #
  #      ------------------------------------------
  #     |   |   A   |   B   |   C   |   D   |  ...
  #      ------------------------------------------
  #     | 1 |       |       |       |       |  ...
  #     | 2 |       |       |       |       |  ...
  #     | 3 |       |       |       |       |  ...
  #     | 4 |       |       |       |       |  ...
  #     |...|  ...  |  ...  |  ...  |  ...  |  ...
  #
  # The headers are the letters and numbers at the top and the left of the
  # worksheet. Since these headers serve mainly as a indication of position on
  # the worksheet they generally do not appear on the printed page. If you wish
  # to have them printed you can use the print_row_col_headers() method :
  #
  #     worksheet.print_row_col_headers
  #
  # Do not confuse these headers with page headers as described in the
  # set_header() section.
  #
  def print_row_col_headers(option = nil)
    unless option
      @print_headers = 1
    else
      @print_headers = option
    end
  end

  #
  # :call-seq:
  #   print_area(first_row, first_col, last_row, last_col)
  #   print_area(A1_notation)
  #
  # Set the area of each worksheet that will be printed.
  #--
  # See also the_store_names() methods in Workbook.rb.
  #++
  #
  # This method is used to specify the area of the worksheet that will be
  # printed. All four parameters must be specified. You can also use
  # A1 notation, see the note about "Cell notation".
  #
  #     worksheet1.print_area('A1:H20')     # Cells A1 to H20
  #     worksheet2.print_area(0, 0, 19, 7)  # The same
  #     worksheet2.print_area('A:H')        # Columns A to H if rows have data
  #
  def print_area(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    return if args.size != 4 # Require 4 parameters

    @print_range.row_min, @print_range.col_min, @print_range.row_max, @print_range.col_max = args
  end

  #
  # Set the order in which pages are printed.
  #
  # The print_across method is used to change the default print direction.
  # This is referred to by Excel as the sheet "page order".
  #
  #     worksheet.print_across
  #
  # The default page order is shown below for a worksheet that extends over 4
  # pages. The order is called "down then across":
  #
  #     [1] [3]
  #     [2] [4]
  #
  # However, by using the print_across method the print order will be changed
  # to "across then down":
  #
  #     [1] [2]
  #     [3] [4]
  #
  def print_across
    @page_order = 1
  end

  #
  # Store the vertical and horizontal number of pages that will define the
  # maximum area printed.
  #--
  # See also store_setup() and store_wsbool() below.
  #++
  #
  # The fit_to_pages() method is used to fit the printed area to a specific
  # number of pages both vertically and horizontally. If the printed area
  # exceeds the specified number of pages it will be scaled down to fit.
  # This guarantees that the printed area will always appear on the
  # specified number of pages even if the page size or margins change.
  #
  #     worksheet1.fit_to_pages(1, 1)  # Fit to 1x1 pages
  #     worksheet2.fit_to_pages(2, 1)  # Fit to 2x1 pages
  #     worksheet3.fit_to_pages(1, 2)  # Fit to 1x2 pages
  #
  # The print area can be defined using the print_area() method.
  #
  # A common requirement is to fit the printed output to n pages wide but
  # have the height be as long as necessary. To achieve this set the _height_
  # to zero or leave it blank:
  #
  #     worksheet1.fit_to_pages(1, 0)  # 1 page wide and as long as necessary
  #     worksheet2.fit_to_pages(1)     # The same
  #
  # Note that although it is valid to use both fit_to_pages() and set_print
  #_scale() on the same worksheet only one of these options can be active at
  # a time. The last method call made will set the active option.
  #
  # Note that fit_to_pages() will override any manual page breaks that are
  # defined in the worksheet.
  #
  def fit_to_pages(width = 0, height = 0)
    @fit_page      = 1
    @fit_width     = width
    @fit_height    = height
  end

  #
  # Set the scale factor of the printed page. Scale factors in the range
  # 10 <= _scale_ <= 400 are valid:
  #
  #     worksheet1.set_print_scale(50)
  #     worksheet2.set_print_scale(75)
  #     worksheet3.set_print_scale(300)
  #     worksheet4.set_print_scale(400)
  #
  # The default scale factor is 100. Note, set_print_scale() does not affect
  # the scale of the visible page in Excel. For that you should use set_zoom().
  #
  # Note also that although it is valid to use both fit_to_pages() and
  # set_print_scale() on the same worksheet only one of these options can be
  # active at a time. The last method call made will set the active option.
  #
  def set_print_scale(scale = 100)
    # Confine the scale to Excel's range
    if scale < 10 or scale > 400
      #           carp "Print scale scale outside range: 10 <= zoom <= 400";
      scale = 100
    end

    # Turn off "fit to page" option
    @fit_page    = 0

    @print_scale = scale.to_i
  end

  #
  # Store the horizontal page breaks on a worksheet. _breaks_ is Fixnum or Array
  # of Fixnum.
  #
  # Add horizontal page breaks to a worksheet. A page break causes all the
  # data that follows it to be printed on the next page. Horizontal page breaks
  # act between rows. To create a page break between rows 20 and 21 you must
  # specify the break at row 21. However in zero index notation this is
  # actually row 20. So you can pretend for a small while that you are using 1
  # index notation:
  #
  #     worksheet1.set_h_pagebreaks(20)  # Break between row 20 and 21
  #
  # The set_h_pagebreaks() method will accept a array of page breaks and you
  # can call it more than once:
  #
  #     worksheet2.set_h_pagebreaks([ 20,  40,  60,  80, 100])  # Add breaks
  #     worksheet2.set_h_pagebreaks([120, 140, 160, 180, 200])  # Add some more
  #
  # Note: If you specify the "fit to page" option via the fit_to_pages()
  # method it will override all manual page breaks.
  #
  # There is a silent limitation of about 1000 horizontal page breaks per
  # worksheet in line with an Excel internal limitation.
  #
  def set_h_pagebreaks(breaks)
    @hbreaks += breaks.respond_to?(:to_ary) ? breaks : [breaks]
  end

  #
  # Store the vertical page breaks on a worksheet. _breaks_ is Fixnum or Array
  # of Fixnum.
  #
  # Add vertical page breaks to a worksheet. A page break causes all the data
  # that follows it to be printed on the next page. Vertical page breaks act
  # between columns. To create a page break between columns 20 and 21 you must
  # specify the break at column 21. However in zero index notation this is
  # actually column 20. So you can pretend for a small while that you are using
  # 1 index notation:
  #
  #     worksheet1.set_v_pagebreaks(20) # Break between column 20 and 21
  #
  # The set_v_pagebreaks() method will accept a list of page breaks and you
  # can call it more than once:
  #
  #     worksheet2.set_v_pagebreaks([ 20,  40,  60,  80, 100]) # Add breaks
  #     worksheet2.set_v_pagebreaks([120, 140, 160, 180, 200]) # Add some more
  #
  # Note: If you specify the "fit to page" option via the fit_to_pages() method
  # it will override all manual page breaks.
  #
  def set_v_pagebreaks(breaks)
    @vbreaks += breaks.respond_to?(:to_ary) ? breaks : [breaks]
  end

  #
  # Causes the write() method to treat integers with a leading zero as a string.
  # This ensures that any leading zeros such, as in zip codes, are maintained.
  #
  # This method changes the default handling of integers with leading zeros
  # when using the write() method.
  #
  # The write() method uses regular expressions to determine what type of data
  # to write to an Excel worksheet. If the data looks like a number it writes
  # a number using write_number(). One problem with this approach is that
  # occasionally data looks like a number but you don't want it treated as
  # a number.
  #
  # Zip codes and ID numbers, for example, often start with a leading zero.
  # If you write this data as a number then the leading zero(s) will be
  # stripped. This is the also the default behaviour when you enter data
  # manually in Excel.
  #
  # To get around this you can use one of three options. Write a formatted
  # number, write the number as a string or use the keep_leading_zeros()
  # method to change the default behaviour of write():
  #
  #    # Implicitly write a number, the leading zero is removed: 1209
  #    worksheet.write('A1', '01209')
  #
  #    # Write a zero padded number using a format: 01209
  #    format1 = workbook.add_format(:num_format => '00000')
  #    worksheet.write('A2', '01209', format1)
  #
  #    # Write explicitly as a string: 01209
  #    worksheet.write_string('A3', '01209')
  #
  #    # Write implicitly as a string: 01209
  #    worksheet.keep_leading_zeros()
  #    worksheet.write('A4', '01209')
  #
  # The above code would generate a worksheet that looked like the following:
  #
  #     -----------------------------------------------------------
  #    |   |     A     |     B     |     C     |     D     | ...
  #     -----------------------------------------------------------
  #    | 1 |      1209 |           |           |           | ...
  #    | 2 |     01209 |           |           |           | ...
  #    | 3 | 01209     |           |           |           | ...
  #    | 4 | 01209     |           |           |           | ...
  #
  # The examples are on different sides of the cells due to the fact that Excel
  # displays strings with a left justification and numbers with a right
  # justification by default. You can change this by using a format to justify
  # the data, see "CELL FORMATTING".
  #
  # It should be noted that if the user edits the data in examples A3 and A4
  # the strings will revert back to numbers. Again this is Excel's default
  # behaviour. To avoid this you can use the text format @:
  #
  #    # Format as a string (01209)
  #    format2 = workbook.add_format(:num_format => '@')
  #    worksheet.write_string('A5', '01209', format2)
  #
  # The keep_leading_zeros() property is off by default. The keep
  #_leading_zeros() method takes 0 or 1 as an argument. It defaults to 1 if
  # an argument isn't specified:
  #
  #    worksheet.keep_leading_zeros()  # Set on
  #    worksheet.keep_leading_zeros(1) # Set on
  #    worksheet.keep_leading_zeros(0) # Set off
  #
  # See also the add_write_handler() method.
  #
  def keep_leading_zeros(val = true)
    @leading_zeros = val
  end

  #
  # Make any comments in the worksheet visible.
  #
  # This method is used to make all cell comments visible when a worksheet is
  # opened.
  #
  # Individual comments can be made visible using the visible parameter of the
  # write_comment method (see above):
  #
  #     worksheet.write_comment('C3', 'Hello', :visible => 1)
  #
  # If all of the cell comments have been made visible you can hide individual
  # comments as follows:
  #
  #     worksheet.write_comment('C3', 'Hello', :visible => 0)
  #
  #
  def show_comments(val = true)
    @comments.visible = val ? true : false
  end

  #
  # Set the start page number.
  #
  # The set_start_page() method is used to set the number of the starting page
  # when the worksheet is printed out. The default value is 1.
  #
  #     worksheet.set_start_page(2)
  #
  def set_start_page(start_page = 1)
    @page_start    = start_page
    @custom_start  = 1
  end

  #
  # Set the topmost and leftmost visible row and column.
  # TODO: Document this when tested fully for interaction with panes.
  #
  def set_first_row_column(row = 0, col = 0)
    row = RowMax - 1  if row > RowMax - 1
    col = ColMax - 1  if col > ColMax - 1

    @first_row = row
    @first_col = col
  end

  #--
  #
  # Allow the user to add their own matches and handlers to the write() method.
  #
  # This method is used to extend the WriteExcel write() method to handle user
  # defined data.
  #
  # If you refer to the section on write() above you will see that it acts as an
  # alias for several more specific write_* methods. However, it doesn't always
  # act in exactly the way that you would like it to.
  #
  # One solution is to filter the input data yourself and call the appropriate
  # write_* method. Another approach is to use the add_write_handler() method
  # to add your own automated behaviour to write().
  #
  # The add_write_handler() method take two arguments, _re_, a regular
  # expression to match incoming data and _code_ a callback function to handle
  # the matched data:
  #
  #     worksheet.add_write_handler(qr/^\d\d\d\d$/, \&my_write)
  #
  # (In the these examples the qr operator is used to quote the regular expression
  # strings, see perlop for more details).
  #
  # The method is used as follows. say you wished to write 7 digit ID numbers as
  # a string so that any leading zeros were preserved*, you could do something
  # like the following:
  #
  #     worksheet.add_write_handler(qr/^\d{7}$/, \&write_my_id)
  #
  #     sub write_my_id {
  #         my $worksheet = shift;
  #         return $worksheet->write_string(@_);
  #     }
  #
  # * You could also use the keep_leading_zeros() method for this.
  #
  # Then if you call write() with an appropriate string it will be handled automatically:
  #
  #     # Writes 0000000. It would normally be written as a number; 0.
  #     $worksheet->write('A1', '0000000');
  #
  # The callback function will receive a reference to the calling worksheet
  # and all of the other arguments that were passed to write(). The callback
  # will see an @_ argument list that looks like the following:
  #
  #     $_[0]   A ref to the calling worksheet. *
  #     $_[1]   Zero based row number.
  #     $_[2]   Zero based column number.
  #     $_[3]   A number or string or token.
  #     $_[4]   A format ref if any.
  #     $_[5]   Any other arguments.
  #     ...
  #
  #     *  It is good style to shift this off the list so the @_ is the same
  #        as the argument list seen by write().
  #
  # Your callback should return() the return value of the write_* method that
  # was called or undef to indicate that you rejected the match and want
  # write() to continue as normal.
  #
  # So for example if you wished to apply the previous filter only to ID
  # values that occur in the first column you could modify your callback
  # function as follows:
  #
  #     sub write_my_id {
  #         my $worksheet = shift;
  #         my $col       = $_[1];
  #
  #         if ($col == 0) {
  #             return $worksheet->write_string(@_);
  #         }
  #         else {
  #             # Reject the match and return control to write()
  #             return undef;
  #         }
  #     }
  #
  # Now, you will get different behaviour for the first column and other
  # columns:
  #
  #     $worksheet->write('A1', '0000000'); # Writes 0000000
  #     $worksheet->write('B1', '0000000'); # Writes 0
  #
  # You may add more than one handler in which case they will be called in the
  # order that they were added.
  #
  # Note, the add_write_handler() method is particularly suited for handling
  # dates.
  #
  # See the write_handler 1-4 programs in the examples directory for further
  # examples.
  #
  #++
#  def add_write_handler(regexp, code_ref)
#    #       return unless ref $_[1] eq 'CODE';
#
#    @write_match.push([regexp, code_ref])
#  end

  #
  # :call-seq:
  #   write(row, col,    token, format)
  #   write(A1_notation, token, format)
  #
  # Parse token and call appropriate write method. row and column are zero
  # indexed. format is optional.
  #
  # The write_url() methods have a flag to prevent recursion when writing a
  # string that looks like a url.
  #
  # Returns: return value of called subroutine
  #
  #
  # Excel makes a distinction between data types such as strings, numbers,
  # blanks, formulas and hyperlinks. To simplify the process of writing
  # data the write() method acts as a general alias for several more
  # specific methods:
  #    write_string()
  #    write_number()
  #    write_blank()
  #    write_formula()
  #    write_url()
  #    write_row()
  #    write_col()
  #
  # The general rule is that if the data looks like a something then a
  # something is written. Here are some examples in both row-column
  # and A1 notation:
  #                                                         # Same as:
  #    worksheet.write(0, 0, 'Hello'                     )  # write_string()
  #    worksheet.write(1, 0, 'One'                       )  # write_string()
  #    worksheet.write(2, 0,  2                          )  # write_number()
  #    worksheet.write(3, 0,  3.00001                    )  # write_number()
  #    worksheet.write(4, 0,  ""                         )  # write_blank()
  #    worksheet.write(5, 0,  ''                         )  # write_blank()
  #    worksheet.write(6, 0,  nil                        )  # write_blank()
  #    worksheet.write(7, 0                              )  # write_blank()
  #    worksheet.write(8, 0,  'http://www.ruby-lang.org/')  # write_url()
  #    worksheet.write('A9',  'ftp://ftp.ruby-lang.org/' )  # write_url()
  #    worksheet.write('A10', 'internal:Sheet1!A1'       )  # write_url()
  #    worksheet.write('A11', 'external:c:\foo.xls'      )  # write_url()
  #    worksheet.write('A12', '=A3 + 3*A4'               )  # write_formula()
  #    worksheet.write('A13', '=SIN(PI()/4)'             )  # write_formula()
  #    worksheet.write('A14', ['name', 'company']        )  # write_row()
  #    worksheet.write('A15', [ ['name', 'company'] ]    )  # write_col()
  #
  # And if the keep_leading_zeros property is set:
  #  $worksheet.write('A16,  2                     ); # write_number()
  #    $worksheet.write('A17,  02                    ); # write_string()
  #    $worksheet.write('A18,  00002                 ); # write_string()
  #
  # The "looks like" rule is defined by regular expressions:
  #
  # * write_number() if _token_ is a number based on the following regex:
  #   token =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/.
  #
  # * write_string() if keep_leading_zeros() is set and _token_ is an integer
  #   with leading zeros based on the following regex: token =~ /^0\d+$/.
  #
  # * write_blank() if _token_ is undef or a blank string: undef, "" or ''.
  #
  # * write_url() if _token_ is a http, https, ftp or mailto URL based on the
  #   following regexes: token =~ m|^[fh]tt?ps?://| or $token =~ m|^mailto:|.
  #
  # * write_url() if _token_ is an internal or external sheet reference based
  #   on the following regex: token =~ m[^(in|ex)ternal:].
  #
  # * write_formula() if the first character of _token_ is "=".
  #
  # * write_row() if _token_ is an array.
  #
  # * write_col() if _token+ is an array of array.
  #
  # * write_string() if none of the previous conditions apply.
  #
  # The format parameter is optional. It should be a valid Format object, see
  # "CELL FORMATTING":
  #
  #    format = workbook.add_format
  #    format.set_bold
  #    format.set_color('red')
  #    format.set_align('center')
  #
  #    worksheet.write(4, 0, 'Hello', format)   # Formatted string
  #
  # The write() method will ignore empty strings or undef tokens unless a
  # format is also supplied. As such you needn't worry about special
  # handling for empty or undef values in your data. See also the
  # write_blank() method.
  #
  # One problem with the write() method is that occasionally data looks like a
  # number but you don't want it treated as a number. For example, zip codes or
  # ID numbers often start with a leading zero. If you write this data as a
  # number then the leading zero(s) will be stripped. You can change this
  # default behaviour by using the keep_leading_zeros() method. While this
  # property is in place any integers with leading zeros will be treated as
  # strings and the zeros will be preserved. See the keep_leading_zeros()
  # section for a full discussion of this issue.
  #
  # You can also add your own data handlers to the write() method using
  # add_write_handler().
  #
  # The write methods return:
  #
  #    0 for success.
  #   -1 for insufficient number of arguments.
  #   -2 for row or column out of bounds.
  #   -3 for string too long.
  #
  def write(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    token = args[2]

    # Handle undefs as blanks
    token ||= ''

    # First try user defined matches.
    @write_match.each do |aref|
      re  = aref[0]
      sub = aref[1]

      if token =~ Regexp.new(re)
        match = eval("#{sub} self, args")
        return match if match
      end
    end

    # Match an array ref.
    if token.respond_to?(:to_ary)
      write_row(*args)
    elsif token.respond_to?(:coerce)  # Numeric
      write_number(*args)
      # Match http, https or ftp URL
    elsif token =~ %r|^[fh]tt?ps?://|
      write_url(*args)
      # Match mailto:
    elsif token =~ %r|^mailto:|
      write_url(*args)
      # Match internal or external sheet link
    elsif token =~ %r!^(?:in|ex)ternal:!
      write_url(*args)
      # Match formula
    elsif token =~ /^=/
      write_formula(*args)
      # Match blank
    elsif token == ''
      args.delete_at(2)     # remove the empty string from the parameter list
      write_blank(*args)
    else
      write_string(*args)
    end
  end

  #
  # :call-seq:
  #   write_number(row, col,    token[, format])
  #   write_number(A1_notation, token[, format])
  #
  # Write a double to the specified row and column (zero indexed).
  # An integer can be written as a double. Excel will display an
  # integer. $format is optional.
  #
  # Returns  0 : normal termination
  #         -1 : insufficient number of arguments
  #         -2 : row or column out of range
  #
  # Write an integer or a float to the cell specified by row and column
  #
  #    worksheet.write_number(0, 0,  123456)
  #    worksheet.write_number('A2',  2.3451)
  #
  # See the note about "Cell notation". The format parameter is optional.
  #
  # In general it is sufficient to use the write() method.
  #
  def write_number(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    return -1 if args.size < 3                # Check the number of args

    record  = 0x0203                          # Record identifier
    length  = 0x000E                          # Number of bytes to follow

    row     = args[0]                         # Zero indexed row
    col     = args[1]                         # Zero indexed column
    num     = args[2]
    xf      = xf_record_index(row, col, args[3]) # The cell format

    # Check that row and col are valid and store max and min values
    return -2 if check_dimensions(row, col) != 0

    header = [record, length].pack('vv')
    data   = [row, col, xf].pack('vvv')
    xl_double = [num].pack("d")

    xl_double.reverse! if @byte_order

    # Store the data or write immediately depending on the compatibility mode.
    store_with_compatibility(row, col, header + data + xl_double)

    0
  end

  #
  # :call-seq:
  #   write_string(row, col,    token[, format])
  #   write_string(A1_notation, token[, format])
  #
  # Write a string to the specified row and column (zero indexed).
  #
  # The format parameter is optional.
  #
  # Returns  0 : normal termination
  #         -1 : insufficient number of arguments
  #         -2 : row or column out of range
  #         -3 : long string truncated to 255 chars
  #
  #
  #    worksheet.write_string(0, 0, 'Your text here')
  #    worksheet.write_string('A2', 'or here')
  #
  # The maximum string size is 32767 characters. However the maximum string
  # segment that Excel can display in a cell is 1000. All 32767 characters can
  # be displayed in the formula bar.
  #
  # The write() method will also handle strings in UTF-8 format.
  # You can also write Unicode in UTF16 format via the
  # write_utf16be_string() method.
  #
  # In general it is sufficient to use the write() method. However, you may
  # sometimes wish to use the write_string() method to write data that looks
  # like a number but that you don't want treated as a number. For example,
  # zip codes or phone numbers:
  #
  #    # Write as a plain string
  #    worksheet.write_string('A1', '01209')
  #
  # However, if the user edits this string Excel may convert it back to a
  # number. To get around this you can use the Excel text format @:
  #
  #    # Format as a string. Doesn't change to a number when edited
  #    format1 = workbook.add_format(:num_format => '@')
  #    worksheet.write_string('A2', '01209', format1)
  #
  def write_string(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    return -1 if (args.size < 3)                # Check the number of args

    row, col, str, format = args
    str = str.to_s
    xf  = xf_record_index(row, col, format)    # The cell format
    encoding    = 0x0
    str_error   = 0

    ruby_19 {str = convert_to_ascii_if_ascii(str) }

    # Handle utf8 strings
    if is_utf8?(str)
      str_utf16le = utf8_to_16le(str)
      return write_utf16le_string(row, col, str_utf16le, args[3])
    end

    # Check that row and col are valid and store max and min values
    return -2 unless check_dimensions(row, col) == 0

    # Limit the string to the max number of chars.
    if str.bytesize > 32767
      str       = str[0, 32767]
      str_error = -3
    end

    # Prepend the string with the type.
    str_header  = [str.length, encoding].pack('vC')
    str         = str_header + str

    str_unique = update_workbook_str_table(str)

    record      = 0x00FD                        # Record identifier
    length      = 0x000A                        # Bytes to follow
    header = [record, length].pack('vv')
    data   = [row, col, xf, str_unique].pack('vvvV')

    # Store the data or write immediately depending on the compatibility mode.
    store_with_compatibility(row, col, header + data)

    str_error
  end

  #
  # :call-seq:
  #   write_utf16be_string(row, col, string, format)
  #
  # Write a Unicode string to the specified row and column (zero indexed).
  # $format is optional.
  # Returns  0 : normal termination
  #         -1 : insufficient number of arguments
  #         -2 : row or column out of range
  #         -3 : long string truncated to 255 chars
  #
  def write_utf16be_string(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    return -1 if args.size < 3                  # Check the number of args

    record      = 0x00FD                        # Record identifier
    length      = 0x000A                        # Bytes to follow

    row, col, str = args
    xf          = xf_record_index(row, col, args[3]) # The cell format
    encoding    = 0x1
    str_error   = 0

    # Check that row and col are valid and store max and min values
    return -2 unless check_dimensions(row, col) == 0

    # Limit the utf16 string to the max number of chars (not bytes).
    if str.bytesize > 32767* 2
      str       = str[0..32767*2]
      str_error = -3
    end

    num_bytes = str.bytesize
    num_chars = (num_bytes / 2).to_i

    # Check for a valid 2-byte char string.
    raise "Uneven number of bytes in Unicode string" unless num_bytes % 2 == 0

    # Change from UTF16 big-endian to little endian
    str = utf16be_to_16le(str)

    # Add the encoding and length header to the string.
    str_header  = [num_chars, encoding].pack("vC")
    str         = str_header + str

    str_unique = update_workbook_str_table(str)

    header = [record, length].pack("vv")
    data   = [row, col, xf, str_unique].pack("vvvV")

    # Store the data or write immediately depending on the compatibility mode.
    store_with_compatibility(row, col, header + data)

    str_error
  end

  #
  # :call-seq:
  #   write_utf16le_string(row, col, string, format)
  #
  # Write a UTF-16LE string to the specified row and column (zero indexed).
  # $format is optional.
  # Returns  0 : normal termination
  #         -1 : insufficient number of arguments
  #         -2 : row or column out of range
  #         -3 : long string truncated to 255 chars
  #
  def write_utf16le_string(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    return -1 if (args.size < 3)                  # Check the number of args

    row, col, str, format = args

    # Change from UTF16 big-endian to little endian
    str = utf16be_to_16le(str)

    write_utf16be_string(row, col, str, format)
  end

  #
  # :call-seq:
  #   write_blank(row, col   , format)  -> Fixnum
  #   write_blank(A1_notation, format)  -> Fixnum
  #
  # Write a blank cell to the specified row and column (zero indexed).
  # A blank cell is used to specify formatting without adding a string
  # or a number.
  #
  # A blank cell without a format serves no purpose. Therefore, we don't write
  # a BLANK record unless a format is specified. This is mainly an optimisation
  # for the write_row() and write_col() methods.
  #
  # Returns  0 : normal termination (including no format)
  #         -1 : insufficient number of arguments
  #         -2 : row or column out of range
  #
  #This method is used to add formatting to a cell which doesn't contain a
  # string or number value.
  #
  # Excel differentiates between an "Empty" cell and a "Blank" cell. An
  # "Empty" cell is a cell which doesn't contain data whilst a "Blank" cell
  # is a cell which doesn't contain data but does contain formatting. Excel
  # stores "Blank" cells but ignores "Empty" cells.
  #
  # As such, if you write an empty cell without formatting it is ignored:
  #
  #    worksheet.write('A1',  nil, format)  # write_blank()
  #    worksheet.write('A2',  nil        )  # Ignored
  #
  # This seemingly uninteresting fact means that you can write arrays of data
  # without special treatment for undef or empty string values.
  #
  # See the note about "Cell notation".
  #
  def write_blank(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    # Check the number of args
    return -1 if args.size < 2

    # Don't write a blank cell unless it has a format
    return 0 unless args[2]

    row, col, format = args

    # Check that row and col are valid and store max and min values
    return -2 unless check_dimensions(row, col) == 0

    xf = xf_record_index(row, col, format)   # The cell format

    record  = 0x0201                         # Record identifier
    length  = 0x0006                         # Number of bytes to follow
    header    = [record, length].pack('vv')
    data      = [row, col, xf].pack('vvv')

    # Store the data or write immediately depending    on the compatibility mode.
    store_with_compatibility(row, col, header + data)

    0
  end

  #
  # :call-seq:
  #   write_formula(row, col   , formula[, format, value])  -> Fixnum
  #   write_formula(A1_notation, formula[, format, value])  -> Fixnum
  #
  # Write a formula to the specified row and column (zero indexed).
  #
  # format is optional.
  # value is an optional result of the formula that can be supplied by the
  # user.
  #
  # Returns  0 : normal termination
  #         -1 : insufficient number of arguments
  #         -2 : row or column out of range
  #
  # Write a formula or function to the cell specified by row and column:
  #
  #     worksheet.write_formula(0, 0, '=$B$3 + B4'  )
  #     worksheet.write_formula(1, 0, '=SIN(PI()/4)')
  #     worksheet.write_formula(2, 0, '=SUM(B1:B5)' )
  #     worksheet.write_formula('A4', '=IF(A3>1,"Yes", "No")'   )
  #     worksheet.write_formula('A5', '=AVERAGE(1, 2, 3, 4)'    )
  #     worksheet.write_formula('A6', '=DATEVALUE("1-Jan-2001")')
  #
  # See the note about "Cell notation". For more information about writing
  # Excel formulas see "FORMULAS AND FUNCTIONS IN EXCEL"
  #
  # See also the section "Improving performance when working with formulas"
  # and the store_formula() and repeat_formula() methods.
  #
  # If required, it is also possible to specify the calculated value of the
  # formula. This is occasionally necessary when working with non-Excel
  # applications that don't calculated the value of the formula. The
  # calculated value is added at the end of the argument list:
  #
  #     worksheet.write('A1', '=2+2', format, 4);
  #
  # However, this probably isn't something that will ever need to do. If you
  # do use this feature then do so with care.
  #
  # =FORMULAS AND FUNCTIONS IN EXCEL
  #
  # ==Caveats
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
  # ==Introduction
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
  # Cells in Excel are referenced using the A1 notation system where the column
  # is designated by a letter and the row by a number. Columns range from A to
  # IV i.e. 0 to 255, rows range from 1 to 65536.
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
  #     %q{='Test Data'!A1}
  #     %q{='Test Data1:Test Data2'!A1}
  #
  # The sheet reference and the cell reference are separated by ! the exclamation
  # mark symbol. If worksheet names contain spaces, commas o parentheses then
  # Excel requires that the name is enclosed in single quotes as shown in the
  # last two examples above. In order to avoid using a lot of escape characters
  # you can use the quote operator %q{} to protect the quotes. See perlop in
  # the main Perl documentation. Only valid sheet names that have been added
  # using the add_worksheet() method can be used in formulas. You cannot
  # reference external workbooks.
  #
  # The following table lists the operators that are available in Excel's
  # formulas. The majority of the operators are the same as Perl's,
  # differences are indicated:
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
  #
  #     String operator:
  #     ================
  #     Operator  Meaning                   Example
  #         &     Concatenation             "Hello " & "World!" # [2]
  #
  #
  #     Reference operators:
  #     ====================
  #     Operator  Meaning                   Example
  #         :     Range operator            A1:A4               # [3]
  #         ,     Union operator            SUM(1, 2+2, B3)     # [4]
  #
  #
  #     Notes:
  #     [1]: You can get a percentage with formatting and modulus with MOD().
  #     [2]: Equivalent to ("Hello " . "World!") in Perl.
  #     [3]: This range is equivalent to cells A1, A2, A3 and A4.
  #     [4]: The comma behaves like the list separator in Perl.
  #
  # The range and comma operators can have different symbols in non-English
  # versions of Excel. These will be supported in a later version of
  # WriteExcel. European users of Excel take note:
  #
  #     worksheet.write('A1', '=SUM(1; 2; 3)')  # Wrong!!
  #     worksheet.write('A1', '=SUM(1, 2, 3)')  # Okay
  #
  # The following table lists all of the core functions supported by Excel 5
  # and WriteExcel. Any additional functions that are available through the
  # "Analysis ToolPak" or other add-ins are not supported. These functions
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
  # --
  # You can also modify the module to support function names in the following
  # languages: German, French, Spanish, Portuguese, Dutch, Finnish, Italian
  # and Swedish. See the function_locale.pl program in the examples
  # directory of the distro.
  # ++
  #
  # For a general introduction to Excel's formulas and an explanation of
  # the syntax of the function refer to the Excel help files or the
  # following: http://office.microsoft.com/en-us/assistance/CH062528031033.aspx
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
  # ==Improving performance when working with formulas
  #
  # Writing a large number of formulas with WriteExcel can be
  # slow. This is due to the fact that each formula has to be parsed and
  # with the current implementation this is computationally expensive.
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
  # A formula can be parsed and stored via the store_formula() worksheet
  # method. You can then use the repeat_formula() method to substitute
  # _pattern_, _replace_ pairs in the stored formula:
  #
  #     formula = worksheet.store_formula('=A1 * 3 + 50')
  #
  #     (0...1000).each do |row|
  #        worksheet.repeat_formula(row, 1, formula, format, 'A1', 'A'.(row +1))
  #     end
  #
  # On an arbitrary test machine this method was 10 times faster than the
  # brute force method shown above.
  # --
  # For more information about how WriteExcel parses and stores formulas see
  # the WriteExcel::Formula man page.
  #
  # It should be noted however that the overall speed of direct formula
  # parsing will be improved in a future version.
  # ++
  def write_formula(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    return -1 if args.size < 3   # Check the number of args

    row, col, formula, format, value = args

    # Check that row and col are valid and store max and min values
    return -2 unless check_dimensions(row, col) == 0

    xf        = xf_record_index(row, col, format)  # The cell format

    # Strip the = sign at the beginning of the formula string
    formula = formula.sub(/^=/, '')

    # Parse the formula using the parser in Formula.pm
    # nakamura add:  to get byte_stream, set second arg TRUE
    # because ruby doesn't have Perl's "wantarray"
    formula = parser.parse_formula(formula, true)

    store_formula_common(row, col, xf, value, formula)
    0
  end

  #
  # :call-seq:
  #   store_formula(formula)  # formula : text string of formula
  #
  # Pre-parse a formula. This is used in conjunction with repeat_formula()
  # to repetitively rewrite a formula without re-parsing it.
  #
  # The store_formula() method is used in conjunction with repeat_formula()
  #  to speed up the generation of repeated formulas. See
  # "Improving performance when working with formulas" in
  # "FORMULAS AND FUNCTIONS IN EXCEL".
  #
  # The store_formula() method pre-parses a textual representation of a
  # formula and stores it for use at a later stage by the repeat_formula()
  # method.
  #
  # store_formula() carries the same speed penalty as write_formula(). However,
  # in practice it will be used less frequently.
  #
  # The return value of this method is a scalar that can be thought of as a
  # reference to a formula.
  #
  #     sin = worksheet.store_formula('=SIN(A1)')
  #     cos = worksheet.store_formula('=COS(A1)')
  #
  #     worksheet.repeat_formula('B1', sin, format, 'A1', 'A2')
  #     worksheet.repeat_formula('C1', cos, format, 'A1', 'A2')
  #
  # Although store_formula() is a worksheet method the return value can be used
  # in any worksheet:
  #
  #     now = worksheet.store_formula('=NOW()')
  #
  #     worksheet1.repeat_formula('B1', now)
  #     worksheet2.repeat_formula('B1', now)
  #     worksheet3.repeat_formula('B1', now)
  #
  def store_formula(formula)       #:nodoc:
    # In order to raise formula errors from the point of view of the calling
    # program we use an eval block and re-raise the error from here.
    #
    tokens = parser.parse_formula(formula.sub(/^=/, ''))

    #       if ($@) {
    #           $@ =~ s/\n$//  # Strip the \n used in the Formula.pm die()
    #           croak $@       # Re-raise the error
    #       }

    # Return the parsed tokens in an anonymous array
    [*tokens]
  end

  #
  # :call-seq:
  #    repeat_formula(row, col,    formula, format, pat, rep, (pat2, rep2,, ...) -> Fixnum
  #    repeat_formula(A1_notation, formula, format, pat, rep, (pat2, rep2,, ...) -> Fixnum
  #
  # Write a formula to the specified row and column (zero indexed) by
  # substituting _pattern_ _replacement_ pairs in the formula created via
  # store_formula(). This allows the user to repetitively rewrite a formula
  # without the significant overhead of parsing.
  #
  # Returns  0 : normal termination
  #         -1 : insufficient number of arguments
  #         -2 : row or column out of range
  #
  # The repeat_formula() method is used in conjunction with store_formula() to
  # speed up the generation of repeated formulas. See
  # "Improving performance when working with formulas" in
  # "FORMULAS AND FUNCTIONS IN EXCEL".
  #
  # In many respects repeat_formula() behaves like write_formula() except that
  # it is significantly faster.
  #
  # The repeat_formula() method creates a new formula based on the pre-parsed
  # tokens returned by store_formula(). The new formula is generated by
  # substituting _pattern_, _replace_ pairs in the stored formula:
  #
  #     formula = worksheet.store_formula('=A1 * 3 + 50')
  #
  #     (0...100).each do |row|
  #       worksheet.repeat_formula(row, 1, formula, format, 'A1', "A#{row + 1}")
  #     end
  #
  # It should be noted that repeat_formula() doesn't modify the tokens. In the
  # above example the substitution is always made against the original token,
  # A1, which doesn't change.
  #
  # As usual, you can use undef if you don't wish to specify a format:
  #
  #     worksheet.repeat_formula('B2', formula, format, 'A1', 'A2')
  #     worksheet.repeat_formula('B3', formula, nil,    'A1', 'A3')
  #
  # The substitutions are made from left to right and you can use as many
  # pattern, replace pairs as you need. However, each substitution is made
  # only once:
  #
  #     formula = worksheet.store_formula('=A1 + A1')
  #
  #     # Gives '=B1 + A1'
  #     worksheet.repeat_formula('B1', formula, undef, 'A1', 'B1')
  #
  #     # Gives '=B1 + B1'
  #     worksheet.repeat_formula('B2', formula, undef, 'A1', 'B1', 'A1', 'B1')
  #
  # Since the pattern is interpolated each time that it is used it is worth
  # using the %q operator to quote the pattern. The qr operator is explained
  # in the perlop man page.
  #
  #     worksheet.repeat_formula('B1', formula, format, %q!A1!, 'A2')
  #
  # Care should be taken with the values that are substituted. The formula
  # returned by repeat_formula() contains several other tokens in addition to
  # those in the formula and these might also match the pattern that you are
  # trying to replace. In particular you should avoid substituting a single
  # 0, 1, 2 or 3.
  #
  # You should also be careful to avoid false matches. For example the following
  # snippet is meant to change the stored formula in steps
  # from =A1 + SIN(A1) to =A10 + SIN(A10).
  #
  #     formula = worksheet.store_formula('=A1 + SIN(A1)')
  #
  #     (1..10).each do |row|
  #       worksheet.repeat_formula(row -1, 1, formula, nil,
  #                                     'A1', "A#{row}",   #! Bad.
  #                                     'A1', "A#{row}"    #! Bad.
  #                               )
  #     end
  #
  # However it contains a bug. In the last iteration of the loop when row is
  # 10 the following substitutions will occur:
  #
  #     sub('A1', 'A10')    changes    =A1 + SIN(A1)     to    =A10 + SIN(A1)
  #     sub('A1', 'A10')    changes    =A10 + SIN(A1)    to    =A100 + SIN(A1) # !!
  #
  # The solution in this case is to use a more explicit match such as /(?!A1\d+)A1/:
  #
  #         worksheet.repeat_formula(row -1, 1, formula, nil,
  #                                     'A1', 'A' . row,
  #                                     /(?!A1\d+)A1/, 'A' . row
  #                                   )
  #
  # See also the repeat.rb program in the examples directory of the distro.
  #
  def repeat_formula(*args)       #:nodoc:
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    return -1 if args.size < 2   # Check the number of args

    row, col, formula, format, *pairs = args

    # Check that row and col are valid and store max and min values
    return -2 unless check_dimensions(row, col) == 0

    # Enforce an even number of arguments in the pattern/replacement list
    raise "Odd number of elements in pattern/replacement list" unless pairs.size % 2 == 0

    # Check that formula is an array ref
    raise "Not a valid formula" unless formula.respond_to?(:to_ary)

    tokens  = formula.join("\t").split("\t")

    # Ensure that there are tokens to substitute
    raise "No tokens in formula" if tokens.empty?

    # As a temporary and undocumented measure we allow the user to specify the
    # result of the formula by appending a result => value pair to the end
    # of the arguments.
    value = nil
    if pairs[-2] == 'result'
      value = pairs.pop
      pairs.pop
    end

    while !pairs.empty?
      pattern = pairs.shift
      replace = pairs.shift

      tokens.each do |token|
        break if token.sub!(pattern, replace)
      end
    end

    # Change the parameters in the formula cached by the Formula.pm object
    formula  = parser.parse_tokens(tokens)

    raise "Unrecognised token in formula" unless formula

    xf = xf_record_index(row, col, format) # The cell format

    store_formula_common(row, col, xf, value, formula)
    0
  end

  #
  # :call-seq:
  #   write_row(row, col   , array[, format])
  #   write_row(A1_notation, array[, format])
  #
  # Write a row of data starting from (row, col). Call write_col() if any of
  # the elements of the array are in turn array. This allows the writing of
  # 1D or 2D arrays of data in one go.
  #
  # Returns: the first encountered error value or zero for no errors
  #
  #
  # The write_row() method can be used to write a 1D or 2D array of data in
  # one go. This is useful for converting the results of a database query into
  # an Excel worksheet. You must pass a reference to the array of data rather
  # than the array itself. The write() method is then called for each element
  # of the data. For example:
  #
  #    array      = ['awk', 'gawk', 'mawk']
  #
  #    worksheet.write_row(0, 0, array_ref)
  #
  #    # The above example is equivalent to:
  #    worksheet.write(0, 0, array[0])
  #    worksheet.write(0, 1, array[1])
  #    worksheet.write(0, 2, array[2])
  #
  # Note: For convenience the write() method behaves in the same way as
  # write_row() if it is passed an array. Therefore the following two method
  # calls are equivalent:
  #
  #    worksheet.write_row('A1', array) # Write a row of data
  #    worksheet.write(    'A1', array) # Same thing
  #
  # As with all of the write methods the format parameter is optional. If a
  # format is specified it is applied to all the elements of the data array.
  #
  # Array references within the data will be treated as columns. This allows you
  # to write 2D arrays of data in one go. For example:
  #
  #    eec =  [
  #                ['maggie', 'milly', 'molly', 'may'  ],
  #                [13,       14,      15,      16     ],
  #                ['shell',  'star',  'crab',  'stone']
  #           ]
  #
  #    worksheet.write_row('A1', eec)
  #
  # Would produce a worksheet as follows:
  #
  #     -----------------------------------------------------------
  #    |   |    A    |    B    |    C    |    D    |    E    | ...
  #     -----------------------------------------------------------
  #    | 1 | maggie  | 13      | shell   | ...     |  ...    | ...
  #    | 2 | milly   | 14      | star    | ...     |  ...    | ...
  #    | 3 | molly   | 15      | crab    | ...     |  ...    | ...
  #    | 4 | may     | 16      | stone   | ...     |  ...    | ...
  #    | 5 | ...     | ...     | ...     | ...     |  ...    | ...
  #    | 6 | ...     | ...     | ...     | ...     |  ...    | ...
  #
  # To write the data in a row-column order refer to the write_col() method
  # below.
  #
  # Any +nil+ values in the data will be ignored unless a format is applied
  # to the data, in which case a formatted blank cell will be written. In
  # either case the appropriate row or column value will still be
  # incremented.
  #
  # The write_row() method returns the first error encountered when
  # writing the elements of the data or zero if no errors were encountered.
  # See the return values described for the write() method above.
  #
  # See also the write_arrays.rb program in the examples directory of the
  # distro.
  #
  def write_row(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    # Catch non array refs passed by user.
    raise "Not an array ref in call to write_row() #{$!}" unless args[2].respond_to?(:to_ary)

    row, col, tokens, options = args
    error = false
    if tokens
      tokens.each do |token|
        # Check for nested arrays
        if token.respond_to?(:to_ary)
          ret = write_col(row, col, token, options)
        else
          ret = write(row, col, token, options)
        end

        # Return only the first error encountered, if any.
        error ||= ret
        col += 1
      end
    end
    error || 0
  end

  #
  # :call-seq:
  #   write_column(row, col   , array[, format])
  #   write_column(A1_notation, array[, format])
  #
  # Write a column of data starting from (row, col). Call write_row() if any of
  # the elements of the array are in turn array. This allows the writing
  # of 1D or 2D arrays of data in one go.
  #
  # Returns: the first encountered error value or zero for no errors
  #
  #
  # The write_col() method can be used to write a 1D or 2D array of data in one
  # go. This is useful for converting the results of a database query into an
  # Excel worksheet. The write() method is then called for each element of the
  # data. For example:
  #
  #    array      = ['awk', 'gawk', 'mawk']
  #
  #    worksheet.write_col(0, 0, array)
  #
  #    # The above example is equivalent to:
  #    worksheet.write(0, 0, array[0])
  #    worksheet.write(1, 0, array[1])
  #    worksheet.write(2, 0, array[2])
  #
  # As with all of the write methods the format parameter is optional. If a
  # format is specified it is applied to all the elements of the data array.
  #
  # Array within the data will be treated as rows. This allows you to write
  # 2D arrays of data in one go. For example:
  #
  #    eec =  [
  #                ['maggie', 'milly', 'molly', 'may'  ],
  #                [13,       14,      15,      16     ],
  #                ['shell',  'star',  'crab',  'stone']
  #            ]
  #
  #    worksheet.write_col('A1', eec)
  #
  # Would produce a worksheet as follows:
  #
  #     -----------------------------------------------------------
  #    |   |    A    |    B    |    C    |    D    |    E    | ...
  #     -----------------------------------------------------------
  #    | 1 | maggie  | milly   | molly   | may     |  ...    | ...
  #    | 2 | 13      | 14      | 15      | 16      |  ...    | ...
  #    | 3 | shell   | star    | crab    | stone   |  ...    | ...
  #    | 4 | ...     | ...     | ...     | ...     |  ...    | ...
  #    | 5 | ...     | ...     | ...     | ...     |  ...    | ...
  #    | 6 | ...     | ...     | ...     | ...     |  ...    | ...
  #
  # To write the data in a column-row order refer to the write_row() method
  # above.
  #
  # Any +nil+ values in the data will be ignored unless a format is applied to
  # the data, in which case a formatted blank cell will be written. In either
  # case the appropriate row or column value will still be incremented.
  #
  # As noted above the write() method can be used as a synonym for write_row()
  # and write_row() handles nested array as columns. Therefore, the following
  # two method calls are equivalent although the more explicit call to
  # write_col() would be preferable for maintainability:
  #
  #    worksheet.write_col('A1', array)     # Write a column of data
  #    worksheet.write(    'A1', [ array ]) # Same thing
  #
  # The write_col() method returns the first error encountered when writing
  # the elements of the data or zero if no errors were encountered. See the
  # return values described for the write() method above.
  #
  # See also the write_arrays.pl program in the examples directory of the distro.
  #
  def write_col(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    # Catch non array refs passed by user.
    raise "Not an array ref in call to write_row()" unless args[2].respond_to?(:to_ary)

    row, col, tokens, options = args
    error   = false
    if tokens
      tokens.each do |token|
        # write() will deal with any nested arrays
        ret = write(row, col, token, options)

        # Return only the first error encountered, if any.
        error ||= ret
        row += 1
      end
    end
    error || 0
  end

  #
  # :call-seq:
  #   write_date_time(row, col   , date_string[, format])
  #   write_date_time(A1_notation, date_string[, format])
  #
  # Write a datetime string in ISO8601 "yyyy-mm-ddThh:mm:ss.ss" format as a
  # number representing an Excel date. format is optional.
  #
  # Returns  0 : normal termination
  #         -1 : insufficient number of arguments
  #         -2 : row or column out of range
  #         -3 : Invalid date_time, written as string
  #
  # The write_date_time() method can be used to write a date or time to the
  # cell specified by row and column:
  #
  #     worksheet.write_date_time('A1', '2004-05-13T23:20', date_format)
  #
  # The date_string should be in the following format:
  #
  #     yyyy-mm-ddThh:mm:ss.sss
  #
  # This conforms to an ISO8601 date but it should be noted that the full
  # range of ISO8601 formats are not supported.
  #
  # The following variations on the date_string parameter are permitted:
  #
  #     yyyy-mm-ddThh:mm:ss.sss         # Standard format
  #     yyyy-mm-ddT                     # No time
  #               Thh:mm:ss.sss         # No date
  #     yyyy-mm-ddThh:mm:ss.sssZ        # Additional Z (but not time zones)
  #     yyyy-mm-ddThh:mm:ss             # No fractional seconds
  #     yyyy-mm-ddThh:mm                # No seconds
  #
  # Note that the T is required in all cases.
  #
  # A date should always have a format, otherwise it will appear as a number,
  # see "DATES AND TIME IN EXCEL" and "CELL FORMATTING". Here is a typical
  # example:
  #
  #     date_format = workbook.add_format(:num_format => 'mm/dd/yy')
  #     worksheet.write_date_time('A1', '2004-05-13T23:20', date_format)
  #
  # Valid dates should be in the range 1900-01-01 to 9999-12-31, for the 1900
  # epoch and 1904-01-01 to 9999-12-31, for the 1904 epoch. As with Excel,
  # dates outside these ranges will be written as a string.
  #
  # See also the date_time.rb program in the examples directory of the distro.
  #
  def write_date_time(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    return -1 if args.size < 3                    # Check the number of args

    row, col, str, format = args

    # Check that row and col are valid and store max and min values
    return -2 unless check_dimensions(row, col) == 0

    date_time = convert_date_time(str, date_1904?)

    if date_time
      error = write_number(row, col, date_time, args[3])
    else
      # The date isn't valid so write it as a string.
      write_string(row, col, str, format)
      error = -3
    end
    error
  end

  #
  # :call-seq:
  #   write_comment(row, col,    comment[, optionhash(es)])  -> Fixnum
  #   write_comment(A1_notation, comment[, optionhash(es)])  -> Fixnum
  #
  # Write a comment to the specified row and column (zero indexed).
  #
  # Returns  0 : normal termination
  #         -1 : insufficient number of arguments
  #         -2 : row or column out of range
  #
  # The write_comment() method is used to add a comment to a cell. A cell
  # comment is indicated in Excel by a small red triangle in the upper
  # right-hand corner of the cell. Moving the cursor over the red triangle
  # will reveal the comment.
  #
  # The following example shows how to add a comment to a cell:
  #
  #     worksheet.write        (2, 2, 'Hello')
  #     worksheet.write_comment(2, 2, 'This is a comment.')
  #
  # As usual you can replace the row and column parameters with an A1 cell
  # reference. See the note about "Cell notation".
  #
  #     worksheet.write        ('C3', 'Hello')
  #     worksheet.write_comment('C3', 'This is a comment.')
  #
  # On systems with perl 5.8 and later the write_comment() method will also
  # handle strings in UTF-8 format.
  #
  #     worksheet.write_comment('C3', "\x{263a}")       # Smiley
  #     worksheet.write_comment('C4', 'Comment ca va?')
  #
  # In addition to the basic 3 argument form of write_comment() you can pass in
  # several optional key/value pairs to control the format of the comment.
  # For example:
  #
  #     worksheet.write_comment('C3', 'Hello', :visible => 1, :author => 'Ruby')
  #
  # Most of these options are quite specific and in general the default comment
  # behaviour will be all that you need. However, should you need greater
  # control over the format of the cell comment the following options are
  # available:
  #
  #     :encoding
  #     :author
  #     :author_encoding
  #     :visible
  #     :x_scale
  #     :width
  #     :y_scale
  #     :height
  #     :color
  #     :start_cell
  #     :start_row
  #     :start_col
  #     :x_offset
  #     :y_offset
  #
  # Option: :encoding
  #
  #   This option is used to indicate that the comment string is encoded as
  #   UTF-16BE.
  #
  #     comment = [0x263a].pack('n')     # UTF-16BE Smiley symbol
  #
  #     worksheet.write_comment('C3', comment, :encoding => 1)
  #
  # Option: :author
  #
  #   This option is used to indicate who the author of the comment is. Excel
  #   displays the author of the comment in the status bar at the bottom of
  #   the worksheet. This is usually of interest in corporate environments
  #   where several people might review and provide comments to a workbook.
  #
  #     worksheet.write_comment('C3', 'Atonement', :author => 'Ian McEwan')
  #
  # Option: :author_encoding
  #
  #   This option is used to indicate that the author string is encoded as UTF-16BE.
  #
  # Option: :visible
  #
  #   This option is used to make a cell comment visible when the worksheet
  #   is opened. The default behaviour in Excel is that comments are initially
  #   hidden. However, it is also possible in Excel to make individual or all
  #   comments visible. In WriteExcel individual comments can be made visible
  #   as follows:
  #
  #     worksheet.write_comment('C3', 'Hello', :visible => 1)
  #
  #   It is possible to make all comments in a worksheet visible using the show
  #   comments() worksheet method (see below). Alternatively, if all of the cell
  #   comments have been made visible you can hide individual comments:
  #
  #     worksheet.write_comment('C3', 'Hello', :visible => 0)
  #
  # Option: :x_scale
  #
  #   This option is used to set the width of the cell comment box as a factor
  #   of the default width.
  #
  #     worksheet.write_comment('C3', 'Hello', :x_scale => 2)
  #     worksheet.write_comment('C4', 'Hello', :x_scale => 4.2)
  #
  # Option: :width
  #
  #   This option is used to set the width of the cell comment box
  #   explicitly in pixels.
  #
  #     worksheet.write_comment('C3', 'Hello', :width => 200)
  #
  # Option: :y_scale
  #
  #   This option is used to set the height of the cell comment box as a
  #   factor of the default height.
  #
  #     worksheet.write_comment('C3', 'Hello', :y_scale => 2)
  #     worksheet.write_comment('C4', 'Hello', :y_scale => 4.2)
  #
  # Option: :height
  #
  #   This option is used to set the height of the cell comment box
  #   explicitly in pixels.
  #
  #     worksheet.write_comment('C3', 'Hello', :height => 200)
  #
  # Option: :color
  #
  #   This option is used to set the background colour of cell comment box.
  #   You can use one of the named colours recognised by WriteExcel or a colour
  #   index. See "COLOURS IN EXCEL".
  #
  #     worksheet.write_comment('C3', 'Hello', :color => 'green')
  #     worksheet.write_comment('C4', 'Hello', :color => 0x35)    # Orange
  #
  # Option: :start_cell
  #
  #   This option is used to set the cell in which the comment will appear.
  #   By default Excel displays comments one cell to the right and one cell
  #   above the cell to which the comment relates. However, you can change
  #   this behaviour if you wish. In the following example the comment which
  #   would appear by default in cell D2 is moved to E2.
  #
  #     worksheet.write_comment('C3', 'Hello', :start_cell => 'E2')
  #
  # Option: :start_row
  #
  #   This option is used to set the row in which the comment will appear.
  #   See the start_cell option above. The row is zero indexed.
  #
  #     worksheet.write_comment('C3', 'Hello', :start_row => 0)
  #
  # Option: :start_col
  #
  #   This option is used to set the column in which the comment will appear.
  #   See the start_cell option above. The column is zero indexed.
  #
  #     worksheet.write_comment('C3', 'Hello', :start_col => 4)
  #
  # Option: :x_offset
  #
  #   This option is used to change the x offset, in pixels, of a comment
  #   within a cell:
  #
  #     worksheet.write_comment('C3', comment, :x_offset => 30)
  #
  # Option: :y_offset
  #
  #   This option is used to change the y offset, in pixels, of a comment
  #   within a cell:
  #
  #     worksheet.write_comment('C3', comment, :x_offset => 30)
  #
  # You can apply as many of these options as you require.
  #
  # ==Note about row height and comments.
  #
  # If you specify the height of a row that contains a comment then WriteExcel
  # will adjust the height of the comment to maintain the default or user
  # specified dimensions. However, the height of a row can also be adjusted
  # automatically by Excel if the text wrap property is set or large fonts are
  # used in the cell. This means that the height of the row is unknown to
  # WriteExcel at run time and thus the comment box is stretched with the row.
  # Use the set_row() method to specify the row height explicitly and avoid
  # this problem.
  #
  def write_comment(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    return -1 if args.size < 3   # Check the number of args

    row, col, comment, params = args

    # Check for pairs of optional arguments, i.e. an odd number of args.
    # raise "Uneven number of additional arguments" if args.size % 2 == 0

    # Check that row and col are valid and store max and min values
    return -2 unless check_dimensions(row, col) == 0

    if params && params[:start_cell]
      params[:start_row], params[:start_col] = substitute_cellref(params[:start_cell])
    end

    # We have to avoid duplicate comments in cells or else Excel will complain.
    @comments << Comment.new(self, *args)
  end

  #
  # :call-seq:
  #   write_url(row, col   , url[, label, , format]) -> int
  #   write_url(A1_notation, url[, label, , format]) -> int
  #
  # Write a hyperlink. This is comprised of two elements: the visible _label_ and
  # the invisible link. The visible _label_ is the same as the link unless an
  # alternative string is specified.
  #
  # The parameters _label_ and _format_ are optional.
  #
  # The _url_ can be to a http, ftp, mail, internal sheet, or external
  # directory url.
  #
  # Returns  0 : normal termination
  #         -1 : insufficient number of arguments
  #         -2 : row or column out of range
  #         -3 : long string truncated to 255 chars
  #
  # Write a hyperlink to a URL in the cell specified by row and column. The
  # hyperlink is comprised of two elements: the visible _label_ and the
  # invisible link. The visible _label_ is the same as the link unless an
  # alternative label is specified. The parameters _label_ and the _format_
  # are optional.
  #
  # The _label_ is written using the write() method. Therefore it is possible
  # to write strings, numbers or formulas as labels.
  #
  # There are four web style URI's supported: http://, https://, ftp:// and
  # mailto::
  #
  #     worksheet.write_url(0, 0,  'ftp://www.ruby.org/'                  )
  #     worksheet.write_url(1, 0,  'http://www.ruby.com/', 'Ruby home'    )
  #     worksheet.write_url('A3',  'http://www.ruby.com/', format        )
  #     worksheet.write_url('A4',  'http://www.ruby.com/', 'Perl', format)
  #     worksheet.write_url('A5',  'mailto:bar@foo.com'            )
  #
  # There are two local URIs supported: internal: and external:. These are used
  # for hyperlinks to internal worksheet references or external workbook and
  # worksheet references:
  #
  #     worksheet.write_url('A6',  'internal:Sheet2!A1'                   )
  #     worksheet.write_url('A7',  'internal:Sheet2!A1',   format         )
  #     worksheet.write_url('A8',  'internal:Sheet2!A1:B2'                )
  #     worksheet.write_url('A9',  q{internal:'Sales Data'!A1}            )
  #     worksheet.write_url('A10', 'external:c:\temp\foo.xls'             )
  #     worksheet.write_url('A11', 'external:c:\temp\foo.xls#Sheet2!A1'   )
  #     worksheet.write_url('A12', 'external:..\..\..\foo.xls'            )
  #     worksheet.write_url('A13', 'external:..\..\..\foo.xls#Sheet2!A1'  )
  #     worksheet.write_url('A13', 'external:\\\\NETWORK\share\foo.xls'   )
  #
  # All of the these URI types are recognised by the write() method, see above.
  #
  # Worksheet references are typically of the form Sheet1!A1. You can also refer
  # to a worksheet range using the standard Excel notation: Sheet1!A1:B2.
  #
  # In external links the workbook and worksheet name must be separated by the
  # # character: external:Workbook.xls#Sheet1!A1'.
  #
  # You can also link to a named range in the target worksheet. For example say
  # you have a named range called my_name in the workbook c:\temp\foo.xls you
  # could link to it as follows:
  #
  #     worksheet.write_url('A14', 'external:c:\temp\foo.xls#my_name')
  #
  # Note, you cannot currently create named ranges with WriteExcel.
  #
  # Links to network files are also supported. MS/Novell Network files normally
  # begin with two back slashes as follows \\NETWORK\etc. In order to generate
  # this in a single or double quoted string you will have to escape the
  # backslashes, '\\\\NETWORK\etc'.
  #
  # If you are using double quote strings then you should be careful to escape
  # anything that looks like a metacharacter. Why can't I use "C:\temp\foo" in
  # DOS paths?.
  #
  # Finally, you can avoid most of these quoting problems by using forward
  # slashes. These are translated internally to backslashes:
  #
  #     worksheet.write_url('A14', "external:c:/temp/foo.xls"             )
  #     worksheet.write_url('A15', 'external://NETWORK/share/foo.xls'     )
  #
  # See also, the note about "Cell notation".
  #
  def write_url(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    # Check the number of args
    return -1 if args.size < 3

    # Add start row and col to arg list
    write_url_range(args[0], args[1], *args)
  end

  #
  # :call-seq:
  #   write_url_range(row1, col1, row2, col2, url[, string, , format])  -> Fixnum
  #   write_url_range('A1:D2',                url[, string, , format])  -> Fixnum
  #
  # This is the more general form of write_url(). It allows a hyperlink to be
  # written to a range of cells. This function also decides the type of hyperlink
  # to be written. These are either, Web (http, ftp, mailto), Internal
  # (Sheet1!A1) or external ('c:\temp\foo.xls#Sheet1!A1').
  #
  # See also write_url() above for a general description and return values.
  #
  # This method is essentially the same as the write_url() method described
  # above. The main difference is that you can specify a link for a range of
  # cells:
  #
  #     worksheet.write_url(0, 0, 0, 3, 'ftp://www.ruby.org/'              )
  #     worksheet.write_url(1, 0, 0, 3, 'http://www.ruby.com/', 'Ruby home')
  #     worksheet.write_url('A3:D3',    'internal:Sheet2!A1'               )
  #     worksheet.write_url('A4:D4',    'external:c:\temp\foo.xls'         )
  #
  # This method is generally only required when used in conjunction with merged
  # cells. See the merge_range() method and the merge property of a Format
  # object, "CELL FORMATTING".
  #
  # There is no way to force this behaviour through the write() method.
  #
  # The parameters _string_ and the $format are optional and their position is
  # interchangeable. However, they are applied only to the first cell in the
  # range.
  #
  # See also, the note about "Cell notation".
  #
  def write_url_range(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    # Check the number of args
    return -1 if args.size < 5

    # Reverse the order of _string_ and _format_ if necessary. We work on a copy
    # in order to protect the callers args.
    #
    args[5], args[6] = [ args[6], args[5] ] if args[5].respond_to?(:xf_index)

    url = args[4]

    # Check for internal/external sheet links or default to web link
    return write_url_internal(*args) if url =~ /^internal:/
    return write_url_external(*args) if url =~ /^external:/
    write_url_web(*args)
  end

  #
  # :call-seq:
  #   insert_chart(row, col,   chart, x, y, scale_x, scale_y)
  #
  # Insert a chart into a worksheet. The $chart argument should be a Chart
  # object or else it is assumed to be a filename of an external binary file.
  # The latter is for backwards compatibility.
  #
  # This method can be used to insert a Chart object into a worksheet.
  # The Chart must be created by the add_chart() Workbook method and it must
  # have the embedded option set.
  #
  #     chart = workbook.add_chart(:type => 'Chart::Line', :embedded => true )
  #
  #     # Configure the chart.
  #     ...
  #
  #     # Insert the chart into the a worksheet.
  #     worksheet.insert_chart('E2', chart)
  #
  # See add_chart() for details on how to create the Chart object and
  # WriteExcel::Chart for details on how to configure it. See also the
  # chart_*.pl programs in the examples directory of the distro.
  #
  # The _x_, _y_, _scale_x_ and _scale_y_ parameters are optional.
  #
  # The parameters _x_ and _y_ can be used to specify an offset from the top
  # left hand corner of the cell specified by _row_ and _col_. The offset values
  # are in pixels. See the insert_image method above for more information on sizes.
  #
  #     worksheet1.insert_chart('E2', chart, 3, 3)
  #
  # The parameters _scale_x_ and _scale_y_ can be used to scale the inserted
  # image horizontally and vertically:
  #
  # Scale the width by 120% and the height by 150%
  #     worksheet.insert_chart('E2', chart, 0, 0, 1.2, 1.5)
  #
  # The easiest way to calculate the required scaling is to create a test
  # chart worksheet with WriteExcel. Then open the file, select the chart
  # and drag the corner to get the required size. While holding down the
  # mouse the scale of the resized chart is shown to the left of the formula
  # bar.
  #
  # Note: you must call set_row() or set_column() before insert_chart()
  # if you wish to change the default dimensions of any of the rows or columns
  # that the chart occupies. The height of a row can also change if you use
  # a font that is larger than the default. This in turn will affect the
  # scaling of your chart. To avoid this you should explicitly set the height
  # of the row using set_row() if it contains a font size that will change
  # the row height.
  #
  def insert_chart(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    chart       = args[2]

    if chart.respond_to?(:embedded)
      print "Not a embedded style Chart object in insert_chart()" unless chart.embedded
    else
      # Assume an external bin filename.
        print "Couldn't locate #{chart} in insert_chart()" unless FileTest.exist?(chart)
    end

    @charts << EmbeddedChart.new(self, *args)
  end

  #
  # :call-seq:
  #   insert_image(row, col,    filename, x, y, scale_x, scale_y)
  #   insert_image(A1_notation, filename, x, y, scale_x, scale_y)
  #
  # Insert an image into the worksheet.
  #
  # This method can be used to insert a image into a worksheet. The image can
  # be in PNG, JPEG or BMP format. The _x_, _y_, _scale_x_ and _scale_y_
  # parameters are optional.
  #
  #     worksheet1.insert_image('A1', 'ruby.bmp')
  #     worksheet2.insert_image('A1', '../images/ruby.bmp')
  #     worksheet3.insert_image('A1', 'c:\images\ruby.bmp')
  #
  # The parameters _x_ and _y_ can be used to specify an offset from the top
  # left hand corner of the cell specified by _row_ and _col_. The offset
  # values are in pixels.
  #
  #     worksheet1.insert_image('A1', 'ruby.bmp', 32, 10)
  #
  # The default width of a cell is 63 pixels. The default height of a cell is
  # 17 pixels. The pixels offsets can be calculated using the following
  # relationships:
  #
  #     Wp = int(12We)   if We <  1
  #     Wp = int(7We +5) if We >= 1
  #     Hp = int(4/3He)
  #
  #     where:
  #     We is the cell width in Excels units
  #     Wp is width in pixels
  #     He is the cell height in Excels units
  #     Hp is height in pixels
  #
  # The offsets can be greater than the width or height of the underlying cell.
  # This can be occasionally useful if you wish to align two or more images
  # relative to the same cell.
  #
  # The parameters _scale_x_ and _scale_y_ can be used to scale the inserted
  # image horizontally and vertically:
  #
  #     # Scale the inserted image: width x 2.0, height x 0.8
  #     worksheet.insert_image('A1', 'ruby.bmp', 0, 0, 2, 0.8)
  #
  # See also the images.rb program in the examples directory of the distro.
  #
  # Note:
  #
  # you must call set_row() or set_column() before insert_image() if you wish
  # to change the default dimensions of any of the rows or columns that the
  # image occupies. The height of a row can also change if you use a font that
  # is larger than the default. This in turn will affect the scaling of your
  # image. To avoid this you should explicitly set the height of the row using
  # set_row() if it contains a font size that will change the row height.
  #
  # BMP images must be 24 bit, true colour, bitmaps. In general it is best to
  # avoid BMP images since they aren't compressed.
  #
  def insert_image(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)
    # args = [row, col, filename, x_offset, y_offset, scale_x, scale_y]
    image = Image.new(self, *args)
    raise "Insufficient arguments in insert_image()" unless args.size >= 3
    raise "Couldn't locate #{image.filename}: $!"    unless test(?e, image.filename)

    @images << image
  end

  # Older method name for backwards compatibility.
  #   *insert_bitmap = *insert_image;

  #
  # DATA VALIDATION
  #

  #
  # :call-seq:
  #    data_validation(row, col, params)
  #    data_validation(first_row, first_col, last_row, last_col, params)
  #
  # This method handles the interface to Excel data validation.
  # Somewhat ironically the this requires a lot of validation code since the
  # interface is flexible and covers a several types of data validation.
  #
  # We allow data validation to be called on one cell or a range of cells. The
  # hashref contains the validation parameters and must be the last param:
  #
  # Returns  0 : normal termination
  #         -1 : insufficient number of arguments
  #         -2 : row or column out of range
  #         -3 : incorrect parameter.
  #
  # The data_validation() method is used to construct an Excel data validation
  # or to limit the user input to a dropdown list of values.
  #
  #     worksheet.data_validation('B3',
  #         {
  #             :validate => 'integer',
  #             :criteria => '>',
  #             :value    => 100,
  #         })
  #
  #     worksheet.data_validation('B5:B9',
  #         {
  #             :validate => 'list',
  #             :value    => ['open', 'high', 'close'],
  #         })
  #
  # This method contains a lot of parameters and is described in detail in a
  # separate section "DATA VALIDATION IN EXCEL".
  #
  # See also the data_validate.rb program in the examples directory of the distro
  #
  # The data_validation() method is used to construct an Excel data validation.
  #
  # It can be applied to a single cell or a range of cells. You can pass 3
  # parameters such as (_row_, _col_, {...}) or 5 parameters such as
  # (_first_row_, _first_col_, _last_row_, _last_col_, {...}). You can also
  # use A1 style notation. For example:
  #
  #     worksheet.data_validation(0, 0,       {...})
  #     worksheet.data_validation(0, 0, 4, 1, {...})
  #
  #     # Which are the same as:
  #
  #     $worksheet.data_validation('A1',       {...})
  #     $worksheet.data_validation('A1:B5',    {...})
  #
  # See also the note about "Cell notation" for more information.
  #
  # The last parameter in data_validation() must be a hash ref containing the
  # parameters that describe the type and style of the data validation. The
  # allowable parameters are:
  #
  #     validate
  #     criteria
  #     value | minimum | source
  #     maximum
  #     ignore_blank
  #     dropdown
  #
  #     input_title
  #     input_message
  #     show_input
  #
  #     error_title
  #     error_message
  #     error_type
  #     show_error
  #
  # These parameters are explained in the following sections. Most of the
  # parameters are optional, however, you will generally require the three main
  # options validate, criteria and value.
  #
  #     worksheet.data_validation('B3',
  #         {
  #             :validate => 'integer',
  #             :criteria => '>',
  #             :value    => 100
  #         })
  #
  # The data_validation method returns:
  #
  #      0 for success.
  #     -1 for insufficient number of arguments.
  #     -2 for row or column out of bounds.
  #     -3 for incorrect parameter or value.
  #
  # ===validate
  #
  # This parameter is passed in a hash ref to data_validation().
  #
  # The validate parameter is used to set the type of data that you wish to
  # validate. It is always required and it has no default value. Allowable
  # values are:
  #
  #     any
  #     integer
  #     decimal
  #     list
  #     date
  #     time
  #     length
  #     custom
  #
  # * any is used to specify that the type of data is unrestricted. This
  #   is the same as not applying a data validation. It is only provided for
  #   completeness and isn't used very often in the context of WriteExcel.
  #
  # * integer restricts the cell to integer values. Excel refers to this
  #   as 'whole number'.
  #
  #     :validate => 'integer',
  #     :criteria => '>',
  #     :value    => 100,
  #
  # * decimal restricts the cell to decimal values.
  #
  #     :validate => 'decimal',
  #     :criteria => '>',
  #     :value    => 38.6,
  #
  # * list restricts the cell to a set of user specified values. These
  #   can be passed in an array ref or as a cell range (named ranges aren't
  #   currently supported):
  #
  #     :validate => 'list',
  #     :value    => ['open', 'high', 'close'],
  #     # Or like this:
  #     :value    => 'B1:B3',
  #
  # Excel requires that range references are only to cells on the
  # same worksheet.
  #
  # * date restricts the cell to date values. Dates in Excel are expressed
  #   as integer values but you can also pass an ISO860 style string as used in
  #   write_date_time(). See also "DATES AND TIME IN EXCEL" for more information
  #   about working with Excel's dates.
  #
  #     :validate => 'date',
  #     :criteria => '>',
  #     :value    => 39653, # 24 July 2008
  #     # Or like this:
  #     :value    => '2008-07-24T',
  #
  # * time restricts the cell to time values. Times in Excel are expressed
  #   as decimal values but you can also pass an ISO860 style string as used in
  #   write_date_time(). See also "DATES AND TIME IN EXCEL" for more information
  #   about working with Excel's times.
  #
  #     :validate => 'time',
  #     :criteria => '>',
  #     :value    => 0.5, # Noon
  #     # Or like this:
  #     :value    => 'T12:00:00',
  #
  # * length restricts the cell data based on an integer string length.
  #   Excel refers to this as 'Text length'.
  #
  #     :validate => 'length',
  #     :criteria => '>',
  #     :value    => 10,
  #
  # * custom restricts the cell based on an external Excel formula that
  #   returns a TRUE/FALSE value.
  #
  #     :validate => 'custom',
  #     :value    => '=IF(A10>B10,TRUE,FALSE)',
  #
  # ===criteria
  #
  # This parameter is passed in a hash ref to data_validation().
  #
  # The criteria parameter is used to set the criteria by which the data in
  # the cell is validated. It is almost always required except for the list and
  # custom validate options. It has no default value. Allowable values are:
  #
  #     'between'
  #     'not between'
  #     'equal to'                  |  '=='  |  '='
  #     'not equal to'              |  '!='  |  '<>'
  #     'greater than'              |  '>'
  #     'less than'                 |  '<'
  #     'greater than or equal to'  |  '>='
  #     'less than or equal to'     |  '<='
  #
  # You can either use Excel's textual description strings, in the first
  # column above, or the more common operator alternatives. The following
  # are equivalent:
  #
  #     :validate => 'integer',
  #     :criteria => 'greater than',
  #     :value    => 100,
  #
  #     :validate => 'integer',
  #     :criteria => '>',
  #     :value    => 100,
  #
  # The list and custom validate options don't require a criteria. If you
  # specify one it will be ignored.
  #
  #     :validate => 'list',
  #     :value    => ['open', 'high', 'close'],
  #
  #     :validate => 'custom',
  #     :value    => '=IF(A10>B10,TRUE,FALSE)',
  #
  # ===value | minimum | source
  #
  # This parameter is passed in a hash ref to data_validation().
  #
  # The value parameter is used to set the limiting value to which the criteria
  # is applied. It is always required and it has no default value. You can also
  # use the synonyms minimum or source to make the validation a little clearer
  # and closer to Excel's description of the parameter:
  #
  #     # Use 'value'
  #     :validate => 'integer',
  #     :criteria => '>',
  #     :value    => 100,
  #
  #     # Use 'minimum'
  #     :validate => 'integer',
  #     :criteria => 'between',
  #     :minimum  => 1,
  #     :maximum  => 100,
  #
  #     # Use 'source'
  #     :validate => 'list',
  #     :source   => 'B1:B3',
  #
  # ===maximum
  #
  # This parameter is passed in a hash ref to data_validation().
  #
  # The maximum parameter is used to set the upper limiting value when the
  # criteria is either 'between' or 'not between':
  #
  #     :validate => 'integer',
  #     :criteria => 'between',
  #     :minimum  => 1,
  #     :maximum  => 100,
  #
  # ===ignore_blank
  #
  # This parameter is passed in a hash ref to data_validation().
  #
  # The ignore_blank parameter is used to toggle on and off the
  # 'Ignore blank' option in the Excel data validation dialog. When the option
  # is on the data validation is not applied to blank data in the cell. It is
  # on by default.
  #
  #     :ignore_blank => 0,  # Turn the option off
  #
  # ===dropdown
  #
  # This parameter is passed in a hash ref to data_validation().
  #
  # The dropdown parameter is used to toggle on and off the 'In-cell dropdown'
  # option in the Excel data validation dialog. When the option is on a
  # dropdown list will be shown for list validations. It is on by default.
  #
  #     :dropdown => 0,      # Turn the option off
  #
  # ===input_title
  #
  # This parameter is passed in a hash ref to data_validation().
  #
  # The input_title parameter is used to set the title of the input message
  # that is displayed when a cell is entered. It has no default value and is
  # only displayed if the input message is displayed. See the input_message
  # parameter below.
  #
  #     :input_title   => 'This is the input title',
  #
  # The maximum title length is 32 characters. UTF8 strings are handled
  # automatically.
  #
  # ===input_message
  #
  # This parameter is passed in a hash ref to data_validation().
  #
  # The input_message parameter is used to set the input message that is
  # displayed when a cell is entered. It has no default value.
  #
  #     :validate      => 'integer',
  #     :criteria      => 'between',
  #     :minimum       => 1,
  #     :maximum       => 100,
  #     :input_title   => 'Enter the applied discount:',
  #     :input_message => 'between 1 and 100',
  #
  # The message can be split over several lines using newlines, "\n" in double
  # quoted strings.
  #
  #     :input_message => "This is\na test.",
  #
  # The maximum message length is 255 characters. UTF8 strings are handled
  # automatically.
  #
  # ===show_input
  #
  # This parameter is passed in a hash ref to data_validation().
  #
  # The show_input parameter is used to toggle on and off the 'Show input
  # message when cell is selected' option in the Excel data validation dialog.
  # When the option is off an input message is not displayed even if it has
  # been set using input_message. It is on by default.
  #
  #     :show_input => 0,      # Turn the option off
  #
  # ===error_title
  #
  # This parameter is passed in a hash ref to data_validation().
  #
  # The error_title parameter is used to set the title of the error message
  # that is displayed when the data validation criteria is not met. The default
  # error title is 'Microsoft Excel'.
  #
  #     :error_title   => 'Input value is not valid',
  #
  # The maximum title length is 32 characters. UTF8 strings are handled
  # automatically.
  #
  # ===error_message
  #
  # This parameter is passed in a hash ref to data_validation().
  #
  # The error_message parameter is used to set the error message that is
  # displayed when a cell is entered. The default error message is
  # "The value you entered is not valid.\nA user has restricted values that can
  # be entered into the cell.".
  #
  #     :validate      => 'integer',
  #     :criteria      => 'between',
  #     :minimum       => 1,
  #     :maximum       => 100,
  #     :error_title   => 'Input value is not valid',
  #     :error_message => 'It should be an integer between 1 and 100',
  #
  # The message can be split over several lines using newlines, "\n" in double
  # quoted strings.
  #
  #     :input_message => "This is\na test.",
  #
  # The maximum message length is 255 characters. UTF8 strings are handled
  # automatically.
  #
  # ===error_type
  #
  # This parameter is passed in a hash ref to data_validation().
  #
  # The error_type parameter is used to specify the type of error dialog that
  # is displayed. There are 3 options:
  #
  #     'stop'
  #     'warning'
  #     'information'
  #
  # The default is 'stop'.
  #
  # ===show_error
  #
  # This parameter is passed in a hash ref to data_validation().
  #
  # The show_error parameter is used to toggle on and off the 'Show error alert
  # after invalid data is entered' option in the Excel data validation dialog.
  # When the option is off an error message is not displayed even if it has been
  # set using error_message. It is on by default.
  #
  #     :show_error => 0,      # Turn the option off
  #
  # ===Examples
  #
  # Example 1. Limiting input to an integer greater than a fixed value.
  #
  #     worksheet.data_validation('A1',
  #         {
  #             :validate        => 'integer',
  #             :criteria        => '>',
  #             :value           => 0,
  #         })
  #
  # Example 2. Limiting input to an integer greater than a fixed value where
  # the value is referenced from a cell.
  #
  #     worksheet.data_validation('A2',
  #         {
  #             :validate        => 'integer',
  #             :criteria        => '>',
  #             :value           => '=E3',
  #         })
  #
  # Example 3. Limiting input to a decimal in a fixed range.
  #
  #     worksheet.data_validation('A3',
  #         {
  #             :validate        => 'decimal',
  #             :criteria        => 'between',
  #             :minimum         => 0.1,
  #             :maximum         => 0.5,
  #         })
  #
  # Example 4. Limiting input to a value in a dropdown list.
  #
  #     worksheet.data_validation('A4',
  #         {
  #             :validate        => 'list',
  #             :source          => ['open', 'high', 'close'],
  #         })
  #
  # Example 5. Limiting input to a value in a dropdown list where the list
  # is specified as a cell range.
  #
  #     worksheet.data_validation('A5',
  #         {
  #             :validate        => 'list',
  #             :source          => '=E4:G4',
  #         })
  #
  # Example 6. Limiting input to a date in a fixed range.
  #
  #     worksheet.data_validation('A6',
  #         {
  #             :validate        => 'date',
  #             :criteria        => 'between',
  #             :minimum         => '2008-01-01T',
  #             :maximum         => '2008-12-12T',
  #         })
  #
  # Example 7. Displaying a message when the cell is selected.
  #
  #     worksheet.data_validation('A7',
  #         {
  #             :validate      => 'integer',
  #             :criteria      => 'between',
  #             :minimum       => 1,
  #             :maximum       => 100,
  #             :input_title   => 'Enter an integer:',
  #             :input_message => 'between 1 and 100',
  #         })
  #
  # See also the data_validate.rb program in the examples directory of the distro.
  #
  def data_validation(*args)
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    # Make the last row/col the same as the first if not defined.
    row1, col1, row2, col2 = args
    return -2 if check_dimensions(row1, col1, 1, 1) != 0
    return -2 if !row2.kind_of?(Hash) && check_dimensions(row2, col2, 1, 1) != 0

    validation = DataValidation.factory(parser, date_1904?, *args)
    return validation if (-3..-1).include?(validation)

    # Store the validation information until we close the worksheet.
    @validations << validation
  end

  def is_name_utf16be?  # :nodoc:
    if @name_utf16be == 0
      false
    elsif @name_utf16be == 1
      true
    else
      !!@name_utf16be
    end
  end

  def index  # :nodoc:
    @workbook.worksheets.index(self)
  end

  def type  # :nodoc:
    @type
  end

  def images_array  # :nodoc:
    @images.array
  end

  def offset  # :nodoc:
    @offset
  end

  def offset=(val)  # :nodoc:
    @offset = val
  end

  def selected?  # :nodoc:
    @selected
  end

  def selected=(val)  # :nodoc:
    @selected = val
  end

  def hidden?  # :nodoc:
    @hidden
  end

  def hidden=(val)  # :nodoc:
    @hidden = val
  end

  def num_images  # :nodoc:
    @num_images
  end

  def num_images=(val)  # :nodoc:
    @num_images = val
  end

  def image_mso_size  # :nodoc:
    @image_mso_size
  end

  def image_mso_size=(val)  # :nodoc:
    @image_mso_size = val
  end

  def images_size   #:nodoc:
    @images.array.size
  end

  def comments_size   #:nodoc:
    @comments.array.size
  end

  def charts_size   #:nodoc:
    @charts.array.size
  end

  def print_title_name_record_long     #:nodoc:
    @title_range.name_record_long(@workbook.ext_refs["#{index}:#{index}"])
  end

  def name_record_short(cell_range, hidden = nil)
    cell_range.name_record_short(@workbook.ext_refs["#{index}:#{index}"], hidden)
  end

  def print_title_name_record_short(hidden = nil)     #:nodoc:
    name_record_short(@title_range, hidden)
  end

  def autofilter_name_record_short(hidden = nil)     #:nodoc:
    name_record_short(@filter_area, hidden) if @filter_area.count != 0
  end

  def print_area_name_record_short(hidden = nil)     #:nodoc:
    name_record_short(@print_range, hidden) if @print_range.row_min
  end

  #
  # Calculate the vertices that define the position of a graphical object within
  # the worksheet.
  #
  #         +------------+------------+
  #         |     A      |      B     |
  #   +-----+------------+------------+
  #   |     |(x1,y1)     |            |
  #   |  1  |(A1)._______|______      |
  #   |     |    |              |     |
  #   |     |    |              |     |
  #   +-----+----|    BITMAP    |-----+
  #   |     |    |              |     |
  #   |  2  |    |______________.     |
  #   |     |            |        (B2)|
  #   |     |            |     (x2,y2)|
  #   +---- +------------+------------+
  #
  # Example of a bitmap that covers some of the area from cell A1 to cell B2.
  #
  # Based on the width and height of the bitmap we need to calculate 8 vars:
  #     $col_start, $row_start, $col_end, $row_end, $x1, $y1, $x2, $y2.
  # The width and height of the cells are also variable and have to be taken into
  # account.
  # The values of $col_start and $row_start are passed in from the calling
  # function. The values of $col_end and $row_end are calculated by subtracting
  # the width and height of the bitmap from the width and height of the
  # underlying cells.
  # The vertices are expressed as a percentage of the underlying cell width as
  # follows (rhs values are in pixels):
  #
  #       x1 = X / W *1024
  #       y1 = Y / H *256
  #       x2 = (X-1) / W *1024
  #       y2 = (Y-1) / H *256
  #
  #       Where:  X is distance from the left side of the underlying cell
  #               Y is distance from the top of the underlying cell
  #               W is the width of the cell
  #               H is the height of the cell
  #
  # Note: the SDK incorrectly states that the height should be expressed as a
  # percentage of 1024.
  #
  def position_object(col_start, row_start, x1, y1, width, height)   #:nodoc:
    # col_start;  # Col containing upper left corner of object
    # x1;         # Distance to left side of object

    # row_start;  # Row containing top left corner of object
    # y1;         # Distance to top of object

    # col_end;    # Col containing lower right corner of object
    # x2;         # Distance to right side of object

    # row_end;    # Row containing bottom right corner of object
    # y2;         # Distance to bottom of object

    # width;      # Width of image frame
    # height;     # Height of image frame

    # Adjust start column for offsets that are greater than the col width
    x1, col_start = adjust_col_position(x1, col_start)

    # Adjust start row for offsets that are greater than the row height
    y1, row_start = adjust_row_position(y1, row_start)

    # Initialise end cell to the same as the start cell
    col_end    = col_start
    row_end    = row_start

    width     += x1
    height    += y1

    # Subtract the underlying cell widths to find the end cell of the image
    width, col_end = adjust_col_position(width, col_end)

    # Subtract the underlying cell heights to find the end cell of the image
    height, row_end = adjust_row_position(height, row_end)

    # Bitmap isn't allowed to start or finish in a hidden cell, i.e. a cell
    # with zero eight or width.
    #
    return if size_col(col_start) == 0
    return if size_col(col_end)   == 0
    return if size_row(row_start) == 0
    return if size_row(row_end)   == 0

    # Convert the pixel values to the percentage value expected by Excel
    x1 = 1024.0 * x1     / size_col(col_start)
    y1 =  256.0 * y1     / size_row(row_start)
    x2 = 1024.0 * width  / size_col(col_end)
    y2 =  256.0 * height / size_row(row_end)

    # Simulate ceil() without calling POSIX::ceil().
    x1 = (x1 +0.5).to_i
    y1 = (y1 +0.5).to_i
    x2 = (x2 +0.5).to_i
    y2 = (y2 +0.5).to_i

    [
      col_start, x1,
      row_start, y1,
      col_end,   x2,
      row_end,   y2
    ]
  end

  def filter_count
    @filter_area.count
  end

  def store_parent_mso_record(dg_length, spgr_length, spid)  # :nodoc:
    store_mso_dg_container(dg_length)      +
    store_mso_dg                           +
    store_mso_spgr_container(spgr_length)  +
    store_mso_sp_container(40)             +
    store_mso_spgr()                       +
    store_mso_sp(0x0, spid, 0x0005)
  end

  #
  # Write the Escher SpContainer record that is part of MSODRAWING.
  #
  def store_mso_sp_container(length)   #:nodoc:
    type        = 0xF004
    version     = 15
    instance    = 0
    data        = ''

    add_mso_generic(type, version, instance, data, length)
  end

  #
  # Write the Escher Sp record that is part of MSODRAWING.
  #
  def store_mso_sp(instance, spid, options)   #:nodoc:
    type        = 0xF00A
    version     = 2
    data        = ''
    length      = 8
    data        = [spid, options].pack('VV')

    add_mso_generic(type, version, instance, data, length)
  end

  #
  # Write the Escher Opt record that is part of MSODRAWING.
  #
  def store_mso_opt_image(spid)   #:nodoc:
    type        = 0xF00B
    version     = 3
    instance    = 3
    data        = ''
    length      = nil

    data = [0x4104].pack('v') +
    [spid].pack('V')        +
    [0x01BF].pack('v')      +
    [0x00010000].pack('V')  +
    [0x03BF].pack( 'v')     +
    [0x00080000].pack( 'V')

    add_mso_generic(type, version, instance, data, length)
  end

  #
  # Write the Escher ClientAnchor record that is part of MSODRAWING.
  #    flag
  #    col_start     # Col containing upper left corner of object
  #    x1            # Distance to left side of object
  #
  #    row_start     # Row containing top left corner of object
  #    y1            # Distance to top of object
  #
  #    col_end       # Col containing lower right corner of object
  #    x2            # Distance to right side of object
  #
  #    row_end       # Row containing bottom right corner of object
  #    y2            # Distance to bottom of object
  #
  def store_mso_client_anchor(flag, col_start, x1, row_start, y1, col_end, x2, row_end, y2)   #:nodoc:
    type        = 0xF010
    version     = 0
    instance    = 0
    data        = ''
    length      = 18

    data = [flag, col_start, x1, row_start, y1, col_end, x2, row_end, y2].pack('v9')

    add_mso_generic(type, version, instance, data, length)
  end

  #
  # Write the Escher ClientData record that is part of MSODRAWING.
  #
  def store_mso_client_data   #:nodoc:
    type        = 0xF011
    version     = 0
    instance    = 0
    data        = ''
    length      = 0

    add_mso_generic(type, version, instance, data, length)
  end

  def comments_visible?
    @comments.visible?
  end

  #
  # Excel BIFF BOUNDSHEET record.
  #
  #    sheetname  # Worksheet name
  #    offset     # Location of worksheet BOF
  #    type       # Worksheet type
  #    hidden     # Worksheet hidden flag
  #    encoding   # Sheet name encoding
  #
  def boundsheet       #:nodoc:
    hidden    = self.hidden? ? 1 : 0
    encoding  = self.is_name_utf16be? ? 1 : 0

    record    = 0x0085                  # Record identifier
    length    = 0x08 + @name.bytesize   # Number of bytes to follow

    cch       = @name.bytesize          # Length of sheet name

    # Character length is num of chars not num of bytes
    cch /= 2 if is_name_utf16be?

    # Change the UTF-16 name from BE to LE
    sheetname = is_name_utf16be? ? @name.unpack('v*').pack('n*') : @name

    grbit     = @type | hidden

    header    = [record, length].pack("vv")
    data      = [@offset, grbit, cch, encoding].pack("VvCC")

    header + data + sheetname
  end

  def num_shapes
    1 + num_images + comments_size + charts_size + filter_count
  end

  def push_object_ids(mso_size, drawings_saved, max_spid, start_spid, clusters)
    mso_size     += image_mso_size

    # Add a drawing object for each sheet with comments.
    drawings_saved += 1

    # For each sheet start the spids at the next 1024 interval.
    max_spid   = 1024 * (1 + Integer((max_spid -1)/1024.0))
    start_spid = max_spid

    # Max spid for each sheet and eventually for the workbook.
    max_spid  += num_shapes

    # Store the cluster ids
    mso_size += 8 * (num_shapes / 1024 + 1)
    push_cluster(num_shapes, drawings_saved, clusters)

    # Pass calculated values back to the worksheet
    @object_ids = ObjectIds.new(start_spid, drawings_saved, num_shapes, max_spid -1)

    [mso_size, drawings_saved, max_spid, start_spid]
  end

  def push_cluster(num_shapes, drawings_saved, clusters)
    i = num_shapes
    while i > 0
      size = i > 1024 ? 1024 : i
      clusters << [drawings_saved, size]
      i -= 1024
    end
  end

  ###############################################################################
  #
  # Internal methods
  #

  private

  def update_workbook_str_table(str)
    @workbook.update_str_table(str)
  end

  def active?
    self == @workbook.worksheets.activesheet
  end

  def frozen?
    @frozen
  end

  def display_zeros?
    !@hide_zeros
  end

  def set_header_footer_common(type, string, margin, encoding)  # :nodoc:
    ruby_19 { string = convert_to_ascii_if_ascii(string) }

    limit    = encoding != 0 ? 255 *2 : 255

    # Handle utf8 strings
    if is_utf8?(string)
      string = utf8_to_16be(string)
      encoding = 1
    end

    if string.bytesize >= limit
      #           carp 'Header string must be less than 255 characters';
      return
    end

    if type == :header
      @header          = string
      @margin_header   = margin
      @header_encoding = encoding
    else
      @footer          = string
      @margin_footer   = margin
      @footer_encoding = encoding
    end
  end

  def merge_range_core(rwFirst, colFirst, rwLast, colLast, string, format, encoding)
    # Temp code to prevent merged formats in non-merged cells.
    error = "Error: refer to merge_range() in the documentation. " +
    "Can't use previously non-merged format in merged cells"

    raise error if format.used_merge == -1
    format.used_merge = 0   # Until the end of this function.

    # Set the merge_range property of the format object. For BIFF8+.
    format.set_merge_range

    # Excel doesn't allow a single cell to be merged
    raise "Can't merge single cell" if rwFirst  == rwLast and
    colFirst == colLast

    # Swap last row/col with first row/col as necessary
    rwFirst,  rwLast  = rwLast,  rwFirst  if rwFirst  > rwLast
    colFirst, colLast = colLast, colFirst if colFirst > colLast

    # Write the first cell
    yield(rwFirst, colFirst, string, format, encoding)

    # Pad out the rest of the area with formatted blank cells.
    (rwFirst .. rwLast).each do |row|
      (colFirst .. colLast).each do |col|
        next if row == rwFirst and col == colFirst
        write_blank(row, col, format)
      end
    end

    merge_cells(rwFirst, colFirst, rwLast, colLast)

    # Temp code to prevent merged formats in non-merged cells.
    format.used_merge = 1
  end

  #
  # Extract the tokens from the filter expression. The tokens are mainly non-
  # whitespace groups. The only tricky part is to extract string tokens that
  # contain whitespace and/or quoted double quotes (Excel's escaped quotes).
  #
  # Examples: 'x <  2000'
  #           'x >  2000 and x <  5000'
  #           'x = "foo"'
  #           'x = "foo bar"'
  #           'x = "foo "" bar"'
  #
  def extract_filter_tokens(expression = nil)   #:nodoc:
    return [] unless expression

    tokens = []
    str = expression
    while str =~ /"(?:[^"]|"")*"|\S+/
      tokens << $&
      str = $~.post_match
    end

    # Remove leading and trailing quotes and unescape other quotes
    tokens.map! do |token|
      token.sub!(/^"/, '')
      token.sub!(/"$/, '')
      token.gsub!(/""/, '"')

      # if token is number, convert to numeric.
      if token =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/
        token.to_f == token.to_i ? token.to_i : token.to_f
      else
        token
      end
    end

    tokens
  end

  #
  # Converts the tokens of a possibly conditional expression into 1 or 2
  # sub expressions for further parsing.
  #
  # Examples:
  #          ('x', '==', 2000) -> exp1
  #          ('x', '>',  2000, 'and', 'x', '<', 5000) -> exp1 and exp2
  #
  def parse_filter_expression(expression, tokens)   #:nodoc:
    # The number of tokens will be either 3 (for 1 expression)
    # or 7 (for 2  expressions).
    #
    if (tokens.size == 7)
      conditional = tokens[3]
      if conditional =~ /^(and|&&)$/
        conditional = 0
      elsif conditional =~ /^(or|\|\|)$/
        conditional = 1
      else
        raise "Token '#{conditional}' is not a valid conditional " +
        "in filter expression '#{expression}'"
      end
      expression_1 = parse_filter_tokens(expression, tokens[0..2])
      expression_2 = parse_filter_tokens(expression, tokens[4..6])
      [expression_1, conditional, expression_2].flatten
    else
      parse_filter_tokens(expression, tokens)
    end
  end

  #
  # Parse the 3 tokens of a filter expression and return the operator and token.
  #
  def parse_filter_tokens(expression, tokens)     #:nodoc:
    operators = {
      '==' => 2,
      '='  => 2,
      '=~' => 2,
      'eq' => 2,

      '!=' => 5,
      '!~' => 5,
      'ne' => 5,
      '<>' => 5,

      '<'  => 1,
      '<=' => 3,
      '>'  => 4,
      '>=' => 6,
    }

    operator = operators[tokens[1]]
    token    = tokens[2]

    # Special handling of "Top" filter expressions.
    if tokens[0] =~ /^top|bottom$/i
      value = tokens[1]
      if (value =~ /\D/ or value.to_i < 1 or value.to_i > 500)
        raise "The value '#{value}' in expression '#{expression}' " +
        "must be in the range 1 to 500"
      end
      token.downcase!
      if (token != 'items' and token != '%')
        raise "The type '#{token}' in expression '#{expression}' " +
        "must be either 'items' or '%'"
      end

      if (tokens[0] =~ /^top$/i)
        operator = 30
      else
        operator = 32
      end

      if (tokens[2] == '%')
        operator += 1
      end

      token    = value
    end

    if (not operator and tokens[0])
      raise "Token '#{tokens[1]}' is not a valid operator " +
      "in filter expression '#{expression}'"
    end

    # Special handling for Blanks/NonBlanks.
    if (token =~ /^blanks|nonblanks$/i)
      # Only allow Equals or NotEqual in this context.
      if (operator != 2 and operator != 5)
        raise "The operator '#{tokens[1]}' in expression '#{expression}' " +
        "is not valid in relation to Blanks/NonBlanks'"
      end

      token.downcase!

      # The operator should always be 2 (=) to flag a "simple" equality in
      # the binary record. Therefore we convert <> to =.
      if (token == 'blanks')
        if (operator == 5)
          operator = 2
          token    = 'nonblanks'
        end
      else
        if (operator == 5)
          operator = 2
          token    = 'blanks'
        end
      end
    end

    # if the string token contains an Excel match character then change the
    # operator type to indicate a non "simple" equality.
    if (operator == 2 and token =~ /[*?]/)
      operator = 22
    end

    [operator, token]
  end

  def store_with_compatibility(row, col, data)  # :nodoc:
    if compatibility?
      store_to_table(row, col, data)
    else
      append(data)
    end
  end

  def store_to_table(row, col, data)  # :nodoc:
    if @table[row]
      @table[row][col] = data
    else
      tmp = []
      tmp[col] = data
      @table[row] = tmp
    end
  end

  def compatibility?
    compatibility = @workbook.compatibility
    if compatibility == 0 || !compatibility
      false
    else
      true
    end
  end

  #
  # Returns an index to the XF record in the workbook.
  #
  # Note: this is a function, not a method.
  #
  def xf_record_index(row, col, xf=nil)       #:nodoc:
    if xf.respond_to?(:xf_index)
      xf.xf_index
    elsif @row_formats.has_key?(row)
      @row_formats[row].xf_index
    elsif @col_formats.has_key?(col)
      @col_formats[col].xf_index
    else
      0x0F
    end
  end

  #
  # Substitute an Excel cell reference in A1 notation for  zero based row and
  # column values in an argument list.
  #
  # Ex: ("A4", "Hello") is converted to (3, 0, "Hello").
  #
  def substitute_cellref(cell, *args)       #:nodoc:
    return [cell, *args] if cell.respond_to?(:coerce) # Numeric

    cell.upcase!

    # Convert a column range: 'A:A' or 'B:G'.
    # A range such as A:A is equivalent to A1:65536, so add rows as required
    if cell =~ /\$?([A-I]?[A-Z]):\$?([A-I]?[A-Z])/
      row1, col1 =  cell_to_rowcol($1 +'1')
      row2, col2 =  cell_to_rowcol($2 +'65536')
      return [row1, col1, row2, col2, *args]
    end

    # Convert a cell range: 'A1:B7'
    if cell =~ /\$?([A-I]?[A-Z]\$?\d+):\$?([A-I]?[A-Z]\$?\d+)/
      row1, col1 =  cell_to_rowcol($1)
      row2, col2 =  cell_to_rowcol($2)
      return [row1, col1, row2, col2, *args]
    end

    # Convert a cell reference: 'A1' or 'AD2000'
    if (cell =~ /\$?([A-I]?[A-Z]\$?\d+)/)
      row1, col1 =  cell_to_rowcol($1)
      return [row1, col1, *args]

    end

    raise("Unknown cell reference #{cell}")
  end

  #
  # Convert an Excel cell reference in A1 notation to a zero based row and column
  # reference; converts C1 to (0, 2).
  #
  # Returns: row, column
  #
  def cell_to_rowcol(cell)       #:nodoc:
    cell =~ /\$?([A-I]?[A-Z])\$?(\d+)/
    col     = $1
    row     = $2.to_i

    col = chars_to_col($1.split(//))

    # Convert 1-index to zero-index
    row -= 1
    col -= 1

    [row, col]
  end

  #
  # This is an internal method that is used to filter elements of the array of
  # pagebreaks used in the store_hbreak() and store_vbreak() methods. It:
  #   1. Removes duplicate entries from the list.
  #   2. Sorts the list.
  #   3. Removes 0 from the list if present.
  #
  def sort_pagebreaks(breaks)       #:nodoc:
    breaks.uniq.sort!
    breaks.shift if breaks[0] == 0

    # 1000 vertical pagebreaks appears to be an internal Excel 5 limit.
    # It is slightly higher in Excel 97/200, approx. 1026
    breaks.size > 1000 ? breaks[0..999] : breaks
  end

  #
  # Based on the algorithm provided by Daniel Rentz of OpenOffice.
  #
  def encode_password(password)
    i = 0
    chars = password.split(//)
    count = chars.size

    chars.collect! do |char|
      i += 1
      char     = char.ord << i
      low_15   = char & 0x7fff
      high_15  = char & 0x7fff << 15
      high_15  = high_15 >> 15
      char     = low_15 | high_15
    end

    encoded_password  = 0x0000
    chars.each { |c| encoded_password ^= c }
    encoded_password ^= count
    encoded_password ^= 0xCE4B
  end

  #
  # value     # Result to be encoded.
  #
  # Encode the user supplied result for a formula.
  #
  def encode_formula_result(value = nil)       #:nodoc:
    is_string = 0                 # Formula evaluates to str.
    # my $num;                    # Current value of formula.
    # my $grbit;                  # Option flags.

    unless value
      grbit  = 0x03
      num    = [0].pack("d")
    else
      # The user specified the result of the formula. We turn off the recalc
      # flag and check the result type.
      grbit  = 0x00

      if value.to_s =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/
        # Value is a number.
        num = [value].pack("d")
      else
        bools = {
          'TRUE'    => [1,  1],
          'FALSE'   => [1,  0],
          '#NULL!'  => [2,  0],
          '#DIV/0!' => [2,  7],
          '#VALUE!' => [2, 15],
          '#REF!'   => [2, 23],
          '#NAME?'  => [2, 29],
          '#NUM!'   => [2, 36],
          '#N/A'    => [2, 42]
        }

        if bools[value]
          # Value is a boolean.
          num = [bools[value][0], bools[value][1], 0, 0xFFFF].pack("vvvv")
        else
          # Value is a string.
          num = [0, 0, 0, 0xFFFF].pack("vvvv")
          is_string = 1
        end
      end
    end

    [num, grbit, is_string]
  end

  #
  # Pack the string value when a formula evaluates to a string. The value cannot
  # be calculated by the module and thus must be supplied by the user.
  #
  def get_formula_string(string)       #:nodoc:
    ruby_19 { string = convert_to_ascii_if_ascii(string) }

    record    = 0x0207         # Record identifier
    length    = 0x00           # Bytes to follow
    # string                   # Formula string.
    strlen    = string.bytesize  # Length of the formula string (chars).
    encoding  = 0              # String encoding.

    # Handle utf8 strings.
    if is_utf8?(string)
      string = utf8_to_16be(string)
      encoding = 1
    end

    length    = 0x03 + string.bytesize  # Length of the record data

    header    = [record, length].pack("vv")
    data      = [strlen, encoding].pack("vC")

    header + data + string
  end

  def store_formula_common(row, col, xf, value, formula)  # :nodoc:
    # Excel normally stores the last calculated value of the formula in $num.
    # Clearly we are not in a position to calculate this "a priori". Instead
    # we set $num to zero and set the option flags in $grbit to ensure
    # automatic calculation of the formula when the file is opened.
    # As a workaround for some non-Excel apps we also allow the user to
    # specify the result of the formula.
    #
    # is_string                                # Formula evaluates to str
    # num                                      # Current value of formula
    # grbit                                    # Option flags
    num, grbit, is_string = encode_formula_result(value)

    record    = 0x0006       # Record identifier
    chn       = 0x0000       # Must be zero

    formlen   = formula.bytesize     # Length of the binary string
    length    = 0x16 + formlen       # Length of the record data

    header    = [record, length].pack("vv")
    data      = [row, col, xf].pack("vvv") +
                num                        +
                [grbit, chn, formlen].pack('vVv')

    # The STRING record if the formula evaluates to a string.
    string  = ''
    string  = get_formula_string(value) if is_string != 0

    # Store the data or write immediately depending on the compatibility mode.
    store_with_compatibility(row, col, header + data + formula + string)
  end

  #    row1                         # Start row
  #    col1                         # Start column
  #    row2                         # End row
  #    col2                         # End column
  #    url                          # URL string
  #    str                          # Alternative label
  #
  # Used to write http, ftp and mailto hyperlinks.
  # The link type ($options) is 0x03 is the same as absolute dir ref without
  # sheet. However it is differentiated by the $unknown2 data stream.
  #
  # See also write_url() above for a general description and return values.
  #
  def write_url_web(row1, col1, row2, col2, url, str = nil, format = nil)       #:nodoc:
    ruby_19 { url = convert_to_ascii_if_ascii(url) }

    record = 0x01B8                       # Record identifier
    length = 0x00000                      # Bytes to follow

    xf     = format || url_format        # The cell format

    # Write the visible label but protect against url recursion in write().
    str          = url unless str
    error        = write_string(row1, col1, str, xf)
    return error if error == -2

    # Pack the undocumented parts of the hyperlink stream
    unknown1    = ["D0C9EA79F9BACE118C8200AA004BA90B02000000"].pack("H*")
    unknown2    = ["E0C9EA79F9BACE118C8200AA004BA90B"].pack("H*")

    # Pack the option flags
    options     = [0x03].pack("V")

    # URL encoding.
    encoding    = 0

    # Convert an Utf8 URL type and to a null terminated wchar string.
    if is_utf8?(url)
      url = utf8_to_16be(url)
      # URL is null terminated.
      ruby_18 { url += "\0\0" } ||
      ruby_19 { url += "\0\0".force_encoding('UTF-16BE') }
      encoding = 1
    end

    # Convert an Ascii URL type and to a null terminated wchar string.
    if encoding == 0
      url  =
        ruby_18 { url + "\0" } ||
        ruby_19 { url.force_encoding('BINARY') + "\0".force_encoding('BINARY') }
      url  = url.unpack('c*').pack('v*')
    end

    # Pack the length of the URL
    url_len     = [url.bytesize].pack("V")

    # Calculate the data length
    length         = 0x34 + url.bytesize

    # Pack the header data
    header      = [record, length].pack("vv")
    data        = [row1, row2, col1, col2].pack("vvvv")

    # Write the packed data
    append( header, data,unknown1,options,unknown2,url_len,url)

    error
  end

  #    row1                         # Start row
  #    col1                         # Start column
  #    row2                         # End row
  #    col2                         # End column
  #    url                          # URL string
  #    str                          # Alternative label
  #
  # Used to write internal reference hyperlinks such as "Sheet1!A1".
  #
  # See also write_url() above for a general description and return values.
  #
  def write_url_internal(row1, col1, row2, col2, url, str = nil, format = nil)       #:nodoc:
    record = 0x01B8                       # Record identifier
    length = 0x00000                      # Bytes to follow

    xf     = format || url_format        # The cell format

    # Strip URL type
    url = url.sub(/^internal:/, '')

    # Write the visible label but protect against url recursion in write().
    str          = url.dup unless str
    error        = write_string(row1, col1, str, xf)
    return error if error == -2

    # Pack the undocumented parts of the hyperlink stream
    unknown1    = ["D0C9EA79F9BACE118C8200AA004BA90B02000000"].pack("H*")

    # Pack the option flags
    options     = [0x08].pack("V")

    # URL encoding.
    encoding    = 0

    # Convert an Utf8 URL type and to a null terminated wchar string.
    ruby_18 do
      if is_utf8?(url)
        # Quote sheet name if not already, i.e., Sheet!A1 to 'Sheet!A1'.
        url = "'#{sheetname_from_url(url)}'!#{cell_from_url(url)}" if not url =~ /^'/
        # URL is null terminated.
        ruby_18 { url = utf8_to_16be(url) + "\0\0" } ||
          encoding = 1
      end
    end

    # Convert an Ascii URL type and to a null terminated wchar string.
    if encoding == 0
      url += "\0"
      url = url.unpack('c*').pack('v*')
    end

    # Pack the length of the URL as chars (not wchars)
    url_len     = [(url.bytesize/2).to_i].pack("V")

    # Calculate the data length
    length         = 0x24 + url.bytesize

    # Pack the header data
    header      = [record, length].pack("vv")
    data        = [row1, row2, col1, col2].pack("vvvv")

    # Write the packed data
    append( header, data, unknown1, options, url_len, url)

    error
  end

  def sheetname_from_url(url)
    sheetname, cell = url.split('!')
    sheetname
  end

  def cell_from_url(url)
    sheetname, cell = url.split('!')
    cell
  end

  #
  # Write links to external directory names such as 'c:\foo.xls',
  # c:\foo.xls#Sheet1!A1', '../../foo.xls'. and '../../foo.xls#Sheet1!A1'.
  #
  # Note: Excel writes some relative links with the $dir_long string. We ignore
  # these cases for the sake of simpler code.
  #
  # See also write_url() above for a general description and return values.
  #
  def write_url_external(row1, col1, row2, col2, url, str = nil, format = nil)       #:nodoc:
    # Network drives are different. We will handle them separately
    # MS/Novell network drives and shares start with \\
    if url =~ /^external:(\\\\|\/\/)/
      return write_url_external_net(row1, col1, row2, col2, url, str, format)
    end

    record      = 0x01B8                       # Record identifier
    length      = 0x00000                      # Bytes to follow

    xf     = format || url_format        # The cell format

    # Strip URL type and change Unix dir separator to Dos style (if needed)
    #
    url = url.sub(/^external:/, '').gsub(%r|/|, '\\')

    # Write the visible label but protect against url recursion in write().
    str = url.sub(/\#/, ' - ') unless str
    error        = write_string(row1, col1, str, xf)
    return error if error == -2

    # Determine if the link is relative or absolute:
    # Absolute if link starts with DOS drive specifier like C:
    # Otherwise default to 0x00 for relative link.
    #
    absolute    = 0x00
    absolute    = 0x02  if url =~ /^[A-Za-z]:/

    dir_long, link_type, sheet_len, sheet = analyze_link(url, absolute)

    # Pack the link type
    link_type      = [link_type].pack("V")

    # Calculate the up-level dir count e.g. (..\..\..\ == 3)
    up_count    = 0
    while dir_long.sub!(/^\.\.\\/, '')
      up_count += 1
    end
    up_count    = [up_count].pack("v")

    # Store the short dos dir name (null terminated)
    dir_short   = dir_long + "\0"

    # Store the long dir name as a wchar string (non-null terminated)
    dir_long = dir_long.split('').join("\0") + "\0"

    # Pack the lengths of the dir strings
    dir_short_len = [dir_short.bytesize].pack("V")
    dir_long_len  = [dir_long.bytesize].pack("V")
    stream_len    = [dir_long.bytesize + 0x06].pack("V")

    # Pack the undocumented parts of the hyperlink stream
    unknown1 = ['D0C9EA79F9BACE118C8200AA004BA90B02000000'].pack("H*")
    unknown2 = ['0303000000000000C000000000000046'].pack("H*")
    unknown3 = ['FFFFADDE000000000000000000000000000000000000000'].pack("H*")
    unknown4 = [0x03].pack("v")

    # Pack the main data stream
    data        = [row1, row2, col1, col2].pack("vvvv") +
    unknown1     +
    link_type    +
    unknown2     +
    up_count     +
    dir_short_len+
    dir_short    +
    unknown3     +
    stream_len   +
    dir_long_len +
    unknown4     +
    dir_long     +
    sheet_len    +
    sheet

    # Pack the header data
    length      = data.bytesize
    header      = [record, length].pack("vv")

    # Write the packed data
    append(header, data)

    error
  end

  #
  # Write links to external MS/Novell network drives and shares such as
  # '//NETWORK/share/foo.xls' and '//NETWORK/share/foo.xls#Sheet1!A1'.
  #
  # See also write_url() above for a general description and return values.
  #
  def write_url_external_net(row1, col1, row2, col2, url, str, format)       #:nodoc:
    record      = 0x01B8                       # Record identifier
    length      = 0x00000                      # Bytes to follow

    xf          = format || url_format  # The cell format

    # Strip URL type and change Unix dir separator to Dos style (if needed)
    #
    url = url.sub(/^external:/, '').gsub!(%r|/|, '\\')

    # Write the visible label but protect against url recursion in write().
    str = url.sub(/\#/, ' - ') unless str
    error        = write_string(row1, col1, str, xf)
    return error if error == -2

    dir_long, link_type, sheet_len, sheet = analyze_link(url)

    # Pack the link type
    link_type      = [link_type].pack("V")

    # Make the string null terminated
    dir_long      += "\0"

    # Pack the lengths of the dir string
    dir_long_len  = [dir_long.bytesize].pack("V")

    # Store the long dir name as a wchar string (non-null terminated)
    dir_long = dir_long.split('').join("\0") + "\0"

    # Pack the undocumented part of the hyperlink stream
    unknown1    = ['D0C9EA79F9BACE118C8200AA004BA90B02000000'].pack("H*")

    # Pack the main data stream
    data         = [row1, row2, col1, col2].pack("vvvv") +
    unknown1     +
    link_type    +
    dir_long_len +
    dir_long     +
    sheet_len    +
    sheet

    # Pack the header data
    length      = data.bytesize
    header      = [record, length].pack("vv")

    # Write the packed data
    append(header, data)

    error
  end

  def url_format
    @workbook.url_format
  end

  # Determine if the link contains a sheet reference and change some of the
  # parameters accordingly.
  # Split the dir name and sheet name (if it exists)
  #
  def analyze_link(url, absolute = nil)  # :nodoc:
    dir_long , sheet = url.split(/\#/)
    link_type = absolute ? (0x01 | absolute) : 0x0103

    if sheet
      link_type |= 0x08
      sheet_len  = [sheet.bytesize + 0x01].pack("V")
      sheet      = sheet.split('').join("\0") + "\0\0\0"
    else
      sheet_len   = ''
      sheet       = ''
    end

    [dir_long, link_type, sheet_len, sheet]
  end

  def date_1904?     # :nodoc:
    @workbook.date_1904
  end

  #        row    : Row Number
  #        colMic : First defined column
  #        colMac : Last defined column
  #
  # Write a default row record, in compatibility mode, for rows that don't have
  # user specified values..
  #
  def write_row_default(row, colMic, colMac)       #:nodoc:

    record      = 0x0208               # Record identifier
    length      = 0x0010               # Number of bytes to follow

    miyRw       = 0xFF                 # Row height
    irwMac      = 0x0000               # Used by Excel to optimise loading
    reserved    = 0x0000               # Reserved
    grbit       = 0x0100               # Option flags
    ixfe        = 0x0F                 # XF index

    store_simple(record, length,
                 row, colMic, colMac, miyRw, irwMac, reserved, grbit, ixfe)
  end

  #
  # Check that $row and $col are valid and store max and min values for use in
  # DIMENSIONS record. See, store_dimensions().
  #
  # The $ignore_row/$ignore_col flags is used to indicate that we wish to
  # perform the dimension check without storing the value.
  #
  # The ignore flags are use by set_row() and data_validate.
  #
  def check_dimensions(row, col, ignore_row = 0, ignore_col = 0)       #:nodoc:
    return -2 unless row
    return -2 if row >= RowMax

    return -2 unless col
    return -2 if col >= ColMax

    @dimension.row(row) if ignore_row == 0
    @dimension.col(col) if ignore_col == 0

    0
  end

  #
  # Writes Excel DIMENSIONS to define the area in which there is cell data.
  #
  # Notes:
  #   Excel stores the max row/col as row/col +1.
  #   Max and min values of 0 are used to indicate that no cell data.
  #   We set the undef member data to 0 since it is used by store_table().
  #   Inserting images or charts doesn't change the DIMENSION data.
  #
  def store_dimensions   #:nodoc:
    record    = 0x0200         # Record identifier
    length    = 0x000E         # Number of bytes to follow
    reserved  = 0x0000         # Reserved by Excel

    @dimension.increment_row_max
    @dimension.increment_col_max

    header = [record, length].pack("vv")
    fields = [@dimension.row_min, @dimension.row_max, @dimension.col_min, @dimension.col_max, reserved]
    data   = fields.pack("VVvvv")

    prepend(header, data)
  end

  #
  # Write BIFF record Window2.
  #
  def store_window2   #:nodoc:
    record         = 0x023E     # Record identifier
    length         = 0x0012     # Number of bytes to follow

    grbit          = 0x00B6     # Option flags
    rwTop          = @first_row   # Top visible row
    colLeft        = @first_col   # Leftmost visible column
    rgbHdr         = 0x00000040            # Row/col heading, grid color

    wScaleSLV      = 0x0000                # Zoom in page break preview
    wScaleNormal   = 0x0000                # Zoom in normal view
    reserved       = 0x00000000


    # The options flags that comprise $grbit
    fDspFmla       = @display_formulas # 0 - bit
    fDspGrid       = @screen_gridlines # 1
    fDspRwCol      = @display_headers  # 2
    fFrozen        = frozen? ? 1 : 0   # 3
    fDspZeros      = display_zeros? ? 1 : 0   # 4
    fDefaultHdr    = 1                 # 5
    fArabic        = @display_arabic || 0  # 6
    fDspGuts       = @outline.visible? ? 1 : 0       # 7
    fFrozenNoSplit = @frozen_no_split  # 0 - bit
    fSelected      = selected? ? 1 : 0 # 1
    fPaged         = active? ?   1 : 0 # 2
    fBreakPreview  = 0                # 3

    grbit             = fDspFmla
    grbit            |= fDspGrid       << 1
    grbit            |= fDspRwCol      << 2
    grbit            |= fFrozen        << 3
    grbit            |= fDspZeros      << 4
    grbit            |= fDefaultHdr    << 5
    grbit            |= fArabic        << 6
    grbit            |= fDspGuts       << 7
    grbit            |= fFrozenNoSplit << 8
    grbit            |= fSelected      << 9
    grbit            |= fPaged         << 10
    grbit            |= fBreakPreview  << 11

    header = [record, length].pack("vv")
    data    =[grbit, rwTop, colLeft, rgbHdr, wScaleSLV, wScaleNormal, reserved].pack("vvvVvvV")

    append(header, data)
  end

  #
  # Set page view mode. Only applicable to Mac Excel.
  #
  def store_page_view   #:nodoc:
    return if @page_view == 0
    data    = ['C8081100C808000000000040000000000900000000'].pack("H*")
    append(data)
  end

  #
  # Write the Tab Color BIFF record.
  #
  def store_tab_color   #:nodoc:
    color   = @tab_color

    return if color == 0

    record  = 0x0862      # Record identifier
    length  = 0x0014      # Number of bytes to follow

    zero    = 0x0000
    unknown = 0x0014

    store_simple(record, length, record, zero, zero, zero, zero,
                 zero, unknown, zero, color, zero)
  end

  #
  # Write BIFF record DEFROWHEIGHT.
  #
  def store_defrow   #:nodoc:
    record   = 0x0225      # Record identifier
    length   = 0x0004      # Number of bytes to follow

    grbit    = 0x0000      # Options.
    height   = 0x00FF      # Default row height

    header = [record, length].pack("vv")
    data   = [grbit,  height].pack("vv")

    prepend(header, data)
  end

  #
  # Write BIFF record DEFCOLWIDTH.
  #
  def store_defcol   #:nodoc:
    record   = 0x0055      # Record identifier
    length   = 0x0002      # Number of bytes to follow
    colwidth = 0x0008      # Default column width

    header   = [record, length].pack("vv")
    data     = [colwidth].pack("v")

    prepend(header, data)
  end

  def store_colinfo(colinfo)   # :nodoc:
    prepend(*colinfo.biff_record)
  end

  #
  # Write BIFF record FILTERMODE to indicate that the worksheet contains
  # AUTOFILTER record, ie. autofilters with a filter set.
  #
  def store_filtermode   #:nodoc:
    # Only write the record if the worksheet contains a filtered autofilter.
    return '' if @filter_on == 0

    record      = 0x009B      # Record identifier
    length      = 0x0000      # Number of bytes to follow

    header = [record, length].pack('vv')

    prepend(header)
  end

  #
  # Write BIFF record AUTOFILTERINFO.
  #
  def store_autofilterinfo   #:nodoc:
    # Only write the record if the worksheet contains an autofilter.
    return '' if @filter_area.count == 0

    record      = 0x009D      # Record identifier
    length      = 0x0002      # Number of bytes to follow
    num_filters = @filter_area.count

    header = [record, length].pack('vv')
    data   = [num_filters].pack('v')

    prepend(header, data)
  end

  #
  # Write BIFF record SELECTION.
  #
  def store_selection(first_row=0, first_col=0, last_row = nil, last_col =nil)   #:nodoc:
    record   = 0x001D                  # Record identifier
    length   = 0x000F                  # Number of bytes to follow

    pane_position = @active_pane       # Pane position
    row_active    = first_row          # Active row
    col_active    = first_col          # Active column
    irefAct  = 0                       # Active cell ref
    cref     = 1                       # Number of refs

    row_first = first_row              # First row in reference
    col_first = first_col              # First col in reference
    row_last  = last_row || row_first  # Last  row in reference
    col_last  = last_col || col_first  # Last  col in reference

    # Swap last row/col for first row/col as necessary
    row_first, row_last = row_last, row_first if row_first > row_last
    col_first, col_last = col_last, col_first if col_first > col_last

    header = [record, length].pack('vv')
    data = [pane_position, row_active, col_active, irefAct, cref,
      row_first, row_last, col_first, col_last].pack('CvvvvvvCC')

    append(header, data)
  end

  #
  # Write BIFF record EXTERNCOUNT to indicate the number of external sheet
  # references in a worksheet.
  #
  # Excel only stores references to external sheets that are used in formulas.
  # For simplicity we store references to all the sheets in the workbook
  # regardless of whether they are used or not. This reduces the overall
  # complexity and eliminates the need for a two way dialogue between the formula
  # parser the worksheet objects.
  #
  def store_externcount(count)   #:nodoc:
    record   = 0x0016          # Record identifier
    length   = 0x0002          # Number of bytes to follow

    cxals    = count           # Number of external references

    header = [record, length].pack('vv')
    data   = [cxals].pack('v')

    prepend(header, data)
  end

  # sheetname  : Worksheet name
  #
  # Writes the Excel BIFF EXTERNSHEET record. These references are used by
  # formulas. A formula references a sheet name via an index. Since we store a
  # reference to all of the external worksheets the EXTERNSHEET index is the same
  # as the worksheet index.
  #
  def store_externsheet(sheetname)   #:nodoc:
    record    = 0x0017         # Record identifier
    # length;                     # Number of bytes to follow

    # cch                        # Length of sheet name
    # rgch                       # Filename encoding

    # References to the current sheet are encoded differently to references to
    # external sheets.
    #
    if @name == sheetname
      sheetname = ''
      length    = 0x02  # The following 2 bytes
      cch       = 1     # The following byte
      rgch      = 0x02  # Self reference
    else
      length    = 0x02 + sheetname.bytesize
      cch       = sheetname.bytesize
      rgch      = 0x03  # Reference to a sheet in the current workbook
    end

    header = [record, length].pack('vv')
    data   = [cch, rgch].pack('CC')

    prepend(header, data, sheetname)
  end

  #    y           = args[0] || 0   # Vertical split position
  #    x           = $_[1] || 0;   # Horizontal split position
  #    rwTop       = $_[2];        # Top row visible
  #    my $colLeft     = $_[3];        # Leftmost column visible
  #    my $no_split    = $_[4];        # No used here.
  #    my $pnnAct      = $_[5];        # Active pane
  #
  #
  # Writes the Excel BIFF PANE record.
  # The panes can either be frozen or thawed (unfrozen).
  # Frozen panes are specified in terms of a integer number of rows and columns.
  # Thawed panes are specified in terms of Excel's units for rows and columns.
  #
  def store_panes(y=0, x=0, rwtop=nil,  colleft=nil, no_split=nil, pnnAct=nil)   #:nodoc:
    record      = 0x0041       # Record identifier
    length      = 0x000A       # Number of bytes to follow

    # Code specific to frozen or thawed panes.
    if frozen?
      # Set default values for $rwTop and $colLeft
      rwtop   = y unless rwtop
      colleft = x unless colleft
    else
      # Set default values for $rwTop and $colLeft
      rwtop   = 0  unless rwtop
      colleft = 0  unless colleft

      # Convert Excel's row and column units to the internal units.
      # The default row height is 12.75
      # The default column width is 8.43
      # The following slope and intersection values were interpolated.
      #
      y = 20*y      + 255
      x = 113.879*x + 390
    end


    # Determine which pane should be active. There is also the undocumented
    # option to override this should it be necessary: may be removed later.
    #
    unless pnnAct
      pnnAct = 0 if (x != 0 && y != 0) # Bottom right
      pnnAct = 1 if (x != 0 && y == 0) # Top right
      pnnAct = 2 if (x == 0 && y != 0) # Bottom left
      pnnAct = 3 if (x == 0 && y == 0) # Top left
    end

    @active_pane = pnnAct # Used in store_selection

    store_simple(record, length, x, y, rwtop, colleft, pnnAct)
  end

  #
  # Store the page setup SETUP BIFF record.
  #
  def store_setup   #:nodoc:
    record       = 0x00A1                  # Record identifier
    length       = 0x0022                  # Number of bytes to follow

    iPaperSize   = @paper_size    # Paper size
    iScale       = @print_scale   # Print scaling factor
    iPageStart   = @page_start    # Starting page number
    iFitWidth    = @fit_width     # Fit to number of pages wide
    iFitHeight   = @fit_height    # Fit to number of pages high
    grbit        = 0x00           # Option flags
    iRes         = 0x0258         # Print resolution
    iVRes        = 0x0258         # Vertical print resolution
    numHdr       = @margin_header # Header Margin
    numFtr       = @margin_footer # Footer Margin
    iCopies      = 0x01           # Number of copies

    fLeftToRight = @page_order    # Print over then down
    fLandscape   = @orientation   # Page orientation
    fNoPls       = 0x0                     # Setup not read from printer
    fNoColor     = @black_white   # Print black and white
    fDraft       = @draft_quality # Print draft quality
    fNotes       = @print_comments# Print notes
    fNoOrient    = 0x0            # Orientation not set
    fUsePage     = @custom_start  # Use custom starting page

    grbit           = fLeftToRight
    grbit          |= fLandscape    << 1
    grbit          |= fNoPls        << 2
    grbit          |= fNoColor      << 3
    grbit          |= fDraft        << 4
    grbit          |= fNotes        << 5
    grbit          |= fNoOrient     << 6
    grbit          |= fUsePage      << 7


    numHdr = [numHdr].pack('d')
    numFtr = [numFtr].pack('d')

    if @byte_order
      numHdr.reverse!
      numFtr.reverse!
    end

    header = [record, length].pack('vv')
    data1  = [iPaperSize, iScale, iPageStart,
              iFitWidth, iFitHeight, grbit, iRes, iVRes].pack("vvvvvvvv")

    data2  = numHdr + numFtr
    data3  = [iCopies].pack('v')

    prepend(header, data1, data2, data3)

  end

  #
  # Store the header caption BIFF record.
  #
  def store_header   #:nodoc:
    store_header_footer_common(:header)
  end

  #
  # Store the footer caption BIFF record.
  #
  def store_footer   #:nodoc:
    store_header_footer_common(:footer)
  end

  #
  # type :  :header / :footer
  #
  def store_header_footer_common(type)  # :nodoc:
    if type == :header
      record   = 0x0014
      str      = @header || ''
      encoding = @header_encoding || 0
    else
      record   = 0x0015
      str      = @footer || ''
      encoding = @footer_encoding || 0
    end
    cch         = str.bytesize        # Length of header/footer string

    # Character length is num of chars not num of bytes
    cch         /= 2 if encoding != 0

    # Change the UTF-16 name from BE to LE
    str         = str.unpack('v*').pack('n*') if encoding != 0

    length      = 3 + str.bytesize

    header      = [record, length].pack('vv')
    data        = [cch, encoding].pack('vC')

    prepend(header, data, str)
  end

  #
  # Store the horizontal centering HCENTER BIFF record.
  #
  def store_hcenter   #:nodoc:
    store_biff_common(:hcenter)
  end

  #
  # Store the vertical centering VCENTER BIFF record.
  #
  def store_vcenter   #:nodoc:
    store_biff_common(:vcenter)
  end

  #
  # Store the LEFTMARGIN BIFF record.
  #
  def store_margin_left   #:nodoc:
    store_margin_common(0x0026, 0x0008, @margin_left)
  end

  #
  # Store the RIGHTMARGIN BIFF record.
  #
  def store_margin_right   #:nodoc:
    store_margin_common(0x0027, 0x0008, @margin_right)
  end

  #
  # Store the TOPMARGIN BIFF record.
  #
  def store_margin_top   #:nodoc:
    store_margin_common(0x0028, 0x0008, @margin_top)
  end

  #
  # Store the BOTTOMMARGIN BIFF record.
  #
  def store_margin_bottom   #:nodoc:
    store_margin_common(0x0029, 0x0008, @margin_bottom)
  end

  #
  # record     : Record identifier
  # length     : bytes to follow
  # margin     : Margin in inches
  #
  def store_margin_common(record, length, margin)  # :nodoc:
    header  = [record, length].pack('vv')
    data    = [margin].pack('d')

    data.reverse! if @byte_order

    prepend(header, data)
  end

  #
  # :call-seq:
  # merge_cells(first_row, first_col, last_row, last_col)
  #
  # This is an Excel97/2000 method. It is required to perform more complicated
  # merging than the normal align merge in Format.pm
  #
  def merge_cells(*args) #:nodoc:
    # Check for a cell reference in A1 notation and substitute row and column
    args = row_col_notation(args)

    record  = 0x00E5                    # Record identifier
    length  = 0x000A                    # Bytes to follow

    cref     = 1                        # Number of refs
    rwFirst  = args[0]                  # First row in reference
    colFirst = args[1]                  # First col in reference
    rwLast   = args[2] || rwFirst       # Last  row in reference
    colLast  = args[3] || colFirst      # Last  col in reference

    # Excel doesn't allow a single cell to be merged
    return if rwFirst == rwLast and colFirst == colLast

    # Swap last row/col with first row/col as necessary
    rwFirst,  rwLast  = rwLast,  rwFirst  if rwFirst  > rwLast
    colFirst, colLast = colLast, colFirst if colFirst > colLast

    store_simple(record, length, cref, rwFirst, rwLast, colFirst, colLast)
  end

  #
  # Write the PRINTHEADERS BIFF record.
  #
  def store_print_headers   #:nodoc:
    store_biff_common(:print_headers)
  end

  #
  # Write the PRINTGRIDLINES BIFF record. Must be used in conjunction with the
  # GRIDSET record.
  #
  def store_print_gridlines   #:nodoc:
    store_biff_common(:print_gridlines)
  end

  def store_biff_common(type)  # :nodoc:
    case type
    when :hcenter
      record = 0x0083
      flag   = @hcenter || 0
    when :vcenter
      record = 0x0084
      flag   = @vcenter || 0
    when :print_headers
      record = 0x002a
      flag   = @print_headers || 0
    when :print_gridlines
      record = 0x002b
      flag   = @print_gridlines
    end
    length   = 0x0002

    header      = [record, length].pack("vv")
    data        = [flag].pack("v")

    prepend(header, data)
  end

  #
  # Write the GRIDSET BIFF record. Must be used in conjunction with the
  # PRINTGRIDLINES record.
  #
  def store_gridset   #:nodoc:
    record      = 0x0082                        # Record identifier
    length      = 0x0002                        # Bytes to follow

    fGridSet    = @print_gridlines == 0 ? 1 : 0 # Boolean flag

    header      = [record, length].pack("vv")
    data        = [fGridSet].pack("v")

    prepend(header, data)
  end

  #
  # Write the GUTS BIFF record. This is used to configure the gutter margins
  # where Excel outline symbols are displayed. The visibility of the gutters is
  # controlled by a flag in WSBOOL. See also store_wsbool().
  #
  # We are all in the gutter but some of us are looking at the stars.
  #
  def store_guts   #:nodoc:
    record      = 0x0080   # Record identifier
    length      = 0x0008   # Bytes to follow

    dxRwGut     = 0x0000   # Size of row gutter
    dxColGut    = 0x0000   # Size of col gutter

    row_level   = @outline.row_level

    # Calculate the maximum column outline level. The equivalent calculation
    # for the row outline level is carried out in set_row().
    #
    col_level = @colinfo.collect {|colinfo| colinfo.level}.max || 0

    # Set the limits for the outline levels (0 <= x <= 7).
    col_level = 0 if col_level < 0
    col_level = 7 if col_level > 7

    # The displayed level is one greater than the max outline levels
    row_level += 1 if row_level > 0
    col_level += 1 if col_level > 0

    header = [record, length].pack("vv")
    data   = [dxRwGut, dxColGut, row_level, col_level].pack("vvvv")

    prepend(header, data)
  end

  #
  # Write the WSBOOL BIFF record, mainly for fit-to-page. Used in conjunction
  # with the SETUP record.
  #
  def store_wsbool   #:nodoc:
    record      = 0x0081   # Record identifier
    length      = 0x0002   # Bytes to follow

    grbit       = 0x0000   # Option flags

    # Set the option flags
    grbit |= 0x0001                        # Auto page breaks visible
    grbit |= 0x0020 if @outline.style != 0 # Auto outline styles
    grbit |= 0x0040 if @outline.below != 0 # Outline summary below
    grbit |= 0x0080 if @outline.right != 0 # Outline summary right
    grbit |= 0x0100 if @fit_page      != 0 # Page setup fit to page
    grbit |= 0x0400 if @outline.visible?   # Outline symbols displayed

    header = [record, length].pack("vv")
    data   = [grbit].pack('v')

    prepend(header, data)
  end

  #
  # Write the HORIZONTALPAGEBREAKS BIFF record.
  #
  def store_hbreak   #:nodoc:
    store_breaks_common(@hbreaks)
  end

  #
  # Write the VERTICALPAGEBREAKS BIFF record.
  #
  def store_vbreak   #:nodoc:
    store_breaks_common(@vbreaks)
  end

  def store_breaks_common(breaks)  # :nodoc:
    unless breaks.empty?
      record  = breaks == @vbreaks ? 0x001a : 0x001b # Record identifier
      cbrk    = breaks.size   # Number of page breaks
      length  = 2 + 6 * cbrk         # Bytes to follow

      header = [record, length].pack("vv")
      data   = [cbrk].pack("v")

      # Append each sorted page break
      sort_pagebreaks(breaks).each do |brk|
        data += [brk, 0x0000, 0x00ff].pack("vvv")
      end

      prepend(header, data)
    end
  end

  #
  # Set the Biff PROTECT record to indicate that the worksheet is protected.
  #
  def store_protect   #:nodoc:
    store_protect_common
  end

  def protect?
    @protect
  end

  #
  # Set the Biff OBJPROTECT record to indicate that objects are protected.
  #
  def store_obj_protect   #:nodoc:
    store_protect_common(:obj)
  end

  def store_protect_common(type = nil)  # :nodoc:
    if protect?
      record = if type == :obj      # Record identifier
        0x0063                      # store_obj_protect
      else
        0x0012                      # store_protect
      end
      length = 0x0002               # Bytes to follow

      fLock  = protect? ? 1 : 0     # Worksheet is protected

      header = [record, length].pack("vv")
      data   = [fLock].pack("v")

      prepend(header, data)
    end
  end


  #
  # Write the worksheet PASSWORD record.
  #
  def store_password   #:nodoc:
    # Exit unless sheet protection and password have been specified
    return  unless protect? && @password

    record      = 0x0013               # Record identifier
    length      = 0x0002               # Bytes to follow

    wPassword   = @password            # Encoded password

    header      = [record, length].pack("vv")
    data        = [wPassword].pack("v")

    prepend(header, data)
  end

  #
  # Note about compatibility mode.
  #
  # Excel doesn't require every possible Biff record to be present in a file.
  # In particular if the indexing records INDEX, ROW and DBCELL aren't present
  # it just ignores the fact and reads the cells anyway. This is also true of
  # the EXTSST record. Gnumeric and OOo also take this approach. This allows
  # WriteExcel to ignore these records in order to minimise the amount of data
  # stored in memory. However, other third party applications that read Excel
  # files often expect these records to be present. In "compatibility mode"
  # WriteExcel writes these records and tries to be as close to an Excel
  # generated file as possible.
  #
  # This requires additional data to be stored in memory until the file is
  # about to be written. This incurs a memory and speed penalty and may not be
  # suitable for very large files.
  #



  #
  # Write cell data stored in the worksheet row/col table.
  #
  # This is only used when compatibity_mode() is in operation.
  #
  # This method writes ROW data, then cell data (NUMBER, LABELSST, etc) and then
  # DBCELL records in blocks of 32 rows. This is explained in detail (for a
  # change) in the Excel SDK and in the OOo Excel file format doc.
  #
  def store_table   #:nodoc:
    return unless compatibility?

    # Offset from the DBCELL record back to the first ROW of the 32 row block.
    row_offset = 0

    # Track rows that have cell data or modified by set_row().
    written_rows = []


    # Write the ROW records with updated max/min col fields.
    #
    (0 .. @dimension.row_max-1).each do |row|
      # Skip unless there is cell data in row or the row has been modified.
      next unless @table[row] or @row_data[row]

      # Store the rows with data.
      written_rows.push(row)

      # Increase the row offset by the length of a ROW record;
      row_offset += 20

      # The max/min cols in the ROW records are the same as in DIMENSIONS.
      col_min = @dimension.col_min
      col_max = @dimension.col_max

      # Write a user specified ROW record (modified by set_row()).
      if @row_data[row]
        # Rewrite the min and max cols for user defined row record.
        packed_row = @row_data[row]
        packed_row[6..9] = [col_min, col_max].pack('vv')
        append(packed_row)
      else
        # Write a default Row record if there isn't a  user defined ROW.
        write_row_default(row, col_min, col_max)
      end

      # If 32 rows have been written or we are at the last row in the
      # worksheet then write the cell data and the DBCELL record.
      #
      if written_rows.size == 32 || row == @dimension.row_max - 1
        # Offsets to the first cell of each row.
        cell_offsets = []
        cell_offsets.push(row_offset - 20)

        # Write the cell data in each row and sum their lengths for the
        # cell offsets.
        #
        written_rows.each do |rw|
          cell_offset = 0

          if @table[rw]
            @table[rw].each do |clm|
              next unless clm
              append(clm)
              length = clm.bytesize
              row_offset  += length
              cell_offset += length
            end
          end
          cell_offsets.push(cell_offset)
        end

        # The last offset isn't required.
        cell_offsets.pop

        # Stores the DBCELL offset for use in the INDEX record.
        @db_indices.push(@datasize)

        # Write the DBCELL record.
        store_dbcell(row_offset, cell_offsets)

        # Clear the variable for the next block of rows.
        written_rows   = []
        cell_offsets   = []
        row_offset     = 0
      end
    end
  end

  #
  # Store the DBCELL record using the offset calculated in store_table().
  #
  # This is only used when compatibity_mode() is in operation.
  #
  def store_dbcell(row_offset, cell_offsets)   #:nodoc:
    record          = 0x00D7                     # Record identifier
    length          = 4 + 2 * cell_offsets.size  # Bytes to follow

    header          = [record, length].pack('vv')
    data            = [row_offset].pack('V')
    cell_offsets.each do |co|
      data += [co].pack('v')
    end

    append(header, data)
  end

  #
  # Store the INDEX record using the DBCELL offsets calculated in store_table().
  #
  # This is only used when compatibity_mode() is in operation.
  #
  def store_index   #:nodoc:
    return unless compatibility?

    indices     = @db_indices
    reserved    = 0x00000000
    row_min     = @dimension.row_min
    row_max     = @dimension.row_max

    record      = 0x020B                 # Record identifier
    length      = 16 + 4 * indices.size  # Bytes to follow

    header      = [record, length].pack('vv')
    data        = [reserved, row_min, row_max, reserved].pack('VVVV')

    indices.each do |index|
      data += [index + @offset + 20 + length + 4].pack('V')
    end

    prepend(header, data)
  end

  def adjust_col_position(x, col)  # :nodoc:
    while x >= size_col(col)
      x -= size_col(col)
      col += 1
    end
    [x, col]
  end

  def adjust_row_position(y, row)  # :nodoc:
    while y >= size_row(row)
      y -= size_row(row)
      row += 1
    end
    [y, row]
  end

  #
  # Convert the width of a cell from user's units to pixels. Excel rounds the
  # column width to the nearest pixel. If the width hasn't been set by the user
  # we use the default value. If the column is hidden we use a value of zero.
  #
  def size_col(col)   #:nodoc:
    # Look up the cell value to see if it has been changed
    if @col_sizes[col]
      width = @col_sizes[col]

      # The relationship is different for user units less than 1.
      if width < 1
        (width *12).to_i
      else
        (width *7 +5 ).to_i
      end
    else
      64
    end
  end

  #
  # Convert the height of a cell from user's units to pixels. By interpolation
  # the relationship is: y = 4/3x. If the height hasn't been set by the user we
  # use the default value. If the row is hidden we use a value of zero. (Not
  # possible to hide row yet).
  #
  def size_row(row)   #:nodoc:
    # Look up the cell value to see if it has been changed
    if @row_sizes[row]
      if @row_sizes[row] == 0
        0
      else
        (4/3.0 * @row_sizes[row]).to_i
      end
    else
      17
    end
  end

  #
  # Store the window zoom factor. This should be a reduced fraction but for
  # simplicity we will store all fractions with a numerator of 100.
  #
  def store_zoom   #:nodoc:
    # If scale is 100 we don't need to write a record
    return if @zoom == 100

    record      = 0x00A0               # Record identifier
    length      = 0x0004               # Bytes to follow

    store_simple(record, length, @zoom, 100)
  end

  # Older method name for backwards compatibility.
  #   *write_unicode    = *write_utf16be_string;
  #   *write_unicode_le = *write_utf16le_string;

  #
  # Function to iterate through the columns that form part of an autofilter
  # range and write Biff AUTOFILTER records if a filter expression has been set.
  #
  def store_autofilters   #:nodoc:
    # Skip all columns if no filter have been set.
    return '' if @filter_on == 0

    col1 = @filter_area.col_min
    col2 = @filter_area.col_max

    col1.upto(col2) do |i|
      # Reverse order since records are being pre-pended.
      col = col2 -i

      # Skip if column doesn't have an active filter.
      next unless @filter_cols[col]

      # Retrieve the filter tokens and write the autofilter records.
      store_autofilter(col, *@filter_cols[col])
    end
  end

  #
  # Function to write worksheet AUTOFILTER records. These contain 2 Biff Doper
  # structures to represent the 2 possible filter conditions.
  #
  def store_autofilter(index, operator_1, token_1,   #:nodoc:
                                 join = nil, operator_2 = nil, token_2 = nil)
    record          = 0x009E
    length          = 0x0000

    top10_active    = 0
    top10_direction = 0
    top10_percent   = 0
    top10_value     = 101

    grbit       = join || 0
    optimised_1 = 0
    optimised_2 = 0
    doper_1     = ''
    doper_2     = ''
    string_1    = ''
    string_2    = ''

    # Excel used an optimisation in the case of a simple equality.
    optimised_1 = 1 if               operator_1 == 2
    optimised_2 = 1 if operator_2 && operator_2 == 2

    # Convert non-simple equalities back to type 2. See  parse_filter_tokens().
    operator_1 = 2 if               operator_1 == 22
    operator_2 = 2 if operator_2 && operator_2 == 22

    # Handle a "Top" style expression.
    if operator_1 >= 30
      # Remove the second expression if present.
      operator_2 = nil
      token_2    = nil

      # Set the active flag.
      top10_active    = 1

      if (operator_1 == 30 or operator_1 == 31)
        top10_direction = 1
      end

      if (operator_1 == 31 or operator_1 == 33)
        top10_percent = 1
      end

      if (top10_direction == 1)
        operator_1 = 6
      else
        operator_1 = 3
      end

      top10_value     = token_1.to_i
      token_1         = 0
    end

    grbit     |= optimised_1      << 2
    grbit     |= optimised_2      << 3
    grbit     |= top10_active     << 4
    grbit     |= top10_direction  << 5
    grbit     |= top10_percent    << 6
    grbit     |= top10_value      << 7

    doper_1, string_1 = pack_doper(operator_1, token_1)
    doper_2, string_2 = pack_doper(operator_2, token_2)

    doper_1  = '' unless doper_1
    doper_2  = '' unless doper_2
    string_1 = '' unless string_1
    string_2 = '' unless string_2

    data = [index].pack('v')
    data += [grbit].pack('v')
    data += doper_1 + doper_2 + string_1 + string_2

    length  = data.bytesize
    header  = [record, length].pack('vv')

    prepend(header, data)
  end

  #
  # Create a Biff Doper structure that represents a filter expression. Depending
  # on the type of the token we pack an Empty, String or Number doper.
  #
  def pack_doper(operator, token)   #:nodoc:
    doper       = ''
    string      = ''

    # Return default doper for non-defined filters.
    unless operator
      return pack_unused_doper, string
    end

    if token.to_s =~ /^blanks|nonblanks$/i
      doper  = pack_blanks_doper(operator, token)
    elsif operator == 2 or
      !(token.to_s  =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
      # Excel treats all tokens as strings if the operator is equality, =.
      string = token.to_s
      ruby_19 { string = convert_to_ascii_if_ascii(string) }

      encoding = 0
      length   = string.bytesize

      # Handle utf8 strings
      if is_utf8?(string)
        string = utf8_to_16be(string)
        encodign = 1
      end

      string =
        ruby_18 { [encoding].pack('C') +  string } ||
        ruby_19 { [encoding].pack('C') +  string.force_encoding('BINARY') }
      doper  = pack_string_doper(operator, length)
    else
      string = ''
      doper  = pack_number_doper(operator, token)
    end

    [doper, string]
  end

  #
  # Pack an empty Doper structure.
  #
  def pack_unused_doper   #:nodoc:
    [0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0].pack('C10')
  end

  #
  # Pack an Blanks/NonBlanks Doper structure.
  #
  def pack_blanks_doper(operator, token)   #:nodoc:
    if token == 'blanks'
      type     = 0x0C
      operator = 2
    else
      type     = 0x0E
      operator = 5
    end

    [type,       # Data type
      operator,
      0x0000, 0x0000     # Reserved
    ].pack('CCVV')
  end

  #
  # Pack an string Doper structure.
  #
  def pack_string_doper(operator, length)   #:nodoc:
    [0x06,     # Data type
      operator,
      0x0000,         #Reserved
      length,         # String char length
      0x0, 0x0, 0x0   # Reserved
    ].pack('CCVCCCC')
  end

  #
  # Pack an IEEE double number Doper structure.
  #
  def pack_number_doper(operator, number)   #:nodoc:
    number = [number].pack('d')
    number.reverse! if @byte_order

    [0x04, operator].pack('CC') + number
  end

  #
  # Store the collections of records that make up images.
  #
  def store_images   #:nodoc:
    # Skip this if there aren't any images.
    return if @images.array.empty?

    spid = @object_ids.spid

    @images.array.each_index do |i|
      @images.array[i].store_image_record(i, @images.array.size, charts_size, @filter_area.count, comments_size, spid)
      store_obj_image(i + 1)
    end

    @object_ids.spid = spid
  end

  def store_child_mso_record(spid, *vertices)  # :nodoc:
    store_mso_sp_container(88)             +
    store_mso_sp(201, spid, 0x0A00)        +
    store_mso_opt_filter                   +
    store_mso_client_anchor(1, *vertices)  +
    store_mso_client_data
  end

  #
  # Store the collections of records that make up charts.
  #
  def store_charts   #:nodoc:
    # Skip this if there aren't any charts.
    return if charts_size == 0

    record = 0x00EC           # Record identifier

    charts = @charts.array

    charts.each_index do |i|
      data = ''
      if i == 0 && images_size == 0
        dg_length    = 192 + 120 * (charts_size - 1) + 96 * filter_count + 128 * comments_size
        spgr_length  = dg_length - 24

        # Write the parent MSODRAWIING record.
        data += store_parent_mso_record(dg_length, spgr_length, @object_ids.spid)
        @object_ids.spid += 1
      end
      data += store_mso_sp_container_sp(@object_ids.spid)
      data += store_mso_opt_chart_client_anchor_client_data(*charts[i].vertices)
      length = data.bytesize
      header = [record, length].pack("vv")
      append(header, data)

      store_obj_chart(images_size + i + 1)
      store_chart_binary(charts[i].chart)
      @object_ids.spid += 1
    end

    # Simulate the EXTERNSHEET link between the chart and data using a formula
    # such as '=Sheet1!A1'.
    # TODO. Won't work for external data refs. Also should use a more direct
    #       method.
    #
    store_formula("='#{@name}'!A1")
  end

  def store_mso_sp_container_sp(spid)  # :nodoc:
    store_mso_sp_container(112) + store_mso_sp(201, spid, 0x0A00)
  end

  def store_mso_opt_chart_client_anchor_client_data(*vertices)  # :nodoc:
    store_mso_opt_chart                   +
    store_mso_client_anchor(0, *vertices) +
    store_mso_client_data
  end

  #
  # Add the binary data for a chart. This could either be from a Chart object
  # or from an external binary file (for backwards compatibility).
  #
  def store_chart_binary(chart)   #:nodoc:
    if chart.respond_to?(:to_str)
      filehandle = File.open(chart, "rb")
      #      die "Couldn't open $filename in add_chart_ext(): $!.\n";
      while tmp = filehandle.read(4096)
        append(tmp)
      end
    else
      chart.close
      tmp = chart.get_data
      append(tmp)
    end
  end

  #
  # Store the collections of records that make up filters.
  #
  def store_filters   #:nodoc:
    # Skip this if there aren't any filters.
    return if @filter_area.count == 0

    @object_ids.spid = @filter_area.store

    # Simulate the EXTERNSHEET link between the filter and data using a formula
    # such as '=Sheet1!A1'.
    # TODO. Won't work for external data refs. Also should use a more direct
    #       method.
    #
    formula = "='#{@name}'!A1"
    store_formula(formula)
  end

  #
  # Store the collections of records that make up cell comments.
  #
  # NOTE: We write the comment objects last since that makes it a little easier
  # to write the NOTE records directly after the MSODRAWIING records.
  #
  def store_comments   #:nodoc:
    return if @comments.array.empty?

    spid = @object_ids.spid
    num_comments    = comments_size

    # Number of objects written so far.
    num_objects     = images_size + @filter_area.count + charts_size

    @comments.array.each_index { |i| spid = @comments.array[i].store_comment_record(i, num_objects, num_comments, spid) }

    # Write the NOTE records after MSODRAWIING records.
    @comments.array.each_index { |i| @comments.array[i].store_note_record(num_objects + i + 1) }
  end

  #
  # Write the Escher DgContainer record that is part of MSODRAWING.
  #
  def store_mso_dg_container(length)   #:nodoc:
    type        = 0xF002
    version     = 15
    instance    = 0
    data        = ''
    add_mso_generic(type, version, instance, data, length)
  end

  #
  # Write the Escher Dg record that is part of MSODRAWING.
  #
  def store_mso_dg   #:nodoc:
    type        = 0xF008
    version     = 0
    length      = 8
    data        = [@object_ids.num_shapes, @object_ids.max_spid].pack("VV")

    add_mso_generic(type, version, @object_ids.drawings_saved, data, length)
  end

  #
  # Write the Escher SpgrContainer record that is part of MSODRAWING.
  #
  def store_mso_spgr_container(length)   #:nodoc:
    type        = 0xF003
    version     = 15
    instance    = 0
    data        = ''

    add_mso_generic(type, version, instance, data, length)
  end

  #
  # Write the Escher Spgr record that is part of MSODRAWING.
  #
  def store_mso_spgr   #:nodoc:
    type        = 0xF009
    version     = 1
    instance    = 0
    data        = [0, 0, 0, 0].pack("VVVV")
    length      = 16

    add_mso_generic(type, version, instance, data, length)
  end

  #
  # Write the Escher Opt record that is part of MSODRAWING.
  #
  def store_mso_opt_chart   #:nodoc:
    type        = 0xF00B
    version     = 3
    instance    = 9
    data        = ''
    length      = nil

    data = store_mso_protection_and_text
    data += [0x0181].pack('v')   +        # Fill Style -> fillColor
    [0x0800004E].pack('V')       +
    [0x0183].pack('v')           +        # Fill Style -> fillBackColor
    [0x0800004D].pack('V')       +

    [0x01BF].pack('v')           +        # Fill Style -> fNoFillHitTest
    [0x00110010].pack('V')       +
    [0x01C0].pack('v')           +        # Line Style -> lineColor
    [0x0800004D].pack('V')       +
    [0x01FF].pack('v')           +        # Line Style -> fNoLineDrawDash
    [0x00080008].pack('V')       +
    [0x023F].pack('v')           +        # Shadow Style -> fshadowObscured
    [0x00020000].pack('V')       +
    [0x03BF].pack('v')           +        # Group Shape -> fPrint
    [0x00080000].pack('V')

    add_mso_generic(type, version, instance, data, length)
  end

  #
  # Write the Escher Opt record that is part of MSODRAWING.
  #
  def store_mso_opt_filter   #:nodoc:
    type        = 0xF00B
    version     = 3
    instance    = 5
    data        = ''
    length      = nil

    data = store_mso_protection_and_text
    data += [0x01BF].pack('v')   +        # Fill Style -> fNoFillHitTest
    [0x00010000].pack('V')       +
    [0x01FF].pack('v')           +        # Line Style -> fNoLineDrawDash
    [0x00080000].pack('V')       +
    [0x03BF].pack('v')           +        # Group Shape -> fPrint
    [0x000A0000].pack('V')

    add_mso_generic(type, version, instance, data, length)
  end

  def store_mso_protection_and_text  # :nodoc:
    [0x007F].pack('v')       +        # Protection -> fLockAgainstGrouping
    [0x01040104].pack('V')   +
    [0x00BF].pack('v')       +        # Text -> fFitTextToShape
    [0x00080008].pack('V')
  end

  #
  # Write the OBJ record that is part of image records.
  #    obj_id      # Object ID number.
  #
  def store_obj_image(obj_id)   #:nodoc:
    record      = 0x005D   # Record identifier
    length      = 0x0026   # Bytes to follow

    obj_type    = 0x0008   # Object type (Picture).
    data        = ''       # Record data.

    sub_record  = 0x0000   # Sub-record identifier.
    sub_length  = 0x0000   # Length of sub-record.
    sub_data    = ''       # Data of sub-record.
    options     = 0x6011
    reserved    = 0x0000

    # Add ftCmo (common object data) subobject
    sub_record  = 0x0015   # ftCmo
    sub_length  = 0x0012
    sub_data    = [obj_type, obj_id, options, reserved, reserved, reserved].pack('vvvVVV')
    data        = [sub_record, sub_length].pack('vv') + sub_data

    # Add ftCf (Clipboard format) subobject
    sub_record  = 0x0007   # ftCf
    sub_length  = 0x0002
    sub_data    = [0xFFFF].pack( 'v')
    data        += [sub_record, sub_length].pack('vv') + sub_data

    # Add ftPioGrbit (Picture option flags) subobject
    sub_record  = 0x0008   # ftPioGrbit
    sub_length  = 0x0002
    sub_data    = [0x0001].pack('v')
    data        += [sub_record, sub_length].pack('vv') + sub_data

    # Add ftEnd (end of object) subobject
    sub_record  = 0x0000   # ftNts
    sub_length  = 0x0000
    data        += [sub_record, sub_length].pack('vv')

    # Pack the record.
    header  = [record, length].pack('vv')

    append(header, data)

  end

  #
  # Write the OBJ record that is part of chart records.
  #    obj_id     # Object ID number.
  #
  def store_obj_chart(obj_id)   #:nodoc:
    obj_type    = 0x0005   # Object type (chart).

    options     = 0x6011
    reserved    = 0x0000

    # Add ftCmo (common object data) subobject
    sub_record  = 0x0015   # ftCmo
    sub_length  = 0x0012
    sub_data    = [obj_type, obj_id, options, reserved, reserved, reserved].pack('vvvVVV')
    data        = [sub_record, sub_length].pack('vv') + sub_data

    # Add ftEnd (end of object) subobject
    sub_record  = 0x0000   # ftNts
    sub_length  = 0x0000
    data        += [sub_record, sub_length].pack('vv')

    # Pack the record.
    record      = 0x005D   # Record identifier
    length      = 0x001A   # Bytes to follow
    header  = [record, length].pack('vv')

    append(header, data)

  end

  #
  # Store the count of the DV records to follow.
  #
  # Note, this could be wrapped into store_dv() but we may require separate
  # handling of the object id at a later stage.
  #
  def store_validation_count   #:nodoc:
    append(@validations.count_dv_record)
  end

  #
  # Store the data_validation records.
  #
  def store_validations   #:nodoc:
    return if @validations.size == 0

    @validations.each do |data_validation|
      append(data_validation.dv_record)
    end
  end

  def parser   # :nodoc:
    @workbook.parser
  end

  # Check for a cell reference in A1 notation and substitute row and column
  def row_col_notation(args)   # :nodoc:
    if args[0] =~ /^\D/
      substitute_cellref(*args)
    else
      args
    end
  end
end  # class Worksheet

end  # module Writeexcel
