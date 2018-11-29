#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

######################################################################
#
# Examples of formatting using the WriteExcel module
#
# reverse('©'), September 2002, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'writeexcel'


######################################################################
#
# Intro.
#
def intro(workbook)

    worksheet = workbook.add_worksheet('Introduction')

    worksheet.set_column(0, 0, 60)

    format = workbook.add_format()
    format.set_bold()
    format.set_size(14)
    format.set_color('blue')
    format.set_align('center')

    format2 = workbook.add_format()
    format2.set_bold()
    format2.set_color('blue')

    worksheet.write(2, 0, 'This workbook demonstrates some of',  format)
    worksheet.write(3, 0, 'the formatting options provided by',  format)
    worksheet.write(4, 0, 'the WriteExcel module.', format)

    worksheet.write('A7',  'Sections:', format2)
    worksheet.write('A8',  "internal:Fonts!A1",             'Fonts'          )
    worksheet.write('A9',  "internal:'Named colors'!A1",    'Named colors'   )
    worksheet.write('A10', "internal:'Standard colors'!A1", 'Standard colors')
    worksheet.write('A11', "internal:'Numeric formats'!A1", 'Numeric formats')
    worksheet.write('A12', "internal:Borders!A1",           'Borders'        )
    worksheet.write('A13', "internal:Patterns!A1",          'Patterns'       )
    worksheet.write('A14', "internal:Alignment!A1",         'Alignment'      )
    worksheet.write('A15', "internal:Miscellaneous!A1",     'Miscellaneous'  )

end


######################################################################
#
# Demonstrate the named colors.
#
def named_colors(workbook, heading, center)

    worksheet = workbook.add_worksheet('Named colors')

    worksheet.set_column(0, 3, 15)

    worksheet.write(0, 0, "Index", heading)
    worksheet.write(0, 1, "Index", heading)
    worksheet.write(0, 2, "Name",  heading)
    worksheet.write(0, 3, "Color", heading)

    i = 1

    COLORS.each do |index, color|
        format = workbook.add_format(
                                            :bg_color => color,
                                            :pattern  => 1,
                                            :border   => 1
                                         )

        worksheet.write(i+1, 0, index,                    center)
        worksheet.write(i+1, 1, sprintf("0x%02X", index), center)
        worksheet.write(i+1, 2, color,                    center)
        worksheet.write(i+1, 3, '',                       format)
        i += 1
    end
end


######################################################################
#
# Demonstrate the standard Excel colors in the range 8..63.
#
def standard_colors(workbook, heading, center)

    worksheet = workbook.add_worksheet('Standard colors')

    worksheet.set_column(0, 3, 15)

    worksheet.write(0, 0, "Index", heading)
    worksheet.write(0, 1, "Index", heading)
    worksheet.write(0, 2, "Color", heading)
    worksheet.write(0, 3, "Name",  heading)

    8.upto(63) do |i|
        format = workbook.add_format(
                                            :bg_color => i,
                                            :pattern  => 1,
                                            :border   => 1
                                         )

        worksheet.write((i -7), 0, i,                    center)
        worksheet.write((i -7), 1, sprintf("0x%02X", i), center)
        worksheet.write((i -7), 2, '',                   format)

        # Add the  color names
        if COLORS[i]
            worksheet.write((i -7), 3, COLORS[i], center)

        end
    end
end


