module Writeexcel

class Worksheet < BIFFWriter
  require 'writeexcel/helper'

  class ColInfo
    #
    #   new(firstcol, lastcol, width, [format, hidden, level, collapsed])
    #
    #   firstcol : First formatted column
    #   lastcol  : Last formatted column
    #   width    : Col width in user units, 8.43 is default
    #   format   : format object
    #   hidden   : hidden flag
    #   level    : outline level
    #   collapsed : ?
    #
    def initialize(*args)
      @firstcol, @lastcol, @width, @format, @hidden, @level, @collapsed = args
      @width ||= 8.43  # default width
      @level ||= 0     # default level
    end

    # Write BIFF record COLINFO to define column widths
    #
    # Note: The SDK says the record length is 0x0B but Excel writes a 0x0C
    # length record.
    #
    def biff_record
      record   = 0x007D          # Record identifier
      length   = 0x000B          # Number of bytes to follow

      coldx    = (pixels * 256 / 7).to_i   # Col width in internal units
      reserved = 0x00                      # Reserved

      header = [record, length].pack("vv")
      data   = [@firstcol, @lastcol, coldx,
                ixfe, grbit, reserved].pack("vvvvvC")
      [header, data]
    end

    # Excel rounds the column width to the nearest pixel. Therefore we first
    # convert to pixels and then to the internal units. The pixel to users-units
    # relationship is different for values less than 1.
    #
    def pixels
      if @width < 1
        result = @width * 12
      else
        result = @width * 7 + 5
      end
      result.to_i
    end

    def ixfe
      if @format && @format.respond_to?(:xf_index)
        ixfe = @format.xf_index
      else
        ixfe = 0x0F
      end
    end

    # Set the limits for the outline levels (0 <= x <= 7).
    def level
      if @level < 0
        0
      elsif 7 < @level
        7
      else
        @level
      end
    end

    # Set the options flags. (See set_row() for more details).
    def grbit
      grbit    = 0x0000                    # Option flags
      grbit |= 0x0001 if @hidden && @hidden != 0
      grbit |= level << 8
      grbit |= 0x1000 if @collapsed && @collapsed != 0
      grbit
    end
  end
end

end
