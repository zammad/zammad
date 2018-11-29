# -*- coding: utf-8 -*-
#
# BIFFwriter - An abstract base class for Excel workbooks and worksheets.
#
#
# Used in conjunction with WriteExcel
#
# Copyright 2000-2010, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#


require 'tempfile'
require 'writeexcel/write_file'

class BIFFWriter < WriteFile       #:nodoc:

  BIFF_Version = 0x0600
  BigEndian    = [1].pack("I") == [1].pack("N")

  attr_reader :data, :datasize

  ######################################################################
  # The args here aren't used by BIFFWriter, but they are needed by its
  # subclasses.  I don't feel like creating multiple constructors.
  ######################################################################

  def initialize
    super
    set_byte_order
    @ignore_continue = false
  end

  ###############################################################################
  #
  # _set_byte_order()
  #
  # Determine the byte order and store it as class data to avoid
  # recalculating it for each call to new().
  #
  def set_byte_order
    # Check if "pack" gives the required IEEE 64bit float
    teststr = [1.2345].pack("d")
    hexdata = [0x8D, 0x97, 0x6E, 0x12, 0x83, 0xC0, 0xF3, 0x3F]
    number  = hexdata.pack("C8")

    if number == teststr
      @byte_order = false    # Little Endian
    elsif number == teststr.reverse
      @byte_order = true     # Big Endian
    else
      # Give up. I'll fix this in a later version.
      raise( "Required floating point format not supported "  +
      "on this platform. See the portability section " +
      "of the documentation."
      )
    end
  end

  ###############################################################################
  #
  # get_data().
  #
  # Retrieves data from memory in one chunk, or from disk in $buffer
  # sized chunks.
  #
  def get_data
    buflen = 4096

    # Return data stored in memory
    unless @data.nil?
      tmp   = @data
      @data = nil
      if @using_tmpfile
        @filehandle.open
        @filehandle.binmode
      end
      return tmp
    end

    # Return data stored on disk
    if @using_tmpfile
      return @filehandle.read(buflen)
    end

    # No data to return
    nil
  end

  ###############################################################################
  #
  # _store_bof($type)
  #
  # $type = 0x0005, Workbook
  # $type = 0x0010, Worksheet
  # $type = 0x0020, Chart
  #
  # Writes Excel BOF record to indicate the beginning of a stream or
  # sub-stream in the BIFF file.
  #
  def store_bof(type = 0x0005)
    record  = 0x0809      # Record identifier
    length  = 0x0010      # Number of bytes to follow

    # According to the SDK $build and $year should be set to zero.
    # However, this throws a warning in Excel 5. So, use these
    # magic numbers.
    build   = 0x0DBB
    year    = 0x07CC

    bfh     = 0x00000041
    sfo     = 0x00000006

    header  = [record,length].pack("vv")
    data    = [BIFF_Version,type,build,year,bfh,sfo].pack("vvvvVV")

    prepend(header, data)
  end

  ###############################################################################
  #
  # _store_eof()
  #
  # Writes Excel EOF record to indicate the end of a BIFF stream.
  #
  def store_eof
    record = 0x000A
    length = 0x0000
    header = [record,length].pack("vv")

    append(header)
  end

  ###############################################################################
  #
  # _add_continue()
  #
  # Excel limits the size of BIFF records. In Excel 5 the limit is 2084 bytes. In
  # Excel 97 the limit is 8228 bytes. Records that are longer than these limits
  # must be split up into CONTINUE blocks.
  #
  # This function take a long BIFF record and inserts CONTINUE records as
  # necessary.
  #
  # Some records have their own specialised Continue blocks so there is also an
  # option to bypass this function.
  #
  def add_continue(data)
    # Skip this if another method handles the continue blocks.
    return data if @ignore_continue

    record  = 0x003C # Record identifier
    header  = [record, @limit].pack("vv")

    # The first 2080/8224 bytes remain intact. However, we have to change
    # the length field of the record.
    #
    data_array = split_by_length(data, @limit)
    first_data = data_array.shift
    last_data  = data_array.pop || ''
    first_data[2, 2] = [@limit-4].pack('v')
    first_data <<
      data_array.join(header) <<
      [record, last_data.bytesize].pack('vv') <<
      last_data
  end

  ###############################################################################
  #
  # _add_mso_generic()
  #    my $type        = $_[0];
  #    my $version     = $_[1];
  #    my $instance    = $_[2];
  #    my $data        = $_[3];
  #
  # Create a mso structure that is part of an Escher drawing object. These are
  # are used for images, comments and filters. This generic method is used by
  # other methods to create specific mso records.
  #
  # Returns the packed record.
  #
  def add_mso_generic(type, version, instance, data, length = nil)
    length  ||= data.bytesize

    # The header contains version and instance info packed into 2 bytes.
    header  = version | (instance << 4)

    record  = [header, type, length].pack('vvV') + data
  end

  def not_using_tmpfile
    @filehandle.close(true) if @filehandle
    @filehandle = nil
    @using_tmpfile = nil
  end

  def clear_data_for_test # :nodoc:
    @data = ''
  end

  def cleanup # :nodoc:
    @filehandle.close(true) if @filehandle
  end

  # override Object#inspect
  def inspect          # :nodoc:
    to_s
  end

  private

  def split_by_length(data, length)
    array = []
    s = 0
    while s < data.length
      array << data[s, length]
      s += length
    end
    array
  end
end