######################################################################
#
# Demonstrate the standard numeric formats.
#
def numeric_formats(workbook, heading, center)

    worksheet = workbook.add_worksheet('Numeric formats')

    worksheet.set_column(0, 4, 15)
    worksheet.set_column(5, 5, 45)

    worksheet.write(0, 0, "Index",       heading)
    worksheet.write(0, 1, "Index",       heading)
    worksheet.write(0, 2, "Unformatted", heading)
    worksheet.write(0, 3, "Formatted",   heading)
    worksheet.write(0, 4, "Negative",    heading)
    worksheet.write(0, 5, "Format",      heading)

    formats = []
    formats.push([ 0x00, 1234.567,   0,         'General' ])
    formats.push([ 0x01, 1234.567,   0,         '0' ])
    formats.push([ 0x02, 1234.567,   0,         '0.00' ])
    formats.push([ 0x03, 1234.567,   0,         '#,##0' ])
    formats.push([ 0x04, 1234.567,   0,         '#,##0.00' ])
    formats.push([ 0x05, 1234.567,   -1234.567, '($#,##0_);($#,##0)' ])
    formats.push([ 0x06, 1234.567,   -1234.567, '($#,##0_);[Red]($#,##0)' ])
    formats.push([ 0x07, 1234.567,   -1234.567, '($#,##0.00_);($#,##0.00)' ])
    formats.push([ 0x08, 1234.567,   -1234.567, '($#,##0.00_);[Red]($#,##0.00)' ])
    formats.push([ 0x09, 0.567,      0,         '0%' ])
    formats.push([ 0x0a, 0.567,      0,         '0.00%' ])
    formats.push([ 0x0b, 1234.567,   0,         '0.00E+00' ])
    formats.push([ 0x0c, 0.75,       0,         '# ?/?' ])
    formats.push([ 0x0d, 0.3125,     0,         '# ??/??' ])
    formats.push([ 0x0e, 36892.521,  0,         'm/d/yy' ])
    formats.push([ 0x0f, 36892.521,  0,         'd-mmm-yy' ])
    formats.push([ 0x10, 36892.521,  0,         'd-mmm' ])
    formats.push([ 0x11, 36892.521,  0,         'mmm-yy' ])
    formats.push([ 0x12, 36892.521,  0,         'h:mm AM/PM' ])
    formats.push([ 0x13, 36892.521,  0,         'h:mm:ss AM/PM' ])
    formats.push([ 0x14, 36892.521,  0,         'h:mm' ])
    formats.push([ 0x15, 36892.521,  0,         'h:mm:ss' ])
    formats.push([ 0x16, 36892.521,  0,         'm/d/yy h:mm' ])
    formats.push([ 0x25, 1234.567,   -1234.567, '(#,##0_);(#,##0)' ])
    formats.push([ 0x26, 1234.567,   -1234.567, '(#,##0_);[Red](#,##0)' ])
    formats.push([ 0x27, 1234.567,   -1234.567, '(#,##0.00_);(#,##0.00)' ])
    formats.push([ 0x28, 1234.567,   -1234.567, '(#,##0.00_);[Red](#,##0.00)' ])
    formats.push([ 0x29, 1234.567,   -1234.567, '_(* #,##0_);_(* (#,##0);_(* "-"_);_(@_)' ])
    formats.push([ 0x2a, 1234.567,   -1234.567, '_($* #,##0_);_($* (#,##0);_($* "-"_);_(@_)' ])
    formats.push([ 0x2b, 1234.567,   -1234.567, '_(* #,##0.00_);_(* (#,##0.00);_(* "-"??_);_(@_)' ])
    formats.push([ 0x2c, 1234.567,   -1234.567, '_($* #,##0.00_);_($* (#,##0.00);_($* "-"??_);_(@_)' ])
    formats.push([ 0x2d, 36892.521,  0,         'mm:ss' ])
    formats.push([ 0x2e, 3.0153,     0,         '[h]:mm:ss' ])
    formats.push([ 0x2f, 36892.521,  0,         'mm:ss.0' ])
    formats.push([ 0x30, 1234.567,   0,         '##0.0E+0' ])
    formats.push([ 0x31, 1234.567,   0,         '@' ])

    i = 0
    formats.each do |format|
        style = workbook.add_format()
        style.set_num_format(format[0])

        i += 1
        worksheet.write(i, 0, format[0],                    center)
        worksheet.write(i, 1, sprintf("0x%02X", format[0]), center)
        worksheet.write(i, 2, format[1],                    center)
        worksheet.write(i, 3, format[1],                    style)

        if format[2] != 0
            worksheet.write(i, 4, format[2], style)
        end

        worksheet.write_string(i, 5, format[3])
    end
end


