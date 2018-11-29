# -*- coding: utf-8 -*-
###############################################################################
#
# Workbook - A writer class for Excel Workbooks.
#
#
# Used in conjunction with WriteExcel
#
# Copyright 2000-2010, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
require 'nkf'
require 'forwardable'
require 'writeexcel/biffwriter'
require 'writeexcel/worksheet'
require 'writeexcel/chart'
require 'writeexcel/format'
require 'writeexcel/formula'
require 'writeexcel/olewriter'
require 'writeexcel/storage_lite'
require 'writeexcel/compatibility'
require 'writeexcel/shared_string_table'
require 'writeexcel/worksheets'

class Workbook < BIFFWriter
  require 'writeexcel/properties'
  require 'writeexcel/helper'

  extend Forwardable

  attr_reader :url_format, :parser, :tempdir, :date_1904
  attr_reader :compatibility, :palette
  attr_reader :ext_refs
  attr_reader :worksheets

  BOF = 12  # :nodoc:
  EOF = 4   # :nodoc:

  #
  # _file_ is a filename (as string) or io object where to out spreadsheet data.
  # you can set default format of workbook using _default_formats_.
  #
  # A new Excel workbook is created using the new() constructor which accepts
  # either a filename or an IO object as a parameter. The following example
  # creates a new Excel file based on a filename:
  #
  #     workbook  = WriteExcel.new('filename.xls')
  #     worksheet = workbook.add_worksheet
  #     worksheet.write(0, 0, 'Hi Excel!')
  #
  # Here are some other examples of using new():
  #
  #     workbook1 = WriteExcel.new(filename)
  #     workbook2 = WriteExcel.new('/tmp/filename.xls')
  #     workbook3 = WriteExcel.new("c:\\tmp\\filename.xls")
  #     workbook4 = WriteExcel.new('c:\tmp\filename.xls')
  #
  # The last two examples demonstrates how to create a file on DOS or
  # Windows where it is necessary to either escape the directory
  # separator \ or to use single quotes to ensure that it isn't interpolated.
  #
  # The new() constructor returns a WriteExcel object that you can use to add
  # worksheets and store data.
  #
  # If the file cannot be created, due to file permissions or some other reason,
  # new will raise Exception Errno::EXXX.
  #
  # You can also pass a valid IO object to the new() constructor.:
  #     require 'stringio'
  #
  #     io = StringIO.new
  #     workbook = WriteExcel.new(io)  # After workbook.close, you can get excel data as io.string
  #
  # And, you can also pass default format properties.
  #
  #     workbook = WriteExcel.new(filename, :font => 'Courier New', :size => 11)
  #
  def initialize(file, default_formats = {})
    super()
    @file                  = file
    @default_formats       = default_formats
    @parser                = Writeexcel::Formula.new(@byte_order)
    @tempdir               = nil
    @date_1904             = false
    @xf_index              = 0
    @biffsize              = 0
    @sheet_count           = 0
    @chart_count           = 0
    @codepage              = 0x04E4
    @country               = 1
    @worksheets            = Worksheets.new
    @formats               = []
    @palette               = []
    @biff_only             = 0

    @internal_fh           = 0
    @fh_out                = ""

    @shared_string_table   = SharedStringTable.new
    @extsst_offsets        = []  # array of [global_offset, local_offset]
    @extsst_buckets        = 0
    @extsst_bucket_size    = 0

    @ext_refs              = {}

    @mso_clusters          = []
    @mso_size              = 0

    @hideobj               = false

    @summary               = ''
    @doc_summary           = ''
    @localtime             = Time.now

    @defined_names         = []

    setup_built_in_formats(default_formats)

    # Add the default format for hyperlinks
    @url_format = add_format(:color => 'blue', :underline => 1)

    if file.respond_to?(:to_str) && file != ''
      @fh_out      = open(file, "wb")
      @internal_fh = 1
    else
      @fh_out = file
    end

    # Set colour palette.
    set_palette_xl97
  end

  #
  # Calls finalization methods and explicitly close the OLEwriter files
  # handle.
  #
  # An explicit close() is required if the file must be closed prior to performing
  # some external action on it such as copying it, reading its size or attaching
  # it to an email.
  #
  # In general, if you create a file with a size of 0 bytes or you fail to create
  # a file you need to call close().
  #
  def close
    return if fileclosed?  # Prevent close() from being called twice.

    @fileclosed = true
    store_workbook
    cleanup
  end

  # get array of Worksheet objects
  #
  # :call-seq:
  #   sheets              -> array of all Wordsheet object
  #   sheets(1, 3, 4)     -> array of spcified Worksheet object.
  #
  # The sheets() method returns a array, or a sliced array, of the worksheets
  # in a workbook.
  #
  # If no arguments are passed the method returns a list of all the worksheets
  # in the workbook. This is useful if you want to repeat an operation on each
  # worksheet:
  #
  #     workbook.sheets.each do |worksheet|
  #        print worksheet.get_name
  #     end
  #
  # You can also specify a slice list to return one or more worksheet objects:
  #
  #     worksheet = workbook.sheets(0)
  #     worksheet.write('A1', 'Hello')
  #
  # you can write the above example as:
  #
  #     workbook.sheets(0).write('A1', 'Hello')
  #
  # The following example returns the first and last worksheet in a workbook:
  #
  #     workbook.sheets(0, -1).each do |sheet|
  #        # Do something
  #     end
  #
  def sheets(*args)
    if args.empty?
      @worksheets
    else
      args.collect{|i| @worksheets[i] }
    end
  end

  #
  # Add a new worksheet to the Excel workbook.
  #
  # if _sheetname_ is UTF-16BE format, pass true as _name_utf16be_.
  #
  # At least one worksheet should be added to a new workbook. A worksheet is
  # used to write data into cells:
  #
  #     worksheet1 = workbook.add_worksheet            # Sheet1
  #     worksheet2 = workbook.add_worksheet('Foglio2') # Foglio2
  #     worksheet3 = workbook.add_worksheet('Data')    # Data
  #     worksheet4 = workbook.add_worksheet            # Sheet4
  #
  # If _sheetname_ is not specified the default Excel convention will be followed,
  # i.e. Sheet1, Sheet2, etc. The utf_16_be parameter is optional, see below.
  #
  # The worksheet name must be a valid Excel worksheet name, i.e. it cannot
  # contain any of the following characters, [ ] : * ? / \
  # and it must be less than 32 characters. In addition, you cannot use the same,
  # case insensitive, _sheetname_ for more than one worksheet.
  #
  # This method will also handle strings in UTF-8 format.
  #
  #     worksheet = workbook.add_worksheet("シート名")
  #
  # UTF-16BE worksheet names using an additional optional parameter:
  #
  #     name = [0x263a].pack('n')
  #     worksheet = workbook.add_worksheet(name, true)   # Smiley
  #
  def add_worksheet(sheetname = '', name_utf16be = false)
    name, name_utf16be = check_sheetname(sheetname, name_utf16be)

    init_data = [
                  self,
                  name,
                  name_utf16be
    ]
    worksheet = Writeexcel::Worksheet.new(*init_data)
    @worksheets << worksheet                      # Store ref for iterator
    @parser.set_ext_sheets(name, worksheet.index) # Store names in Formula.rb
    worksheet
  end

  #
  # Create a chart for embedding or as as new sheet.
  #
  # This method is use to create a new chart either as a standalone worksheet
  # (the default) or as an embeddable object that can be inserted into a
  # worksheet via the insert_chart() Worksheet method.
  #
  #     chart = workbook.add_chart(:type => 'Chart::Column')
  #
  # The properties that can be set are:
  #
  #   :type      (required)
  #   :name      (optional)
  #   :name_utf16be  (optional)
  #   :embedded  (optional)
  #
  # * :type
  #
  # This is a required parameter. It defines the type of chart that will be created.
  #
  #   chart = workbook.add_chart(:type => 'Chart::Line')
  #
  # The available types are:
  #
  #   'Chart::Column'
  #   'Chart::Bar'
  #   'Chart::Line'
  #   'Chart::Area'
  #   'Chart::Pie'
  #   'Chart::Scatter'
  #   'Chart::Stock'
  #
  # * :name
  #
  # Set the name for the chart sheet. The name property is optional and
  # if it isn't supplied will default to Chart1 .. n. The name must be
  # a valid Excel worksheet name. See add_worksheet() for more details
  # on valid sheet names. The :name property can be omitted for embedded
  # charts.
  #
  #   chart = workbook.add_chart(
  #              :type => 'Chart::Line',
  #              :name => 'Results Chart'
  #           )
  #
  # * :name_utf16be
  #
  # if :name is UTF-16BE format, pass true as :name_utf16be
  #
  # * :encoding
  #
  # if :name is UTF-16BE format, pass 1 as :encoding.
  # This key is obsolete in v0.7 or later. Use :name_utf16be instead.
  #
  # * :embedded
  #
  # Specifies true that the Chart object will be inserted in a worksheet via
  # the insert_chart() Worksheet method. It is an error to try insert a
  # Chart that doesn't have this flag set.
  #
  #   chart = workbook.add_chart(:type => 'Chart::Line', :embedded => true)
  #
  #   # Configure the chart.
  #   ...
  #
  #   # Insert the chart into the a worksheet.
  #   worksheet.insert_chart('E2', chart)
  #
  # See WriteExcel::Chart for details on how to configure the
  # chart object once it is created. See also the chart_*.rb programs in the
  # examples directory of the distro.
  #
  def add_chart(properties)
    name = ''
    name_utf16be = false

    # Type must be specified so we can create the required chart instance.
    type = properties[:type]
    raise "Must define chart type in add_chart()" if type.nil?

    # Ensure that the chart defaults to non embedded.
    embedded = properties[:embedded]

    # Check the worksheet name for non-embedded charts.
    unless embedded
      properties[:name_utf16be] = true if properties[:encoding] == 1
      name, name_utf16be =
        check_sheetname(properties[:name], properties[:name_utf16be], true)
    end

    init_data = [
      self,
      name,
      name_utf16be
    ]

    chart = Writeexcel::Chart.factory(type, *init_data)
    # If the chart isn't embedded let the workbook control it.
    if !embedded
      @worksheets << chart          # Store ref for iterator
    else
      chart.set_embedded_config_data
    end
    chart
  end

  #
  # Add an externally created chart.
  #
  # This method is use to include externally generated charts in a WriteExcel
  # file.
  #
  #     chart = workbook.add_chart_ext('chart01.bin', 'Chart1')
  #
  # This feature is semi-deprecated in favour of the "native" charts created
  # using add_chart(). Read external_charts.txt in the external_charts
  # directory of the distro for a full explanation.
  #
  def add_chart_ext(filename, chartname, name_utf16be = false)
    type = 'extarnal'

    name, name_utf16be = check_sheetname(chartname, name_utf16be)

    init_data = [
      filename,
      name,
      name_utf16be
    ]

    chart = Writeexcel::Chart.factory(self, type, init_data)
    @worksheets << chart      # Store ref for iterator
    chart
  end

  #
  # The add_format method can be used to create new Format objects which are
  # used to apply formatting to a cell. You can either define the properties
  # at creation time via a hash of property values or later via method calls.
  #
  #     format1 = workbook.add_format(props) # Set properties at creation
  #     format2 = workbook.add_format        # Set properties later
  #
  # See the "CELL FORMATTING" section for more details about Format properties and how to set them.
  #
  def add_format(*args)
    fmts = {}
    args.each { |arg| fmts = fmts.merge(arg) }
    format = Writeexcel::Format.new(@xf_index, @default_formats.merge(fmts))
    @xf_index += 1
    @formats.push format # Store format reference
    format
  end

  #
  # Set the compatibility mode.
  #
  # This method is used to improve compatibility with third party
  # applications that read Excel files.
  #
  #     workbook.compatibility_mode
  #
  # An Excel file is comprised of binary records that describe properties of
  # a spreadsheet. Excel is reasonably liberal about this and, outside of a
  # core subset, it doesn't require every possible record to be present when
  # it reads a file. This is also true of Gnumeric and OpenOffice.Org Calc.
  #
  # WriteExcel takes advantage of this fact to omit some records in order to
  # minimise the amount of data stored in memory and to simplify and speed up
  # the writing of files. However, some third party applications that read
  # Excel files often expect certain records to be present. In
  # "compatibility mode" WriteExcel writes these records and tries to be as
  # close to an Excel generated file as possible.
  #
  # Applications that require compatibility_mode() are Apache POI,
  # Apple Numbers, and Quickoffice on Nokia, Palm and other devices. You should
  # also use compatibility_mode() if your Excel file will be used as an external
  # data source by another Excel file.
  #
  # If you encounter other situations that require compatibility_mode(),
  # please let me know.
  #
  # It should be noted that compatibility_mode() requires additional data to be
  # stored in memory and additional processing. This incurs a memory and speed
  # penalty and may not be suitable for very large files (>20MB).
  #
  # You must call compatibility_mode() before calling add_worksheet().
  #
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
  def compatibility_mode(mode = true)
    unless sheets.empty?
      raise "compatibility_mode() must be called before add_worksheet()"
    end
    @compatibility = mode
  end

  #
  # Set the date system: false = 1900 (the default), true = 1904
  #
  # Excel stores dates as real numbers where the integer part stores the
  # number of days since the epoch and the fractional part stores the
  # percentage of the day. The epoch can be either 1900 or 1904. Excel for
  # Windows uses 1900 and Excel for Macintosh uses 1904. However, Excel on
  # either platform will convert automatically between one system and
  # the other.
  #
  # WriteExcel stores dates in the 1900 format by default. If you wish to
  # change this you can call the set_1904() workbook method. You can query
  # the current value by calling the get_1904() workbook method. This returns
  # false for 1900 and true for 1904.
  #
  # See also "DATES AND TIME IN EXCEL" for more information about working
  # with Excel's date system.
  #
  # In general you probably won't need to use set_1904().
  #
  def set_1904(mode = true)
    unless sheets.empty?
      raise "set_1904() must be called before add_worksheet()"
    end
    @date_1904 = (!mode || mode == 0) ? false : true
  end

  def get_1904
    @date_1904
  end

  #
  # Change the RGB components of the elements in the colour palette.
  #
  # The set_custom_color() method can be used to override one of the built-in
  # palette values with a more suitable colour.
  #
  # The value for _index_ should be in the range 8..63, see "COLOURS IN EXCEL".
  #
  # The default named colours use the following indices:
  #
  #      8   =>   black
  #      9   =>   white
  #     10   =>   red
  #     11   =>   lime
  #     12   =>   blue
  #     13   =>   yellow
  #     14   =>   magenta
  #     15   =>   cyan
  #     16   =>   brown
  #     17   =>   green
  #     18   =>   navy
  #     20   =>   purple
  #     22   =>   silver
  #     23   =>   gray
  #     33   =>   pink
  #     53   =>   orange
  #
  # A new colour is set using its RGB (red green blue) components. The red,
  # green and blue values must be in the range 0..255. You can determine the
  # required values in Excel using the Tools->Options->Colors->Modify dialog.
  #
  # The set_custom_color() workbook method can also be used with a HTML style
  # #rrggbb hex value:
  #
  #     workbook.set_custom_color(40, 255,  102,  0   ) # Orange
  #     workbook.set_custom_color(40, 0xFF, 0x66, 0x00) # Same thing
  #     workbook.set_custom_color(40, '#FF6600'       ) # Same thing
  #
  #     font = workbook.add_format(:color => 40)   # Use the modified colour
  #
  # The return value from set_custom_color() is the index of the colour that
  # was changed:
  #
  #     ferrari = workbook.set_custom_color(40, 216, 12, 12)
  #
  #     format  = workbook.add_format(
  #                                 :bg_color => $ferrari,
  #                                 :pattern  => 1,
  #                                 :border   => 1
  #                            )
  #
  def set_custom_color(index, red = nil, green = nil, blue = nil)
    # Match a HTML #xxyyzz style parameter
    if !red.nil? && red =~ /^#(\w\w)(\w\w)(\w\w)/
      red   = $1.hex
      green = $2.hex
      blue  = $3.hex
    end

    # Check that the colour index is the right range
    if index < 8 || index > 64
      raise "Color index #{index} outside range: 8 <= index <= 64"
    end

    # Check that the colour components are in the right range
    if (red   < 0 || red   > 255) ||
      (green < 0 || green > 255) ||
      (blue  < 0 || blue  > 255)
      raise "Color component outside range: 0 <= color <= 255"
    end

    index -=8       # Adjust colour index (wingless dragonfly)

    # Set the RGB value
    @palette[index] = [red, green, blue, 0]

    index + 8
  end

  #
  # Change the default temp directory
  #
  # For speed and efficiency WriteExcel stores worksheet data in temporary
  # files prior to assembling the final workbook.
  #
  # If WriteExcel is unable to create these temporary files it will store
  # the required data in memory. This can be slow for large files.
  #
  # The problem occurs mainly with IIS on Windows although it could feasibly
  # occur on Unix systems as well. The problem generally occurs because the
  # default temp file directory is defined as C:/ or some other directory that
  # IIS doesn't provide write access to.
  #
  # To check if this might be a problem on a particular system you can run a
  # simple test program with -w or use warnings. This will generate a warning
  # if the module cannot create the required temporary files:
  #
  #     #!/usr/bin/ruby -w
  #
  #     require 'WriteExcel'
  #
  #     workbook  = WriteExcel.new('test.xls')
  #     worksheet = workbook.add_worksheet
  #     workbook.close
  #
  # To avoid this problem the set_tempdir() method can be used to specify a
  # directory that is accessible for the creation of temporary files.
  #
  # Even if the default temporary file directory is accessible you may wish
  # to specify an alternative location for security or maintenance reasons:
  #
  #     workbook.set_tempdir('/tmp/writeexcel')
  #     workbook.set_tempdir('c:\windows\temp\writeexcel')
  #
  # The directory for the temporary file must exist, set_tempdir() will not
  # create a new directory.
  #
  # One disadvantage of using the set_tempdir() method is that on some Windows
  # systems it will limit you to approximately 800 concurrent tempfiles. This
  # means that a single program running on one of these systems will be limited
  # to creating a total of 800 workbook and worksheet objects. You can run
  # multiple, non-concurrent programs to work around this if necessary.
  #
  def set_tempdir(dir = '')
    raise "#{dir} is not a valid directory" if dir != '' && !FileTest.directory?(dir)
    raise "set_tempdir must be called before add_worksheet" unless sheets.empty?

    @tempdir = dir
  end

  #
  # The default code page or character set used by WriteExcel is ANSI. This is
  # also the default used by Excel for Windows. Occasionally however it may be
  # necessary to change the code page via the set_codepage() method.
  #
  # Changing the code page may be required if your are using WriteExcel on the
  # Macintosh and you are using characters outside the ASCII 128 character set:
  #
  #     workbook.set_codepage(1) # ANSI, MS Windows
  #     workbook.set_codepage(2) # Apple Macintosh
  #
  # The set_codepage() method is rarely required.
  #
  def set_codepage(type = 1)
    if type == 2
      @codepage = 0x8000
    else
      @codepage = 0x04E4
    end
  end

  #
  #  store the country code.
  #
  # Some non-english versions of Excel may need this set to some value other
  # than 1 = "United States". In general the country code is equal to the
  # international dialling code.
  #
  def set_country(code = 1)
    @country = code
  end

  #
  # This method is used to defined a name that can be used to represent a
  # value, a single cell or a range of cells in a workbook.
  #
  #     workbook.define_name('Exchange_rate', '=0.96')
  #     workbook.define_name('Sales',         '=Sheet1!$G$1:$H$10')
  #     workbook.define_name('Sheet2!Sales',  '=Sheet2!$G$1:$G$10')
  #
  # See the defined_name.rb program in the examples dir of the distro.
  #
  # Note: This currently a beta feature. More documentation and examples
  # will be added.
  #
  def define_name(name, formula, encoding = 0)
    sheet_index = 0
    full_name   = name.downcase

    if name =~ /^(.*)!(.*)$/
      sheetname   = $1
      name        = $2
      sheet_index = 1 + @parser.get_sheet_index(sheetname)
    end

    # Strip the = sign at the beginning of the formula string
    formula = formula.sub(/^=/, '')

    # Parse the formula using the parser in Formula.pm
    parser  = @parser

    # In order to raise formula errors from the point of view of the calling
    # program we use an eval block and re-raise the error from here.
    #
    tokens = parser.parse_formula(formula)

    # Force 2d ranges to be a reference class.
    tokens.collect! { |t| t.gsub(/_ref3d/, '_ref3dR') }
    tokens.collect! { |t| t.gsub(/_range3d/, '_range3dR') }

    # Parse the tokens into a formula string.
    formula = parser.parse_tokens(tokens)

    defined_names.push(
       {
         :name        => name,
         :encoding    => encoding,
         :sheet_index => sheet_index,
         :formula     => formula
       }
     )

    index = defined_names.size

    parser.set_ext_name(name, index)
  end

  #
  # Set the document properties such as Title, Author etc. These are written to
  # property sets in the OLE container.
  #
  # The set_properties method can be used to set the document properties of
  # the Excel file created by WriteExcel. These properties are visible when you
  # use the File->Properties  menu option in Excel and are also available to
  # external applications that read or index windows files.
  #
  # The properties should be passed as a hash of values as follows:
  #
  #     workbook.set_properties(
  #         :title    => 'This is an example spreadsheet',
  #         :author   => 'cxn03651',
  #         :comments => 'Created with Ruby and WriteExcel',
  #     )
  #
  # The properties that can be set are:
  #
  #    * :title
  #    * :subject
  #    * :author
  #    * :manager
  #    * :company
  #    * :category
  #    * :keywords
  #    * :comments
  #
  # User defined properties are not supported due to effort required.
  #
  # You can also pass UTF-8 strings as properties.
  #
  #     workbook.set_properties(
  #         :subject => "住所録"
  #     )
  #
  # Usually WriteExcel allows you to use UTF-16. However, document properties
  # don't support UTF-16 for these type of strings.
  #
  # In order to promote the usefulness of Ruby and the WriteExcel module
  # consider adding a comment such as the following when using document
  # properties:
  #
  #     workbook.set_properties(
  #         ...,
  #         :comments => 'Created with Ruby and writeexcel',
  #         ...,
  #     )
  #
  # See also the properties.rb program in the examples directory of the distro.
  #
  def set_properties(params)
    # Ignore if no args were passed.
    return -1 if !params.respond_to?(:to_hash) || params.empty?

    params.each do |k, v|
      params[k] = convert_to_ascii_if_ascii(v) if v.respond_to?(:to_str)
    end

    # Check for valid input parameters.
    check_valid_params_for_properties(params)

    # Set the creation time unless specified by the user.
    params[:created] = @localtime unless params.has_key?(:created)

    #
    # Create the SummaryInformation property set.
    #

    # Get the codepage of the strings in the property set.
    properties = [:title, :subject, :author, :keywords,  :comments, :last_author]
    params[:codepage] = get_property_set_codepage(params, properties)

    # Create an array of property set values.
    properties.unshift(:codepage)
    properties.push(:created)

    # Pack the property sets.
    @summary =
      create_summary_property_set(property_sets(properties, params))

    #
    # Create the DocSummaryInformation property set.
    #

    # Get the codepage of the strings in the property set.
    properties = [:category, :manager, :company]
    params[:codepage] = get_property_set_codepage(params, properties)

    # Create an array of property set values.
    properties.unshift(:codepage)

    # Pack the property sets.
    @doc_summary =
      create_doc_summary_property_set(property_sets(properties, params))

    # Set a flag for when the files is written.
    @add_doc_properties = true
  end

  def extsst_buckets  # :nodoc:
    @extsst_buckets
  end

  def extsst_bucket_size  # :nodoc:
    @extsst_bucket_size
  end

  def biff_only=(val)  # :nodoc:
    @biff_only = val
  end

  def summary  # :nodoc:
    @summary
  end

  def localtime=(val)  # :nodoc:
    @localtime = val
  end

  def update_str_table(str)
    @shared_string_table << str
  end

  #==========================================
  #  Internal method
  #==========================================

  private

  # Add the in-built style formats and the default cell format.
  def setup_built_in_formats(default_formats)   # :nodoc:
    add_format(:type => 1)                        #  0 Normal
    add_format(:type => 1)                        #  1 RowLevel 1
    add_format(:type => 1)                        #  2 RowLevel 2
    add_format(:type => 1)                        #  3 RowLevel 3
    add_format(:type => 1)                        #  4 RowLevel 4
    add_format(:type => 1)                        #  5 RowLevel 5
    add_format(:type => 1)                        #  6 RowLevel 6
    add_format(:type => 1)                        #  7 RowLevel 7
    add_format(:type => 1)                        #  8 ColLevel 1
    add_format(:type => 1)                        #  9 ColLevel 2
    add_format(:type => 1)                        # 10 ColLevel 3
    add_format(:type => 1)                        # 11 ColLevel 4
    add_format(:type => 1)                        # 12 ColLevel 5
    add_format(:type => 1)                        # 13 ColLevel 6
    add_format(:type => 1)                        # 14 ColLevel 7
    add_format(default_formats)                   # 15 Cell XF
    add_format(:type => 1, :num_format => 0x2B)   # 16 Comma
    add_format(:type => 1, :num_format => 0x29)   # 17 Comma[0]
    add_format(:type => 1, :num_format => 0x2C)   # 18 Currency
    add_format(:type => 1, :num_format => 0x2A)   # 19 Currency[0]
    add_format(:type => 1, :num_format => 0x09)   # 20 Percent
  end

  def fileclosed?
    @fileclosed || false
  end

  #
  # Check for valid worksheet names. We check the length, if it contains any
  # invalid characters and if the name is unique in the workbook.
  #
  def check_sheetname(name, name_utf16be = false, chart = nil)       #:nodoc:
    # name_utf16be parameter may set 0/1 in v0.6.6 or earlier
    name_utf16be = false if name_utf16be == 0
    name_utf16be = true  if name_utf16be == 1

    increment_sheet_chart_count(chart)
    if name.nil? || name == ""
      name_utf16be = false
      name = default_sheet_chart_name(chart)
    end

    ruby_19 { name = convert_to_ascii_if_ascii(name) }
    check_sheetname_length(name, name_utf16be)
    check_sheetname_even(name) if name_utf16be
    check_sheetname_valid_chars(name, name_utf16be)

    # Handle utf8 strings
    if !name_utf16be && is_utf8?(name)
      name = utf8_to_16be(name)
      name_utf16be = true
    end

    check_sheetname_uniq(name, name_utf16be)
    [name,  name_utf16be]
  end

  # Increment the Sheet/Chart number used for default sheet names below.
  def increment_sheet_chart_count(chart)
    if chart
      @chart_count += 1
    else
      @sheet_count += 1
    end
  end

  # Supply default Sheet/Chart name if none has been defined.
  def default_sheet_chart_name(chart)
    if chart
      "Chart#{@chart_count}"
    else
      "Sheet#{@sheet_count}"
    end
  end

  def check_sheetname_length(name, name_utf16be)       #:nodoc:
    # Check that sheetname is <= 31 (1 or 2 byte chars). Excel limit.
    limit           = name_utf16be ? 62 : 31
    raise "Sheetname $name must be <= 31 chars" if name.bytesize > limit
  end

  def check_sheetname_even(name)       #:nodoc:
    # Check that Unicode sheetname has an even number of bytes
    if (name.bytesize % 2 != 0)
      raise "Odd number of bytes in Unicode worksheet name: #{name}"
    end
  end

  def check_sheetname_valid_chars(name, name_utf16be)       #:nodoc:
    # Check that sheetname doesn't contain any invalid characters
    invalid_chars    = %r![\[\]:*?/\\]!

    if ascii_sheetname_invalid_chars?(name, name_utf16be, invalid_chars) ||
        non_ascii_sheetname_invalid_chars?(name, invalid_chars)
      raise "Invalid character []:*?/\\ in worksheet name: #{name}"
    end
  end

  def ascii_sheetname_invalid_chars?(name, name_utf16be, invalid_chars)  # :nodoc:
    # Check ASCII names
    !name_utf16be && name =~ invalid_chars
  end

  def non_ascii_sheetname_invalid_chars?(name, invalid_chars)   # :nodoc:
    # Extract any 8bit clean chars from the UTF16 name and validate them.
    str = ruby_19 { name.dup.force_encoding("binary") } || ruby_18 { name.dup }
    while str =~ /../m
      hi, lo = $~[0].unpack('aa')
      str = $~.post_match
      if hi == "\0" and lo =~ invalid_chars
        raise 'Invalid character []:*?/\\ in worksheet name: ' + name
      end
    end
  end

  # Check that the worksheet name doesn't already exist since this is a fatal
  # error in Excel 97. The check must also exclude case insensitive matches
  # since the names 'Sheet1' and 'sheet1' are equivalent. The tests also have
  # to take the name_utf16be into account.
  #
  def check_sheetname_uniq(name, name_utf16be)       #:nodoc:
    @worksheets.each do |worksheet|
      name_a  = name
      encd_a  = name_utf16be
      name_b  = worksheet.name
      encd_b  = worksheet.is_name_utf16be?
      error   = false

      if    !encd_a and !encd_b
        error  = (name_a.downcase == name_b.downcase)
      elsif !encd_a and encd_b
        name_a = ascii_to_16be(name_a)
        error  = (name_a.downcase == name_b.downcase)
      elsif encd_a and !encd_b
        name_b = ascii_to_16be(name_b)
        error  = (name_a.downcase == name_b.downcase)
      elsif encd_a and encd_b
        error  = (name_a.downcase == name_b.downcase)
        # TODO : not converted yet.

        #  We can't easily do a case insensitive test of the UTF16 names.
        # As a special case we check if all of the high bytes are nulls and
        # then do an ASCII style case insensitive test.
        #
        # Strip out the high bytes (funkily).
        # my $hi_a = grep {ord} $name_a =~ /(.)./sg;
        # my $hi_b = grep {ord} $name_b =~ /(.)./sg;
        #
        # if ($hi_a or $hi_b) {
        #    $error  = 1 if    $name_a  eq    $name_b;
        # }
        # else {
        #    $error  = 1 if lc($name_a) eq lc($name_b);
        # }
      end
      if error
        raise "Worksheet name '#{name}', with case ignored, is already in use"
      end
    end
  end

  #
  # Sets the colour palette to the Excel 97+ default.
  #
  def set_palette_xl97       #:nodoc:
    @palette = [
      [0x00, 0x00, 0x00, 0x00],   # 8
      [0xff, 0xff, 0xff, 0x00],   # 9
      [0xff, 0x00, 0x00, 0x00],   # 10
      [0x00, 0xff, 0x00, 0x00],   # 11
      [0x00, 0x00, 0xff, 0x00],   # 12
      [0xff, 0xff, 0x00, 0x00],   # 13
      [0xff, 0x00, 0xff, 0x00],   # 14
      [0x00, 0xff, 0xff, 0x00],   # 15
      [0x80, 0x00, 0x00, 0x00],   # 16
      [0x00, 0x80, 0x00, 0x00],   # 17
      [0x00, 0x00, 0x80, 0x00],   # 18
      [0x80, 0x80, 0x00, 0x00],   # 19
      [0x80, 0x00, 0x80, 0x00],   # 20
      [0x00, 0x80, 0x80, 0x00],   # 21
      [0xc0, 0xc0, 0xc0, 0x00],   # 22
      [0x80, 0x80, 0x80, 0x00],   # 23
      [0x99, 0x99, 0xff, 0x00],   # 24
      [0x99, 0x33, 0x66, 0x00],   # 25
      [0xff, 0xff, 0xcc, 0x00],   # 26
      [0xcc, 0xff, 0xff, 0x00],   # 27
      [0x66, 0x00, 0x66, 0x00],   # 28
      [0xff, 0x80, 0x80, 0x00],   # 29
      [0x00, 0x66, 0xcc, 0x00],   # 30
      [0xcc, 0xcc, 0xff, 0x00],   # 31
      [0x00, 0x00, 0x80, 0x00],   # 32
      [0xff, 0x00, 0xff, 0x00],   # 33
      [0xff, 0xff, 0x00, 0x00],   # 34
      [0x00, 0xff, 0xff, 0x00],   # 35
      [0x80, 0x00, 0x80, 0x00],   # 36
      [0x80, 0x00, 0x00, 0x00],   # 37
      [0x00, 0x80, 0x80, 0x00],   # 38
      [0x00, 0x00, 0xff, 0x00],   # 39
      [0x00, 0xcc, 0xff, 0x00],   # 40
      [0xcc, 0xff, 0xff, 0x00],   # 41
      [0xcc, 0xff, 0xcc, 0x00],   # 42
      [0xff, 0xff, 0x99, 0x00],   # 43
      [0x99, 0xcc, 0xff, 0x00],   # 44
      [0xff, 0x99, 0xcc, 0x00],   # 45
      [0xcc, 0x99, 0xff, 0x00],   # 46
      [0xff, 0xcc, 0x99, 0x00],   # 47
      [0x33, 0x66, 0xff, 0x00],   # 48
      [0x33, 0xcc, 0xcc, 0x00],   # 49
      [0x99, 0xcc, 0x00, 0x00],   # 50
      [0xff, 0xcc, 0x00, 0x00],   # 51
      [0xff, 0x99, 0x00, 0x00],   # 52
      [0xff, 0x66, 0x00, 0x00],   # 53
      [0x66, 0x66, 0x99, 0x00],   # 54
      [0x96, 0x96, 0x96, 0x00],   # 55
      [0x00, 0x33, 0x66, 0x00],   # 56
      [0x33, 0x99, 0x66, 0x00],   # 57
      [0x00, 0x33, 0x00, 0x00],   # 58
      [0x33, 0x33, 0x00, 0x00],   # 59
      [0x99, 0x33, 0x00, 0x00],   # 60
      [0x99, 0x33, 0x66, 0x00],   # 61
      [0x33, 0x33, 0x99, 0x00],   # 62
      [0x33, 0x33, 0x33, 0x00]    # 63
    ]
  end

  def property_set(property, params)       #:nodoc:
    valid_properties[property][0..1] + [params[property]]
  end

  def property_sets(properties, params)       #:nodoc:
    properties.select { |property| params[property.to_sym] }.
      collect do |property|
        property_set(property.to_sym, params)
      end
  end

  # List of valid input parameters.
  def valid_properties       #:nodoc:
    {
      :codepage      => [0x0001, 'VT_I2'      ],
      :title         => [0x0002, 'VT_LPSTR'   ],
      :subject       => [0x0003, 'VT_LPSTR'   ],
      :author        => [0x0004, 'VT_LPSTR'   ],
      :keywords      => [0x0005, 'VT_LPSTR'   ],
      :comments      => [0x0006, 'VT_LPSTR'   ],
      :last_author   => [0x0008, 'VT_LPSTR'   ],
      :created       => [0x000C, 'VT_FILETIME'],
      :category      => [0x0002, 'VT_LPSTR'   ],
      :manager       => [0x000E, 'VT_LPSTR'   ],
      :company       => [0x000F, 'VT_LPSTR'   ],
      :utf8          => 1
    }
  end

  def check_valid_params_for_properties(params)       #:nodoc:
    params.each_key do |k|
      unless valid_properties.has_key?(k)
        raise "Unknown parameter '#{k}' in set_properties()"
      end
    end
  end

  #
  # Get the character codepage used by the strings in a property set. If one of
  # the strings used is utf8 then the codepage is marked as utf8. Otherwise
  # Latin 1 is used (although in our case this is limited to 7bit ASCII).
  #
  def get_property_set_codepage(params, properties)       #:nodoc:
    # Allow for manually marked utf8 strings.
    return 0xFDE9 unless params[:utf8].nil?
    properties.each do |property|
      next unless params.has_key?(property.to_sym)
      return 0xFDE9 if is_utf8?(params[property.to_sym])
    end
    return 0x04E4  # Default codepage, Latin 1.
  end

  #
  # Assemble worksheets into a workbook and send the BIFF data to an OLE
  # storage.
  #
  def store_workbook       #:nodoc:
    # Add a default worksheet if non have been added.
    add_worksheet if @worksheets.empty?

    # Calculate size required for MSO records and update worksheets.
    calc_mso_sizes

    # Ensure that at least one worksheet has been selected.
    unless @worksheets.activesheet
      @worksheets.activesheet = @worksheets.first
      @worksheets.activesheet.select
    end

    # Add Workbook globals
    add_workbook_globals

    # Calculate the offsets required by the BOUNDSHEET records
    calc_sheet_offsets

    # Add BOUNDSHEET records.
    @worksheets.each do |sheet|
      store_boundsheet(sheet)
    end

    # NOTE: If any records are added between here and EOF the
    # calc_sheet_offsets() should be updated to include the new length.
    store_country
    if @ext_refs.keys.size != 0
      store_supbook
      store_externsheet
      store_names
    end
    add_mso_drawing_group
    store_shared_strings
    store_extsst

    # End Workbook globals
    store_eof

    # Store the workbook in an OLE container
    store_ole_file
  end

  def add_workbook_globals
    store_bof(0x0005)
    store_codepage
    store_window1
    store_hideobj
    store_1904
    store_all_fonts
    store_all_num_formats
    store_all_xfs
    store_all_styles
    store_palette
  end

  #
  # Store the workbook in an OLE container using the default handler or using
  # OLE::Storage_Lite if the workbook data is > ~ 7MB.
  #
  def store_ole_file       #:nodoc:
    maxsize = 7_087_104
