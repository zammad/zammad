# -*- coding: utf-8 -*-
require 'helper'
require 'stringio'

class TC_Format < Test::Unit::TestCase

  TEST_DIR    = File.expand_path(File.dirname(__FILE__))
  PERL_OUTDIR = File.join(TEST_DIR, 'perl_output')

  def setup
    @ruby_file = StringIO.new
    @format = Writeexcel::Format.new
  end

  def test_set_format_properties
  end

  def test_format_properties_with_valid_value
    # set_format_properties( propty => val )
    valid_properties = get_valid_format_properties
    valid_properties.each do |k,v|
      fmt = Writeexcel::Format.new
      before = get_format_property(fmt)
      fmt.set_format_properties(k => v)
      after  = get_format_property(fmt)
      after.delete_if {|key, val| before[key] == val }
      assert_equal(1, after.size, "change 1 property[:#{k}] but #{after.size} was changed.#{after.inspect}")
      assert_equal(v, after[k], "[:#{k}] doesn't match.")
    end

    # set_format_properties( propty_1 => val1, propty_2 => val2)
    valid_properties.each do |k,v|
      fmt = Writeexcel::Format.new
      before = get_format_property(fmt)
      fmt.set_format_properties(k => v, :bold => 1)
      after  = get_format_property(fmt)
      after.delete_if {|key, val| before[key] == val }
      assert_equal(2, after.size, "change 1 property[:#{k}] but #{after.size} was changed.#{after.inspect}")
      assert_equal(v, after[k], "[:#{k}] doesn't match.")
      assert_equal(700, after[:bold])
    end

    # set_format_properties( hash_variable )
    valid_properties = get_valid_format_properties
    valid_properties.each do |k,v|
      arg = {k => v}
      fmt = Writeexcel::Format.new
      before = get_format_property(fmt)
      fmt.set_format_properties(arg)
      after  = get_format_property(fmt)
      after.delete_if {|key, val| before[key] == val }
      assert_equal(1, after.size, "change 1 property[:#{k}] but #{after.size} was changed.#{after.inspect}")
      assert_equal(v, after[k], "[:#{k}] doesn't match.")
    end

    # set_format_properties( hash_variable, hash_variable... )
    valid_properties = get_valid_format_properties
    valid_properties.each do |k,v|
      arg  = {k => v}
      arg2 = {:bold => 1}
      fmt = Writeexcel::Format.new
      before = get_format_property(fmt)
      fmt.set_format_properties(arg, arg2)
      after  = get_format_property(fmt)
      after.delete_if {|key, val| before[key] == val }
      assert_equal(2, after.size, "change 1 property[:#{k}] but #{after.size} was changed.#{after.inspect}")
      assert_equal(v, after[k], "[:#{k}] doesn't match.")
      assert_equal(700, after[:bold])
    end

    # set_color by string
    valid_color_string_number = get_valid_color_string_number
    [:color , :bg_color, :fg_color].each do |coltype|
      valid_color_string_number.each do |str, num|
        fmt = Writeexcel::Format.new
        before = get_format_property(fmt)
        fmt.set_format_properties(coltype => str)
        after  = get_format_property(fmt)
        after.delete_if {|key, val| before[key] == val }
        assert_equal(1, after.size, "change 1 property[:#{coltype}:#{str}] but #{after.size} was changed.#{after.inspect}")
        assert_equal(num, after[:"#{coltype}"], "[:#{coltype}:#{str}] doesn't match.")
      end
    end


  end

  def test_format_properties_with_invalid_value
  end

  def test_set_font
  end

=begin
set_size()
    Default state:      Font size is 10
    Default action:     Set font size to 1
    Valid args:         Integer values from 1 to as big as your screen.
Set the font size. Excel adjusts the height of a row to accommodate the largest font size in the row. You can also explicitly specify the height of a row using the set_row() worksheet method.
=end
  def test_set_size
    # default state
    assert_equal(10, @format.size)

    # valid size from low to high
    [1, 100, 100**10].each do |size|
      fmt = Writeexcel::Format.new
      fmt.set_size(size)
      assert_equal(size, fmt.size, "valid size:#{size} - doesn't match.")
    end

    # invalid size  -- size doesn't change
    [-1, 0, 1/2.0, 'hello', true, false, nil, [0,0], {:invalid => "val"}].each do |size|
      fmt = Writeexcel::Format.new
      default = fmt.size
      fmt.set_size(size)
      assert_equal(default, fmt.size, "size:#{size.inspect} doesn't match.")
    end
  end