######################################################################
#
# Demonstrate the font options.
#
def fonts(workbook, heading, center)

    worksheet = workbook.add_worksheet('Fonts')

    worksheet.set_column(0, 0, 30)
    worksheet.set_column(1, 1, 10)

    worksheet.write(0, 0, "Font name",   heading)
    worksheet.write(0, 1, "Font size",   heading)

    fonts = []
    fonts.push([10, 'Arial' ])
    fonts.push([12, 'Arial' ])
    fonts.push([14, 'Arial' ])
    fonts.push([12, 'Arial Black' ])
    fonts.push([12, 'Arial Narrow' ])
    fonts.push([12, 'Century Schoolbook' ])
    fonts.push([12, 'Courier' ])
    fonts.push([12, 'Courier New' ])
    fonts.push([12, 'Garamond' ])
    fonts.push([12, 'Impact' ])
    fonts.push([12, 'Lucida Handwriting'] )
    fonts.push([12, 'Times New Roman' ])
    fonts.push([12, 'Symbol' ])
    fonts.push([12, 'Wingdings' ])
    fonts.push([12, 'A font that doesnt exist' ])

    i = 0
    fonts.each do |font|
        format = workbook.add_format()

        format.set_size(font[0])
        format.set_font(font[1])

        i += 1
        worksheet.write(i, 0, font[1], format)
        worksheet.write(i, 1, font[0], format)
    end

end


######################################################################
#
# Demonstrate the standard Excel border styles.
#
def borders(workbook, heading, center)

    worksheet = workbook.add_worksheet('Borders')

    worksheet.set_column(0, 4, 10)
    worksheet.set_column(5, 5, 40)

    worksheet.write(0, 0, "Index", heading)
    worksheet.write(0, 1, "Index", heading)
    worksheet.write(0, 3, "Style", heading)
    worksheet.write(0, 5, "The style is highlighted in red for ", heading)
    worksheet.write(1, 5, "emphasis, the default color is black.", heading)

    0.upto(13) do |i|
        format = workbook.add_format()
        format.set_border(i)
        format.set_border_color('red')
        format.set_align('center')

        worksheet.write((2*(i+1)), 0, i,                    center)
        worksheet.write((2*(i+1)), 1, sprintf("0x%02X", i), center)

        worksheet.write((2*(i+1)), 3, "Border", format)
    end

    worksheet.write(30, 0, "Diag type", heading)
    worksheet.write(30, 1, "Index", heading)
    worksheet.write(30, 3, "Style", heading)
    worksheet.write(30, 5, "Diagonal Boder styles", heading)

    1.upto(3) do |i|
        format = workbook.add_format()
        format.set_diag_type(i)
        format.set_diag_border(1)
        format.set_diag_color('red')
        format.set_align('center')

        worksheet.write((2*(i+15)), 0, i,                     center)
        worksheet.write((2*(i+15)), 1, sprintf("0x%02X", i),  center)

        worksheet.write((2*(i+15)), 3, "Border", format)
    end
end



######################################################################
#
# Demonstrate the standard Excel cell patterns.
#
def patterns(workbook, heading, center)

    worksheet = workbook.add_worksheet('Patterns')

    worksheet.set_column(0, 4, 10)
    worksheet.set_column(5, 5, 50)

    worksheet.write(0, 0, "Index", heading)
    worksheet.write(0, 1, "Index", heading)
    worksheet.write(0, 3, "Pattern", heading)

    worksheet.write(0, 5, "The background colour has been set to silver.", heading)
    worksheet.write(1, 5, "The foreground colour has been set to green.",  heading)

    0.upto(18) do |i|
        format = workbook.add_format()

        format.set_pattern(i)
        format.set_bg_color('silver')
        format.set_fg_color('green')
        format.set_align('center')

        worksheet.write((2*(i+1)), 0, i,                    center)
        worksheet.write((2*(i+1)), 1, sprintf("0x%02X", i), center)

        worksheet.write((2*(i+1)), 3, "Pattern", format)

        if i == 1
            worksheet.write((2*(i+1)), 5, "This is solid colour, the most useful pattern.", heading)
        end
    end
end


