module Writeexcel

class Worksheet < BIFFWriter
  require 'writeexcel/helper'

  class Collection
    def initialize
      @items = {}
    end

    def <<(item)
      if @items[item.row]
        @items[item.row][item.col] = item
      else
        @items[item.row] = { item.col => item }
      end
    end

    def array
      return @array if @array

      @array = []
      @items.keys.sort.each do |row|
        @items[row].keys.sort.each do |col|
          @array << @items[row][col]
        end
      end
      @array
    end

  end

  class Comments < Collection
    attr_writer :visible

    def initialize
      super
      @visible  = false
    end

    def visible?
      @visible
    end
  end

  class Comment
    attr_reader :row, :col, :string, :encoding, :author, :author_encoding, :visible, :color, :vertices

    def initialize(worksheet, row, col, string, options = {})
      @worksheet = worksheet
      @row, @col = row, col
      @params = params_with(options)
      @string, @params[:encoding] = string_and_encoding(string, @params[:encoding], 'comment')

      # Limit the string to the max number of chars (not bytes).
      max_len = 32767
      max_len = max_len * 2 if @params[:encoding] != 0

      if @string.bytesize > max_len
        @string = @string[0 .. max_len]
      end
      @encoding        = @params[:encoding]
      @author          = @params[:author]
      @author_encoding = @params[:author_encoding]
      @visible         = @params[:visible]
      @color           = @params[:color]
      @vertices        = calc_vertices
    end

    def store_comment_record(i, num_objects, num_comments, spid)
      str_len  = string.bytesize
      str_len  = str_len / 2 if encoding != 0 # Num of chars not bytes.

      spid = store_comment_mso_drawing_record(i, num_objects, num_comments, spid, visible, color, vertices)
      store_obj_comment(num_objects + i + 1)
      store_mso_drawing_text_box
      store_txo(str_len)
      store_txo_continue_1(string, encoding)
      formats  = [[0, 9], [str_len, 0]]
      store_txo_continue_2(formats)
      spid
    end

    #
    # Write the worksheet NOTE record that is part of cell comments.
    #
    def store_note_record(obj_id)   #:nodoc:
      comment_author = author
      comment_author_enc = author_encoding
      ruby_19 { comment_author = [comment_author].pack('a*') if comment_author.ascii_only? }
      record      = 0x001C               # Record identifier
      length      = 0x000C               # Bytes to follow

      comment_author     = '' unless comment_author
      comment_author_enc = 0  unless author_encoding

      # Use the visible flag if set by the user or else use the worksheet value.
      # The flag is also set in store_mso_opt_comment() but with the opposite
      # value.
      if visible
        comment_visible = visible != 0                 ? 0x0002 : 0x0000
      else
        comment_visible = @worksheet.comments_visible? ? 0x0002 : 0x0000
      end

      # Get the number of chars in the author string (not bytes).
      num_chars  = comment_author.bytesize
      num_chars  = num_chars / 2 if comment_author_enc != 0 && comment_author_enc

      # Null terminate the author string.
      comment_author =
        ruby_18 { comment_author + "\0" } ||
        ruby_19 { comment_author.force_encoding('BINARY') + "\0".force_encoding('BINARY') }

      # Pack the record.
      data    = [@row, @col, comment_visible, obj_id, num_chars, comment_author_enc].pack("vvvvvC")

      length  = data.bytesize + comment_author.bytesize
      header  = [record, length].pack("vv")

      append(header, data, comment_author)
    end

    #
    # Write the Escher Opt record that is part of MSODRAWING.
    #
    def store_mso_opt_comment(spid, visible = nil, colour = 0x50)   #:nodoc:
      type        = 0xF00B
      version     = 3
      instance    = 9
      data        = ''
      length      = 54

      # Use the visible flag if set by the user or else use the worksheet value.
      # Note that the value used is the opposite of Comment#note_record.
      #
      if visible
        visible = visible != 0       ? 0x0000 : 0x0002
      else
        visible = @worksheet.comments_visible? ? 0x0000 : 0x0002
      end

      data = [spid].pack('V')                            +
      ['0000BF00080008005801000000008101'].pack("H*") +
      [colour].pack("C")                              +
      ['000008830150000008BF011000110001'+'02000000003F0203000300BF03'].pack("H*")  +
      [visible].pack('v')                             +
      ['0A00'].pack('H*')

      @worksheet.add_mso_generic(type, version, instance, data, length)
    end

    #
    # OBJ record that is part of cell comments.
    #    obj_id      # Object ID number.
    #
    def obj_comment_record(obj_id)   #:nodoc:
      record      = 0x005D   # Record identifier
      length      = 0x0034   # Bytes to follow

      obj_type    = 0x0019   # Object type (comment).
      data        = ''       # Record data.

      sub_record  = 0x0000   # Sub-record identifier.
      sub_length  = 0x0000   # Length of sub-record.
      sub_data    = ''       # Data of sub-record.
      options     = 0x4011
      reserved    = 0x0000

      # Add ftCmo (common object data) subobject
      sub_record     = 0x0015   # ftCmo
      sub_length     = 0x0012
      sub_data       = [obj_type, obj_id, options, reserved, reserved, reserved].pack( "vvvVVV")
      data           = [sub_record, sub_length].pack("vv") + sub_data

      # Add ftNts (note structure) subobject
      sub_record  = 0x000D   # ftNts
      sub_length  = 0x0016
      sub_data    = [reserved,reserved,reserved,reserved,reserved,reserved].pack( "VVVVVv")
      data        += [sub_record, sub_length].pack("vv") + sub_data

      # Add ftEnd (end of object) subobject
      sub_record  = 0x0000   # ftNts
      sub_length  = 0x0000
      data        += [sub_record, sub_length].pack("vv")

      # Pack the record.
      header      = [record, length].pack("vv")

      header + data
    end

    private

    def params_with(options)
      params = default_params.update(options)

      # Ensure that a width and height have been set.
      params[:width]  = default_width  unless params[:width]  && params[:width] != 0
      params[:width]  = params[:width] * params[:x_scale]  if params[:x_scale] != 0
      params[:height] = default_height unless params[:height] && params[:height] != 0
      params[:height] = params[:height] * params[:y_scale] if params[:y_scale] != 0

      params[:author], params[:author_encoding] =
          string_and_encoding(params[:author], params[:author_encoding], 'author')

      # Set the comment background colour.
      params[:color] = background_color(params[:color])

      # Set the default start cell and offsets for the comment. These are
      # generally fixed in relation to the parent cell. However there are
      # some edge cases for cells at the, er, edges.
      #
      params[:start_row] = default_start_row unless params[:start_row]
      params[:y_offset]  = default_y_offset  unless params[:y_offset]
      params[:start_col] = default_start_col unless params[:start_col]
      params[:x_offset]  = default_x_offset  unless params[:x_offset]

      params
    end

    def default_params
      {
        :author          => '',
        :author_encoding => 0,
        :encoding        => 0,
        :color           => nil,
        :start_cell      => nil,
        :start_col       => nil,
        :start_row       => nil,
        :visible         => nil,
        :width           => default_width,
        :height          => default_height,
        :x_offset        => nil,
        :x_scale         => 1,
        :y_offset        => nil,
        :y_scale         => 1
      }
    end

    def default_width
      128
    end

    def default_height
      74
    end

    def default_start_row
      case @row
      when 0     then 0
      when 65533 then 65529
      when 65534 then 65530
      when 65535 then 65531
      else            @row -1
      end
    end

    def default_y_offset
      case @row
      when 0     then 2
      when 65533 then 4
      when 65534 then 4
      when 65535 then 2
      else            7
      end
    end

    def default_start_col
      case @col
      when 253   then 250
      when 254   then 251
      when 255   then 252
      else            @col + 1
      end
    end

    def default_x_offset
      case @col
      when 253   then 49
      when 254   then 49
      when 255   then 49
      else            15
      end
    end

    def string_and_encoding(string, encoding, type)
      string = convert_to_ascii_if_ascii(string)
      if encoding != 0
        raise "Uneven number of bytes in #{type} string" if string.bytesize % 2 != 0
        # Change from UTF-16BE to UTF-16LE
        string = utf16be_to_16le(string)
      # Handle utf8 strings
      else
        if is_utf8?(string)
          string = NKF.nkf('-w16L0 -m0 -W', string)
          ruby_19 { string.force_encoding('UTF-16LE') }
          encoding = 1
        end
      end
      [string, encoding]
    end

    def background_color(color)
      color = Colors.new.get_color(color)
      color = 0x50 if color == 0x7FFF  # Default color.
      color
    end

    # Calculate the positions of comment object.
    def calc_vertices
      @worksheet.position_object( @params[:start_col],
        @params[:start_row],
        @params[:x_offset],
        @params[:y_offset],
        @params[:width],
        @params[:height]
      )
    end

    def store_comment_mso_drawing_record(i, num_objects, num_comments, spid, visible, color, vertices)
      if i == 0 && num_objects == 0
        # Write the parent MSODRAWIING record.
        dg_length   = 200 + 128 * (num_comments - 1)
        spgr_length = 176 + 128 * (num_comments - 1)

        data = @worksheet.store_parent_mso_record(dg_length, spgr_length, spid)
        spid += 1
      else
        data = ''
      end
      data += @worksheet.store_mso_sp_container(120) + @worksheet.store_mso_sp(202, spid, 0x0A00)
      spid += 1
      data +=
        store_mso_opt_comment(0x80, visible, color) +
        @worksheet.store_mso_client_anchor(3, *vertices)               +
        @worksheet.store_mso_client_data
      record      = 0x00EC           # Record identifier
      length      = data.bytesize
      header      = [record, length].pack("vv")
      append(header, data)

      spid
    end

    def store_obj_comment(obj_id)
      append(obj_comment_record(obj_id))
    end

    #
    # Write the MSODRAWING ClientTextbox record that is part of comments.
    #
    def store_mso_drawing_text_box   #:nodoc:
      record      = 0x00EC           # Record identifier
      length      = 0x0008           # Bytes to follow

      data        = store_mso_client_text_box
      header  = [record, length].pack('vv')

      append(header, data)
    end

    #
    # Write the Escher ClientTextbox record that is part of MSODRAWING.
    #
    def store_mso_client_text_box   #:nodoc:
      type        = 0xF00D
      version     = 0
      instance    = 0
      data        = ''
      length      = 0

      @worksheet.add_mso_generic(type, version, instance, data, length)
    end

    #
    # Write the worksheet TXO record that is part of cell comments.
    #    string_len           # Length of the note text.
    #    format_len           # Length of the format runs.
    #    rotation             # Options
    #
    def store_txo(string_len, format_len = 16, rotation = 0)   #:nodoc:
      record      = 0x01B6               # Record identifier
      length      = 0x0012               # Bytes to follow

      grbit       = 0x0212               # Options
      reserved    = 0x0000               # Options

      # Pack the record.
      header  = [record, length].pack('vv')
      data    = [grbit, rotation, reserved, reserved, string_len, format_len, reserved].pack("vvVvvvV")
      append(header, data)
    end

    #
    # Write the first CONTINUE record to follow the TXO record. It contains the
    # text data.
    #    string               # Comment string.
    #    encoding             # Encoding of the string.
    #
    def store_txo_continue_1(string, encoding = 0)   #:nodoc:
      # Split long comment strings into smaller continue blocks if necessary.
      # We can't let BIFFwriter::_add_continue() handled this since an extra
      # encoding byte has to be added similar to the SST block.
      #
      # We make the limit size smaller than the add_continue() size and even
      # so that UTF16 chars occur in the same block.
      #
      limit = 8218
      while string.bytesize > limit
        string[0 .. limit] = ""
        tmp_str = string
        data    = [encoding].pack("C") +
          ruby_18 { tmp_str } ||
          ruby_19 { tmp_str.force_encoding('ASCII-8BIT') }
        length  = data.bytesize
        header  = [record, length].pack('vv')

        append(header, data)
      end

      # Pack the record.
      data    =
        ruby_18 { [encoding].pack("C") + string } ||
        ruby_19 { [encoding].pack("C") + string.force_encoding('ASCII-8BIT') }

      record      = 0x003C               # Record identifier
      length  = data.bytesize
      header  = [record, length].pack('vv')

      append(header, data)
    end

    #
    # Write the second CONTINUE record to follow the TXO record. It contains the
    # formatting information for the string.
    #    formats           # Formatting information
    #
    def store_txo_continue_2(formats)   #:nodoc:
      # Pack the record.
      data = ''

      formats.each do |a_ref|
        data += [a_ref[0], a_ref[1], 0x0].pack('vvV')
      end

      record      = 0x003C               # Record identifier
      length  = data.bytesize
      header  = [record, length].pack("vv")

      append(header, data)
    end

    def append(*args)
      @worksheet.append(*args)
    end
  end
end

end