=begin
set_color()

    Default state:      Excels default color, usually black
    Default action:     Set the default color
    Valid args:         Integers from 8..63 or the following strings:
                        'black'
                        'blue'
                        'brown'
                        'cyan'
                        'gray'
                        'green'
                        'lime'
                        'magenta'
                        'navy'
                        'orange'
                        'pink'
                        'purple'
                        'red'
                        'silver'
                        'white'
                        'yellow'

Set the font colour. The set_color() method is used as follows:

    format = workbook.add_format()
    format.set_color('red')
    worksheet.write(0, 0, 'wheelbarrow', format)

Note: The set_color() method is used to set the colour of the font in a cell.
To set the colour of a cell use the set_bg_color() and set_pattern() methods.
=end
  def test_set_color
    # default state
    default_col = 0x7FFF
    assert_equal(default_col, @format.color)

    # valid color
    # set by string
    str_num = get_valid_color_string_number
    str_num.each do |str,num|
      fmt = Writeexcel::Format.new
      fmt.set_color(str)
      assert_equal(num, fmt.color)
    end

    # valid color
    # set by number
    [8, 36, 63].each do |color|
      fmt = Writeexcel::Format.new
      fmt.set_color(color)
      assert_equal(color, fmt.color)
    end

    # invalid color
    ['color', :col, -1, 63.5, 10*10].each do |color|
      fmt = Writeexcel::Format.new
      fmt.set_color(color)
      assert_equal(default_col, fmt.color, "color : #{color}")
    end

    # invalid color    ...but...
    # 0 <= color < 8  then color += 8 in order to valid value
    [0, 7.5].each do |color|
      fmt = Writeexcel::Format.new
      fmt.set_color(color)
      assert_equal((color + 8).to_i, fmt.color, "color : #{color}")
    end


  end

=begin
set_bold()

    Default state:      bold is off  (internal value = 400)
    Default action:     Turn bold on
    Valid args:         0, 1 [1]

Set the bold property of the font:

    $format->set_bold();  # Turn bold on

[1] Actually, values in the range 100..1000 are also valid.
    400 is normal, 700 is bold and 1000 is very bold indeed.
    It is probably best to set the value to 1 and use normal bold.
=end

  def test_set_bold
    # default state
    assert_equal(400, @format.bold)

    # valid weight
    fmt = Writeexcel::Format.new
    fmt.set_bold
    assert_equal(700, fmt.bold)
    {0 => 400, 1 => 700, 100 => 100, 1000 => 1000}.each do |weight, value|
      fmt = Writeexcel::Format.new
      fmt.set_bold(weight)
      assert_equal(value, fmt.bold)
    end

    # invalid weight
    [-1, 99, 1001, 'bold'].each do |weight|
      fmt = Writeexcel::Format.new
      fmt.set_bold(weight)
      assert_equal(400, fmt.bold, "weight : #{weight}")
    end
  end

=begin
set_italic()

    Default state:      Italic is off
    Default action:     Turn italic on
    Valid args:         0, 1

 Set the italic property of the font:

    format.set_italic()  # Turn italic on
=end
  def test_set_italic
    # default state
    assert_equal(0, @format.italic)

    # valid arg
    fmt = Writeexcel::Format.new
    fmt.set_italic
    assert_equal(1, fmt.italic)
    {0=>0, 1=>1}.each do |arg,value|
      fmt = Writeexcel::Format.new
      fmt.set_italic(arg)
      assert_equal(value, fmt.italic, "arg : #{arg}")
    end

    # invalid arg
    [-1, 0.2, 100, 'italic', true, false, nil].each do |arg|
      assert_raise(ArgumentError,
      "set_italic(#{arg}) : invalid arg. arg must be 0, 1 or none."){
        fmt = Writeexcel::Format.new
        fmt.set_italic(arg)
      }
    end
  end

=begin
set_underline()

    Default state:      Underline is off
    Default action:     Turn on single underline
    Valid args:         0  = No underline
                        1  = Single underline
                        2  = Double underline
                        33 = Single accounting underline
                        34 = Double accounting underline