######################################################################
#
# Demonstrate the standard Excel cell alignments.
#
def alignment(workbook, heading, center)

    worksheet = workbook.add_worksheet('Alignment')

    worksheet.set_column(0, 7, 12)
    worksheet.set_row(0, 40)
    worksheet.set_selection(7, 0)

    format01 = workbook.add_format()
    format02 = workbook.add_format()
    format03 = workbook.add_format()
    format04 = workbook.add_format()
    format05 = workbook.add_format()
    format06 = workbook.add_format()
    format07 = workbook.add_format()
    format08 = workbook.add_format()
    format09 = workbook.add_format()
    format10 = workbook.add_format()
    format11 = workbook.add_format()
    format12 = workbook.add_format()
    format13 = workbook.add_format()
    format14 = workbook.add_format()
    format15 = workbook.add_format()
    format16 = workbook.add_format()
    format17 = workbook.add_format()

    format02.set_align('top')
    format03.set_align('bottom')
    format04.set_align('vcenter')
    format05.set_align('vjustify')
    format06.set_text_wrap()

    format07.set_align('left')
    format08.set_align('right')
    format09.set_align('center')
    format10.set_align('fill')
    format11.set_align('justify')
    format12.set_merge()

    format13.set_rotation(45)
    format14.set_rotation(-45)
    format15.set_rotation(270)

    format16.set_shrink()
    format17.set_indent(1)

    worksheet.write(0, 0, 'Vertical',     heading)
    worksheet.write(0, 1, 'top',          format02)
    worksheet.write(0, 2, 'bottom',       format03)
    worksheet.write(0, 3, 'vcenter',      format04)
    worksheet.write(0, 4, 'vjustify',     format05)
    worksheet.write(0, 5, "text\nwrap",   format06)

    worksheet.write(2, 0, 'Horizontal',   heading)
    worksheet.write(2, 1, 'left',         format07)
    worksheet.write(2, 2, 'right',        format08)
    worksheet.write(2, 3, 'center',       format09)
    worksheet.write(2, 4, 'fill',         format10)
    worksheet.write(2, 5, 'justify',      format11)

    worksheet.write(3, 1, 'merge',        format12)
    worksheet.write(3, 2, '',             format12)

    worksheet.write(3, 3, 'Shrink ' * 3,  format16)
    worksheet.write(3, 4, 'Indent',       format17)


    worksheet.write(5, 0, 'Rotation',     heading)
    worksheet.write(5, 1, 'Rotate 45',    format13)
    worksheet.write(6, 1, 'Rotate -45',   format14)
    worksheet.write(7, 1, 'Rotate 270',   format15)
end


######################################################################
#
# Demonstrate other miscellaneous features.
#
def misc(workbook)

    worksheet = workbook.add_worksheet('Miscellaneous')

    worksheet.set_column(2, 2, 25)

    format01 = workbook.add_format()
    format02 = workbook.add_format()
    format03 = workbook.add_format()
    format04 = workbook.add_format()
    format05 = workbook.add_format()
    format06 = workbook.add_format()
    format07 = workbook.add_format()

    format01.set_underline(0x01)
    format02.set_underline(0x02)
    format03.set_underline(0x21)
    format04.set_underline(0x22)
    format05.set_font_strikeout()
    format06.set_font_outline()
    format07.set_font_shadow()

    worksheet.write(1,  2, 'Underline  0x01',          format01)
    worksheet.write(3,  2, 'Underline  0x02',          format02)
    worksheet.write(5,  2, 'Underline  0x21',          format03)
    worksheet.write(7,  2, 'Underline  0x22',          format04)
    worksheet.write(9,  2, 'Strikeout',                format05)
    worksheet.write(11, 2, 'Outline (Macintosh only)', format06)
    worksheet.write(13, 2, 'Shadow (Macintosh only)',  format07)
end


######################################################################
#
# main
#
workbook = WriteExcel.new('formats.xls')

# Some common formats
center  = workbook.add_format(:align => 'center')
heading = workbook.add_format(:align => 'center', :bold => 1)

# The named colors
COLORS = {
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

# Call these subroutines to demonstrate different formatting options
intro(workbook)
fonts(workbook, heading, center)
named_colors(workbook, heading, center)
standard_colors(workbook, heading, center)
numeric_formats(workbook, heading, center)
borders(workbook, heading, center)
patterns(workbook, heading, center)
alignment(workbook, heading, center)
misc(workbook)

# Note: this is required
workbook.close

