# -*- coding: utf-8 -*-
###############################################################################
#
# Properties - A module for creating Excel property sets.
#
#
# Used in conjunction with WriteExcel
#
# Copyright 2000-2010, John McNamara.
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#

require 'date'

###############################################################################
#
# create_summary_property_set().
#
# Create the SummaryInformation property set. This is mainly used for the
# Title, Subject, Author, Keywords, Comments, Last author keywords and the
# creation date.
#
def create_summary_property_set(properties)       #:nodoc:
    byte_order          = [0xFFFE].pack('v')
    version             = [0x0000].pack('v')
    system_id           = [0x00020105].pack('V')
    class_id            = ['00000000000000000000000000000000'].pack('H*')
    num_property_sets   = [0x0001].pack('V')
    format_id           = ['E0859FF2F94F6810AB9108002B27B3D9'].pack('H*')
    offset              = [0x0030].pack('V')
    num_property        = [properties.size].pack('V')
    property_offsets    = ''

    # Create the property set data block and calculate the offsets into it.
    property_data, offsets = pack_property_data(properties)

    # Create the property type and offsets based on the previous calculation.
    0.upto(properties.size - 1) do |i|
      property_offsets += [properties[i][0], offsets[i]].pack('VV')
    end

    # Size of size (4 bytes) +  num_property (4 bytes) + the data structures.
    size = 8 + (property_offsets).bytesize + property_data.bytesize
    size = [size].pack('V')

    byte_order         +
    version            +
    system_id          +
    class_id           +
    num_property_sets  +
    format_id          +
    offset             +
    size               +
    num_property       +
    property_offsets   +
    property_data
end


###############################################################################
#
# Create the DocSummaryInformation property set. This is mainly used for the
# Manager, Company and Category keywords.
#
# The DocSummary also contains a stream for user defined properties. However
# this is a little arcane and probably not worth the implementation effort.
#
def create_doc_summary_property_set(properties)       #:nodoc:
    byte_order          = [0xFFFE].pack('v')
    version             = [0x0000].pack('v')
    system_id           = [0x00020105].pack('V')
    class_id            = ['00000000000000000000000000000000'].pack('H*')
    num_property_sets   = [0x0002].pack('V')

    format_id_0         = ['02D5CDD59C2E1B10939708002B2CF9AE'].pack('H*')
    format_id_1         = ['05D5CDD59C2E1B10939708002B2CF9AE'].pack('H*')
    offset_0            = [0x0044].pack('V')
    num_property_0      = [properties.size].pack('V')
    property_offsets_0  = ''

    # Create the property set data block and calculate the offsets into it.
    property_data_0, offsets = pack_property_data(properties)

    # Create the property type and offsets based on the previous calculation.
    0.upto(properties.size-1) do |i|
      property_offsets_0 += [properties[i][0], offsets[i]].pack('VV')
    end

    # Size of size (4 bytes) +  num_property (4 bytes) + the data structures.
    data_len = 8 + (property_offsets_0).bytesize + property_data_0.bytesize
    size_0   = [data_len].pack('V')

    # The second property set offset is at the end of the first property set.
    offset_1 = [0x0044 + data_len].pack('V')

    # We will use a static property set stream rather than try to generate it.
    property_data_1 = [%w(
        98 00 00 00 03 00 00 00 00 00 00 00 20 00 00 00
        01 00 00 00 36 00 00 00 02 00 00 00 3E 00 00 00
        01 00 00 00 02 00 00 00 0A 00 00 00 5F 50 49 44
        5F 47 55 49 44 00 02 00 00 00 E4 04 00 00 41 00
        00 00 4E 00 00 00 7B 00 31 00 36 00 43 00 34 00
        42 00 38 00 33 00 42 00 2D 00 39 00 36 00 35 00
        46 00 2D 00 34 00 42 00 32 00 31 00 2D 00 39 00
        30 00 33 00 44 00 2D 00 39 00 31 00 30 00 46 00
        41 00 44 00 46 00 41 00 37 00 30 00 31 00 42 00
        7D 00 00 00 00 00 00 00 2D 00 39 00 30 00 33 00
    ).join('')].pack('H*')

    byte_order         +
    version            +
    system_id          +
    class_id           +
    num_property_sets  +
    format_id_0        +
    offset_0           +
    format_id_1        +
    offset_1           +
    size_0             +
    num_property_0     +
    property_offsets_0 +
    property_data_0    +
    property_data_1
end


###############################################################################
#
# _pack_property_data().
#
# Create a packed property set structure. Strings are null terminated and
# padded to a 4 byte boundary. We also use this function to keep track of the
# property offsets within the data structure. These offsets are used by the
# calling functions. Currently we only need to handle 4 property types:
# VT_I2, VT_LPSTR, VT_FILETIME.
#
def pack_property_data(properties, offset = 0)       #:nodoc:
    packed_property     = ''
    data                = ''
    offsets             = []

    # Get the strings codepage from the first property.
    codepage = properties[0][2]

    # The properties start after 8 bytes for size + num_properties + 8 bytes
    # for each propety type/offset pair.
    offset += 8 * (properties.size + 1)

    properties.each do |property|
      offsets.push(offset)

      property_type = property[1]

      if    property_type == 'VT_I2'
        packed_property = pack_VT_I2(property[2])
      elsif property_type == 'VT_LPSTR'
        packed_property = pack_VT_LPSTR(property[2], codepage)
      elsif property_type == 'VT_FILETIME'
        packed_property = pack_VT_FILETIME(property[2])
      else
        raise "Unknown property type: '#{property_type}'\n"
      end

      offset += packed_property.bytesize
      data   += packed_property
    end

    [data, offsets]
end

###############################################################################
#
# _pack_VT_I2().
#
# Pack an OLE property type: VT_I2, 16-bit signed integer.
#
def pack_VT_I2(value)       #:nodoc:
    type    = 0x0002
    data = [type, value].pack('VV')
end

###############################################################################
#
# _pack_VT_LPSTR().
#
# Pack an OLE property type: VT_LPSTR, String in the Codepage encoding.
# The strings are null terminated and padded to a 4 byte boundary.
#
def pack_VT_LPSTR(str, codepage)       #:nodoc:
    type        = 0x001E
    string      =
      ruby_18 { "#{str}\0" } ||
      ruby_19 { str.force_encoding('BINARY') + "\0".encode('BINARY') }

    if codepage == 0x04E4
      # Latin1
      length = string.bytesize
    elsif codepage == 0xFDE9
      # utf8
      length = string.bytesize
    else
      raise "Unknown codepage: #{codepage}\n"
    end

    # Pack the data.
    data  = [type, length].pack('VV')
    data += string

    # The packed data has to null padded to a 4 byte boundary.
    if (extra = length % 4) != 0
        data += "\0" * (4 - extra)
    end
    data
end

###############################################################################
#
# _pack_VT_FILETIME().
#
# Pack an OLE property type: VT_FILETIME.
#
def pack_VT_FILETIME(localtime)       #:nodoc:
  type        = 0x0040

  epoch = DateTime.new(1601, 1, 1)

  t = localtime.getgm

  datetime = DateTime.new(
                t.year,
                t.mon,
                t.mday,
                t.hour,
                t.min,
                t.sec,
                t.usec
              )
  bignum = (datetime - epoch) * 86400 * 1e7.to_i
  high, low = bignum.divmod 1 << 32

  [type].pack('V') + [low, high].pack('V2')
end