Set the underline property of the font.

    format.set_underline()   # Single underline
=end
  def test_set_underline
    # default state
    assert_equal(0, @format.underline, "default state")

    # valid args
    fmt = Writeexcel::Format.new
    fmt.set_underline
    assert_equal(1, fmt.underline, "No arg")

    [0, 1, 2, 33, 34].each do |arg|
      fmt = Writeexcel::Format.new
      fmt.set_underline(arg)
      assert_equal(arg, fmt.underline, "arg : #{arg}")
    end

    # invalid args
    [-1, 0.2, 100, 'under', true, false, nil].each do |arg|
      assert_raise(ArgumentError,
      "set_underline(#{arg}) : arg must be 0, 1 or none, 2, 33, 34."){
        fmt = Writeexcel::Format.new
        fmt.set_underline(arg)
      }
    end
  end

=begin
set_font_strikeout()

    Default state:      Strikeout is off
    Default action:     Turn strikeout on
    Valid args:         0, 1

Set the strikeout property of the font.
=end
  def test_set_font_strikeout
    # default state
    assert_equal(0, @format.font_strikeout, "default state")

    # valid args
    fmt = Writeexcel::Format.new
    fmt.set_font_strikeout
    assert_equal(1, fmt.font_strikeout, "No arg")

    [0, 1].each do |arg|
      fmt = Writeexcel::Format.new
      fmt.set_font_strikeout(arg)
      assert_equal(arg, fmt.font_strikeout, "arg : #{arg}")
    end

    # invalid args
    [-1, 0.2, 100, 'strikeout', true, false, nil].each do |arg|
      assert_raise(ArgumentError,
      "set_font_strikeout(#{arg}) : arg must be 0, 1 or none."){
        fmt = Writeexcel::Format.new
        fmt.set_font_strikeout(arg)
      }
    end
  end

=begin
set_font_script()

    Default state:      Super/Subscript is off
    Default action:     Turn Superscript on
    Valid args:         0  = Normal
                        1  = Superscript
                        2  = Subscript

Set the superscript/subscript property of the font. This format is currently not very useful.
=end
  def test_set_font_script
    # default state
    assert_equal(0, @format.font_script, "default state")

    # valid args
    fmt = Writeexcel::Format.new
    fmt.set_font_script
    assert_equal(1, fmt.font_script, "No arg")

    [0, 1, 2].each do |arg|
      fmt = Writeexcel::Format.new
      fmt.set_font_script(arg)
      assert_equal(arg, fmt.font_script, "arg : #{arg}")
    end

    # invalid args
    [-1, 0.2, 100, 'script', true, false, nil].each do |arg|
      assert_raise(ArgumentError,
      "set_font_script(#{arg}) : arg must be 0, 1 or none, or 2."){
        fmt = Writeexcel::Format.new
        fmt.set_font_script(arg)
      }
    end

  end

=begin
set_font_outline()

    Default state:      Outline is off
    Default action:     Turn outline on
    Valid args:         0, 1

Macintosh only.
=end
  def test_set_font_outline
    # default state
    assert_equal(0, @format.font_outline, "default state")

    # valid args
    fmt = Writeexcel::Format.new
    fmt.set_font_outline
    assert_equal(1, fmt.font_outline, "No arg")

    [0, 1].each do |arg|
      fmt = Writeexcel::Format.new
      fmt.set_font_outline(arg)
      assert_equal(arg, fmt.font_outline, "arg : #{arg}")
    end

    # invalid args
    [-1, 0.2, 100, 'outline', true, false, nil].each do |arg|
      assert_raise(ArgumentError,
      "set_font_outline(#{arg}) : arg must be 0, 1 or none."){
        fmt = Writeexcel::Format.new
        fmt.set_font_outline(arg)
      }
    end
  end

=begin
set_font_shadow()

    Default state:      Shadow is off
    Default action:     Turn shadow on
    Valid args:         0, 1

Macintosh only.
=end
  def test_set_font_shadow
    # default state
    assert_equal(0, @format.font_shadow, "default state")

    # valid args
    fmt = Writeexcel::Format.new
    fmt.set_font_shadow
    assert_equal(1, fmt.font_shadow, "No arg")

    [0, 1].each do |arg|
      fmt = Writeexcel::Format.new
      fmt.set_font_shadow(arg)
      assert_equal(arg, fmt.font_shadow, "arg : #{arg}")
    end

    # invalid args
    [-1, 0.2, 100, 'shadow', true, false, nil].each do |arg|
      assert_raise(ArgumentError,
      "set_font_shadow(#{arg}) : arg must be 0, 1 or none."){
        fmt = Writeexcel::Format.new
        fmt.set_font_shadow(arg)
      }
    end
  end

