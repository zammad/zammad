# -*- coding: utf-8 -*-
###############################################################################
#
# Chart - A writer class for Excel Charts.
#
#
# Used in conjunction with WriteExcel
#
# Copyright 2000-2010, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel/worksheet'
require 'writeexcel/colors'

###############################################################################
#
# Formatting information.
#
# perltidy with options: -mbl=2 -pt=0 -nola
#
# Any camel case Hungarian notation style variable names in the BIFF record
# writing sub-routines below are for similarity with names used in the Excel
# documentation. Otherwise lowercase underscore style names are used.
#


###############################################################################
#
# The chart class hierarchy is as follows. Chart.pm acts as a factory for the
# sub-classes.
#
#
#     BIFFwriter
#                     ^
#                     |
#     Writeexcel::Worksheet
#                     ^
#                     |
#     Writeexcel::Chart
#                     ^
#                     |
#     Writeexcel::Chart::* (sub-types)
#

#
# = Chart
# Chart - A writer class for Excel Charts.
#
module Writeexcel

class Chart < Worksheet
  require 'writeexcel/helper'

  #
  # Factory method for returning chart objects based on their class type.
  #
  def self.factory(type, *args)       #:nodoc:
    klass =
    case type
    when 'Chart::Column'
      Chart::Column
    when 'Chart::Bar'
      Chart::Bar
    when 'Chart::Line'
      Chart::Line
    when 'Chart::Area'
      Chart::Area
    when 'Chart::Pie'
      Chart::Pie
    when 'Chart::Scatter'
      Chart::Scatter
    when 'Chart::Stock'
      Chart::Stock
    end

    klass.new(*args)
  end

  #
  # :call-seq:
  #   new(filename, name, index, encoding, activesheet, firstsheet, external_bin = nil)
  #
  # Default constructor for sub-classes.
  #
  def initialize(*args)       #:nodoc:
    super

    @type        = 0x0200
    @orientation = 0x0
    @series      = []
    @embedded    = false

    @external_bin = false
    @x_axis_formula = nil
    @x_axis_name = nil
    @y_axis_formula = nil
    @y_axis_name = nil
    @title_name = nil
    @title_formula = nil
    @vary_data_color = 0
    set_default_properties
    set_default_config_data
  end

  #
  # Add a series and it's properties to a chart.
  #
  # In an Excel chart a "series" is a collection of information such as values,
  # x-axis labels and the name that define which data is plotted. These
  # settings are displayed when you select the Chart -> Source Data... menu
  # option.
  #
  # With a WriteExcel chart object the add_series() method is used to set the
  # properties for a series:
  #
  #     chart.add_series(
  #       :categories    => '=Sheet1!$A$2:$A$10',
  #       :values        => '=Sheet1!$B$2:$B$10',
  #       :name          => 'Series name',
  #       :name_formula  => '=Sheet1!$B$1'
  #     )
  #
  # The properties that can be set are:
  #
  #     :values        (required)
  #     :categories    (optional for most chart types)
  #     :name          (optional)
  #     :name_formula  (optional)
  #
  #     * :values
  #
  #       This is the most important property of a series and must be set for
  #       every chart object. It links the chart with the worksheet data that
  #       it displays.
  #
  #           chart.add_series(:values => '=Sheet1!$B$2:$B$10')
  #
  #       Note the format that should be used for the formula. It is the same
  #       as is used in Excel. You must also add the worksheet that you are
  #       referring to before you link to it, via the workbook
  #       add_worksheet() method.
  #
  #     * :categories
  #
  #       This sets the chart category labels. The category is more or less
  #       the same as the X-axis. In most chart types the categories property
  #       is optional and the chart will just assume a sequential series
  #       from 1 .. n.
  #
  #           chart.add_series(
  #             :categories    => '=Sheet1!$A$2:$A$10',
  #             :values        => '=Sheet1!$B$2:$B$10'
  #           )
  #
  #     * :name
  #
  #       Set the name for the series. The name is displayed in the chart
  #       legend and in the formula bar. The name property is optional and
  #       if it isn't supplied will default to Series 1 .. n.
  #
  #           chart.add_series(
  #             ...
  #             :name          => 'Series name'
  #           )
  #
  #     * :name_formula
  #
  #       Optional, can be used to link the name to a worksheet cell.
  #       See "Chart names and links".
  #
  #           chart.add_series(
  #             ...
  #             :name          => 'Series name',
  #             :name_formula  => '=Sheet1!$B$1'
  #           )
  #
  # You can add more than one series to a chart. The series numbering and
  # order in the final chart is the same as the order in which that are added.
  #
  #     # Add the first series.
  #     chart.add_series(
  #       :categories => '=Sheet1!$A$2:$A$7',
  #       :values     => '=Sheet1!$B$2:$B$7',
  #       :name       => 'Test data series 1'
  #     )
  #
  #     # Add another series. Category is the same but values are different.
  #     chart.add_series(
  #       :categories => '=Sheet1!$A$2:$A$7',
  #       :values     => '=Sheet1!$C$2:$C$7',
  #       :name       => 'Test data series 2'
  #     )
  #
  def add_series(params)
    raise "Must specify 'values' in add_series()" if params[:values].nil?

    # Parse the ranges to validate them and extract salient information.
    value_data    = parse_series_formula(params[:values])
    category_data = parse_series_formula(params[:categories])
    name_formula  = parse_series_formula(params[:name_formula])

    # Default category count to the same as the value count if not defined.
    category_data[1] = value_data[1] if category_data.size < 2

    # Add the parsed data to the user supplied data.
    params[:values]       = value_data
    params[:categories]   = category_data
    params[:name_formula] = name_formula

    # Encode the Series name.
    name, encoding = encode_utf16(params[:name], params[:name_encoding])

    params[:name]          = name
    params[:name_encoding] = encoding

    @series << params
  end

  #
  # Set the properties of the X-axis.
  #
  # The set_x_axis() method is used to set properties of the X axis.
  #
  #     chart.set_x_axis(:name => 'Sample length (m)' )
  #
  # The properties that can be set are:
  #
  #     :name          (optional)
  #     :name_formula  (optional)
  #
  #     * :name
  #
  #       Set the name (title or caption) for the axis. The name is displayed
  #       below the X axis. This property is optional. The default is to have
  #       no axis name.
  #
  #           chart.set_x_axis( :name => 'Sample length (m)' )
  #
  #     * :name_formula
  #
  #       Optional, can be used to link the name to a worksheet cell.
  #       See "Chart names and links".
  #
  #           chart.set_x_axis(
  #             :name          => 'Sample length (m)',
  #             :name_formula  => '=Sheet1!$A$1'
  #           )
  #
  # Additional axis properties such as range, divisions and ticks will be made
  # available in later releases.
  def set_x_axis(params)
    name, encoding = encode_utf16(params[:name], params[:name_encoding])
    formula = parse_series_formula(params[:name_formula])

    @x_axis_name     = name
    @x_axis_encoding = encoding
    @x_axis_formula  = formula
  end

  #
  # Set the properties of the Y-axis.
  #
  # The set_y_axis() method is used to set properties of the Y axis.
  #
  #     chart.set_y_axis(:name => 'Sample weight (kg)' )
  #
  # The properties that can be set are:
  #
  #     :name          (optional)
  #     :name_formula  (optional)
  #
  #     * :name
  #
  #       Set the name (title or caption) for the axis. The name is displayed
  #       to the left of the Y axis. This property is optional. The default
  #       is to have no axis name.
  #
  #           chart.set_y_axis(:name => 'Sample weight (kg)' )
  #
  #     * :name_formula
  #
  #       Optional, can be used to link the name to a worksheet cell.
  #       See "Chart names and links".
  #
  #           chart.set_y_axis(
  #             :name          => 'Sample weight (kg)',
  #             :name_formula  => '=Sheet1!$B$1'
  #           )
  #
  # Additional axis properties such as range, divisions and ticks will be made
  # available in later releases.
  #
  def set_y_axis(params)
    name, encoding = encode_utf16(params[:name], params[:name_encoding])
    formula = parse_series_formula(params[:name_formula])

    @y_axis_name     = name
    @y_axis_encoding = encoding
    @y_axis_formula  = formula
  end

  #
  # The set_title() method is used to set properties of the chart title.
  #
  #     chart.set_title(:name => 'Year End Results')
  #
  # The properties that can be set are:
  #
  #     :name          (optional)
  #     :name_formula  (optional)
  #
  #     * :name
  #
  #       Set the name (title) for the chart. The name is displayed above the
  #       chart. This property is optional. The default is to have no chart
  #       title.
  #
  #           chart.set_title(:name => 'Year End Results')
  #
  #     * :name_formula
  #
  #       Optional, can be used to link the name to a worksheet cell.
  #       See "Chart names and links".
  #
  #           chart.set_title(
  #             :name          => 'Year End Results',
  #             :name_formula  => '=Sheet1!$C$1'
  #           )
  #
  def set_title(params)
    name, encoding = encode_utf16( params[:name], params[:name_encoding])

    formula = parse_series_formula(params[:name_formula])

    @title_name     = name
    @title_encoding = encoding
    @title_formula  = formula
  end

  #
  # Set the properties of the chart legend.
  #
  def set_legend(params = {})
    if params.has_key?(:position)
      if params[:position].downcase == 'none'
        @legend[:visible] = 0
      end
    end
  end

  #
  # Set the properties of the chart plotarea.
  #
  def set_plotarea(params = {})
    return if params.empty?

    area = @plotarea

    # Set the plotarea visibility.
    if params.has_key?(:visible)
      area[:visible] = params[:visible]
      return if area[:visible] == 0
    end

    # TODO. could move this out of if statement.
    area[:bg_color_index] = 0x08

    # Set the chart background colour.
    if params.has_key?(:color)
      index, rgb = get_color_indices(params[:color])
      if !index.nil?
        area[:fg_color_index] = index
        area[:fg_color_rgb]   = rgb
        area[:bg_color_index] = 0x08
        area[:bg_color_rgb]   = 0x000000
      end
    end

    # Set the border line colour.
    if params.has_key?(:line_color)
      index, rgb = get_color_indices(params[:line_color])
      if !index.nil?
        area[:line_color_index] = index
        area[:line_color_rgb]   = rgb
      end
    end

    # Set the border line pattern.
    if params.has_key?(:line_pattern)
        pattern = get_line_pattern(params[:line_pattern])
        area[:line_pattern] = pattern
    end

    # Set the border line weight.
    if params.has_key?(:line_weight)
        weight = get_line_weight(params[:line_weight])
        area[:line_weight] = weight
    end
  end

  #
  # Set the properties of the chart chartarea.
  #
  def set_chartarea(params = {})
    return if params.empty?

    area = @chartarea

    # Embedded automatic line weight has a different default value.
    area[:line_weight] = 0xFFFF if @embedded

    # Set the chart background colour.
    if params.has_key?(:color)
      index, rgb = get_color_indices(params[:color])
      if !index.nil?
        area[:fg_color_index] = index
        area[:fg_color_rgb]   = rgb
        area[:bg_color_index] = 0x08
        area[:bg_color_rgb]   = 0x000000
        area[:area_pattern]   = 1
        area[:area_options]   = 0x0000 if @embedded
        area[:visible]        = 1
      end
    end

    # Set the border line colour.
    if params.has_key?(:line_color)
      index, rgb = get_color_indices(params[:line_color])
      if !index.nil?
        area[:line_color_index] = index
        area[:line_color_rgb]   = rgb
        area[:line_pattern]     = 0x00
        area[:line_options]     = 0x0000
        area[:visible]          = 1
      end
    end

    # Set the border line pattern.
    if params.has_key?(:line_pattern)
      pattern = get_line_pattern(params[:line_pattern])
      area[:line_pattern]     = pattern
      area[:line_options]     = 0x0000
      area[:line_color_index] = 0x4F unless params.has_key?(:line_color)
      area[:visible]          = 1
    end

    # Set the border line weight.
    if params.has_key?(:line_weight)
        weight = get_line_weight(params[:line_weight])
        area[:line_weight]      = weight
        area[:line_options]     = 0x0000
        area[:line_pattern]     = 0x00 unless params.has_key?(:line_pattern)
        area[:line_color_index] = 0x4F unless params.has_key?(:line_color)
        area[:visible]          = 1
    end
  end



  def using_tmpfile=(val)  # :nodoc:
    @using_tmpfile = val
  end

  def data=(val)  # :nodoc:
    @data = val
  end

  def embedded  # :nodoc:
    @embedded
  end

  def embedded=(val)  # :nodoc:
    @embedded = val
  end

  #
  # Setup the default configuration data for an embedded chart.
  #
  def set_embedded_config_data   # :nodoc:
    @embedded = true

    @chartarea = {
      :visible          => 1,
      :fg_color_index   => 0x4E,
      :fg_color_rgb     => 0xFFFFFF,
      :bg_color_index   => 0x4D,
      :bg_color_rgb     => 0x000000,
      :area_pattern     => 0x0001,
      :area_options     => 0x0001,
      :line_pattern     => 0x0000,
      :line_weight      => 0x0000,
      :line_color_index => 0x4D,
      :line_color_rgb   => 0x000000,
      :line_options     => 0x0009,
    }

    @config = default_config_data.merge({
        :axisparent      => [ 0, 0x01D8, 0x031D, 0x0D79, 0x07E9              ],
        :axisparent_pos  => [ 2, 2, 0x010C, 0x0292, 0x0E46, 0x09FD           ],
        :chart           => [ 0x0000, 0x0000, 0x01847FE8, 0x00F47FE8         ],
        :font_numbers    => [ 5, 10, 0x1DC4, 0x1284, 0x0000                  ],
        :font_series     => [ 6, 10, 0x1DC4, 0x1284, 0x0001                  ],
        :font_title      => [ 7, 12, 0x1DC4, 0x1284, 0x0000                  ],
        :font_axes       => [ 8, 10, 0x1DC4, 0x1284, 0x0001                  ],
        :legend          => [ 0x044E, 0x0E4A, 0x088D, 0x0123, 0x0, 0x1, 0xF  ],
        :legend_pos      => [ 5, 2, 0x044E, 0x0E4A, 0, 0                     ],
        :legend_text     => [ 0xFFFFFFD9, 0xFFFFFFC1, 0, 0, 0x00B1, 0x0000   ],
        :series_text     => [ 0xFFFFFFD9, 0xFFFFFFC1, 0, 0, 0x00B1, 0x1020   ],
        :title_text      => [ 0x060F, 0x004C, 0x038A, 0x016F, 0x0081, 0x1030 ],
        :x_axis_text     => [ 0x07EF, 0x0C8F, 0x153, 0x123, 0x81, 0x00       ],
        :y_axis_text     => [ 0x0057, 0x0564, 0xB5, 0x035D, 0x0281, 0x00, 90 ],
    })
  end

  #
  # Create and store the Chart data structures.
  #
  def close  # :nodoc:
    # Ignore any data that has been written so far since it is probably
    # from unwanted Worksheet method calls.
    @data = ''

    # TODO. Check for charts without a series?

    # Store the chart BOF.
    store_bof(0x0020)

    # Store the page header
    store_header

    # Store the page footer
    store_footer

    # Store the page horizontal centering
    store_hcenter

    # Store the page vertical centering
    store_vcenter

    # Store the left margin
    store_margin_left

    # Store the right margin
    store_margin_right

    # Store the top margin
    store_margin_top

    # Store the bottom margin
    store_margin_bottom

    # Store the page setup
    store_setup

    # Store the sheet password
    store_password

    # Start of Chart specific records.

    # Store the FBI font records.
    store_fbi(*@config[:font_numbers])
    store_fbi(*@config[:font_series])
    store_fbi(*@config[:font_title])
    store_fbi(*@config[:font_axes])

    # Ignore UNITS record.

    # Store the Chart sub-stream.
    store_chart_stream

    # Append the sheet dimensions
    store_dimensions

    # TODO add SINDEX and NUMBER records.

    store_window2 unless @embedded

    store_eof
  end

  private

  #
  # The parent Worksheet class needs to store some data in memory and some in
  # temporary files for efficiency. The Chart* classes don't need to do this
  # since they are dealing with smaller amounts of data so we override
  # _prepend() to turn it into an _append() method. This allows for a more
  # natural method calling order.
  #
  def prepend(*args)  # :nodoc:
    @using_tmpfile = false
    append(*args)
  end


  #
  # Write BIFF record Window2. Note, this overrides the parent Worksheet
  # record because the Chart version of the record is smaller and is used
  # mainly to indicate if the chart tab is selected or not.
  #
  def store_window2   # :nodoc:
    record  = 0x023E     # Record identifier
    length  = 0x000A     # Number of bytes to follow
    grbit   = 0x0000     # Option flags
    rwTop   = 0x0000     # Top visible row
    colLeft = 0x0000     # Leftmost visible column
    rgbHdr  = 0x0000     # Row/col heading, grid color

    # The options flags that comprise grbit
    fDspFmla       = 0                      # 0 - bit
    fDspGrid       = 0                      # 1
    fDspRwCol      = 0                      # 2
    fFrozen        = 0                      # 3
    fDspZeros      = 0                      # 4
    fDefaultHdr    = 0                      # 5
    fArabic        = 0                      # 6
    fDspGuts       = 0                      # 7
    fFrozenNoSplit = 0                      # 0 - bit
    fSelected      = selected? ? 1 : 0      # 1
    fPaged         = 0                      # 2
    fBreakPreview  = 0                      # 3

    #<<< Perltidy ignore this.
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
    #>>>

    header = [record, length].pack("vv")
    data = [grbit, rwTop, colLeft, rgbHdr].pack("vvvV")

    append(header, data)
  end

  #
  # Parse the formula used to define a series. We also extract some range
  # information required for _store_series() and the SERIES record.
  #
  def parse_series_formula(formula)  # :nodoc:
    encoding = 0
    length   = 0
    count    = 0
    tokens = []

    return [''] if formula.nil?

    # Strip the = sign at the beginning of the formula string
    formula = formula.sub(/^=/, '')

    # In order to raise formula errors from the point of view of the calling
    # program we use an eval block and re-raise the error from here.
    #
    tokens = parser.parse_formula(formula)

    # Force ranges to be a reference class.
    tokens.collect! { |t| t.gsub(/_ref3d/, '_ref3dR') }
    tokens.collect! { |t| t.gsub(/_range3d/, '_range3dR') }
    tokens.collect! { |t| t.gsub(/_name/, '_nameR') }

    # Parse the tokens into a formula string.
    formula = parser.parse_tokens(tokens)

    # Return formula for a single cell as used by title and series name.
    return formula if formula.ord == 0x3A

    # Extract the range from the parse formula.
    if formula.ord == 0x3B
        ptg, ext_ref, row_1, row_2, col_1, col_2 = formula.unpack('Cv5')

        # TODO. Remove high bit on relative references.
        count = row_2 - row_1 + 1
    end

    [formula, count]
  end

  #
  # Convert UTF8 strings used in the chart to UTF16.
  #
  def encode_utf16(str, encoding = 0)  # :nodoc:
    # Exit if the $string isn't defined, i.e., hasn't been set by user.
    return [nil, nil] if str.nil?

    string = str.dup
    # Return if encoding is set, i.e., string has been manually encoded.
    #return ( undef, undef ) if $string == 1;

    ruby_19 { string = convert_to_ascii_if_ascii(string) }

    # Handle utf8 strings.
    if is_utf8?(string)
      string = utf8_to_16be(string)
      encoding = 1
    end

    # Chart strings are limited to 255 characters.
    limit = encoding != 0 ? 255 * 2 : 255

    if string.bytesize >= limit
      # truncate the string and raise a warning.
      string = string[0, limit]
    end

    [string, encoding]
  end

  #
  # Convert the user specified colour index or string to an colour index and
  # RGB colour number.
  #
  def get_color_indices(color)   # :nodoc:
    invalid = 0x7FFF   # return from Colors#get_color when color is invalid

    index = Colors.new.get_color(color)
    index = invalid if color.respond_to?(:coerce) && (color < 8 || color > 63)
    if index == invalid
      [nil, nil]
    else
      [index, get_color_rbg(index)]
    end
  end

  #
  # Get the RedGreenBlue number for the colour index from the Workbook palette.
  #
  def get_color_rbg(index)   # :nodoc:
    # Adjust colour index from 8-63 (user range) to 0-55 (Excel range).
    index -= 8

    red_green_blue = palette[index]
    red_green_blue.pack('C*').unpack('V')[0]
  end

  def palette
    @workbook.palette
  end

  #
  # Get the Excel chart index for line pattern that corresponds to the user
  # defined value.
  #
  def get_line_pattern(value)   # :nodoc:
    value = value.downcase if value.respond_to?(:to_str)
    default = 0

    patterns = {
      0              => 5,
      1              => 0,
      2              => 1,
      3              => 2,
      4              => 3,
      5              => 4,
      6              => 7,
      7              => 6,
      8              => 8,
      'solid'        => 0,
      'dash'         => 1,
      'dot'          => 2,
      'dash-dot'     => 3,
      'dash-dot-dot' => 4,
      'none'         => 5,
      'dark-gray'    => 6,
      'medium-gray'  => 7,
      'light-gray'   => 8,
    }

    if patterns.has_key?(value)
      patterns[value]
    else
      default
    end
  end

  #
  # Get the Excel chart index for line weight that corresponds to the user
  # defined value.
  #
  def get_line_weight(value)   # :nodoc:
    value = value.downcase if value.respond_to?(:to_str)
    default = 0

    weights = {
      1          => -1,
      2          => 0,
      3          => 1,
      4          => 2,
      'hairline' => -1,
      'narrow'   => 0,
      'medium'   => 1,
      'wide'     => 2,
    }

    if weights.has_key?(value)
      weights[value]
    else
      default
    end
  end

  #
  # Store the CHART record and it's substreams.
  #
  def store_chart_stream # :nodoc:
    store_chart(*@config[:chart])
    store_begin

    # Store the chart SCL record.
    store_plotgrowth

    if @chartarea[:visible] != 0
      store_chartarea_frame_stream
    end

    # Store SERIES stream for each series.
    index = 0
    @series.each do |series|
      store_series_stream(
          :index            => index,
          :value_formula    => series[:values][0],
          :value_count      => series[:values][1],
          :category_count   => series[:categories][1],
          :category_formula => series[:categories][0],
          :name             => series[:name],
          :name_encoding    => series[:name_encoding],
          :name_formula     => series[:name_formula]
        )
        index += 1
    end

    store_shtprops

    # Write the TEXT streams.
    (5..6).each do |font_index|
      store_defaulttext
      store_series_text_stream(font_index)
    end

    store_axesused(1)
    store_axisparent_stream

    if !@title_name.nil? || !@title_formula.nil?
      store_title_text_stream
    end

    store_end
  end

  def _formula_type_from_param(t, f, params, key)  # :nodoc:
    if params.has_key?(key)
      v = params[key]
      (v.nil? || v == [""] || v == '' || v == 0) ? f : t
    end
  end

  #
  # Write the SERIES chart substream.
  #
  def store_series_stream(params)   # :nodoc:
    name_type     = _formula_type_from_param(2, 1, params, :name_formula)
    value_type    = _formula_type_from_param(2, 0, params, :value_formula)
    category_type = _formula_type_from_param(2, 0, params, :category_formula)

    store_series(params[:value_count], params[:category_count])

    store_begin

    # Store the Series name AI record.
    store_ai(0, name_type, params[:name_formula])
    unless params[:name].nil?
      store_seriestext(params[:name], params[:name_encoding])
    end

    store_ai(1, value_type,    params[:value_formula])
    store_ai(2, category_type, params[:category_formula])
    store_ai(3, 1,             '' )

    store_dataformat_stream(params[:index])
    store_sertocrt
    store_end
  end

  #
  # Write the DATAFORMAT chart substream.
  #
  def store_dataformat_stream(series_index)  # :nodoc:
    store_dataformat(series_index, series_index, 0xFFFF)

    store_begin
    store_3dbarshape
    store_end
  end

  #
  # Write the series TEXT substream.
  #
  def store_series_text_stream(font_index)  # :nodoc:
    store_text(*@config[:series_text])

    store_begin
    store_pos(*@config[:series_text_pos])
    store_fontx( font_index )
    store_ai( 0, 1, '' )
    store_end
  end

  def _formula_type(t, f, formula)   # :nodoc:
    (formula.nil? || formula == [""] || formula == '' || formula == 0) ? f : t
  end

  #
  # Write the X-axis TEXT substream.
  #
  def store_x_axis_text_stream   # :nodoc:
    formula = @x_axis_formula.nil? ? '' : @x_axis_formula
    ai_type = _formula_type(2, 1, formula)

    store_text(*@config[:x_axis_text])

    store_begin
    store_pos(*@config[:x_axis_text_pos])
    store_fontx(8)
    store_ai(0, ai_type, formula)

    unless @x_axis_name.nil?
      store_seriestext(@x_axis_name, @x_axis_encoding)
    end

    store_objectlink(3)
    store_end
  end

  #
  # Write the Y-axis TEXT substream.
  #
  def store_y_axis_text_stream   # :nodoc:
    formula = @y_axis_formula
    ai_type = _formula_type(2, 1, formula)

    store_text(*@config[:y_axis_text])

    store_begin
    store_pos(*@config[:y_axis_text_pos])
    store_fontx(8)
    store_ai(0, ai_type, formula)

    unless @y_axis_name.nil?
      store_seriestext(@y_axis_name, @y_axis_encoding)
    end

    store_objectlink(2)
    store_end
  end

  #
  # Write the legend TEXT substream.
  #
  def store_legend_text_stream   # :nodoc:
    store_text(*@config[:legend_text])

    store_begin
    store_pos(*@config[:legend_text_pos])
    store_ai(0, 1, '')

    store_end
  end

  #
  # Write the title TEXT substream.
  #
  def store_title_text_stream   # :nodoc:
    formula = @title_formula
    ai_type = _formula_type(2, 1, formula)

    store_text(*@config[:title_text])

    store_begin
    store_pos(*@config[:title_text_pos])
    store_fontx(7)
    store_ai(0, ai_type, formula)

    unless @title_name.nil?
      store_seriestext(@title_name, @title_encoding)
    end

    store_objectlink(1)
    store_end
  end

  #
  # Write the AXISPARENT chart substream.
  #
  def store_axisparent_stream   # :nodoc:
    store_axisparent(*@config[:axisparent])

    store_begin
    store_pos(*@config[:axisparent_pos])
    store_axis_category_stream
    store_axis_values_stream

    if !@x_axis_name.nil? || !@x_axis_formula.nil?
      store_x_axis_text_stream
    end

    if !@y_axis_name.nil? || !@y_axis_formula.nil?
      store_y_axis_text_stream
    end

    if @plotarea[:visible] != 0
      store_plotarea
      store_plotarea_frame_stream
    end
    store_chartformat_stream
    store_end
  end

  #
  # Write the AXIS chart substream for the chart category.
  #
  def store_axis_category_stream   # :nodoc:
    store_axis(0)

    store_begin
    store_catserrange
    store_axcext
    store_tick
    store_end
  end

  #
  # Write the AXIS chart substream for the chart values.
  #
  def store_axis_values_stream   # :nodoc:
    store_axis(1)

    store_begin
    store_valuerange
    store_tick
    store_axislineformat
    store_lineformat(0x00000000, 0x0000, 0xFFFF, 0x0009, 0x004D)
    store_end
  end

  #
  # Write the FRAME chart substream.
  #
  def store_plotarea_frame_stream   # :nodoc:
    store_area_frame_stream_common(:plot)
  end

  #
  # Write the FRAME chart substream for and embedded chart.
  #
  def store_chartarea_frame_stream   # :nodoc:
    store_area_frame_stream_common(:chart)
  end

  def store_area_frame_stream_common(type)
    if type == :plot
      area  = @plotarea
      grbit = 0x03
    else
      area = @chartarea
      grbit = 0x02
    end

    store_frame(0x00, grbit)
    store_begin

    store_lineformat(
      area[:line_color_rgb], area[:line_pattern],
      area[:line_weight],    area[:line_options],
      area[:line_color_index]
    )

    store_areaformat(
      area[:fg_color_rgb],   area[:bg_color_rgb],
      area[:area_pattern],   area[:area_options],
      area[:fg_color_index], area[:bg_color_index]
    )

    store_end
  end

  #
  # Write the CHARTFORMAT chart substream.
  #
  def store_chartformat_stream   # :nodoc:
    # The _vary_data_color is set by classes that need it, like Pie.
    store_chartformat(@vary_data_color)

    store_begin

    # Store the BIFF record that will define the chart type.
    store_chart_type

    # Note, the CHARTFORMATLINK record is only written by Excel.

    if @legend[:visible] != 0
        store_legend_stream
    end

    store_marker_dataformat_stream
    store_end
  end

  #
  # This is an abstract method that is overridden by the sub-classes to define
  # the chart types such as Column, Line, Pie, etc.
  #
  def store_chart_type   # :nodoc:

  end

  #
  # This is an abstract method that is overridden by the sub-classes to define
  # properties of markers, linetypes, pie formats and other.
  #
  def store_marker_dataformat_stream   # :nodoc:

  end

  #
  # Write the LEGEND chart substream.
  #
  def store_legend_stream   # :nodoc:
    store_legend(*@config[:legend])

    store_begin
    store_pos(*@config[:legend_pos])
    store_legend_text_stream
    store_end
  end

  ###############################################################################
  #
  # BIFF Records.
  #
  ###############################################################################

  #
  # Write the 3DBARSHAPE chart BIFF record.
  #
  def store_3dbarshape   # :nodoc:
    record = 0x105F    # Record identifier.
    length = 0x0002    # Number of bytes to follow.
    riser  = 0x00      # Shape of base.
    taper  = 0x00      # Column taper type.

    header = [record, length].pack('vv')
    data   = [riser].pack('C')
    data  += [taper].pack('C')

    append(header, data)
  end

  #
  # Write the AI chart BIFF record.
  #
  def store_ai(id, type, formula, format_index = 0)   # :nodoc:
    formula = '' if formula == [""]

    record       = 0x1051     # Record identifier.
    length       = 0x0008     # Number of bytes to follow.
    # id                      # Link index.
    # type                    # Reference type.
    # formula                 # Pre-parsed formula.
    # format_index            # Num format index.
    grbit        = 0x0000     # Option flags.

    ruby_19 { formula = convert_to_ascii_if_ascii(formula) }

    formula_length  = formula.bytesize
    length += formula_length

    header = [record, length].pack('vv')
    data   = [id].pack('C')
    data  += [type].pack('C')
    data  += [grbit].pack('v')
    data  += [format_index].pack('v')
    data  += [formula_length].pack('v')
    if formula.respond_to?(:to_array)
      data +=
        ruby_18 { formula[0] } ||
        ruby_19 { formula[0].encode('BINARY') }
    else
      data +=
        ruby_18 { formula                  unless formula.nil? } ||
        ruby_19 { formula.encode('BINARY') unless formula.nil? }
    end

    append(header, data)
  end

  #
  # Write the AREAFORMAT chart BIFF record. Contains the patterns and colours
  # of a chart area.
  #
  def store_areaformat(rgbFore, rgbBack, pattern, grbit, indexFore, indexBack)  # :nodoc:
    record    = 0x100A     # Record identifier.
    length    = 0x0010     # Number of bytes to follow.
    # rgbFore              # Foreground RGB colour.
    # rgbBack              # Background RGB colour.
    # pattern              # Pattern.
    # grbit                # Option flags.
    # indexFore            # Index to Foreground colour.
    # indexBack            # Index to Background colour.

    header = [record, length].pack('vv')
    data  = [rgbFore].pack('V')
    data += [rgbBack].pack('V')
    data += [pattern].pack('v')
    data += [grbit].pack('v')
    data += [indexFore].pack('v')
    data += [indexBack].pack('v')

    append(header, data)
  end

  #
  # Write the AXCEXT chart BIFF record.
  #
  def store_axcext  # :nodoc:
    record       = 0x1062     # Record identifier.
    length       = 0x0012     # Number of bytes to follow.
    catMin       = 0x0000     # Minimum category on axis.
    catMax       = 0x0000     # Maximum category on axis.
    catMajor     = 0x0001     # Value of major unit.
    unitMajor    = 0x0000     # Units of major unit.
    catMinor     = 0x0001     # Value of minor unit.
    unitMinor    = 0x0000     # Units of minor unit.
    unitBase     = 0x0000     # Base unit of axis.
    catCrossDate = 0x0000     # Crossing point.
    grbit        = 0x00EF     # Option flags.

    store_simple(record, length, catMin, catMax, catMajor, unitMajor,
                 catMinor, unitMinor, unitBase, catCrossDate, grbit)
  end

  #
  # Write the AXESUSED chart BIFF record.
  #
  def store_axesused(num_axes)   # :nodoc:
    record   = 0x1046     # Record identifier.
    length   = 0x0002     # Number of bytes to follow.
    # num_axes            # Number of axes used.

    store_simple(record, length, num_axes)
  end

  #
  # Write the AXIS chart BIFF record to define the axis type.
  #
  def store_axis(type)   # :nodoc:
    record    = 0x101D         # Record identifier.
    length    = 0x0012         # Number of bytes to follow.
    # type                     # Axis type.
    reserved1 = 0x00000000     # Reserved.
    reserved2 = 0x00000000     # Reserved.
    reserved3 = 0x00000000     # Reserved.
    reserved4 = 0x00000000     # Reserved.

    header = [record, length].pack('vv')
    data  = [type].pack('v')
    data += [reserved1].pack('V')
    data += [reserved2].pack('V')
    data += [reserved3].pack('V')
    data += [reserved4].pack('V')

    append(header, data)
  end

  #
  # Write the AXISLINEFORMAT chart BIFF record.
  #
  def store_axislineformat   # :nodoc:
    record      = 0x1021     # Record identifier.
    length      = 0x0002     # Number of bytes to follow.
    line_format = 0x0001     # Axis line format.

    store_simple(record, length, line_format)
  end

  #
  # Write the AXISPARENT chart BIFF record.
  #
  def store_axisparent(iax, x, y, dx, dy)  # :nodoc:
    record = 0x1041         # Record identifier.
    length = 0x0012         # Number of bytes to follow.
    # iax                   # Axis index.
    # x                     # X-coord.
    # y                     # Y-coord.
    # dx                    # Length of x axis.
    # dy                    # Length of y axis.

    header = [record, length].pack('vv')
    data   = [iax].pack('v')
    data  += [x].pack('V')
    data  += [y].pack('V')
    data  += [dx].pack('V')
    data  += [dy].pack('V')

    append(header, data)
  end

  #
  # Write the BEGIN chart BIFF record to indicate the start of a sub stream.
  #
  def store_begin   # :nodoc:
    record = 0x1033     # Record identifier.
    length = 0x0000     # Number of bytes to follow.

    store_simple(record, length)
  end

  #
  # Write the CATSERRANGE chart BIFF record.
  #
  def store_catserrange   # :nodoc:
    record   = 0x1020     # Record identifier.
    length   = 0x0008     # Number of bytes to follow.
    catCross = 0x0001     # Value/category crossing.
    catLabel = 0x0001     # Frequency of labels.
    catMark  = 0x0001     # Frequency of ticks.
    grbit    = 0x0001     # Option flags.

    store_simple(record, length, catCross, catLabel, catMark, grbit)
  end

  #
  # Write the CHART BIFF record. This indicates the start of the chart sub-stream
  # and contains dimensions of the chart on the display. Units are in 1/72 inch
  # and are 2 byte integer with 2 byte fraction.
  #
  def store_chart(x_pos, y_pos, dx, dy)   # :nodoc:
    record   = 0x1002     # Record identifier.
    length   = 0x0010     # Number of bytes to follow.
    # x_pos               # X pos of top left corner.
    # y_pos               # Y pos of top left corner.
    # dx                  # X size.
    # dy                  # Y size.

    header = [record, length].pack('vv')
    data   = [x_pos].pack('V')
    data  += [y_pos].pack('V')
    data  += [dx].pack('V')
    data  += [dy].pack('V')

    append(header, data)
  end

  #
  # Write the CHARTFORMAT chart BIFF record. The parent record for formatting
  # of a chart group.
  #
  def store_chartformat(grbit = 0)   # :nodoc:
    record    = 0x1014         # Record identifier.
    length    = 0x0014         # Number of bytes to follow.
    reserved1 = 0x00000000     # Reserved.
    reserved2 = 0x00000000     # Reserved.
    reserved3 = 0x00000000     # Reserved.
    reserved4 = 0x00000000     # Reserved.
    # grbit                    # Option flags.
    icrt      = 0x0000         # Drawing order.

    header = [record, length].pack('vv')
    data   = [reserved1].pack('V')
    data  += [reserved2].pack('V')
    data  += [reserved3].pack('V')
    data  += [reserved4].pack('V')
    data  += [grbit].pack('v')
    data  += [icrt].pack('v')

    append(header, data)
  end

  #
  # Write the CHARTLINE chart BIFF record.
  #
  def store_chartline   # :nodoc:
    record = 0x101C     # Record identifier.
    length = 0x0002     # Number of bytes to follow.
    type   = 0x0001     # Drop/hi-lo line type.

    store_simple(record, length, type)
  end

  #
  # Write the TEXT chart BIFF record.
  #
  def store_charttext   # :nodoc:
    record           = 0x1025         # Record identifier.
    length           = 0x0020         # Number of bytes to follow.
    horz_align       = 0x02           # Horizontal alignment.
    vert_align       = 0x02           # Vertical alignment.
    bg_mode          = 0x0001         # Background display.
    text_color_rgb   = 0x00000000     # Text RGB colour.
    text_x           = 0xFFFFFF46     # Text x-pos.
    text_y           = 0xFFFFFF06     # Text y-pos.
    text_dx          = 0x00000000     # Width.
    text_dy          = 0x00000000     # Height.
    grbit1           = 0x00B1         # Options
    text_color_index = 0x004D         # Auto Colour.
    grbit2           = 0x0000         # Data label placement.
    rotation         = 0x0000         # Text rotation.

    header = [record, length].pack('vv')
    data  = [horz_align].pack('C')
    data += [vert_align].pack('C')
    data += [bg_mode].pack('v')
    data += [text_color_rgb].pack('V')
    data += [text_x].pack('V')
    data += [text_y].pack('V')
    data += [text_dx].pack('V')
    data += [text_dy].pack('V')
    data += [grbit1].pack('v')
    data += [text_color_index].pack('v')
    data += [grbit2].pack('v')
    data += [rotation].pack('v')

    append(header, data)
  end

  #
  # Write the DATAFORMAT chart BIFF record. This record specifies the series
  # that the subsequent sub stream refers to.
  #
  def store_dataformat(series_index, series_number, point_number)   # :nodoc:
    record        = 0x1006     # Record identifier.
    length        = 0x0008     # Number of bytes to follow.
    # series_index             # Series index.
    # series_number            # Series number. (Same as index).
    # point_number             # Point number.
    grbit         = 0x0000     # Format flags.

    store_simple(record, length, point_number, series_index, series_number, grbit)
  end

  #
  # Write the DEFAULTTEXT chart BIFF record. Identifier for subsequent TEXT
  # record.
  #
  def store_defaulttext   # :nodoc:
    record = 0x1024     # Record identifier.
    length = 0x0002     # Number of bytes to follow.
    type   = 0x0002     # Type.

    store_simple(record, length, type)
  end

  #
  # Write the DROPBAR chart BIFF record.
  #
  def store_dropbar   # :nodoc:
    record      = 0x103D     # Record identifier.
    length      = 0x0002     # Number of bytes to follow.
    percent_gap = 0x0096     # Drop bar width gap (%).

    store_simple(record, length, percent_gap)
  end

  #
  # Write the END chart BIFF record to indicate the end of a sub stream.
  #
  def store_end   # :nodoc:
    record = 0x1034     # Record identifier.
    length = 0x0000     # Number of bytes to follow.

    store_simple(record, length)
  end

  #
  # Write the FBI chart BIFF record. Specifies the font information at the time
  # it was applied to the chart.
  #
  def store_fbi(index, height, width_basis, height_basis, scale_basis)  # :nodoc:
    record       = 0x1060    # Record identifier.
    length       = 0x000A    # Number of bytes to follow.
    # index                  # Font index.
    height       = height * 20    # Default font height in twips.
    # width_basis            # Width basis, in twips.
    # height_basis           # Height basis, in twips.
    # scale_basis            # Scale by chart area or plot area.

    store_simple(record, length, width_basis, height_basis, height, scale_basis, index)
  end

  #
  # Write the FONTX chart BIFF record which contains the index of the FONT
  # record in the Workbook.
  #
  def store_fontx(index)   # :nodoc:
    record = 0x1026     # Record identifier.
    length = 0x0002     # Number of bytes to follow.
    # index             # Font index.

    store_simple(record, length, index)
  end

  #
  # Write the FRAME chart BIFF record.
  #
  def store_frame(frame_type, grbit)   # :nodoc:
    record     = 0x1032     # Record identifier.
    length     = 0x0004     # Number of bytes to follow.
    # frame_type            # Frame type.
    # grbit                 # Option flags.

    store_simple(record, length, frame_type, grbit)
  end

  #
  # Write the LEGEND chart BIFF record. The Marcus Horan method.
  #
  def store_legend(x, y, width, height, wType, wSpacing, grbit)  # :nodoc:
    record   = 0x1015     # Record identifier.
    length   = 0x0014     # Number of bytes to follow.
    # x                   # X-position.
    # y                   # Y-position.
    # width               # Width.
    # height              # Height.
    # wType               # Type.
    # wSpacing            # Spacing.
    # grbit               # Option flags.

    header = [record, length].pack('vv')
    data  = [x].pack('V')
    data += [y].pack('V')
    data += [width].pack('V')
    data += [height].pack('V')
    data += [wType].pack('C')
    data += [wSpacing].pack('C')
    data += [grbit].pack('v')

    append(header, data)
  end

  #
  # Write the LINEFORMAT chart BIFF record.
  #
  def store_lineformat(rgb, lns, we, grbit, index)  # :nodoc:
    record = 0x1007     # Record identifier.
    length = 0x000C     # Number of bytes to follow.
    # rgb               # Line RGB colour.
    # lns               # Line pattern.
    # we                # Line weight.
    # grbit             # Option flags.
    # index             # Index to colour of line.

    header = [record, length].pack('vv')
    data  = [rgb].pack('V')
    data += [lns].pack('v')
    data += [we].pack('v')
    data += [grbit].pack('v')
    data += [index].pack('v')

    append(header, data)
  end

  #
  # Write the MARKERFORMAT chart BIFF record.
  #
  def store_markerformat(rgbFore, rgbBack, marker, grbit, icvFore, icvBack, miSize)# :nodoc:
    record  = 0x1009     # Record identifier.
    length  = 0x0014     # Number of bytes to follow.
    # rgbFore            # Foreground RGB color.
    # rgbBack            # Background RGB color.
    # marker             # Type of marker.
    # grbit              # Format flags.
    # icvFore            # Color index marker border.
    # icvBack            # Color index marker fill.
    # miSize             # Size of line markers.

    header = [record, length].pack('vv')
    data  = [rgbFore].pack('V')
    data += [rgbBack].pack('V')
    data += [marker].pack('v')
    data += [grbit].pack('v')
    data += [icvFore].pack('v')
    data += [icvBack].pack('v')
    data += [miSize].pack('V')

    append(header, data)
  end

  #
  # Write the OBJECTLINK chart BIFF record.
  #
  def store_objectlink(link_type)   # :nodoc:
    record      = 0x1027     # Record identifier.
    length      = 0x0006     # Number of bytes to follow.
    # link_type              # Object text link type.
    link_index1 = 0x0000     # Link index 1.
    link_index2 = 0x0000     # Link index 2.

    store_simple(record, length, link_type, link_index1, link_index2)
  end

  #
  # Write the PIEFORMAT chart BIFF record.
  #
  def store_pieformat   # :nodoc:
    record  = 0x100B     # Record identifier.
    length  = 0x0002     # Number of bytes to follow.
    percent = 0x0000     # Distance % from center.

    store_simple(record, length, percent)
  end

  #
  # Write the PLOTAREA chart BIFF record. This indicates that the subsequent
  # FRAME record belongs to a plot area.
  #
  def store_plotarea   # :nodoc:
    record = 0x1035     # Record identifier.
    length = 0x0000     # Number of bytes to follow.

    store_simple(record, length)
  end

  #
  # Write the PLOTGROWTH chart BIFF record.
  #
  def store_plotgrowth  # :nodoc:
    record  = 0x1064         # Record identifier.
    length  = 0x0008         # Number of bytes to follow.
    dx_plot = 0x00010000     # Horz growth for font scale.
    dy_plot = 0x00010000     # Vert growth for font scale.

    header = [record, length].pack('vv')
    data  = [dx_plot].pack('V')
    data += [dy_plot].pack('V')

    append(header, data)
  end

  #
  # Write the POS chart BIFF record. Generally not required when using
  # automatic positioning.
  #
  def store_pos(mdTopLt, mdBotRt, x1, y1, x2, y2)  # :nodoc:
    record  = 0x104F     # Record identifier.
    length  = 0x0014     # Number of bytes to follow.
    # mdTopLt            # Top left.
    # mdBotRt            # Bottom right.
    # x1                 # X coordinate.
    # y1                 # Y coordinate.
    # x2                 # Width.
    # y2                 # Height.

    header = [record, length].pack('vv')
    data  = [mdTopLt].pack('v')
    data += [mdBotRt].pack('v')
    data += [x1].pack('V')
    data += [y1].pack('V')
    data += [x2].pack('V')
    data += [y2].pack('V')

    append(header, data)
  end

  #
  # Write the SERAUXTREND chart BIFF record.
  #
  def store_serauxtrend(reg_type, poly_order, equation, r_squared)  # :nodoc:
    record     = 0x104B     # Record identifier.
    length     = 0x001C     # Number of bytes to follow.
    # reg_type              # Regression type.
    # poly_order            # Polynomial order.
    # equation              # Display equation.
    # r_squared             # Display R-squared.
    # intercept             # Forced intercept.
    # forecast              # Forecast forward.
    # backcast              # Forecast backward.

    # TODO. When supported, intercept needs to be NAN if not used.
    # Also need to reverse doubles.
    intercept = ['FFFFFFFF0001FFFF'].pack('H*')
    forecast  = ['0000000000000000'].pack('H*')
    backcast  = ['0000000000000000'].pack('H*')

    header = [record, length].pack('vv')
    data  = [reg_type].pack('C')
    data += [poly_order].pack('C')
    data += intercept
    data += [equation].pack('C')
    data += [r_squared].pack('C')
    data += forecast
    data += backcast

    append(header, data)
  end

  #
  # Write the SERIES chart BIFF record.
  #
  def store_series(category_count, value_count)  # :nodoc:
    record         = 0x1003     # Record identifier.
    length         = 0x000C     # Number of bytes to follow.
    category_type  = 0x0001     # Type: category.
    value_type     = 0x0001     # Type: value.
    # category_count            # Num of categories.
    # value_count               # Num of values.
    bubble_type    = 0x0001     # Type: bubble.
    bubble_count   = 0x0000     # Num of bubble values.

    store_simple(record, length, category_type, value_type,
                 category_count, value_count, bubble_type, bubble_count)
  end

  #
  # Write the SERIESTEXT chart BIFF record.
  #
  def store_seriestext(str, encoding)  # :nodoc:
    ruby_19 { str = convert_to_ascii_if_ascii(str) }

    record   = 0x100D          # Record identifier.
    length   = 0x0000          # Number of bytes to follow.
    id       = 0x0000          # Text id.
    # str                      # Text.
    # encoding                 # String encoding.
    cch      = str.bytesize      # String length.

    encoding ||= 0

    # Character length is num of chars not num of bytes
    cch /= 2 if encoding != 0

    # Change the UTF-16 name from BE to LE
    str = str.unpack('v*').pack('n*') if encoding != 0

    length = 4 + str.bytesize

    header = [record, length].pack('vv')
    data  = [id].pack('v')
    data += [cch].pack('C')
    data += [encoding].pack('C')

    append(header, data, str)
  end

  #
  # Write the SERPARENT chart BIFF record.
  #
  def store_serparent(series)  # :nodoc:
    record = 0x104A     # Record identifier.
    length = 0x0002     # Number of bytes to follow.
    # series            # Series parent.

    store_simple(record, length, series)
  end

  #
  # Write the SERTOCRT chart BIFF record to indicate the chart group index.
  #
  def store_sertocrt   # :nodoc:
    record     = 0x1045     # Record identifier.
    length     = 0x0002     # Number of bytes to follow.
    chartgroup = 0x0000     # Chart group index.

    store_simple(record, length, chartgroup)
  end

  #
  # Write the SHTPROPS chart BIFF record.
  #
  def store_shtprops   # :nodoc:
    record      = 0x1044     # Record identifier.
    length      = 0x0004     # Number of bytes to follow.
    grbit       = 0x000E     # Option flags.
    empty_cells = 0x0000     # Empty cell handling.

    grbit = 0x000A if @embedded

    store_simple(record, length, grbit, empty_cells)
  end

  #
  # Write the TEXT chart BIFF record.
  #
  def store_text(x, y, dx, dy, grbit1, grbit2, rotation = 0x00)# :nodoc:
    record   = 0x1025            # Record identifier.
    length   = 0x0020            # Number of bytes to follow.
    at       = 0x02              # Horizontal alignment.
    vat      = 0x02              # Vertical alignment.
    wBkgMode = 0x0001            # Background display.
    rgbText  = 0x0000            # Text RGB colour.
    # x                          # Text x-pos.
    # y                          # Text y-pos.
    # dx                         # Width.
    # dy                         # Height.
    # grbit1                     # Option flags.
    icvText  = 0x004D            # Auto Colour.
    # grbit2                     # Show legend.
    # rotation                   # Show value.

    header = [record, length].pack('vv')
    data  = [at].pack('C')
    data += [vat].pack('C')
    data += [wBkgMode].pack('v')
    data += [rgbText].pack('V')
    data += [x].pack('V')
    data += [y].pack('V')
    data += [dx].pack('V')
    data += [dy].pack('V')
    data += [grbit1].pack('v')
    data += [icvText].pack('v')
    data += [grbit2].pack('v')
    data += [rotation].pack('v')

    append(header, data)
  end

  #
  # Write the TICK chart BIFF record.
  #
  def store_tick   # :nodoc:
    record    = 0x101E         # Record identifier.
    length    = 0x001E         # Number of bytes to follow.
    tktMajor  = 0x02           # Type of major tick mark.
    tktMinor  = 0x00           # Type of minor tick mark.
    tlt       = 0x03           # Tick label position.
    wBkgMode  = 0x01           # Background mode.
    rgb       = 0x00000000     # Tick-label RGB colour.
    reserved1 = 0x00000000     # Reserved.
    reserved2 = 0x00000000     # Reserved.
    reserved3 = 0x00000000     # Reserved.
    reserved4 = 0x00000000     # Reserved.
    grbit     = 0x0023         # Option flags.
    index     = 0x004D         # Colour index.
    reserved5 = 0x0000         # Reserved.

    header = [record, length].pack('vv')
    data  = [tktMajor].pack('C')
    data += [tktMinor].pack('C')
    data += [tlt].pack('C')
    data += [wBkgMode].pack('C')
    data += [rgb].pack('V')
    data += [reserved1].pack('V')
    data += [reserved2].pack('V')
    data += [reserved3].pack('V')
    data += [reserved4].pack('V')
    data += [grbit].pack('v')
    data += [index].pack('v')
    data += [reserved5].pack('v')

    append(header, data)
  end

  #
  # Write the VALUERANGE chart BIFF record.
  #
  def store_valuerange   # :nodoc:
    record   = 0x101F         # Record identifier.
    length   = 0x002A         # Number of bytes to follow.
    numMin   = 0x00000000     # Minimum value on axis.
    numMax   = 0x00000000     # Maximum value on axis.
    numMajor = 0x00000000     # Value of major increment.
    numMinor = 0x00000000     # Value of minor increment.
    numCross = 0x00000000     # Value where category axis crosses.
    grbit    = 0x011F         # Format flags.

    # TODO. Reverse doubles when they are handled.

    header = [record, length].pack('vv')
    data  = [numMin].pack('d')
    data += [numMax].pack('d')
    data += [numMajor].pack('d')
    data += [numMinor].pack('d')
    data += [numCross].pack('d')
    data += [grbit].pack('v')

    append(header, data)
  end


  ###############################################################################
  #
  # Config data.
  #
  ###############################################################################

  #
  # Setup the default properties for a chart.
  #
  def set_default_properties   # :nodoc:
    @legend = {
      :visible  => 1,
      :position => 0,
      :vertical => 0,
    }

    @chartarea = {
      :visible          => 0,
      :fg_color_index   => 0x4E,
      :fg_color_rgb     => 0xFFFFFF,
      :bg_color_index   => 0x4D,
      :bg_color_rgb     => 0x000000,
      :area_pattern     => 0x0000,
      :area_options     => 0x0000,
      :line_pattern     => 0x0005,
      :line_weight      => 0xFFFF,
      :line_color_index => 0x4D,
      :line_color_rgb   => 0x000000,
      :line_options     => 0x0008,
    }

    @plotarea = {
      :visible          => 1,
      :fg_color_index   => 0x16,
      :fg_color_rgb     => 0xC0C0C0,
      :bg_color_index   => 0x4F,
      :bg_color_rgb     => 0x000000,
      :area_pattern     => 0x0001,
      :area_options     => 0x0000,
      :line_pattern     => 0x0000,
      :line_weight      => 0x0000,
      :line_color_index => 0x17,
      :line_color_rgb   => 0x808080,
      :line_options     => 0x0000,
    }
  end

  #
  # Setup the default configuration data for a chart.
  #
  def set_default_config_data   # :nodoc:
    @config = default_config_data
  end

  def default_config_data   # :nodoc:
    {
        :axisparent      => [ 0, 0x00F8, 0x01F5, 0x0E7F, 0x0B36              ],
        :axisparent_pos  => [ 2, 2, 0x008C, 0x01AA, 0x0EEA, 0x0C52           ],
        :chart           => [ 0x0000, 0x0000, 0x02DD51E0, 0x01C2B838         ],
        :font_numbers    => [ 5, 10, 0x38B8, 0x22A1, 0x0000                  ],
        :font_series     => [ 6, 10, 0x38B8, 0x22A1, 0x0001                  ],
        :font_title      => [ 7, 12, 0x38B8, 0x22A1, 0x0000                  ],
        :font_axes       => [ 8, 10, 0x38B8, 0x22A1, 0x0001                  ],
        :legend          => [ 0x05F9, 0x0EE9, 0x047D, 0x9C, 0x00, 0x01, 0x0F ],
        :legend_pos      => [ 5, 2, 0x05F9, 0x0EE9, 0, 0                     ],
        :legend_text     => [ 0xFFFFFF46, 0xFFFFFF06, 0, 0, 0x00B1, 0x0000   ],
        :legend_text_pos => [ 2, 2, 0, 0, 0, 0                               ],
        :series_text     => [ 0xFFFFFF46, 0xFFFFFF06, 0, 0, 0x00B1, 0x1020   ],
        :series_text_pos => [ 2, 2, 0, 0, 0, 0                               ],
        :title_text      => [ 0x06E4, 0x0051, 0x01DB, 0x00C4, 0x0081, 0x1030 ],
        :title_text_pos  => [ 2, 2, 0, 0, 0x73, 0x1D                         ],
        :x_axis_text     => [ 0x07E1, 0x0DFC, 0xB2, 0x9C, 0x0081, 0x0000     ],
        :x_axis_text_pos => [ 2, 2, 0, 0,  0x2B,  0x17                       ],
        :y_axis_text     => [ 0x002D, 0x06AA, 0x5F, 0x1CC, 0x0281, 0x00, 90  ],
        :y_axis_text_pos => [ 2, 2, 0, 0, 0x17,  0x44                        ],
    }
  end

end  # class Chart

end  # module Writeexcel