#    maxsize = 1

    if !add_doc_properties && @biffsize <= maxsize
      store_through_ole_writer
    else
      store_through_ole_storage_lite
    end
  end

  def store_through_ole_writer
    # Write the OLE file using OLEwriter if data <= 7MB
    ole  = OLEWriter.new(@fh_out)

    # Write the BIFF data without the OLE container for testing.
    ole.biff_only = @biff_only

    # Indicate that we created the filehandle and want to close it.
    ole.internal_fh = @internal_fh

    ole.set_size(@biffsize)
    ole.write_header

    while tmp = get_data
      ole.write(tmp)
    end

    @worksheets.each do |worksheet|
      while tmp = worksheet.get_data
        ole.write(tmp)
      end
    end

    return ole.close
  end

  def store_through_ole_storage_lite
    # Create the Workbook stream.
    stream   = 'Workbook'.unpack('C*').pack('v*')
    workbook = OLEStorageLitePPSFile.new(stream)
    workbook.set_file   # use tempfile

    while tmp = get_data
      workbook.append(tmp)
    end

    @worksheets.each do |worksheet|
      while tmp = worksheet.get_data
        workbook.append(tmp)
      end
    end

    streams = []
    streams << workbook

    # Create the properties streams, if any.
    if add_doc_properties
      stream  = "\5SummaryInformation".unpack('C*').pack('v*')
      summary = OLEStorageLitePPSFile.new(stream, @summary)
      streams << summary
      stream  = "\5DocumentSummaryInformation".unpack('C*').pack('v*')
      summary = OLEStorageLitePPSFile.new(stream, @doc_summary)
      streams << summary
    end
    # Create the OLE root document and add the substreams.
    localtime = @localtime.to_a[0..5]
    localtime[4] -= 1  # month
    localtime[5] -= 1900
    ole_root = OLEStorageLitePPSRoot.new(
                   localtime,
                   localtime,
                   streams
                 )
    ole_root.save(@file)

    # Close the filehandle if it was created internally.
    return @fh_out.close if @internal_fh != 0
  end

  #
  # Calculate Worksheet BOF offsets records for use in the BOUNDSHEET records.
  #
  def calc_sheet_offsets       #:nodoc:
    offset  = @datasize

    # Add the length of the COUNTRY record
    offset += 8

    # Add the length of the SST and associated CONTINUEs
    offset += calculate_shared_string_sizes

    # Add the length of the EXTSST record.
    offset += calculate_extsst_size(@shared_string_table.str_unique)

    # Add the length of the SUPBOOK, EXTERNSHEET and NAME records
    offset += calculate_extern_sizes

    # Add the length of the MSODRAWINGGROUP records including an extra 4 bytes
    # for any CONTINUE headers. See add_mso_drawing_group_continue().
    mso_size = @mso_size
    mso_size += 4 * Integer((mso_size -1) / Float(@limit))
    offset   += mso_size

    @worksheets.each do |sheet|
      offset += BOF + sheet.name.bytesize
    end

    offset += EOF
    @worksheets.each do |sheet|
      sheet.offset = offset
      sheet.close
      offset += sheet.datasize
    end

    @biffsize = offset
  end

  #
  # Calculate the MSODRAWINGGROUP sizes and the indexes of the Worksheet
  # MSODRAWING records.
  #
  # In the following SPID is shape id, according to Escher nomenclature.
  #
  def calc_mso_sizes       #:nodoc:
    mso_size        = 0    # Size of the MSODRAWINGGROUP record
    max_spid        = 1024 # spidMax
    drawings_saved  = 0    # cdgSaved
    clusters        = []

    process_images

    # Add Bstore container size if there are images.
    mso_size += 8 unless @images_data.empty?

    # Iterate through the worksheets, calculate the MSODRAWINGGROUP parameters
    # and space required to store the record and the MSODRAWING parameters
    # required by each worksheet.
    #
    @worksheets.each do |sheet|
      next unless sheet.type == 0x0000
      next if sheet.num_shapes == 1

      mso_size, drawings_saved, max_spid, start_spid =
        sheet.push_object_ids(mso_size, drawings_saved, max_spid, start_spid, clusters)
    end


    # Calculate the MSODRAWINGGROUP size if we have stored some shapes.
    mso_size += 86 if mso_size != 0 # Smallest size is 86+8=94

    shapes_saved = sheets.collect { |sheet| sheet.num_shapes }.
                   select { |num_shapes| num_shapes > 1 }.
                   inject(0) { |result, num_shapes| result + num_shapes }

    @mso_size      = mso_size
    @mso_clusters  = [
      max_spid, clusters.size + 1, shapes_saved,
      drawings_saved, clusters
    ]
  end

  #
  # We need to process each image in each worksheet and extract information.
  # Some of this information is stored and used in the Workbook and some is
  # passed back into each Worksheet. The overall size for the image related
  # BIFF structures in the Workbook is calculated here.
  #
  # MSO size =  8 bytes for bstore_container +
  #            44 bytes for blip_store_entry +
  #            25 bytes for blip
  #          = 77 + image size.
  #
  def process_images       #:nodoc:
    images_seen     = {}
    image_data      = []
    previous_images = []
    image_id        = 1
    images_size     = 0

    @worksheets.each do |sheet|
      next unless sheet.type == 0x0000
      next if sheet.images_size == 0

      num_images      = 0
      image_mso_size  = 0

      sheet.images_array.each do |image|
        num_images += 1
        unless images_seen[image.filename]
          # TODO should also match seen images based on checksum.
          image.id = image_id
          image.ref_count = 1
          image.import

          # Also store new data for use in duplicate images.
          previous_images.push(image)

          # Store information required by the Workbook.
          image_data.push(image)

          # Keep track of overall data size.
          images_size       += image.size + 61  # Size for bstore container.
          image_mso_size    += image.size + 69  # Size for dgg container.

          images_seen[image.filename] = image_id
          image_id += 1
        else
          # We've processed this file already.
          index = images_seen[image.filename] -1

          # Increase image reference count.
          image_data[index].ref_count += 1

          # Add previously calculated data back onto the Worksheet array.
          # image_id, type, width, height
          image.id = previous_images[index].id
          image.type = previous_images[index].type
          image.width = previous_images[index].width
          image.height = previous_images[index].height
        end
      end

      # Store information required by the Worksheet.
      sheet.num_images     = num_images
      sheet.image_mso_size = image_mso_size
    end

    # Store information required by the Workbook.
    @images_size = images_size
    @images_data = image_data     # Store the data for MSODRAWINGGROUP.
  end

  #
  # Store the Excel FONT records.
  #
  def store_all_fonts       #:nodoc:
    format  = @formats[15]   # The default cell format.
    font    = format.get_font

    # Fonts are 0-indexed. According to the SDK there is no index 4,
    4.times { append(font) }

    # Add the default fonts for charts and comments. This aren't connected
    # to XF formats. Note, the font size, and some other properties of
    # chart fonts are set in the FBI record of the chart.

    # Index 5. Axis numbers.
    tmp_format = Writeexcel::Format.new(
        nil,
        :font_only => 1
    )
    append(tmp_format.get_font)

    # Index 6. Series names.
    tmp_format = Writeexcel::Format.new(
        nil,
        :font_only => 1
    )
    append(tmp_format.get_font)

    # Index 7. Title.
    tmp_format = Writeexcel::Format.new(
        nil,
        :font_only => 1,
        :bold      => 1
    )
    append(tmp_format.get_font)

    # Index 8. Axes.
    tmp_format = Writeexcel::Format.new(
        nil,
        :font_only => 1,
        :bold      => 1
    )
    append(tmp_format.get_font)

    # Index 9. Comments.
    tmp_format = Writeexcel::Format.new(
        nil,
        :font_only => 1,
        :font      => 'Tahoma',
        :size      => 8
    )
    append(tmp_format.get_font)

    # Iterate through the XF objects and write a FONT record if it isn't the
    # same as the default FONT and if it hasn't already been used.
    #
    fonts = {}
    index = 10                   # The first user defined FONT

    key = format.get_font_key    # The default font for cell formats.
    fonts[key] = 0               # Index of the default font

    # Fonts that are marked as '_font_only' are always stored. These are used
    # mainly for charts and may not have an associated XF record.

    @formats.each do |fmt|
      key = fmt.get_font_key
      if fmt.font_only == 0 and !fonts[key].nil?
        # FONT has already been used
        fmt.font_index = fonts[key]
      else
        # Add a new FONT record

        if fmt.font_only == 0
          fonts[key] = index
        end

        fmt.font_index = index
        index += 1
        font = fmt.get_font
        append(font)
      end
    end
  end

  #
  # Store user defined numerical formats i.e. FORMAT records
  #
  def store_all_num_formats       #:nodoc:
    num_formats = {}
    index = 164       # User defined FORMAT records start from 0xA4

    # Iterate through the XF objects and write a FORMAT record if it isn't a
    # built-in format type and if the FORMAT string hasn't already been used.
    #
    @formats.each do |format|
      num_format = format.num_format
      encoding   = format.num_format_enc

      # Check if $num_format is an index to a built-in format.
      # Also check for a string of zeros, which is a valid format string
      # but would evaluate to zero.
      #
      unless num_format.to_s =~ /^0+\d/
        next if num_format.to_s =~ /^\d+$/   # built-in
      end

      if num_formats[num_format]
        # FORMAT has already been used
        format.num_format = num_formats[num_format]
      else
        # Add a new FORMAT
        num_formats[num_format] = index
        format.num_format       = index
        store_num_format(num_format, index, encoding)
        index += 1
      end
    end
  end

  #
  # Write all XF records.
  #
  def store_all_xfs       #:nodoc:
    @formats.each do |format|
      xf = format.get_xf
      append(xf)
    end
  end

  #
  # Write all STYLE records.
  #
  def store_all_styles       #:nodoc:
    # Excel adds the built-in styles in alphabetical order.
    built_ins = [
      [0x03, 16], # Comma
      [0x06, 17], # Comma[0]
      [0x04, 18], # Currency
      [0x07, 19], # Currency[0]
      [0x00,  0], # Normal
      [0x05, 20]  # Percent

      # We don't deal with these styles yet.
      #[0x08, 21], # Hyperlink
      #[0x02,  8], # ColLevel_n
      #[0x01,  1], # RowLevel_n
    ]

    built_ins.each do |aref|
      type     = aref[0]
      xf_index = aref[1]

      store_style(type, xf_index)
    end
  end

  #
  # Write the NAME record to define the print area and the repeat rows and cols.
  #
  def store_names  # :nodoc:
    # Create the user defined names.
    defined_names.each do |defined_name|
      store_name(
        defined_name[:name],
        defined_name[:encoding],
        defined_name[:sheet_index],
        defined_name[:formula]
      )
    end

    # Sort the worksheets into alphabetical order by name. This is a
    # requirement for some non-English language Excel patch levels.
    sorted_worksheets = @worksheets.sort_by{ |x| x.name }

    # Create the autofilter NAME records
    create_autofilter_name_records(sorted_worksheets)

    # Create the print area NAME records
    create_print_area_name_records(sorted_worksheets)

    # Create the print title NAME records
    create_print_title_name_records(sorted_worksheets)
  end

  def create_autofilter_name_records(sorted_worksheets)       #:nodoc:
    sorted_worksheets.each do |worksheet|
      append(*worksheet.autofilter_name_record_short(true))
    end
  end

  def create_print_area_name_records(sorted_worksheets)       #:nodoc:
    sorted_worksheets.each do |worksheet|
      append(*worksheet.print_area_name_record_short)
    end
  end

  def create_print_title_name_records(sorted_worksheets)       #:nodoc:
    sorted_worksheets.each do |worksheet|
      # Determine if row + col, row, col or nothing has been defined
      # and write the appropriate record
      #
      if worksheet.title_range.row_min && worksheet.title_range.col_min
        # Row and column titles have been defined.
        # Row title has been defined.
        append(*worksheet.print_title_name_record_long)
      elsif worksheet.title_range.row_min
        # Row title has been defined.
        append(*worksheet.print_title_name_record_short)
      elsif worksheet.title_range.col_min
        # Column title has been defined.
        append(*worksheet.print_title_name_record_short)
      else
        # Nothing left to do
      end
    end
  end

  ###############################################################################
  ###############################################################################
  #
  # BIFF RECORDS
  #


  #
  # Write Excel BIFF WINDOW1 record.
  #
  def store_window1       #:nodoc:
    record    = 0x003D                 # Record identifier
    length    = 0x0012                 # Number of bytes to follow

    x_pos     = 0x0000                 # Horizontal position of window
    y_pos     = 0x0000                 # Vertical position of window
    dx_win    = 0x355C                 # Width of window
    dy_win    = 0x30ED                 # Height of window

    grbit     = 0x0038                 # Option flags
    ctabsel   = @worksheets.selected_count  # Number of workbook tabs selected
    tab_ratio = 0x0258                 # Tab to scrollbar ratio

    tab_cur   = @worksheets.activesheet_index # Active worksheet
    tab_first = @worksheets.firstsheet_index  # 1st displayed worksheet
    header    = [record, length].pack("vv")
    data      = [
                  x_pos, y_pos, dx_win, dy_win,
                  grbit,
                  tab_cur, tab_first,
                  ctabsel, tab_ratio
                ].pack("vvvvvvvvv")

    append(header, data)
  end

  #
  # Writes Excel BIFF BOUNDSHEET record.
  #
  #    sheetname  # Worksheet name
  #    offset     # Location of worksheet BOF
  #    type       # Worksheet type
  #    hidden     # Worksheet hidden flag
  #    encoding   # Sheet name encoding
  #
  def store_boundsheet(sheet)       #:nodoc:
    append(sheet.boundsheet)
  end

  #
  # Write Excel BIFF STYLE records.
  #
  #    type        # Built-in style
  #    xf_index    # Index to style XF
  #
  def store_style(type, xf_index)       #:nodoc:
    record    = 0x0293    # Record identifier
    length    = 0x0004    # Bytes to follow

    level     = 0xff      # Outline style level

    xf_index    |= 0x8000 # Add flag to indicate built-in style.

    header    = [record, length].pack("vv")
    data      = [xf_index, type, level].pack("vCC")

    append(header, data)
  end

  #
  # Writes Excel FORMAT record for non "built-in" numerical formats.
  #
  #    format    # Custom format string
  #    ifmt      # Format index code
  #    encoding  # Char encoding for format string
  #
  def store_num_format(format, ifmt, encoding)       #:nodoc:
    format = format.to_s unless format.respond_to?(:to_str)
    record    = 0x041E         # Record identifier
    # length                   # Number of bytes to follow
    # Char length of format string
    cch = format.bytesize

    ruby_19 { format = convert_to_ascii_if_ascii(format) }

    # Handle utf8 strings
    if is_utf8?(format)
      format = utf8_to_16be(format)
      encoding = 1
      cch = format.bytesize
    end

    # Handle Unicode format strings.
    if encoding == 1
      raise "Uneven number of bytes in Unicode font name" if cch % 2 != 0
      cch /= 2 if encoding != 0
      format  = utf16be_to_16le(format)
    end