=begin
set_num_format()

    Default state:      General format
    Default action:     Format index 1
    Valid args:         See the following table

This method is used to define the numerical format of a number in Excel. It controls whether a number is displayed as an integer, a floating point number, a date, a currency value or some other user defined format.
=end
  def test_set_num_format
    # default state
    assert_equal(0, @format.num_format)

    # Excel built in Format Index (0 .. 49)
    [0, 49].each do |n|
      fmt = Writeexcel::Format.new
      fmt.set_num_format(n)
      assert_equal(n, fmt.num_format, "n: #{n}")
    end

    # Format string
    ["#,##0", "m/d/yy", "hh:mm:ss"].each do |string|
      fmt = Writeexcel::Format.new
      fmt.set_num_format(string)
      assert_equal(string, fmt.num_format, "string: #{string}")
    end
  end

=begin
set_locked()

    Default state:      Cell locking is on
    Default action:     Turn locking on
    Valid args:         0, 1

This property can be used to prevent modification of a cells
 contents. Following Excel's convention, cell locking is
 turned on by default. However, it only has an effect if
 the worksheet has been protected, see the worksheet protect()
  method.

    locked  = workbook.add_format()
    locked.set_locked(1)  # A non-op

    unlocked = workbook.add_format()
    locked.set_locked(0)

    # Enable worksheet protection
    worksheet.protect()

    # This cell cannot be edited.
    worksheet.write('A1', '=1+2', locked)

    # This cell can be edited.
    worksheet->write('A2', '=1+2', unlocked)

Note: This offers weak protection even with a password,
 see the note in relation to the protect() method.
=end
  def test_set_locked
    # default state
    assert_equal(1, @format.locked, "default state")

    # valid args
    fmt = Writeexcel::Format.new
    fmt.set_locked
    assert_equal(1, fmt.locked, "No arg")

    [0, 1].each do |arg|
      fmt = Writeexcel::Format.new
      fmt.set_locked(arg)
      assert_equal(arg, fmt.locked, "arg : #{arg}")
    end

    # invalid args
    [-1, 0.2, 100, 'locked', true, false, nil].each do |arg|
      assert_raise(ArgumentError,
      "set_font_shadow(#{arg}) : arg must be 0, 1 or none."){
        fmt = Writeexcel::Format.new
        fmt.set_locked(arg)
      }
    end
  end
=begin
set_hidden()

    Default state:      Formula hiding is off
    Default action:     Turn hiding on
    Valid args:         0, 1

This property is used to hide a formula while still displaying
 its result. This is generally used to hide complex calculations
 from end users who are only interested in the result.
 It only has an effect if the worksheet has been protected,
 see the worksheet protect() method.

    my hidden = workbook.add_format()
    hidden.set_hidden()

    # Enable worksheet protection
    worksheet.protect()

    # The formula in this cell isn't visible
    worksheet.write('A1', '=1+2', hidden)

Note: This offers weak protection even with a password,
 see the note in relation to the protect() method.
=end
  def test_set_hidden
    # default state
    assert_equal(0, @format.hidden, "default state")

    # valid args
    fmt = Writeexcel::Format.new
    fmt.set_hidden
    assert_equal(1, fmt.hidden, "No arg")

    [0, 1].each do |arg|
      fmt = Writeexcel::Format.new
      fmt.set_hidden(arg)
      assert_equal(arg, fmt.hidden, "arg : #{arg}")
    end

    # invalid args
    [-1, 0.2, 100, 'hidden', true, false, nil].each do |arg|
      assert_raise(ArgumentError,
      "set_font_shadow(#{arg}) : arg must be 0, 1 or none."){
        fmt = Writeexcel::Format.new
        fmt.set_hidden(arg)
      }
    end
  end

=begin
set_align()

    Default state:      Alignment is off
    Default action:     Left alignment
    Valid args:         'left'              Horizontal
                        'center'
                        'right'
                        'fill'
                        'justify'
                        'center_across'

                        'top'               Vertical
                        'vcenter'
                        'bottom'
                        'vjustify'

