# -*- coding: utf-8 -*-
##############################################################################
#
# Format - A class for defining Excel formatting.
#
#
# Used in conjunction with WriteExcel
#
# Copyright 2000-2010, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

#
# Format - A class for defining Excel formatting.
#
# See CELL FORMATTING, FORMAT METHODS, COLOURS IN EXCEL in WriteExcel's rdoc.
#
require 'writeexcel/compatibility'
require 'writeexcel/colors'

module Writeexcel

class Format < Colors
  require 'writeexcel/helper'

  #
  # Constructor
  #
  #    xf_index   :
  #    properties : Hash of property => value
  #
  def initialize(xf_index = 0, properties = {})   # :nodoc:
    @xf_index       = xf_index

    @type           = 0
    @font_index     = 0
    @font           = 'Arial'
    @size           = 10
    @bold           = 0x0190
    @italic         = 0
    @color          = 0x7FFF
    @underline      = 0
    @font_strikeout = 0
    @font_outline   = 0
    @font_shadow    = 0
    @font_script    = 0
    @font_family    = 0
    @font_charset   = 0
    @font_encoding  = 0

    @num_format     = 0
    @num_format_enc = 0

    @hidden         = 0
    @locked         = 1

    @text_h_align   = 0
    @text_wrap      = 0
    @text_v_align   = 2
    @text_justlast  = 0
    @rotation       = 0

    @fg_color       = 0x40
    @bg_color       = 0x41

    @pattern        = 0

    @bottom         = 0
    @top            = 0
    @left           = 0
    @right          = 0

    @bottom_color   = 0x40
    @top_color      = 0x40
    @left_color     = 0x40
    @right_color    = 0x40

    @indent         = 0
    @shrink         = 0
    @merge_range    = 0
    @reading_order  = 0

    @diag_type      = 0
    @diag_color     = 0x40
    @diag_border    = 0

    @font_only      = 0

    # Temp code to prevent merged formats in non-merged cells.
    @used_merge     = 0

    set_format_properties(properties) unless properties.empty?
  end


  #
  # :call-seq:
  #    copy(format)
  #
  # Copy the attributes of another Format object.
  #
  # This method is used to copy all of the properties from one Format object
  # to another:
  #
  #     lorry1 = workbook.add_format
  #     lorry1.set_bold
  #     lorry1.set_italic
  #     lorry1.set_color('red')     # lorry1 is bold, italic and red
  #
  #     lorry2 = workbook.add_format
  #     lorry2.copy(lorry1)
  #     lorry2.set_color('yellow')  # lorry2 is bold, italic and yellow
  #
  # The copy() method is only useful if you are using the method interface
  # to Format properties. It generally isn't required if you are setting
  # Format properties directly using hashes.
  #
  # Note: this is not a copy constructor, both objects must exist prior to
  # copying.
  #
  def copy(other)
    # copy properties except xf, merge_range, used_merge
    # Copy properties
    @type           = other.type
    @font_index     = other.font_index
    @font           = other.font
    @size           = other.size
    @bold           = other.bold
    @italic         = other.italic
    @color          = other.color
    @underline      = other.underline
    @font_strikeout = other.font_strikeout
    @font_outline   = other.font_outline
    @font_shadow    = other.font_shadow
    @font_script    = other.font_script
    @font_family    = other.font_family
    @font_charset   = other.font_charset
    @font_encoding  = other.font_encoding

    @num_format     = other.num_format
    @num_format_enc = other.num_format_enc

    @hidden         = other.hidden
    @locked         = other.locked

    @text_h_align   = other.text_h_align
    @text_wrap      = other.text_wrap
    @text_v_align   = other.text_v_align
    @text_justlast  = other.text_justlast
    @rotation       = other.rotation

    @fg_color       = other.fg_color
    @bg_color       = other.bg_color

    @pattern        = other.pattern

    @bottom         = other.bottom
    @top            = other.top
    @left           = other.left
    @right          = other.right

    @bottom_color   = other.bottom_color
    @top_color      = other.top_color
    @left_color     = other.left_color
    @right_color    = other.right_color

    @indent         = other.indent
    @shrink         = other.shrink
    @reading_order  = other.reading_order

    @diag_type      = other.diag_type
    @diag_color     = other.diag_color
    @diag_border    = other.diag_border

    @font_only      = other.font_only
  end

  #
  # Generate an Excel BIFF XF record.
  #
  def get_xf  # :nodoc:

    # Local Variable
    #    record;     # Record identifier
    #    length;     # Number of bytes to follow
    #
    #    ifnt;       # Index to FONT record
    #    ifmt;       # Index to FORMAT record
    #    style;      # Style and other options
    #    align;      # Alignment
    #    indent;     #
    #    icv;        # fg and bg pattern colors
    #    border1;    # Border line options
    #    border2;    # Border line options
    #    border3;    # Border line options

    # Set the type of the XF record and some of the attributes.
    if @type == 0xFFF5 then
      style = 0xFFF5
    else
      style  = @locked
      style |= @hidden << 1
    end

    # Flags to indicate if attributes have been set.
    atr_num  = (@num_format   != 0) ? 1 : 0
    atr_fnt  = (@font_index   != 0) ? 1 : 0
    atr_alc  = (@text_h_align != 0 ||
                @text_v_align != 2 ||
                @shrink       != 0 ||
                @merge_range  != 0 ||
                @text_wrap    != 0 ||
                @indent       != 0) ? 1 : 0
    atr_bdr  = (@bottom       != 0 ||
                @top          != 0 ||
                @left         != 0 ||
                @right        != 0 ||
                @diag_type    != 0) ? 1 : 0
    atr_pat  = (@fg_color     != 0x40 ||
                @bg_color     != 0x41 ||
                @pattern      != 0x00) ? 1 : 0
    atr_prot = (@hidden       != 0 ||
                @locked       != 1) ? 1 : 0

    # Set attribute changed flags for the style formats.
    if @xf_index != 0 and @type == 0xFFF5
      if @xf_index >= 16
        atr_num    = 0
        atr_fnt    = 1
      else
        atr_num    = 1
        atr_fnt    = 0
      end
      atr_alc    = 1
      atr_bdr    = 1
      atr_pat    = 1
      atr_prot   = 1
    end

    # Set a default diagonal border style if none was specified.
    @diag_border = 1 if (@diag_border ==0 and @diag_type != 0)

    # Reset the default colours for the non-font properties
    @fg_color     = 0x40 if @fg_color     == 0x7FFF
    @bg_color     = 0x41 if @bg_color     == 0x7FFF
    @bottom_color = 0x40 if @bottom_color == 0x7FFF
    @top_color    = 0x40 if @top_color    == 0x7FFF
    @left_color   = 0x40 if @left_color   == 0x7FFF
    @right_color  = 0x40 if @right_color  == 0x7FFF
    @diag_color   = 0x40 if @diag_color   == 0x7FFF

    # Zero the default border colour if the border has not been set.
    @bottom_color = 0 if @bottom    == 0
    @top_color    = 0 if @top       == 0
    @right_color  = 0 if @right     == 0
    @left_color   = 0 if @left      == 0
    @diag_color   = 0 if @diag_type == 0

    # The following 2 logical statements take care of special cases in relation
    # to cell colours and patterns:
    # 1. For a solid fill (_pattern == 1) Excel reverses the role of foreground
    #    and background colours.
    # 2. If the user specifies a foreground or background colour without a
    #    pattern they probably wanted a solid fill, so we fill in the defaults.
    #
    if (@pattern  <= 0x01 && @bg_color != 0x41 && @fg_color == 0x40)
      @fg_color = @bg_color
      @bg_color = 0x40
      @pattern  = 1
    end

    if (@pattern <= 0x01 && @bg_color == 0x41 && @fg_color != 0x40)
      @bg_color = 0x40
      @pattern  = 1
    end

    # Set default alignment if indent is set.
    @text_h_align = 1 if @indent != 0 and @text_h_align == 0


    record         = 0x00E0
    length         = 0x0014

    ifnt           = @font_index
    ifmt           = @num_format


    align          = @text_h_align
    align         |= @text_wrap     << 3
    align         |= @text_v_align  << 4
    align         |= @text_justlast << 7
    align         |= @rotation      << 8

    indent         = @indent
    indent        |= @shrink        << 4
    indent        |= @merge_range   << 5
    indent        |= @reading_order << 6
    indent        |= atr_num        << 10
    indent        |= atr_fnt        << 11
    indent        |= atr_alc        << 12
    indent        |= atr_bdr        << 13
    indent        |= atr_pat        << 14
    indent        |= atr_prot       << 15


    border1        = @left
    border1       |= @right         << 4
    border1       |= @top           << 8
    border1       |= @bottom        << 12

    border2        = @left_color
    border2       |= @right_color   << 7
    border2       |= @diag_type     << 14

    border3        = @top_color
    border3       |= @bottom_color  << 7
    border3       |= @diag_color    << 14
    border3       |= @diag_border   << 21
    border3       |= @pattern       << 26

    icv            = @fg_color
    icv           |= @bg_color      << 7

    header = [record, length].pack("vv")
    data   = [ifnt, ifmt, style, align, indent,
              border1, border2, border3, icv].pack("vvvvvvvVv")

    header + data
  end

  #
  # Generate an Excel BIFF FONT record.
  #
  def get_font  # :nodoc:

    #   my $record;     # Record identifier
    #   my $length;     # Record length

    #   my $dyHeight;   # Height of font (1/20 of a point)
    #   my $grbit;      # Font attributes
    #   my $icv;        # Index to color palette
    #   my $bls;        # Bold style
    #   my $sss;        # Superscript/subscript
    #   my $uls;        # Underline
    #   my $bFamily;    # Font family
    #   my $bCharSet;   # Character set
    #   my $reserved;   # Reserved
    #   my $cch;        # Length of font name
    #   my $rgch;       # Font name
    #   my $encoding;   # Font name character encoding


    dyHeight   = @size * 20
    icv        = @color
    bls        = @bold
    sss        = @font_script
    uls        = @underline
    bFamily    = @font_family
    bCharSet   = @font_charset
    rgch       = @font
    encoding   = @font_encoding

    ruby_19 { rgch = convert_to_ascii_if_ascii(rgch) }

    # Handle utf8 strings
    if is_utf8?(rgch)
      rgch = utf8_to_16be(rgch)
      encoding = 1
    end

    cch = rgch.bytesize
    #
    # Handle Unicode font names.
    if (encoding == 1)
      raise "Uneven number of bytes in Unicode font name" if cch % 2 != 0
      cch  /= 2 if encoding !=0
      rgch  = utf16be_to_16le(rgch)
    end

    record     = 0x31
    length     = 0x10 + rgch.bytesize
    reserved   = 0x00

    grbit      = 0x00
    grbit     |= 0x02 if @italic != 0
    grbit     |= 0x08 if @font_strikeout != 0
    grbit     |= 0x10 if @font_outline != 0
    grbit     |= 0x20 if @font_shadow != 0


    header = [record, length].pack("vv")
    data   = [dyHeight, grbit, icv, bls,
              sss, uls, bFamily,
              bCharSet, reserved, cch, encoding].pack('vvvvvCCCCCC')

    header + data + rgch
  end

  #
  # Returns a unique hash key for a font. Used by Workbook->_store_all_fonts()
  #
  def get_font_key  # :nodoc:
    # The following elements are arranged to increase the probability of
    # generating a unique key. Elements that hold a large range of numbers
    # e.g. _color are placed between two binary elements such as _italic

    key  = "#{@font}#{@size}#{@font_script}#{@underline}#{@font_strikeout}#{@bold}#{@font_outline}"
    key += "#{@font_family}#{@font_charset}#{@font_shadow}#{@color}#{@italic}#{@font_encoding}"
    key.gsub(' ', '_') # Convert the key to a single word
  end

  #
  # Returns the used by Worksheet->_XF()
  #
  def xf_index  # :nodoc:
    @xf_index
  end

  def used_merge  # :nodoc:
    @used_merge
  end

  def used_merge=(val)  # :nodoc:
    @used_merge = val
  end

  def type  # :nodoc:
    @type
  end

  def font_index  # :nodoc:
    @font_index
  end

  def font_index=(val)  # :nodoc:
    @font_index = val
  end

  def font  # :nodoc:
    @font
  end

  def size  # :nodoc:
    @size
  end

  def bold  # :nodoc:
    @bold
  end

  def italic  # :nodoc:
    @italic
  end

  def color  # :nodoc:
    @color
  end

  def underline  # :nodoc:
    @underline
  end

  def font_strikeout  # :nodoc:
    @font_strikeout
  end

  def font_outline  # :nodoc:
    @font_outline
  end

  def font_shadow  # :nodoc:
    @font_shadow
  end

  def font_script  # :nodoc:
    @font_script
  end

  def font_family  # :nodoc:
    @font_family
  end

  def font_charset  # :nodoc:
    @font_charset
  end

  def font_encoding  # :nodoc:
    @font_encoding
  end

  def num_format  # :nodoc:
    @num_format
  end

  def num_format=(val)  # :nodoc:
    @num_format = val
  end

  def num_format_enc  # :nodoc:
    @num_format_enc
  end

  def hidden  # :nodoc:
    @hidden
  end

  def locked  # :nodoc:
    @locked
  end

  def text_h_align  # :nodoc:
    @text_h_align
  end

  def text_wrap  # :nodoc:
    @text_wrap
  end

  def text_v_align  # :nodoc:
    @text_v_align
  end

  def text_justlast  # :nodoc:
    @text_justlast
  end

  def rotation  # :nodoc:
    @rotation
  end

  def fg_color  # :nodoc:
    @fg_color
  end

  def bg_color  # :nodoc:
    @bg_color
  end

  def pattern  # :nodoc:
    @pattern
  end

  def bottom  # :nodoc:
    @bottom
  end

  def top  # :nodoc:
    @top
  end

  def left  # :nodoc:
    @left
  end

  def right  # :nodoc:
    @right
  end

  def bottom_color  # :nodoc:
    @bottom_color
  end

  def top_color  # :nodoc:
    @top_color
  end

  def left_color  # :nodoc:
    @left_color
  end

  def right_color  # :nodoc:
    @right_color
  end

  def indent  # :nodoc:
    @indent
  end

  def shrink  # :nodoc:
    @shrink
  end

  def reading_order  # :nodoc:
    @reading_order
  end

  def diag_type  # :nodoc:
    @diag_type
  end

  def diag_color  # :nodoc:
    @diag_color
  end

  def diag_border  # :nodoc:
    @diag_border
  end

  def font_only  # :nodoc:
    @font_only
  end

  #
  #  used from Worksheet.rb
  #
  #  this is cut & copy of get_color().
  #
  def self._get_color(color)  # :nodoc:
    Colors.new.get_color(color)
  end

  #
  # Set the XF object type as 0 = cell XF or 0xFFF5 = style XF.
  #
  def set_type(type = nil)  # :nodoc:

    if !type.nil? and type == 0
      @type = 0x0000
    else
      @type = 0xFFF5
    end
  end

  #
  #     Default state:      Font size is 10
  #     Default action:     Set font size to 1
  #     Valid args:         Integer values from 1 to as big as your screen.
  #
  # Set the font size. Excel adjusts the height of a row to accommodate the
  # largest font size in the row. You can also explicitly specify the height
  # of a row using the set_row() worksheet method.
  #
  #     format = workbook.add_format
  #     format.set_size(30)
  #
  def set_size(size = 1)
   if size.respond_to?(:to_int) && size.respond_to?(:+) && size >= 1 # avoid Symbol
     @size = size.to_int
   end
  end

  #
  # Set the font colour.
  #
  #    Default state:      Excels default color, usually black
  #    Default action:     Set the default color
  #    Valid args:         Integers from 8..63 or the following strings:
  #                        'black', 'blue', 'brown', 'cyan', 'gray'
  #                        'green', 'lime', 'magenta', 'navy', 'orange'
  #                        'pink', 'purple', 'red', 'silver', 'white', 'yellow'
  #
  # The set_color() method is used as follows:
  #
  #    format = workbook.add_format()
  #    format.set_color('red')
  #    worksheet.write(0, 0, 'wheelbarrow', format)
  #
  # Note: The set_color() method is used to set the colour of the font in a cell.
  #       To set the colour of a cell use the set_bg_color()
  #       and set_pattern() methods.
  #
  def set_color(color = 0x7FFF)
    @color = get_color(color)
  end

  #
  # Set the italic property of the font:
  #
  #     Default state:      Italic is off
  #     Default action:     Turn italic on
  #     Valid args:         0, 1
  #
  #     format.set_italic    # Turn italic on
  #
  def set_italic(arg = 1)
    begin
      if    arg == 1  then @italic = 1   # italic on
      elsif arg == 0  then @italic = 0   # italic off
      else
        raise ArgumentError,
        "\n\n  set_italic(#{arg.inspect})\n    arg must be 0, 1, or none. ( 0:OFF , 1 and none:ON )\n"
      end
    end
  end

  #
  # Set the bold property of the font:
  #
  #     Default state:      bold is off
  #     Default action:     Turn bold on
  #     Valid args:         0, 1 [1]
  #
  #     format.set_bold()   # Turn bold on
  #
  # [1] Actually, values in the range 100..1000 are also valid. 400 is normal,
  # 700 is bold and 1000 is very bold indeed. It is probably best to set the
  # value to 1 and use normal bold.
  #
  def set_bold(weight = nil)

    if weight.nil?
      weight = 0x2BC
    elsif !weight.respond_to?(:to_int) || !weight.respond_to?(:+) # avoid Symbol
      weight = 0x190
    elsif weight == 1                       # Bold text
      weight = 0x2BC
    elsif weight == 0                       # Normal text
      weight = 0x190
    elsif weight <  0x064 || 0x3E8 < weight # Out bound
      weight = 0x190
    else
      weight = weight.to_i
    end

    @bold = weight
  end

  #
  # Set the underline property of the font.
  #
  #     Default state:      Underline is off
  #     Default action:     Turn on single underline
  #     Valid args:         0  = No underline
  #                         1  = Single underline
  #                         2  = Double underline
  #                         33 = Single accounting underline
  #                         34 = Double accounting underline
  #
  #     format.set_underline();   # Single underline
  #
  def set_underline(arg = 1)
    begin
      case arg
      when  0  then @underline =  0    # off
      when  1  then @underline =  1    # Single
      when  2  then @underline =  2    # Double
      when 33  then @underline = 33    # Single accounting
      when 34  then @underline = 34    # Double accounting
      else
        raise ArgumentError,
        "\n\n  set_underline(#{arg.inspect})\n    arg must be 0, 1, or none, 2, 33, 34.\n"
        " ( 0:OFF, 1 and none:Single, 2:Double, 33:Single accounting, 34:Double accounting )\n"
      end
    end
  end

  #
  # Set the strikeout property of the font.
  #
  #     Default state:      Strikeout is off
  #     Default action:     Turn strikeout on
  #     Valid args:         0, 1
  #
  def set_font_strikeout(arg = 1)
    begin
      if    arg == 0 then @font_strikeout = 0
      elsif arg == 1 then @font_strikeout = 1
      else
        raise ArgumentError,
        "\n\n  set_font_strikeout(#{arg.inspect})\n    arg must be 0, 1, or none.\n"
        " ( 0:OFF, 1 and none:Strikeout )\n"
      end
    end
  end

  #
  # Set the superscript/subscript property of the font.
  # This format is currently not very useful.
  #
  #     Default state:      Super/Subscript is off
  #     Default action:     Turn Superscript on
  #     Valid args:         0  = Normal
  #                         1  = Superscript
  #                         2  = Subscript
  #
  def set_font_script(arg = 1)
    begin
      if    arg == 0 then @font_script = 0
      elsif arg == 1 then @font_script = 1
      elsif arg == 2 then @font_script = 2
      else
        raise ArgumentError,
        "\n\n  set_font_script(#{arg.inspect})\n    arg must be 0, 1, or none. or 2\n"
        " ( 0:OFF, 1 and none:Superscript, 2:Subscript )\n"
      end
    end
  end

  #
  # Macintosh only.
  #
  #     Default state:      Outline is off
  #     Default action:     Turn outline on
  #     Valid args:         0, 1
  #
  def set_font_outline(arg = 1)
    begin
      if    arg == 0 then @font_outline = 0
      elsif arg == 1 then @font_outline = 1
      else
        raise ArgumentError,
        "\n\n  set_font_outline(#{arg.inspect})\n    arg must be 0, 1, or none.\n"
        " ( 0:OFF, 1 and none:outline on )\n"
      end
    end
  end

  #
  # Macintosh only.
  #
  #     Default state:      Shadow is off
  #     Default action:     Turn shadow on
  #     Valid args:         0, 1
  #
  def set_font_shadow(arg = 1)
    begin
      if    arg == 0 then @font_shadow = 0
      elsif arg == 1 then @font_shadow = 1
      else
        raise ArgumentError,
        "\n\n  set_font_shadow(#{arg.inspect})\n    arg must be 0, 1, or none.\n"
        " ( 0:OFF, 1 and none:shadow on )\n"
      end
    end
  end

  #
  # prevent modification of a cells contents.
  #
  #     Default state:      Cell locking is on
  #     Default action:     Turn locking on
  #     Valid args:         0, 1
  #
  # This property can be used to prevent modification of a cells contents.
  # Following Excel's convention, cell locking is turned on by default.
  # However, it only has an effect if the worksheet has been protected,
  # see the worksheet protect() method.
  #
  #     locked  = workbook.add_format()
  #     locked.set_locked(1) # A non-op
  #
  #     unlocked = workbook.add_format()
  #     locked.set_locked(0)
  #
  #     # Enable worksheet protection
  #     worksheet.protect()
  #
  #     # This cell cannot be edited.
  #     worksheet.write('A1', '=1+2', locked)
  #
  #     # This cell can be edited.
  #     worksheet.write('A2', '=1+2', unlocked)
  #
  # Note: This offers weak protection even with a password, see the note
  # in relation to the protect() method.
  #
  def set_locked(arg = 1)
    begin
      if    arg == 0 then @locked = 0
      elsif arg == 1 then @locked = 1
      else
        raise ArgumentError,
        "\n\n  set_locked(#{arg.inspect})\n    arg must be 0, 1, or none.\n"
        " ( 0:OFF, 1 and none:Lock On )\n"
      end
    end
  end

  #
  # hide a formula while still displaying its result.
  #
  #     Default state:      Formula hiding is off
  #     Default action:     Turn hiding on
  #     Valid args:         0, 1
  #
  # This property is used to hide a formula while still displaying
  # its result. This is generally used to hide complex calculations
  # from end users who are only interested in the result. It only has
  # an effect if the worksheet has been protected,
  # see the worksheet protect() method.
  #
  #     hidden = workbook.add_format
  #     hidden.set_hidden
  #
  #     # Enable worksheet protection
  #     worksheet.protect
  #
  #     # The formula in this cell isn't visible
  #     worksheet.write('A1', '=1+2', hidden)
  #
  # Note: This offers weak protection even with a password,
  #       see the note in relation to the protect() method  .
  #
  def set_hidden(arg = 1)
    begin
      if    arg == 0 then @hidden = 0
      elsif arg == 1 then @hidden = 1
      else
        raise ArgumentError,
        "\n\n  set_hidden(#{arg.inspect})\n    arg must be 0, 1, or none.\n"
        " ( 0:OFF, 1 and none:hiding On )\n"
      end
    end
  end

  #
  # Set cell alignment.
  #
  #     Default state:      Alignment is off
  #     Default action:     Left alignment
  #     Valid args:         'left'              Horizontal
  #                         'center'
  #                         'right'
  #                         'fill'
  #                         'justify'
  #                         'center_across'
  #
  #                         'top'               Vertical
  #                         'vcenter'
  #                         'bottom'
  #                         'vjustify'
  #
  # This method is used to set the horizontal and vertical text alignment
  # within a cell. Vertical and horizontal alignments can be combined.
  #  The method is used as follows:
  #
  #     format = workbook.add_format
  #     format->set_align('center')
  #     format->set_align('vcenter')
  #     worksheet->set_row(0, 30)
  #     worksheet->write(0, 0, 'X', format)
  #
  # Text can be aligned across two or more adjacent cells using
  # the center_across property. However, for genuine merged cells
  # it is better to use the merge_range() worksheet method.
  #
  # The vjustify (vertical justify) option can be used to provide
  # automatic text wrapping in a cell. The height of the cell will be
  # adjusted to accommodate the wrapped text. To specify where the text
  # wraps use the set_text_wrap() method.
  #
  # For further examples see the 'Alignment' worksheet created by formats.rb.
  #
  def set_align(align = 'left')
    case align.to_s.downcase
    when 'left'             then set_text_h_align(1)
    when 'centre', 'center' then set_text_h_align(2)
    when 'right'            then set_text_h_align(3)
    when 'fill'             then set_text_h_align(4)
    when 'justify'          then set_text_h_align(5)
    when 'center_across', 'centre_across' then set_text_h_align(6)
    when 'merge'            then set_text_h_align(6) # S:WE name
    when 'distributed'      then set_text_h_align(7)
    when 'equal_space'      then set_text_h_align(7) # ParseExcel

    when 'top'              then set_text_v_align(0)
    when 'vcentre'          then set_text_v_align(1)
    when 'vcenter'          then set_text_v_align(1)
    when 'bottom'           then set_text_v_align(2)
    when 'vjustify'         then set_text_v_align(3)
    when 'vdistributed'     then set_text_v_align(4)
    when 'vequal_space'     then set_text_v_align(4) # ParseExcel
    else nil
    end
  end

  #
  # Set vertical cell alignment. This is required by the set_format_properties()
  # method to differentiate between the vertical and horizontal properties.
  #
  def set_valign(alignment)  # :nodoc:
    set_align(alignment)
  end

  #
  # Implements the Excel5 style "merge".
  #
  #     Default state:      Center across selection is off
  #     Default action:     Turn center across on
  #     Valid args:         1
  #
  # Text can be aligned across two or more adjacent cells using the
  # set_center_across() method. This is an alias for the
  # set_align('center_across') method call.
  #
  # Only one cell should contain the text, the other cells should be blank:
  #
  #     format = workbook.add_format
  #     format.set_center_across
  #
  #     worksheet.write(1, 1, 'Center across selection', format)
  #     worksheet.write_blank(1, 2, format)
  #
  # See also the merge1.pl to merge6.rb programs in the examples directory and
  # the merge_range() method.
  #
  def set_center_across(arg = 1)
    set_text_h_align(6)
  end

  #
  # This was the way to implement a merge in Excel5. However it should have been
  # called "center_across" and not "merge".
  # This is now deprecated. Use set_center_across() or better merge_range().
  #
  #
  def set_merge(val=true)  # :nodoc:
    set_text_h_align(6)
  end

  #
  #    Default state:      Text wrap is off
  #    Default action:     Turn text wrap on
  #    Valid args:         0, 1
  #
  # Here is an example using the text wrap property, the escape
  # character \n is used to indicate the end of line:
  #
  #    format = workbook.add_format()
  #    format.set_text_wrap()
  #    worksheet.write(0, 0, "It's\na bum\nwrap", format)
  #
  def set_text_wrap(arg = 1)
    begin
      if    arg == 0 then @text_wrap = 0
      elsif arg == 1 then @text_wrap = 1
      else
        raise ArgumentError,
        "\n\n  set_text_wrap(#{arg.inspect})\n    arg must be 0, 1, or none.\n"
        " ( 0:OFF, 1 and none:text wrap On )\n"
      end
    end
  end

  #
  # Set cells borders to the same style
  #
  #     Also applies to:    set_bottom()
  #                         set_top()
  #                         set_left()
  #                         set_right()
  #
  #     Default state:      Border is off
  #     Default action:     Set border type 1
  #     Valid args:         0-13, See below.
  #
  # A cell border is comprised of a border on the bottom, top, left and right.
  # These can be set to the same value using set_border() or individually
  # using the relevant method calls shown above.
  #
  # The following shows the border styles sorted by WriteExcel index number:
  #
  #     Index   Name            Weight   Style
  #     =====   =============   ======   ===========
  #     0       None            0
  #     1       Continuous      1        -----------
  #     2       Continuous      2        -----------
  #     3       Dash            1        - - - - - -
  #     4       Dot             1        . . . . . .
  #     5       Continuous      3        -----------
  #     6       Double          3        ===========
  #     7       Continuous      0        -----------
  #     8       Dash            2        - - - - - -
  #     9       Dash Dot        1        - . - . - .
  #     10      Dash Dot        2        - . - . - .
  #     11      Dash Dot Dot    1        - . . - . .
  #     12      Dash Dot Dot    2        - . . - . .
  #     13      SlantDash Dot   2        / - . / - .
  #
  # The following shows the borders sorted by style:
  #
  #     Name            Weight   Style         Index
  #     =============   ======   ===========   =====
  #     Continuous      0        -----------   7
  #     Continuous      1        -----------   1
  #     Continuous      2        -----------   2
  #     Continuous      3        -----------   5
  #     Dash            1        - - - - - -   3
  #     Dash            2        - - - - - -   8
  #     Dash Dot        1        - . - . - .   9
  #     Dash Dot        2        - . - . - .   10
  #     Dash Dot Dot    1        - . . - . .   11
  #     Dash Dot Dot    2        - . . - . .   12
  #     Dot             1        . . . . . .   4
  #     Double          3        ===========   6
  #     None            0                      0
  #     SlantDash Dot   2        / - . / - .   13
  #
  # The following shows the borders in the order shown in the Excel Dialog.
  #
  #     Index   Style             Index   Style
  #     =====   =====             =====   =====
  #     0       None              12      - . . - . .
  #     7       -----------       13      / - . / - .
  #     4       . . . . . .       10      - . - . - .
  #     11      - . . - . .       8       - - - - - -
  #     9       - . - . - .       2       -----------
  #     3       - - - - - -       5       -----------
  #     1       -----------       6       ===========
  #
  # Examples of the available border styles are shown in the 'Borders' worksheet
  # created by formats.rb.
  #
  def set_border(style)
    set_bottom(style)
    set_top(style)
    set_left(style)
    set_right(style)
  end

  #
  # set bottom border of the cell.
  # see set_border() about style.
  #
  def set_bottom(style)
    @bottom = style
  end

  #
  # set top border of the cell.
  # see set_border() about style.
  #
  def set_top(style)
    @top = style
  end

  #
  # set left border of the cell.
  # see set_border() about style.
  #
  def set_left(style)
    @left = style
  end

  #
  # set right border of the cell.
  # see set_border() about style.
  #
  def set_right(style)
    @right = style
  end

  #
  # Set cells border to the same color
  #
  #     Also applies to:    set_bottom_color()
  #                         set_top_color()
  #                         set_left_color()
  #                         set_right_color()
  #
  #     Default state:      Color is off
  #     Default action:     Undefined
  #     Valid args:         See set_color()
  #
  # Set the colour of the cell borders. A cell border is comprised of a border
  # on the bottom, top, left and right. These can be set to the same colour
  # using set_border_color() or individually using the relevant method calls
  # shown above. Examples of the border styles and colours are shown in the
  # 'Borders' worksheet created by formats.rb.
  #
  def set_border_color(color)
    set_bottom_color(color)
    set_top_color(color)
    set_left_color(color)
    set_right_color(color)
  end

  #
  # set bottom border color of the cell.
  # see set_border_color() about color.
  #
  def set_bottom_color(color)
    @bottom_color = get_color(color)
  end

  #
  # set top border color of the cell.
  # see set_border_color() about color.
  #
  def set_top_color(color)
    @top_color = get_color(color)
  end

  #
  # set left border color of the cell.
  # see set_border_color() about color.
  #
  def set_left_color(color)
    @left_color = get_color(color)
  end

  #
  # set right border color of the cell.
  # see set_border_color() about color.
  #
  def set_right_color(color)
    @right_color = get_color(color)
  end

  #
  # Set the rotation angle of the text. An alignment property.
  #
  #     Default state:      Text rotation is off
  #     Default action:     None
  #     Valid args:         Integers in the range -90 to 90 and 270
  #
  # Set the rotation of the text in a cell. The rotation can be any angle in
  # the range -90 to 90 degrees.
  #
  #     format = workbook.add_format
  #     format.set_rotation(30)
  #     worksheet.write(0, 0, 'This text is rotated', format)
  #
  # The angle 270 is also supported. This indicates text where the letters run
  # from top to bottom.
  #
  def set_rotation(rotation)
    # The arg type can be a double but the Excel dialog only allows integers.
    rotation = rotation.to_i

    #      if (rotation == 270)
    #         rotation = 255
    #      elsif (rotation >= -90 or rotation <= 90)
    #         rotation = -rotation +90 if rotation < 0;
    #      else
    #         # carp "Rotation $rotation outside range: -90 <= angle <= 90";
    #         rotation = 0;
    #      end
    #
    if rotation == 270
      rotation = 255
    elsif rotation >= -90 && rotation <= 90
      rotation = -rotation + 90 if rotation < 0
    else
      rotation = 0
    end

    @rotation = rotation
  end


  #
  # :call-seq:
  #    set_format_properties( :bold => 1 [, :color => 'red'..] )
  #    set_format_properties( font [, shade, ..])
  #    set_format_properties( :bold => 1, font, ...)
  #      *) font  = { :color => 'red', :bold => 1 }
  #         shade = { :bg_color => 'green', :pattern => 1 }
  #
  # Convert hashes of properties to method calls.
  #
  # The properties of an existing Format object can be also be set by means
  # of set_format_properties():
  #
  #     format = workbook.add_format
  #     format.set_format_properties(:bold => 1, :color => 'red');
  #
  # However, this method is here mainly for legacy reasons. It is preferable
  # to set the properties in the format constructor:
  #
  #     format = workbook.add_format(:bold => 1, :color => 'red');
  #
  def set_format_properties(*properties)   # :nodoc:
    return if properties.empty?
    properties.each do |property|
      property.each do |key, value|
        # Strip leading "-" from Tk style properties e.g. "-color" => 'red'.
        key = key.sub(/^-/, '') if key.respond_to?(:to_str)

        # Create a sub to set the property.
        if value.respond_to?(:to_str) || !value.respond_to?(:+)
          s = "set_#{key}('#{value}')"
        else
          s = "set_#{key}(#{value})"
        end
        eval s
      end
    end
  end

  #
  #     Default state:      Font is Arial
  #     Default action:     None
  #     Valid args:         Any valid font name
  #
  # Specify the font used:
  #
  #     format.set_font('Times New Roman');
  #
  # Excel can only display fonts that are installed on the system that it is
  # running on. Therefore it is best to use the fonts that come as standard
  # such as 'Arial', 'Times New Roman' and 'Courier New'. See also the Fonts
  # worksheet created by formats.rb
  #
  def set_font(fontname)
    @font = fontname
  end

  #
  # This method is used to define the numerical format of a number in Excel.
  #
  #     Default state:      General format
  #     Default action:     Format index 1
  #     Valid args:         See the following table
  #
  # It controls whether a number is displayed as an integer, a floating point
  # number, a date, a currency value or some other user defined format.
  #
  # The numerical format of a cell can be specified by using a format string
  # or an index to one of Excel's built-in formats:
  #
  #     format1 = workbook.add_format
  #     format2 = workbook.add_format
  #     format1.set_num_format('d mmm yyyy')  # Format string
  #     format2.set_num_format(0x0f)          # Format index
  #
  #     worksheet.write(0, 0, 36892.521, format1)       # 1 Jan 2001
  #     worksheet.write(0, 0, 36892.521, format2)       # 1-Jan-01
  #
  # Using format strings you can define very sophisticated formatting of
  # numbers.
  #
  #     format01.set_num_format('0.000')
  #     worksheet.write(0,  0, 3.1415926, format01)     # 3.142
  #
  #     format02.set_num_format('#,##0')
  #     worksheet.write(1,  0, 1234.56,   format02)     # 1,235
  #
  #     format03.set_num_format('#,##0.00')
  #     worksheet.write(2,  0, 1234.56,   format03)     # 1,234.56
  #
  #     format04.set_num_format('0.00')
  #     worksheet.write(3,  0, 49.99,     format04)     # 49.99
  #
  #     # Note you can use other currency symbols such as the pound or yen as well.
  #     # Other currencies may require the use of Unicode.
  #
  #     format07.set_num_format('mm/dd/yy')
  #     worksheet.write(6,  0, 36892.521, format07)     # 01/01/01
  #
  #     format08.set_num_format('mmm d yyyy')
  #     worksheet.write(7,  0, 36892.521, format08)     # Jan 1 2001
  #
  #     format09.set_num_format('d mmmm yyyy')
  #     worksheet.write(8,  0, 36892.521, format09)     # 1 January 2001
  #
  #     format10.set_num_format('dd/mm/yyyy hh:mm AM/PM')
  #     worksheet.write(9,  0, 36892.521, format10)     # 01/01/2001 12:30 AM
  #
  #     format11.set_num_format('0 "dollar and" .00 "cents"')
  #     worksheet.write(10, 0, 1.87,      format11)     # 1 dollar and .87 cents
  #
  #     # Conditional formatting
  #     format12.set_num_format('[Green]General;[Red]-General;General')
  #     worksheet.write(11, 0, 123,       format12)     # > 0 Green
  #     worksheet.write(12, 0, -45,       format12)     # < 0 Red
  #     worksheet.write(13, 0, 0,         format12)     # = 0 Default colour
  #
  #     # Zip code
  #     format13.set_num_format('00000')
  #     worksheet.write(14, 0, '01209',   format13)
  #
  # The number system used for dates is described in "DATES AND TIME IN EXCEL".
  #
  # The colour format should have one of the following values:
  #
  #     [Black] [Blue] [Cyan] [Green] [Magenta] [Red] [White] [Yellow]
  #
  # Alternatively you can specify the colour based on a colour index as follows:
  # [Color n], where n is a standard Excel colour index - 7. See the
  # 'Standard colors' worksheet created by formats.rb.
  #
  # For more information refer to the documentation on formatting in the doc
  # directory of the WriteExcel distro, the Excel on-line help or
  # http://office.microsoft.com/en-gb/assistance/HP051995001033.aspx
  #
  # You should ensure that the format string is valid in Excel prior to using
  # it in WriteExcel.
  #
  # Excel's built-in formats are shown in the following table:
  #
  #     Index   Index   Format String
  #     0       0x00    General
  #     1       0x01    0
  #     2       0x02    0.00
  #     3       0x03    #,##0
  #     4       0x04    #,##0.00
  #     5       0x05    ($#,##0_);($#,##0)
  #     6       0x06    ($#,##0_);[Red]($#,##0)
  #     7       0x07    ($#,##0.00_);($#,##0.00)
  #     8       0x08    ($#,##0.00_);[Red]($#,##0.00)
  #     9       0x09    0%
  #     10      0x0a    0.00%
  #     11      0x0b    0.00E+00
  #     12      0x0c    # ?/?
  #     13      0x0d    # ??/??
  #     14      0x0e    m/d/yy
  #     15      0x0f    d-mmm-yy
  #     16      0x10    d-mmm
  #     17      0x11    mmm-yy
  #     18      0x12    h:mm AM/PM
  #     19      0x13    h:mm:ss AM/PM
  #     20      0x14    h:mm
  #     21      0x15    h:mm:ss
  #     22      0x16    m/d/yy h:mm
  #     ..      ....    ...........
  #     37      0x25    (#,##0_);(#,##0)
  #     38      0x26    (#,##0_);[Red](#,##0)
  #     39      0x27    (#,##0.00_);(#,##0.00)
  #     40      0x28    (#,##0.00_);[Red](#,##0.00)
  #     41      0x29    _(* #,##0_);_(* (#,##0);_(* "-"_);_(@_)
  #     42      0x2a    _($* #,##0_);_($* (#,##0);_($* "-"_);_(@_)
  #     43      0x2b    _(* #,##0.00_);_(* (#,##0.00);_(* "-"??_);_(@_)
  #     44      0x2c    _($* #,##0.00_);_($* (#,##0.00);_($* "-"??_);_(@_)
  #     45      0x2d    mm:ss
  #     46      0x2e    [h]:mm:ss
  #     47      0x2f    mm:ss.0
  #     48      0x30    ##0.0E+0
  #     49      0x31    @
  #
  # For examples of these formatting codes see the 'Numerical formats' worksheet
  # created by formats.rb.
  #--
  # See also the number_formats1.html and the number_formats2.html documents in
  # the doc directory of the distro.
  #++
  #
  # Note 1. Numeric formats 23 to 36 are not documented by Microsoft and may
  # differ in international versions.
  #
  # Note 2. In Excel 5 the dollar sign appears as a dollar sign. In Excel
  # 97-2000 it appears as the defined local currency symbol.
  #
  # Note 3. The red negative numeric formats display slightly differently in
  # Excel 5 and Excel 97-2000.
  #
  def set_num_format(num_format)
    @num_format = num_format
  end

  #
  # This method can be used to indent text. The argument, which should be an
  # integer, is taken as the level of indentation:
  #
  #     Default state:      Text indentation is off
  #     Default action:     Indent text 1 level
  #     Valid args:         Positive integers
  #
  #     format = workbook.add_format
  #     format.set_indent(2)
  #     worksheet.write(0, 0, 'This text is indented', format)
  #
  # Indentation is a horizontal alignment property. It will override any
  # other horizontal properties but it can be used in conjunction with
  # vertical properties.
  #
  def set_indent(indent = 1)
    @indent = indent
  end

  #
  # This method can be used to shrink text so that it fits in a cell.
  #
  #     Default state:      Text shrinking is off
  #     Default action:     Turn "shrink to fit" on
  #     Valid args:         1
  #
  #     format = workbook.add_format
  #     format.set_shrink
  #     worksheet.write(0, 0, 'Honey, I shrunk the text!', format)
  #
  def set_shrink(arg = 1)
    @shrink = 1
  end

  #
  #     Default state:      Justify last is off
  #     Default action:     Turn justify last on
  #     Valid args:         0, 1
  #
  # Only applies to Far Eastern versions of Excel.
  #
  def set_text_justlast(arg = 1)
    @text_justlast = 1
  end

  #
  #     Default state:      Pattern is off
  #     Default action:     Solid fill is on
  #     Valid args:         0 .. 18
  #
  # Set the background pattern of a cell.
  #
  # Examples of the available patterns are shown in the 'Patterns' worksheet
  # created by formats.rb. However, it is unlikely that you will ever need
  # anything other than Pattern 1 which is a solid fill of the background color.
  #
  def set_pattern(pattern = 1)
    @pattern = pattern
  end

  #
  # The set_bg_color() method can be used to set the background colour of a
  # pattern. Patterns are defined via the set_pattern() method. If a pattern
  # hasn't been defined then a solid fill pattern is used as the default.
  #
  #     Default state:      Color is off
  #     Default action:     Solid fill.
  #     Valid args:         See set_color()
  #
  # Here is an example of how to set up a solid fill in a cell:
  #
  #     format = workbook.add_format
  #
  #     format.set_pattern()  # This is optional when using a solid fill
  #
  #     format.set_bg_color('green')
  #     worksheet.write('A1', 'Ray', format)
  #
  # For further examples see the 'Patterns' worksheet created by formats.rb.
  #
  def set_bg_color(color = 0x41)
    @bg_color = get_color(color)
  end

  #
  # The set_fg_color() method can be used to set the foreground colour
  # of a pattern.
  #
  #     Default state:      Color is off
  #     Default action:     Solid fill.
  #     Valid args:         See set_color()
  #
  # For further examples see the 'Patterns' worksheet created by formats.rb.
  #
  def set_fg_color(color = 0x40)
    @fg_color = get_color(color)
  end

  # Dynamically create set methods that aren't already defined.
  def method_missing(name, *args)  # :nodoc:
    # -- original perl comment --
    # There are two types of set methods: set_property() and
    # set_property_color(). When a method is AUTOLOADED we store a new anonymous
    # sub in the appropriate slot in the symbol table. The speeds up subsequent
    # calls to the same method.

    method = "#{name}"

    # Check for a valid method names, i.e. "set_xxx_yyy".
    method =~ /set_(\w+)/ or raise "Unknown method: #{method}\n"

    # Match the attribute, i.e. "@xxx_yyy".
    attribute = "@#{$1}"

    # Check that the attribute exists
    # ........
    if method =~ /set\w+color$/    # for "set_property_color" methods
      value = get_color(args[0])
    else                            # for "set_xxx" methods
      value = args[0].nil? ? 1 : args[0]
    end
    if value.respond_to?(:to_str) || !value.respond_to?(:+)
      s = %Q!#{attribute} = "#{value.to_s}"!
    else
      s = %Q!#{attribute} =   #{value.to_s}!
    end
    eval s
  end
end  # class Format

end  # module Writeexcel

