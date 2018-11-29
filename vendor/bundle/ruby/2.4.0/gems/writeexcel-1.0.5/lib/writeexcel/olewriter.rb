# -*- coding: utf-8 -*-
###############################################################################
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
class MaxSizeError < StandardError; end       #:nodoc:

class OLEWriter       #:nodoc:

  # Not meant for public consumption
  MaxSize    = 7087104 # Use WriteExcel::Big to exceed this
  BlockSize  = 4096
  BlockDiv   = 512
  ListBlocks = 127

  attr_reader :biff_size, :book_size, :big_blocks, :list_blocks
  attr_reader :root_start, :size_allowed
  attr_accessor :biff_only, :internal_fh

  # Accept an IO or IO-like object or a filename (as a String)
  def initialize(arg)
    if arg.respond_to?(:to_str)
      @io = File.open(arg, "w")
    else
      @io = arg
    end
    @io.binmode if @io.respond_to?(:binmode)

    @filehandle    = ""
    @fileclosed    = false
    @internal_fh   = 0
    @biff_only     = 0
    @size_allowed  = true
    @biff_size     = 0
    @book_size     = 0
    @big_blocks    = 0
    @list_blocks   = 0
    @root_start    = 0
    @block_count   = 4
  end

  # Imitate IO.open behavior

  ###############################################################################
  #
  # _initialize()
  #
  # Create a new filehandle or use the provided filehandle.
  #
  def _initialize
    olefile = @olefilename

    # If the filename is a reference it is assumed that it is a valid
    # filehandle, if not we create a filehandle.
    #

    # Create a new file, open for writing
    fh = open(olefile, "wb")

    # Workbook.pm also checks this but something may have happened since
    # then.
    raise "Can't open olefile. It may be in use or protected.\n" unless fh

    @internal_fh = 1

    # Store filehandle
    @filehandle = fh
  end

  def self.open(arg)
    if block_given?
      ole = self.new(arg)
      result = yield(ole)
      ole.close
      result
    else
      self.new(arg)
    end
  end

  ###############################################################################
  #
  # write($data)
  #
  # Write BIFF data to OLE file.
  #
  def write(data)
    @io.write(data)
  end

  ###############################################################################
  #
  # set_size(biffsize)
  #
  # Set the size of the data to be written to the OLE stream
  #
  #   $big_blocks = (109 depot block x (128 -1 marker word)
  #                 - (1 x end words)) = 13842
  #   $maxsize    = $big_blocks * 512 bytes = 7087104
  #
  def set_size(size = BlockSize)
    if size > MaxSize
      return @size_allowed = false
    end

    @biff_size = size
    @book_size = [size, BlockSize].max
    @size_allowed = true
  end

  ###############################################################################
  #
  # _calculate_sizes()
  #
  # Calculate various sizes needed for the OLE stream
  #
  def calculate_sizes
    @big_blocks  = (@book_size.to_f/BlockDiv.to_f).ceil
    @list_blocks = (@big_blocks / ListBlocks) + 1
    @root_start  = @big_blocks
  end

  ###############################################################################
  #
  # close()
  #
  # Write root entry, big block list and close the filehandle.
  # This routine is used to explicitly close the open filehandle without
  # having to wait for DESTROY.
  #
  def close
    if @size_allowed == true
      write_padding          if @biff_only == 0
      write_property_storage if @biff_only == 0
      write_big_block_depot  if @biff_only == 0
    end
    @io.close
  end

  ###############################################################################
  #
  # write_header()
  #
  # Write OLE header block.
  #
  def write_header
    return if @biff_only == 1
    calculate_sizes
    root_start = @root_start
    num_lists  = @list_blocks

    id              = [0xD0CF11E0, 0xA1B11AE1].pack("NN")
    unknown1        = [0x00, 0x00, 0x00, 0x00].pack("VVVV")
    unknown2        = [0x3E, 0x03].pack("vv")
    unknown3        = [-2].pack("v")
    unknown4        = [0x09].pack("v")
    unknown5        = [0x06, 0x00, 0x00].pack("VVV")
    num_bbd_blocks  = [num_lists].pack("V")
    root_startblock = [root_start].pack("V")
    unknown6        = [0x00, 0x1000].pack("VV")
    sbd_startblock  = [-2].pack("V")
    unknown7        = [0x00, -2 ,0x00].pack("VVV")

    write(id)
    write(unknown1)
    write(unknown2)
    write(unknown3)
    write(unknown4)
    write(unknown5)
    write(num_bbd_blocks)
    write(root_startblock)
    write(unknown6)
    write(sbd_startblock)
    write(unknown7)

    unused = [-1].pack("V")

    1.upto(num_lists){
      root_start += 1
      write([root_start].pack("V"))
    }

    num_lists.upto(108){
      write(unused)
    }
  end

  ###############################################################################
  #
  # _write_big_block_depot()
  #
  # Write big block depot.
  #
  def write_big_block_depot
    num_blocks   = @big_blocks
    num_lists    = @list_blocks
    total_blocks = num_lists * 128
    used_blocks  = num_blocks + num_lists + 2

    marker          = [-3].pack("V")
    end_of_chain    = [-2].pack("V")
    unused          = [-1].pack("V")

    1.upto(num_blocks-1){|n|
      write([n].pack("V"))
    }

    write end_of_chain
    write end_of_chain

    1.upto(num_lists){ write(marker) }

    used_blocks.upto(total_blocks){ write(unused) }

  end

  ###############################################################################
  #
  # _write_property_storage()
  #
  # Write property storage. TODO: add summary sheets
  #
  def write_property_storage

    #########  name         type  dir start size
    write_pps('Root Entry', 0x05,  1,   -2, 0x00)
    write_pps('Workbook',   0x02, -1, 0x00, @book_size)
    write_pps("",           0x00, -1, 0x00, 0x0000)
    write_pps("",           0x00, -1, 0x00, 0x0000)
  end

  ###############################################################################
  #
  # _write_pps()
  #
  # Write property sheet in property storage
  #
  def write_pps(name, type, dir, start, size)
    length = 0
    ord_name = []
    unless name.empty?
      name = name + "\0"
      ord_name = name.unpack("c*")
      length = name.bytesize * 2
    end

    rawname        = ord_name.pack("v*")
    zero           = [0].pack("C")

    pps_sizeofname = [length].pack("v")   #0x40
    pps_type       = [type].pack("v")     #0x42
    pps_prev       = [-1].pack("V")       #0x44
    pps_next       = [-1].pack("V")       #0x48
    pps_dir        = [dir].pack("V")      #0x4c

    unknown = [0].pack("V")

    pps_ts1s       = [0].pack("V")        #0x64
    pps_ts1d       = [0].pack("V")        #0x68
    pps_ts2s       = [0].pack("V")        #0x6c
    pps_ts2d       = [0].pack("V")        #0x70
    pps_sb         = [start].pack("V")    #0x74
    pps_size       = [size].pack("V")     #0x78

    write(rawname)
    write(zero * (64 - length)) if 64 - length >= 1
    write(pps_sizeofname)
    write(pps_type)
    write(pps_prev)
    write(pps_next)
    write(pps_dir)
    write(unknown * 5)
    write(pps_ts1s)
    write(pps_ts1d)
    write(pps_ts2s)
    write(pps_ts2d)
    write(pps_sb)
    write(pps_size)
    write(unknown)
  end

  ###############################################################################
  #
  # _write_padding()
  #
  # Pad the end of the file
  #
  def write_padding
    min_size = 512
    min_size = BlockSize if @biff_size < BlockSize

    if @biff_size % min_size != 0
      padding = min_size - (@biff_size % min_size)
      write("\0" * padding)
    end
  end
end