This method is used to set the horizontal and vertical text alignment
within a cell. Vertical and horizontal alignments can be combined.
 The method is used as follows:

    my $format = $workbook->add_format();
    $format->set_align('center');
    $format->set_align('vcenter');
    $worksheet->set_row(0, 30);
    $worksheet->write(0, 0, 'X', $format);

Text can be aligned across two or more adjacent cells using
the center_across property. However, for genuine merged cells
it is better to use the merge_range() worksheet method.

The vjustify (vertical justify) option can be used to provide
automatic text wrapping in a cell. The height of the cell will be
adjusted to accommodate the wrapped text. To specify where the text
wraps use the set_text_wrap() method.
=end
  def test_set_align
    # default state
    assert_equal(0, @format.text_h_align)
    assert_equal(2, @format.text_v_align)

    # valid arg
    valid_args = {'left'=>1, 'center'=>2, 'centre'=>2, 'right'=>3,
      'fill'=>4, 'justify'=>5, 'center_across'=>6,
      'centre_across'=>6, 'merge'=>6,
      'top'=>0, 'vcenter'=>1, 'vcentre'=>1, 'bottom'=>2,
    'vjustify'=>3 }
    valid_args.each do |arg, value|
      fmt = Writeexcel::Format.new
      fmt.set_align(arg)
      case arg
      when 'left', 'center', 'centre', 'right', 'fill', 'justify',
        'center_across', 'centre_across', 'merge'
        assert_equal(value, fmt.text_h_align, "arg: #{arg}")
      when 'top', 'vcenter', 'vcentre', 'bottom', 'vjustify'
        assert_equal(value, fmt.text_v_align, "arg: #{arg}")
      end
    end

    # invalid arg
    [-1, 0, 1.5, nil, true, false, ['left','top'], {'top'=>0}].each do |arg|
      fmt = Writeexcel::Format.new
      val = get_format_property(fmt)
      #print val.inspect
      #exit
      fmt.set_align(arg)
      assert_equal(val[:align], fmt.text_h_align, "arg: #{arg} - text_h_align changed.")
      assert_equal(val[:valign], fmt.text_v_align, "arg: #{arg} - text_v_align changed.")
    end
  end

=begin
set_center_across()

    Default state:      Center across selection is off
    Default action:     Turn center across on
    Valid args:         1

Text can be aligned across two or more adjacent cells
using the set_center_across() method. This is an alias
for the set_align('center_across') method call.

Only one cell should contain the text,
the other cells should be blank:

    format = workbook.add_format()
    format.set_center_across()

    worksheet.write(1, 1, 'Center across selection', format)
    worksheet.write_blank(1, 2, format)
=end
  def test_set_center_across
    # default state
    assert_equal(0, @format.text_h_align)

    # method call then center_across is set. if arg is none, numeric, string, whatever.
    @format.set_center_across
    assert_equal(6, @format.text_h_align)
  end

=begin
set_text_wrap()

    Default state:      Text wrap is off
    Default action:     Turn text wrap on
    Valid args:         0, 1

 Here is an example using the text wrap property, the escape
 character \n is used to indicate the end of line:

    format = workbook.add_format()
    format.set_text_wrap()
    worksheet.write(0, 0, "It's\na bum\nwrap", format)
=end
  def test_set_text_wrap
    # default state
    assert_equal(0, @format.text_wrap, "default state")

    # valid args
    fmt = Writeexcel::Format.new
    fmt.set_text_wrap
    assert_equal(1, fmt.text_wrap, "No arg")

    [0, 1].each do |arg|
      fmt = Writeexcel::Format.new
      fmt.set_text_wrap(arg)
      assert_equal(arg, fmt.text_wrap, "arg : #{arg}")
    end

    # invalid args
    [-1, 0.2, 100, 'text_wrap', true, false, nil].each do |arg|
      assert_raise(ArgumentError,
      "set_text_wrap(#{arg}) : arg must be 0, 1 or none."){
        fmt = Writeexcel::Format.new
        fmt.set_text_wrap(arg)
      }
    end
  end

