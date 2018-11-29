# -*- coding: utf-8 -*-

module Writeexcel

class Colors
  COLORS = {
    :aqua    => 0x0F,
    :cyan    => 0x0F,
    :black   => 0x08,
    :blue    => 0x0C,
    :brown   => 0x10,
    :magenta => 0x0E,
    :fuchsia => 0x0E,
    :gray    => 0x17,
    :grey    => 0x17,
    :green   => 0x11,
    :lime    => 0x0B,
    :navy    => 0x12,
    :orange  => 0x35,
    :pink    => 0x21,
    :purple  => 0x14,
    :red     => 0x0A,
    :silver  => 0x16,
    :white   => 0x09,
    :yellow  => 0x0D,
  }   # :nodoc:

  ###############################################################################
  #
  # get_color(colour)
  #
  # Used in conjunction with the set_xxx_color methods to convert a color
  # string into a number. Color range is 0..63 but we will restrict it
  # to 8..63 to comply with Gnumeric. Colors 0..7 are repeated in 8..15.
  #
  def get_color(color = nil) # :nodoc:
    if color.respond_to?(:to_int) && color.respond_to?(:+)
      # the default color if arg is outside range,
      if color < 0 || 63 < color
        0x7FFF
      # or an index < 8 mapped into the correct range,
      elsif color < 8
        (color + 8).to_i
      # or an integer in the valid range
      else
        color.to_i
      end
    elsif color.respond_to?(:to_sym)
      color = color.downcase.to_sym if color.respond_to?(:to_str)
      # or the color string converted to an integer,
      if COLORS.has_key?(color)
        COLORS[color]
      # or the default color if string is unrecognised,
      else
        0x7FFF
      end
    else
      0x7FFF
    end
  end

  def inspect
    to_s
  end
end  # class Colors

end  # module Writeexcel