=begin
    # Special case to handle Euro symbol, 0x80, in non-Unicode strings.
    if encoding == 0 and format =~ /\x80/
      format   =  format.unpack('C*').pack('v*')
      format.gsub!(/\x80\x00/, "\xAC\x20")
      encoding =  1
    end
=end
    length    = 0x05 + format.bytesize

    header    = [record, length].pack("vv")
    data      = [ifmt, cch, encoding].pack("vvC")

    append(header, data, format)
  end

  #
  # Write Excel 1904 record to indicate the date system in use.
  #
  def store_1904       #:nodoc:
    record    = 0x0022         # Record identifier
    length    = 0x0002         # Bytes to follow

    f1904     = @date_1904 ? 1 : 0     # Flag for 1904 date system

    header    = [record, length].pack("vv")
    data      = [f1904].pack("v")

    append(header, data)
  end

  #
  # Write BIFF record SUPBOOK to indicate that the workbook contains external
  # references, in our case, formula, print area and print title refs.
  #
  def store_supbook       #:nodoc:
    record      = 0x01AE                   # Record identifier
    length      = 0x0004                   # Number of bytes to follow

    tabs        = @worksheets.size         # Number of worksheets
    virt_path   = 0x0401                   # Encoded workbook filename

    header    = [record, length].pack("vv")
    data      = [tabs, virt_path].pack("vv")

    append(header, data)
  end

  #
  # Writes the Excel BIFF EXTERNSHEET record. These references are used by
  # formulas. TODO NAME record is required to define the print area and the
  # repeat rows and columns.
  #
  def store_externsheet  # :nodoc:
    record      = 0x0017                   # Record identifier

    # Get the external refs

    ext = @ext_refs.keys.sort {|a, b| @ext_refs[a].to_i <=> @ext_refs[b].to_i}

    # Change the external refs from stringified "1:1" to [1, 1]
    ext.map! {|e| e.split(/:/).map! {|v| v.to_i} }

    cxti        = ext.size                 # Number of Excel XTI structures
    rgxti       = ''                       # Array of XTI structures

    # Write the XTI structs
    ext.each do |e|
      rgxti += [0, e[0], e[1]].pack("vvv")
    end

    data        = [cxti].pack("v") + rgxti
    header    = [record, data.bytesize].pack("vv")

    append(header, data)
  end

  #
  # Store the NAME record used for storing the print area, repeat rows, repeat
  # columns, autofilters and defined names.
  #
  # TODO. This is a more generic version that will replace store_name_short()
  #       and store_name_long().
  #
  def store_name(name, encoding, sheet_index, formula)  # :nodoc:
    ruby_19 { formula = convert_to_ascii_if_ascii(formula) }

    record          = 0x0018        # Record identifier

    text_length     = name.bytesize
    formula_length  = formula.bytesize

    # UTF-16 string length is in characters not bytes.
    text_length       /= 2 if encoding != 0

    grbit           = 0x0000        # Option flags
    shortcut        = 0x00          # Keyboard shortcut
    ixals           = 0x0000        # Unused index.
    menu_length     = 0x00          # Length of cust menu text
    desc_length     = 0x00          # Length of description text
    help_length     = 0x00          # Length of help topic text
    status_length   = 0x00          # Length of status bar text

    # Set grbit built-in flag and the hidden flag for autofilters.
    if text_length == 1
      grbit = 0x0020 if name.ord == 0x06  # Print area
      grbit = 0x0020 if name.ord == 0x07  # Print titles
      grbit = 0x0021 if name.ord == 0x0D  # Autofilter
    end

    data  = [grbit].pack("v")
    data += [shortcut].pack("C")
    data += [text_length].pack("C")
    data += [formula_length].pack("v")
    data += [ixals].pack("v")
    data += [sheet_index].pack("v")
    data += [menu_length].pack("C")
    data += [desc_length].pack("C")
    data += [help_length].pack("C")
    data += [status_length].pack("C")
    data += [encoding].pack("C")
    data += name
    data += formula

    header = [record, data.bytesize].pack("vv")

    append(header, data)
  end

  #
  # Stores the PALETTE biff record.
  #
  def store_palette       #:nodoc:
    record          = 0x0092                 # Record identifier
    length          = 2 + 4 * @palette.size  # Number of bytes to follow
    ccv             =         @palette.size  # Number of RGB values to follow
    data            = ''                     # The RGB data

    # Pack the RGB data
    @palette.each do |p|
      data += p.pack('CCCC')
    end

    header = [record, length, ccv].pack("vvv")

    append(header, data)
  end

  #
  # Stores the CODEPAGE biff record.
  #
  def store_codepage       #:nodoc:
    record          = 0x0042               # Record identifier
    length          = 0x0002               # Number of bytes to follow
    cv              = @codepage            # The code page

    store_common(record, length, cv)
  end

  #
  # Stores the COUNTRY biff record.
  #
  def store_country       #:nodoc:
    record          = 0x008C               # Record identifier
    length          = 0x0004               # Number of bytes to follow
    country_default = @country
    country_win_ini = @country

    store_common(record, length, country_default, country_win_ini)
  end

  #
  # Stores the HIDEOBJ biff record.
  #
  def store_hideobj       #:nodoc:
    record          = 0x008D               # Record identifier
    length          = 0x0002               # Number of bytes to follow
    hide            = @hideobj ? 1 : 0     # Option to hide objects

    store_common(record, length, hide)
  end

  def store_common(record, length, *data)       #:nodoc:
    header = [record, length].pack("vv")
    add_data   = [*data].pack("v*")

    append(header, add_data)
  end

  #
  # We need to calculate the space required by the SUPBOOK, EXTERNSHEET and NAME
  # records so that it can be added to the BOUNDSHEET offsets.
  #
  def calculate_extern_sizes  # :nodoc:
    ext_refs        = @parser.get_ext_sheets
    length          = 0
    index           = 0

    unless defined_names.empty?
      index   = 0
      key     = "#{index}:#{index}"

      add_ext_refs(ext_refs, key) unless ext_refs.has_key?(key)
    end

    defined_names.each do |defined_name|
      length += 19 + defined_name[:name].bytesize + defined_name[:formula].bytesize
    end

    @worksheets.each do |worksheet|
      key         = "#{index}:#{index}"
      index += 1

      # Add area NAME records
      #
      if worksheet.print_range.row_min
        add_ext_refs(ext_refs, key) unless ext_refs[key]
        length += 31
      end

      # Add title  NAME records
      #
      if worksheet.title_range.row_min && worksheet.title_range.col_min
        add_ext_refs(ext_refs, key) unless ext_refs[key]
        length += 46
      elsif worksheet.title_range.row_min || worksheet.title_range.col_min
        add_ext_refs(ext_refs, key) unless ext_refs[key]
        length += 31
      else
        # TODO, may need this later.
      end

      # Add Autofilter  NAME records
      #
      unless worksheet.filter_count == 0
        add_ext_refs(ext_refs, key) unless ext_refs[key]
        length += 31
      end
    end

    # Update the ref counts.
    ext_ref_count = ext_refs.keys.size
    @ext_refs      = ext_refs

    # If there are no external refs then we don't write, SUPBOOK, EXTERNSHEET
    # and NAME. Therefore the length is 0.

    return length = 0 if ext_ref_count == 0

    # The SUPBOOK record is 8 bytes
    length += 8

    # The EXTERNSHEET record is 6 bytes + 6 bytes for each external ref
    length += 6 * (1 + ext_ref_count)

    length
  end

  def add_ext_refs(ext_refs, key)       #:nodoc:
    ext_refs[key] = ext_refs.keys.size
  end

  #
  # Handling of the SST continue blocks is complicated by the need to include an
  # additional continuation byte depending on whether the string is split between
  # blocks or whether it starts at the beginning of the block. (There are also
  # additional complications that will arise later when/if Rich Strings are
  # supported). As such we cannot use the simple CONTINUE mechanism provided by
  # the add_continue() method in BIFFwriter.pm. Thus we have to make two passes
  # through the strings data. The first is to calculate the required block sizes
  # and the second, in store_shared_strings(), is to write the actual strings.
  # The first pass through the data is also used to calculate the size of the SST
  # and CONTINUE records for use in setting the BOUNDSHEET record offsets. The
  # downside of this is that the same algorithm repeated in store_shared_strings.
  #
  def calculate_shared_string_sizes       #:nodoc:
    str_block_sizes = @shared_string_table.block_sizes

    # Calculate the total length of the SST and associated CONTINUEs (if any).
    # The SST record will have a length even if it contains no strings.
    # This length is required to set the offsets in the BOUNDSHEET records since
    # they must be written before the SST records
    #
    # when array = [a, b, c]  # array not empty?
    # length = 12 + a + 4 + b + 4 + c = 12 + a + b + c + 4 * (array.size - 1)
    #
    length  = str_block_sizes.inject(12){|result, item| result + item}
    length += 4 * (str_block_sizes.size - 1) unless str_block_sizes.empty?

    length
  end

  def self.split_string_setup(encoding, split_string, continue_limit, written, continue)       #:nodoc:
    # We need to avoid the case where a string is continued in the first
    # n bytes that contain the string header information.
    header_length   = 3 # Min string + header size -1
    space_remaining = continue_limit - written - continue

    # Unicode data should only be split on char (2 byte) boundaries.
    # Therefore, in some cases we need to reduce the amount of available
    # space by 1 byte to ensure the correct alignment.
    align = 0

    # Only applies to Unicode strings
    if encoding == 1
      # Min string + header size -1
      header_length = 4
      if space_remaining > header_length
        # String contains 3 byte header => split on odd boundary
        if split_string == 0 and space_remaining % 2 != 1
          space_remaining -= 1
          align = 1
          # Split section without header => split on even boundary
        elsif split_string != 0 and space_remaining % 2 == 1
          space_remaining -= 1
          align = 1
        end
        split_string = 1
      end
    end
    [header_length, space_remaining, align, split_string]
  end

  def_delegator self, :split_string_setup

  #
  # Write all of the workbooks strings into an indexed array.
  #
  # See the comments in calculate_shared_string_sizes() for more information.
  #
  # We also use this routine to record the offsets required by the EXTSST table.
  # In order to do this we first identify the first string in an EXTSST bucket
  # and then store its global and local offset within the SST table. The offset
  # occurs wherever the start of the bucket string is written out via append().
  #
  def store_shared_strings       #:nodoc:
    record              = 0x00FC   # Record identifier
    length              = 0x0008   # Number of bytes to follow
    total               = 0x0000

    # Iterate through the strings to calculate the CONTINUE block sizes
    continue_limit = 8208
    block_length   = 0
    written        = 0
    continue       = 0

    # The SST and CONTINUE block sizes have been pre-calculated by
    # calculate_shared_string_sizes()
    block_sizes    = @shared_string_table.block_sizes

    # The SST record is required even if it contains no strings. Thus we will
    # always have a length
    #
    if block_sizes.size != 0
      length = 8 + block_sizes.shift
    else
      # No strings
      length = 8
    end

    # Initialise variables used to track EXTSST bucket offsets.
    extsst_str_num  = -1
    sst_block_start = @datasize

    # Write the SST block header information
    header      = [record, length].pack("vv")
    data        = [@shared_string_table.str_total, @shared_string_table.str_unique].pack("VV")
    append(header, data)

    # Iterate through the strings and write them out
    return if @shared_string_table.strings.empty?
    @shared_string_table.strings.each do |string|

      string_length = string.bytesize

      # Check if the string is at the start of a EXTSST bucket.
      extsst_str_num += 1
      # Used to track EXTSST bucket offsets.
      bucket_string = (extsst_str_num % @extsst_bucket_size == 0)

      # Block length is the total length of the strings that will be
      # written out in a single SST or CONTINUE block.
      #
      block_length += string_length

      # We can write the string if it doesn't cross a CONTINUE boundary
      if block_length < continue_limit

        # Store location of EXTSST bucket string.
        if bucket_string
          @extsst_offsets.push([@datasize, @datasize - sst_block_start])
          bucket_string = false
        end

        append(string)
        written += string_length
        next
      end

      # Deal with the cases where the next string to be written will exceed
      # the CONTINUE boundary. If the string is very long it may need to be
      # written in more than one CONTINUE record.
      encoding      = string.unpack("xx C")[0]
      split_string  = 0
      while block_length >= continue_limit
        header_length, space_remaining, align, split_string =
          split_string_setup(encoding, split_string, continue_limit, written, continue)

        if space_remaining > header_length
          # Write as much as possible of the string in the current block
          tmp = string[0, space_remaining]

          # Store location of EXTSST bucket string.
          if bucket_string
            @extsst_offsets.push([@datasize, @datasize - sst_block_start])
            bucket_string = false
          end

          append(tmp)

          # The remainder will be written in the next block(s)
          string = string[space_remaining .. string.length-1]

          # Reduce the current block length by the amount written
          block_length -= continue_limit -continue -align

          # If the current string was split then the next CONTINUE block
          # should have the string continue flag (grbit) set unless the
          # split string fits exactly into the remaining space.
          #
          if block_length > 0
            continue = 1
          else
            continue = 0
          end
        else
          # Not enough space to start the string in the current block
          block_length -= continue_limit -space_remaining -continue
          continue = 0
        end

        # Write the CONTINUE block header
        if block_sizes.size != 0
          sst_block_start= @datasize # Reset EXTSST offset.

          record         = 0x003C
          length         = block_sizes.shift

          header         = [record, length].pack("vv")
          header        += [encoding].pack("C") if continue != 0

          append(header)
        end

        # If the string (or substr) is small enough we can write it in the
        # new CONTINUE block. Else, go through the loop again to write it in
        # one or more CONTINUE blocks
        #
        if block_length < continue_limit

          # Store location of EXTSST bucket string.
          if bucket_string
            @extsst_offsets.push([@datasize, @datasize - sst_block_start])
            bucket_string = false
          end
          append(string)

          written = block_length
        else
          written = 0
        end
      end
    end
  end

  #
  # The number of buckets used in the EXTSST is between 0 and 128. The number of
  # strings per bucket (bucket size) has a minimum value of 8 and a theoretical
  # maximum of 2^16. For "number of strings" < 1024 there is a constant bucket
  # size of 8. The following algorithm generates the same size/bucket ratio
  # as Excel.
  #
  def calculate_extsst_size(str_unique)       #:nodoc:
    unique_strings  = str_unique

    if unique_strings < 1024
      bucket_size = 8
    else
      bucket_size = 1 + Integer(unique_strings / 128.0)
    end

    buckets = Integer((unique_strings + bucket_size -1)  / Float(bucket_size))

    @extsst_buckets        = buckets
    @extsst_bucket_size    = bucket_size

    6 + 8 * buckets
  end

  #
  # Write EXTSST table using the offsets calculated in store_shared_strings().
  #
  def store_extsst       #:nodoc:
    offsets     = @extsst_offsets
    bucket_size = @extsst_bucket_size

    record      = 0x00FF                 # Record identifier
    length      = 2 + 8 * offsets.size   # Bytes to follow

    header      = [record, length].pack('vv')
    data        = [bucket_size].pack('v')

    offsets.each do |offset|
      data += [offset[0], offset[1], 0].pack('Vvv')
    end

    append(header, data)
  end

  #
  # Methods related to comments and MSO objects.
  #

  #
  # Write the MSODRAWINGGROUP record that keeps track of the Escher drawing
  # objects in the file such as images, comments and filters.
  #
  def add_mso_drawing_group  #:nodoc:
    return unless @mso_size != 0

    record  = 0x00EB               # Record identifier
    length  = 0x0000               # Number of bytes to follow

    data    = store_mso_dgg_container
    data   += store_mso_dgg(*@mso_clusters)
    data   += store_mso_bstore_container
    @images_data.each do |image|
      data += store_mso_images(image)
    end
    data   += store_mso_opt
    data   += store_mso_split_menu_colors

    length  = data.bytesize
    header  = [record, length].pack("vv")

    add_mso_drawing_group_continue(header + data)

    header + data # For testing only.
  end

  #
  # See first BIFFwriter#add_continue() method.
  #
  # Add specialised CONTINUE headers to large MSODRAWINGGROUP data block.
  # We use the Excel 97 max block size of 8228 - 4 bytes for the header = 8224.
  #
  # The structure depends on the size of the data block:
  #
  #     Case 1:  <=   8224 bytes      1 MSODRAWINGGROUP
  #     Case 2:  <= 2*8224 bytes      1 MSODRAWINGGROUP + 1 CONTINUE
  #     Case 3:  >  2*8224 bytes      2 MSODRAWINGGROUP + n CONTINUE
  #
  def add_mso_drawing_group_continue(data)       #:nodoc:
    limit       = 8228 -4
    mso_group   = 0x00EB # Record identifier
    continue    = 0x003C # Record identifier
    block_count = 1

    # Ignore the base class add_continue() method.
    @ignore_continue = true

    # Case 1 above. Just return the data as it is.
    if data.bytesize <= limit
      append(data)
      return
    end

    # Change length field of the first MSODRAWINGGROUP block. Case 2 and 3.
    tmp, data = devide_string(data, limit + 4)
    tmp[2, 2] = [limit].pack('v')
    append(tmp)

    # Add MSODRAWINGGROUP and CONTINUE blocks for Case 3 above.
    while data.bytesize > limit
      if block_count == 1
        # Add extra MSODRAWINGGROUP block header.
        header = [mso_group, limit].pack("vv")
        block_count += 1
      else
        # Add normal CONTINUE header.
        header = [continue, limit].pack("vv")
      end

      tmp, data = devide_string(data, limit)
      append(header, tmp)
    end

    # Last CONTINUE block for remaining data. Case 2 and 3 above.
    header = [continue, data.bytesize].pack("vv")
    append(header, data)

    # Turn the base class add_continue() method back on.
    @ignore_continue = false
  end

  def devide_string(string, nth)       #:nodoc:
    first_string = string[0, nth]
    latter_string = string[nth, string.size - nth]
    [first_string, latter_string]
  end

  #
  # Write the Escher DggContainer record that is part of MSODRAWINGGROUP.
  #
  def store_mso_dgg_container       #:nodoc:
    type        = 0xF000
    version     = 15
    instance    = 0
    data        = ''
    length      = @mso_size -12 # -4 (biff header) -8 (for this).

    add_mso_generic(type, version, instance, data, length)
  end

  #
  # Write the Escher Dgg record that is part of MSODRAWINGGROUP.
  #
  def store_mso_dgg(max_spid, num_clusters, shapes_saved, drawings_saved, clusters)       #:nodoc:
    type            = 0xF006
    version         = 0
    instance        = 0
    data            = ''
    length          = nil  # Calculate automatically.

    data            = [max_spid, num_clusters,
    shapes_saved, drawings_saved].pack("VVVV")

    clusters.each do |aref|
      drawing_id      = aref[0]
      shape_ids_used  = aref[1]

      data           += [drawing_id, shape_ids_used].pack("VV")
    end

    add_mso_generic(type, version, instance, data, length)
  end

  #
  # Write the Escher BstoreContainer record that is part of MSODRAWINGGROUP.
  #
  def store_mso_bstore_container       #:nodoc:
    return '' if @images_size == 0

    type        = 0xF001
    version     = 15
    instance    = @images_data.size          # Number of images.
    data        = ''
    length      = @images_size +8 *instance

    add_mso_generic(type, version, instance, data, length)
  end

  #
  # Write the Escher BstoreContainer record that is part of MSODRAWINGGROUP.
  #
  def store_mso_images(image)
    blip_store_entry =  store_mso_blip_store_entry(
        image.ref_count, image.type, image.size, image.checksum1
      )

    blip             =  store_mso_blip(
        image.type, image.data, image.size, image.checksum1, image.checksum2
      )

    blip_store_entry + blip
  end

  #
  # Write the Escher BlipStoreEntry record that is part of MSODRAWINGGROUP.
  #
  def store_mso_blip_store_entry(ref_count, image_type, size, checksum1)       #:nodoc:
    type        = 0xF007
    version     = 2
    instance    = image_type
    length      = size +61
    data        = [image_type].pack('C')  +    # Win32
    [image_type].pack('C')  +    # Mac
    [checksum1].pack('H*')  +    # Uid checksum
    [0xFF].pack('v')        +    # Tag
    [size +25].pack('V')    +    # Next Blip size
    [ref_count].pack('V')   +    # Image ref count
    [0x00000000].pack('V')  +    # File offset
    [0x00].pack('C')        +    # Usage
    [0x00].pack('C')        +    # Name length
    [0x00].pack('C')        +    # Unused
    [0x00].pack('C')             # Unused

    add_mso_generic(type, version, instance, data, length)
  end

  #
  # Write the Escher Blip record that is part of MSODRAWINGGROUP.
  #
  def store_mso_blip(image_type, image_data, size, checksum1, checksum2)       #:nodoc:
    instance = 0x046A if image_type == 5 # JPG
    instance = 0x06E0 if image_type == 6 # PNG
    instance = 0x07A9 if image_type == 7 # BMP

    # BMPs contain an extra checksum for the stripped data.
    if image_type == 7
      checksum1 = checksum2 + checksum1
    end

    type        = 0xF018 + image_type
    version     = 0x0000
    length      = size +17
    data        = [checksum1].pack('H*')  +     # Uid checksum
    [0xFF].pack('C')        +     # Tag
    image_data                   # Image

    add_mso_generic(type, version, instance, data, length)
  end

  #
  # Write the Escher Opt record that is part of MSODRAWINGGROUP.
  #
  def store_mso_opt       #:nodoc:
    type        = 0xF00B
    version     = 3
    instance    = 3
    data        = ''
    length      = 18

    data        = ['BF0008000800810109000008C0014000'+'0008'].pack("H*")

    add_mso_generic(type, version, instance, data, length)
  end

  #
  # Write the Escher SplitMenuColors record that is part of MSODRAWINGGROUP.
  #
  def store_mso_split_menu_colors       #:nodoc:
    type        = 0xF11E
    version     = 0
    instance    = 4
    data        = ''
    length      = 16

    data        = ['0D0000080C00000817000008F7000010'].pack("H*")

    add_mso_generic(type, version, instance, data, length)
  end

  def cleanup       #:nodoc:
    super
    sheets.each { |sheet| sheet.cleanup }
  end

  def add_doc_properties
    @add_doc_properties ||= false
  end

  def defined_names
    @defined_names
  end
end