=begin
set_rotation()

    Default state:      Text rotation is off
    Default action:     None
    Valid args:         Integers in the range -90 to 90 and 270

 Set the rotation of the text in a cell. The rotation can be
 any angle in the range -90 to 90 degrees.

    format = workbook.add_format()
    format.set_rotation(30)
    worksheet.write(0, 0, 'This text is rotated', format)

 The angle 270 is also supported. This indicates text where
 the letters run from top to bottom.
=end
  def test_set_rotation
    # default state
    assert_equal(0, @format.rotation)

    #      # valid args  -90 <= angle <=  90, 270   angle can be float or double
    #      [-90.0, 89, 0, 89, 90, 270].each do |angle|
    #         fmt = Writeexcel::Format.new
    #         fmt.set_rotation(angle)
    #         assert_equal(angle, fmt.rotation, "angle: #{angle}")
    #      end
  end

=begin
set_indent()

    Default state:      Text indentation is off
    Default action:     Indent text 1 level
    Valid args:         Positive integers

This method can be used to indent text. The argument, which should
be an integer, is taken as the level of indentation:

    format = workbook.add_format()
    format.set_indent(2)
    worksheet.write(0, 0, 'This text is indented', format)

Indentation is a horizontal alignment property. It will override
any other horizontal properties but it can be used in conjunction
with vertical properties.
=end
  def test_set_indent
    # default state
    assert_equal(0, @format.indent)

    # valid arg -- Positive integers
    [1, 10000000].each do |indent|
      fmt = Writeexcel::Format.new
      fmt.set_indent(indent)
      assert_equal(indent, fmt.indent, "indent: #{indent}")
    end

    # invalid arg
    [].each do |indent|

    end
  end

=begin
set_shrink()

    Default state:      Text shrinking is off
    Default action:     Turn "shrink to fit" on
    Valid args:         1

 This method can be used to shrink text so that it fits in a cell.

    format = workbook.add_format()
    format.set_shrink()
    worksheet.write(0, 0, 'Honey, I shrunk the text!', format)
=end
  def test_set_shrink
    # default state
    assert_equal(0, @format.shrink)
  end

=begin
set_text_justlast()

    Default state:      Justify last is off
    Default action:     Turn justify last on
    Valid args:         0, 1

Only applies to Far Eastern versions of Excel.
=end
  def test_set_text_justlast
    # default state
    assert_equal(0, @format.text_justlast)
  end

=begin
set_pattern()

    Default state:      Pattern is off
    Default action:     Solid fill is on
    Valid args:         0 .. 18

Set the background pattern of a cell.
=end
  def test_set_pattern
    # default state
    assert_equal(0, @format.pattern)
  end

=begin
set_bg_color()

    Default state:      Color is off
    Default action:     Solid fill.
    Valid args:         See set_color()

The set_bg_color() method can be used to set the background
colour of a pattern. Patterns are defined via the set_pattern()
method. If a pattern hasn't been defined then a solid fill
pattern is used as the default.

Here is an example of how to set up a solid fill in a cell:

    format = workbook.add_format()
    format.set_pattern() # This is optional when using a solid fill
    format.set_bg_color('green')
    worksheet.write('A1', 'Ray', format)
=end
  def test_set_bg_color
  end

=begin
set_fg_color()

    Default state:      Color is off
    Default action:     Solid fill.
    Valid args:         See set_color()

The set_fg_color() method can be used to set
 the foreground colour of a pattern.
=end
  def test_set_fg_color
  end

=begin
set_border()

    Also applies to:    set_bottom()
                        set_top()
                        set_left()
                        set_right()

    Default state:      Border is off
    Default action:     Set border type 1
    Valid args:         0-13, See below.

A cell border is comprised of a border on the bottom, top,
left and right. These can be set to the same value using
set_border() or individually using the relevant method
calls shown above.

The following shows the border styles sorted
by WriteExcel index number:

    Index   Name            Weight   Style
    =====   =============   ======   ===========
    0       None            0
    1       Continuous      1        -----------
    2       Continuous      2        -----------
    3       Dash            1        - - - - - -
    4       Dot             1        . . . . . .
    5       Continuous      3        -----------
    6       Double          3        ===========
    7       Continuous      0        -----------
    8       Dash            2        - - - - - -
    9       Dash Dot        1        - . - . - .
    10      Dash Dot        2        - . - . - .
    11      Dash Dot Dot    1        - . . - . .
    12      Dash Dot Dot    2        - . . - . .
    13      SlantDash Dot   2        / - . / - .

