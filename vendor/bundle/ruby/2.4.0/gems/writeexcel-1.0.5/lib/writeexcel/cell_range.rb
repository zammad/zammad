module Writeexcel

class Worksheet < BIFFWriter
  class CellRange
    attr_accessor :row_min, :row_max, :col_min, :col_max

    def initialize(worksheet)
      @worksheet = worksheet
    end

    def increment_row_max
      @row_max += 1 if @row_max
    end

    def increment_col_max
      @col_max += 1 if @col_max
    end

    def row(val)
      @row_min = val if !@row_min || (val < row_min)
      @row_max = val if !@row_max || (val > row_max)
    end

    def col(val)
      @col_min = val if !@col_min || (val < col_min)
      @col_max = val if !@col_max || (val > col_max)
    end

    #
    # assemble the NAME record in the long format that is used for storing the repeat
    # rows and columns when both are specified. This share a lot of code with
    # name_record_short() but we use a separate method to keep the code clean.
    # Code abstraction for reuse can be carried too far, and I should know. ;-)
    #
    #    type
    #    ext_ref           # TODO
    #
    def name_record_long(type, ext_ref)       #:nodoc:
      record          = 0x0018       # Record identifier
      length          = 0x002a       # Number of bytes to follow

      grbit           = 0x0020       # Option flags
      chkey           = 0x00         # Keyboard shortcut
      cch             = 0x01         # Length of text name
      cce             = 0x001a       # Length of text definition
      unknown01       = 0x0000       #
      ixals           = @worksheet.index + 1    # Sheet index
      unknown02       = 0x00         #
      cch_cust_menu   = 0x00         # Length of cust menu text
      cch_description = 0x00         # Length of description text
      cch_helptopic   = 0x00         # Length of help topic text
      cch_statustext  = 0x00         # Length of status bar text
      rgch            = type         # Built-in name type

      unknown03       = 0x29
      unknown04       = 0x0017
      unknown05       = 0x3b

      header          = [record, length].pack("vv")
      data            = [grbit].pack("v")
      data           += [chkey].pack("C")
      data           += [cch].pack("C")
      data           += [cce].pack("v")
      data           += [unknown01].pack("v")
      data           += [ixals].pack("v")
      data           += [unknown02].pack("C")
      data           += [cch_cust_menu].pack("C")
      data           += [cch_description].pack("C")
      data           += [cch_helptopic].pack("C")
      data           += [cch_statustext].pack("C")
      data           += [rgch].pack("C")

      # Column definition
      data           += [unknown03].pack("C")
      data           += [unknown04].pack("v")
      data           += [unknown05].pack("C")
      data           += [ext_ref].pack("v")
      data           += [0x0000].pack("v")
      data           += [0xffff].pack("v")
      data           += [@col_min].pack("v")
      data           += [@col_max].pack("v")

      # Row definition
      data           += [unknown05].pack("C")
      data           += [ext_ref].pack("v")
      data           += [@row_min].pack("v")
      data           += [@row_max].pack("v")
      data           += [0x00].pack("v")
      data           += [0xff].pack("v")
      # End of data
      data           += [0x10].pack("C")

      [header, data]
    end

    #
    # assemble the NAME record in the short format that is used for storing the print
    # area, repeat rows only and repeat columns only.
    #
    #    type
    #    ext_ref          # TODO
    #    hidden           # Name is hidden
    #
    def name_record_short(type, ext_ref, hidden = nil)       #:nodoc:
      record          = 0x0018       # Record identifier
      length          = 0x001b       # Number of bytes to follow

      grbit           = 0x0020       # Option flags
      chkey           = 0x00         # Keyboard shortcut
      cch             = 0x01         # Length of text name
      cce             = 0x000b       # Length of text definition
      unknown01       = 0x0000       #
      ixals           = @worksheet.index + 1    # Sheet index
      unknown02       = 0x00         #
      cch_cust_menu   = 0x00         # Length of cust menu text
      cch_description = 0x00         # Length of description text
      cch_helptopic   = 0x00         # Length of help topic text
      cch_statustext  = 0x00         # Length of status bar text
      rgch            = type         # Built-in name type
      unknown03       = 0x3b         #

      grbit           = 0x0021 if hidden

      rowmin = row_min
      rowmax = row_max
      rowmin, rowmax = 0x0000, 0xffff unless row_min

      colmin = col_min
      colmax = col_max
      colmin, colmax = 0x00, 0xff unless col_min

      header          = [record, length].pack("vv")
      data            = [grbit].pack("v")
      data           += [chkey].pack("C")
      data           += [cch].pack("C")
      data           += [cce].pack("v")
      data           += [unknown01].pack("v")
      data           += [ixals].pack("v")
      data           += [unknown02].pack("C")
      data           += [cch_cust_menu].pack("C")
      data           += [cch_description].pack("C")
      data           += [cch_helptopic].pack("C")
      data           += [cch_statustext].pack("C")
      data           += [rgch].pack("C")
      data           += [unknown03].pack("C")
      data           += [ext_ref].pack("v")

      data           += [rowmin].pack("v")
      data           += [rowmax].pack("v")
      data           += [colmin].pack("v")
      data           += [colmax].pack("v")

      [header, data]
    end
  end

  class CellDimension < CellRange
    def row_min
      @row_min || 0
    end

    def col_min
      @col_min || 0
    end

    def row_max
      @row_max || 0
    end

    def col_max
      @col_max || 0
    end
  end

  class PrintRange < CellRange
    def name_record_short(ext_ref, hidden)
      super(0x06, ext_ref, hidden) # 0x06  NAME type = Print_Area
    end
  end

  class TitleRange < CellRange
    def name_record_long(ext_ref)
      super(0x07, ext_ref) # 0x07  NAME type = Print_Titles
    end

    def name_record_short(ext_ref, hidden)
      super(0x07, ext_ref, hidden) # 0x07  NAME type = Print_Titles
    end
  end

  class FilterRange < CellRange
    def name_record_short(ext_ref, hidden)
      super(0x0D, ext_ref, hidden) # 0x0D  NAME type = Filter Database
    end

    def count
      if @col_min && @col_max
        1 + @col_max - @col_min
      else
        0
      end
    end

    def inside?(col)
      @col_min <= col && col <= @col_max
    end

    def store
      record          = 0x00EC           # Record identifier

      spid            = @worksheet.object_ids.spid

      # Number of objects written so far.
      num_objects     = @worksheet.images_size + @worksheet.charts_size

      (0 .. count-1).each do |i|
        if i == 0 && num_objects
          spid, data = write_parent_msodrawing_record(count, @worksheet.comments_size, spid, vertices(i))
        else
          spid, data = write_child_msodrawing_record(spid, vertices(i))
        end
        length      = data.bytesize
        header      = [record, length].pack("vv")
        append(header, data)

        store_obj_filter(num_objects + i + 1, col_min + i)
      end
      spid
    end

    private

    def write_parent_msodrawing_record(num_filters, num_comments, spid, vertices)
      # Write the parent MSODRAWIING record.
      dg_length   = 168 + 96 * (num_filters - 1)
      spgr_length = 144 + 96 * (num_filters - 1)

      dg_length   += 128 * num_comments
      spgr_length += 128 * num_comments

      data = store_parent_mso_record(dg_length, spgr_length, spid)
      spid += 1
      data += store_child_mso_record(spid, *vertices)
      spid += 1
      [spid, data]
    end

    def write_child_msodrawing_record(spid, vertices)
      data = store_child_mso_record(spid, *vertices)
      spid += 1
      [spid, data]
    end

    def store_parent_mso_record(dg_length, spgr_length, spid)
      @worksheet.__send__("store_parent_mso_record", dg_length, spgr_length, spid)
    end

    def store_child_mso_record(spid, *vertices)
      @worksheet.__send__("store_child_mso_record", spid, *vertices)
    end

    def vertices(i)
      [
        col_min + i,     0,
        row_min,         0,
        col_min + i + 1, 0,
        row_min + 1,     0
      ]
    end

    #
    # Write the OBJ record that is part of filter records.
    #    obj_id        # Object ID number.
    #    col
    #
    def store_obj_filter(obj_id, col)   #:nodoc:
      record      = 0x005D   # Record identifier
      length      = 0x0046   # Bytes to follow

      obj_type    = 0x0014   # Object type (combo box).
      data        = ''       # Record data.

      sub_record  = 0x0000   # Sub-record identifier.
      sub_length  = 0x0000   # Length of sub-record.
      sub_data    = ''       # Data of sub-record.
      options     = 0x2101
      reserved    = 0x0000

      # Add ftCmo (common object data) subobject
      sub_record  = 0x0015   # ftCmo
      sub_length  = 0x0012
      sub_data    = [obj_type, obj_id, options, reserved, reserved, reserved].pack('vvvVVV')
      data        = [sub_record, sub_length].pack('vv') + sub_data

      # Add ftSbs Scroll bar subobject
      sub_record  = 0x000C   # ftSbs
      sub_length  = 0x0014
      sub_data    = ['0000000000000000640001000A00000010000100'].pack('H*')
      data        += [sub_record, sub_length].pack('vv') + sub_data

      # Add ftLbsData (List box data) subobject
      sub_record  = 0x0013   # ftLbsData
      sub_length  = 0x1FEE   # Special case (undocumented).

      # If the filter is active we set one of the undocumented flags.

      if @worksheet.instance_variable_get(:@filter_cols)[col]
        sub_data       = ['000000000100010300000A0008005700'].pack('H*')
      else
        sub_data       = ['00000000010001030000020008005700'].pack('H*')
      end

      data        += [sub_record, sub_length].pack('vv') + sub_data

      # Add ftEnd (end of object) subobject
      sub_record  = 0x0000   # ftNts
      sub_length  = 0x0000
      data        += [sub_record, sub_length].pack('vv')

      # Pack the record.
      header  = [record, length].pack('vv')

      append(header, data)
    end

    def append(*args)
      @worksheet.append(*args)
    end
  end
end

end
