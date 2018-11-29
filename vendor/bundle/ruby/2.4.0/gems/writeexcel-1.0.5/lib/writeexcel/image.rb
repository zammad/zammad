# -*- coding:utf-8 -*-
require 'digest/md5'

module Writeexcel
  class Image
    attr_reader :row, :col, :filename, :x_offset, :y_offset, :scale_x, :scale_y
    attr_reader :data, :size, :checksum1, :checksum2
    attr_accessor :id, :type, :width, :height, :ref_count

    def initialize(worksheet, row, col, filename, x_offset = 0, y_offset = 0, scale_x = 1, scale_y = 1)
      @worksheet = worksheet
      @row = row
      @col = col
      @filename = filename
      @x_offset = x_offset
      @y_offset = y_offset
      @scale_x  = scale_x
      @scale_y  = scale_y
      get_checksum_method
    end

    def import
      File.open(@filename, "rb") do |fh|
        raise "Couldn't import #{@filename}: #{$!}" unless fh
        @data = fh.read
      end
      @size = data.bytesize
      @checksum1 = image_checksum(@data)
      @checksum2 = @checksum1
      process
    end

    def store_image_record(i, num_images, num_charts, num_filters, num_comments, spid)
      image_width  = width
      image_height = height

      image_width  = width  * scale_x unless scale_x == 0
      image_height = height * scale_y unless scale_y == 0

      # Calculate the positions of image object.
      vertices = @worksheet.position_object(col, row, x_offset, y_offset, image_width, image_height)

      if (i == 0)
        data = images_parent_msodrawing_record(num_images, num_charts, num_filters, num_comments, spid, id, vertices)
      else
        data = images_child_msodrawing_record(spid, id, vertices)
      end
      record = 0x00EC           # Record identifier
      length = 0x0000           # Bytes to follow

      length = data.bytesize
      header = [record, length].pack("vv")

      append(header, data)
    end

    private

    # Process the image and extract dimensions.
    def process
      case filetype
      when 'PNG'
        process_png(@data)
      when 'JPG'
        process_jpg(@data)
      when 'BMP'
        process_bmp(@data)
        # The 14 byte header of the BMP is stripped off.
        @data[0, 13] = ''
        # A checksum of the new image data is also required.
        @checksum2  = image_checksum(@data, @id, @id)
        # Adjust size -14 (header) + 16 (extra checksum).
        @size += 2
      end
    end

    def filetype
      return 'PNG' if @data.unpack('x A3')[0] ==  'PNG'
      return 'BMP' if @data.unpack('A2')[0] == 'BM'
      if data.unpack('n')[0] == 0xFFD8
        return 'JPG' if @data.unpack('x6 A4')[0] == 'JFIF' || @data.unpack('x6 A4')[0] == 'Exif'
      else
        raise "Unsupported image format for file: #{@filename}\n"
      end
    end

    # Extract width and height information from a PNG file.
    def process_png(data)
      @type   = 6 # Excel Blip type (MSOBLIPTYPE).
      @width  = data[16, 4].unpack("N")[0]
      @height = data[20, 4].unpack("N")[0]
    end

    # Extract width and height information from a BMP file.
    def process_bmp(data)       #:nodoc:
      @type     = 7   # Excel Blip type (MSOBLIPTYPE).
      # Read the bitmap width and height. Verify the sizes.
      @width, @height = data.unpack("x18 V2")
      check_verify(data)
    end

    def check_verify(data)
      # Check that the file is big enough to be a bitmap.
      raise "#{@filename} doesn't contain enough data." if data.bytesize <= 0x36
      raise "#{@filename}: largest image width #{@width} supported is 65k." if @width > 0xFFFF
      raise "#{@filename}: largest image height supported is 65k." if @height > 0xFFFF

      # Read the bitmap planes and bpp data. Verify them.
      planes, bitcount = data.unpack("x26 v2")
      raise "#{@filename} isn't a 24bit true color bitmap." unless bitcount == 24
      raise "#{@filename}: only 1 plane supported in bitmap image." unless planes == 1

      # Read the bitmap compression. Verify compression.
      compression = data.unpack("x30 V")[0]
      raise "#{@filename}: compression not supported in bitmap image." unless compression == 0
    end

    # Extract width and height information from a JPEG file.
    def process_jpg(data)
      @type     = 5  # Excel Blip type (MSOBLIPTYPE).

      offset = 2
      data_length = data.bytesize

      # Search through the image data to find the 0xFFC0 marker. The height and
      # width are contained in the data for that sub element.
      while offset < data_length
        marker  = data[offset,   2].unpack("n")
        marker = marker[0]
        length  = data[offset+2, 2].unpack("n")
        length = length[0]

        if marker == 0xFFC0 || marker == 0xFFC2
          height = data[offset+5, 2].unpack("n")
          @height = height[0]
          width  = data[offset+7, 2].unpack("n")
          @width  = width[0]
          break
        end

        offset += length + 2
        break if marker == 0xFFDA
      end

      raise "#{@filename}: no size data found in jpeg image.\n" unless @height
    end

    #
    # Generate a checksum for the image using whichever module is available. The
    # available modules are checked in get_checksum_method(). Excel uses an MD4
    # checksum but any other will do. In the event of no checksum module being
    # available we simulate a checksum using the image index.
    #
    # index1 and index2 is not used.
    #
    def image_checksum(data, index1 = 0, index2 = 0)       #:nodoc:
      case @checksum_method
      when 3
        Digest::MD5.hexdigest(data)
      when 1
        # Digest::MD4
        #           return Digest::MD4::md4_hex($data);
      when 2
        # Digest::Perl::MD4
        #           return Digest::Perl::MD4::md4_hex($data);
      else
        # Default
  #      return sprintf('%016X%016X', index2, index1)
      end
    end

    #
    # Check for modules available to calculate image checksum. Excel uses MD4 but
    # MD5 will also work.
    #
    # ------- cxn03651 add -------
    # md5 can use in ruby. so, @checksum_method is always 3.

    def get_checksum_method       #:nodoc:
      @checksum_method = 3
    end

    def images_parent_msodrawing_record(num_images, charts_size, num_filters, num_comments, spid, image_id, vertices)
      dg_length   =  156 + 84*(num_images - 1)
      spgr_length =  132 + 84*(num_images - 1)

      dg_length   += 120 * charts_size
      spgr_length += 120 * charts_size

      dg_length   += 96 * num_filters
      spgr_length += 96 * num_filters

      dg_length   += 128 * num_comments
      spgr_length += 128 * num_comments

      data = @worksheet.store_parent_mso_record(dg_length, spgr_length, spid)
      spid += 1
      data += @worksheet.store_mso_sp_container(76)
      data += @worksheet.store_mso_sp(75, spid, 0x0A00)
      spid += 1
      data += @worksheet.store_mso_opt_image(image_id)
      data += @worksheet.store_mso_client_anchor(2, *vertices)
      data += @worksheet.store_mso_client_data
    end

    def images_child_msodrawing_record(spid, image_id, vertices)
      data = @worksheet.store_mso_sp_container(76) + @worksheet.store_mso_sp(75, spid, 0x0A00)
      spid = spid + 1
      data += @worksheet.store_mso_opt_image(image_id)    +
        @worksheet.store_mso_client_anchor(2, *vertices)  +
        @worksheet.store_mso_client_data
    end

    def append(*args)
      @worksheet.append(*args)
    end
  end
end