The following shows the borders sorted by style:

    Name            Weight   Style         Index
    =============   ======   ===========   =====
    Continuous      0        -----------   7
    Continuous      1        -----------   1
    Continuous      2        -----------   2
    Continuous      3        -----------   5
    Dash            1        - - - - - -   3
    Dash            2        - - - - - -   8
    Dash Dot        1        - . - . - .   9
    Dash Dot        2        - . - . - .   10
    Dash Dot Dot    1        - . . - . .   11
    Dash Dot Dot    2        - . . - . .   12
    Dot             1        . . . . . .   4
    Double          3        ===========   6
    None            0                      0
    SlantDash Dot   2        / - . / - .   13

The following shows the borders in the order shown in the Excel Dialog.

    Index   Style             Index   Style
    =====   =====             =====   =====
    0       None              12      - . . - . .
    7       -----------       13      / - . / - .
    4       . . . . . .       10      - . - . - .
    11      - . . - . .       8       - - - - - -
    9       - . - . - .       2       -----------
    3       - - - - - -       5       -----------
    1       -----------       6       ===========
=end
  def test_set_border
  end

=begin
set_border_color()

    Also applies to:    set_bottom_color()
                        set_top_color()
                        set_left_color()
                        set_right_color()

    Default state:      Color is off
    Default action:     Undefined
    Valid args:         See set_color()

Set the colour of the cell borders. A cell border is comprised of a border
on the bottom, top, left and right. These can be set to the same colour
using set_border_color() or individually using the relevant method
calls shown above.
=end
  def test_set_border_color
  end

=begin
copy($format)

This method is used to copy all of the properties
from one Format object to another:

    lorry1 = workbook.add_format()
    lorry1.set_bold()
    lorry1.set_italic()
    lorry1.set_color('red')    # lorry1 is bold, italic and red

    my lorry2 = workbook.add_format()
    lorry2.copy(lorry1)
    lorry2.set_color('yellow') # lorry2 is bold, italic and yellow

The copy() method is only useful if you are using the method interface
to Format properties. It generally isn't required if you are setting
Format properties directly using hashes.

Note: this is not a copy constructor, both objects must exist prior to copying.
=end

  def test_xf_biff_size
    perl_file = "#{PERL_OUTDIR}/file_xf_biff"
    size = File.size(perl_file)
    @ruby_file.print(@format.get_xf)
    rsize = @ruby_file.size
    assert_equal(size, rsize, "File sizes not the same")
  end

  # Because of the modifications to bg_color and fg_color, I know this
  # test will fail.  This is ok.
  #def test_xf_biff_contents
  #   perl_file = "perl_output/f_xf_biff"
  #   @fh = File.new(@ruby_file,"w+")
  #   @fh.print(@format.xf_biff)
  #   @fh.close
  #   contents = IO.readlines(perl_file)
  #   rcontents = IO.readlines(@ruby_file)
  #   assert_equal(contents,rcontents,"Contents not the same")
  #end

  def test_font_biff_size
    perl_file = "#{PERL_OUTDIR}/file_font_biff"
    @ruby_file.print(@format.get_font)
    contents = IO.readlines(perl_file)
    @ruby_file.rewind
    rcontents = @ruby_file.readlines
    assert_equal(contents, rcontents, "Contents not the same")
  end

  def test_font_biff_contents
    perl_file = "#{PERL_OUTDIR}/file_font_biff"
    @ruby_file.print(@format.get_font)
    contents  = IO.readlines(perl_file)
    @ruby_file.rewind
    rcontents = @ruby_file.readlines
    assert_equal(contents, rcontents, "Contents not the same")
  end

  def test_get_font_key_size
    perl_file = "#{PERL_OUTDIR}/file_font_key"
    @ruby_file.print(@format.get_font_key)
    assert_equal(File.size(perl_file), @ruby_file.size, "Bad file size")
  end

  def test_get_font_key_contents
    perl_file = "#{PERL_OUTDIR}/file_font_key"
    @ruby_file.print(@format.get_font_key)
    contents  = IO.readlines(perl_file)
    @ruby_file.rewind
    rcontents = @ruby_file.readlines
    assert_equal(contents, rcontents, "Contents not the same")
  end

  def test_initialize
    assert_nothing_raised {
      Writeexcel::Format.new(
        :bold => true,
        :size => 10,
        :color => 'black',
        :fg_color => 43,
        :align => 'top',
        :text_wrap => true,
        :border => 1
      )
    }
  end

  # added by Nakamura

  def test_get_xf
    perl_file = "#{PERL_OUTDIR}/file_xf_biff"
    size = File.size(perl_file)
    @ruby_file.print(@format.get_xf)
    rsize = @ruby_file.size
    assert_equal(size, rsize, "File sizes not the same")

    compare_file(perl_file, @ruby_file)
  end

  def test_get_font
    perl_file = "#{PERL_OUTDIR}/file_font_biff"
    size = File.size(perl_file)
    @ruby_file.print(@format.get_font)
    rsize = @ruby_file.size
    assert_equal(size, rsize, "File sizes not the same")

    compare_file(perl_file, @ruby_file)
  end

  def test_get_font_key
    perl_file = "#{PERL_OUTDIR}/file_font_key"
    size = File.size(perl_file)
    @ruby_file.print(@format.get_font_key)
    rsize = @ruby_file.size
    assert_equal(size, rsize, "File sizes not the same")

    compare_file(perl_file, @ruby_file)
  end

  def test_copy
    format1 = Writeexcel::Format.new
    format2 = Writeexcel::Format.new

    format1.set_size(12)

    format2.copy(format1)

    assert_equal(format1.size, format2.size)
  end


  # -----------------------------------------------------------------------------

  def get_valid_format_properties
    {
      :font           => 'Times New Roman',
      :size           => 30,
      :color          => 8,
      :italic         => 1,
      :underline      => 1,
      :font_strikeout => 1,
      :font_script    => 1,
      :font_outline   => 1,
      :font_shadow    => 1,
      :locked         => 0,
      :hidden         => 1,
      :text_wrap      => 1,
      :text_justlast  => 1,
      :indent         => 2,
      :shrink         => 1,
      :pattern        => 18,
      :bg_color       => 30,
      :fg_color       => 63
    }
  end

  def get_valid_color_string_number
    {
      :black     =>    8,
      :blue      =>   12,
      :brown     =>   16,
      :cyan      =>   15,
      :gray      =>   23,
      :green     =>   17,
      :lime      =>   11,
      :magenta   =>   14,
      :navy      =>   18,
      :orange    =>   53,
      :pink      =>   33,
      :purple    =>   20,
      :red       =>   10,
      :silver    =>   22,
      :white     =>    9,
      :yellow    =>   13
    }
  end
  #         :rotation => -90,
  #         :center_across => 1,
  #         :align => 'left',

  def get_format_property(format)
    text_h_align = {
      1 => 'left',
      2 => 'center/centre',
      3 => 'right',
      4 => 'fill',
      5 => 'justiry',
      6 => 'center_across/centre_across/merge',
      7 => 'distributed/equal_space'
    }

    text_v_align = {
      0 => 'top',
      1 => 'vcenter/vcentre',
      2 => 'bottom',
      3 => 'vjustify',
      4 => 'vdistributed/vequal_space'
    }

    return {
      :font                => format.font,
      :size                => format.size,
      :color               => format.color,
      :bold                => format.bold,
      :italic              => format.italic,
      :underline           => format.underline,
      :font_strikeout      => format.font_strikeout,
      :font_script         => format.font_script,
      :font_outline        => format.font_outline,
      :font_shadow         => format.font_shadow,
      :num_format          => format.num_format,
      :locked              => format.locked,
      :hidden              => format.hidden,
      :align               => format.text_h_align,
      :valign              => format.text_v_align,
      :rotation            => format.rotation,
      :text_wrap           => format.text_wrap,
      :text_justlast       => format.text_justlast,
      :center_across       => format.text_h_align,
      :indent              => format.indent,
      :shrink              => format.shrink,
      :pattern             => format.pattern,
      :bg_color            => format.bg_color,
      :fg_color            => format.fg_color,
      :bottom              => format.bottom,
      :top                 => format.top,
      :left                => format.left,
      :right               => format.right,
      :bottom_color        => format.bottom_color,
      :top_color           => format.top_color,
      :left_color          => format.left_color,
      :right_color         => format.right_color
    }
  end
end
