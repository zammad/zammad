# -*- coding: utf-8 -*-
###############################################################################
#
# A test for WriteExcel.
#
#
# all test is commented out because Workbook#add_mso_... was set to private
# method. Before that, all test passed.
#
#
#
#
# Tests for the internal methods used to write the records in an Escher drawing
# object such as images, comments and filters.
#
# reverse('©'), September 2005, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
############################################################################
require 'helper'
require 'stringio'

class TC_escher < Test::Unit::TestCase

  def setup
    @workbook  = WriteExcel.new(StringIO.new)
    @worksheet = @workbook.add_worksheet
  end

  def teardown
    if @workbook.instance_variable_get(:@filehandle)
      @workbook.instance_variable_get(:@filehandle).close(true)
    end
    if @worksheet.instance_variable_get(:@filehandle)
      @worksheet.instance_variable_get(:@filehandle).close(true)
    end
  end

  def test_for_store_mso_dg_container
    caption = sprintf(" \t_store_mso_dg_container()")
    data    = [0xC8]
    target  = %w( 0F 00 02 F0 C8 00 00 00 ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_dg_container", *data))

    assert_equal(target, result, caption)
  end

  def test_for_store_mso_dg
    caption = sprintf(" \t_store_mso_dg()")
    @worksheet.instance_variable_set(:@object_ids, Writeexcel::Worksheet::ObjectIds.new(nil, 1, 2, 1025))
    target  = %w( 10 00 08 F0
    08 00 00 00 02 00 00 00 01 04 00 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_dg"))

    assert_equal(target, result, caption)
  end

  def test_for_store_mso_dgg
    caption = sprintf(" \t_store_mso_dgg()")
    data    = [ 1026, 2, 2, 1, [[1,2]] ]
    target  = %w( 00 00 06 F0
    18 00 00 00 02 04 00 00 02 00 00 00 02 00 00 00
    01 00 00 00 01 00 00 00 02 00 00 00
    ).join(' ')

    result  = unpack_record(@workbook.__send__("store_mso_dgg", *data))

    assert_equal(target, result, caption)
  end

  def test_for_store_mso_spgr_container
    caption = sprintf(" \t_store_mso_spgr_container()")
    data    = [0xB0]
    target  = %w(
    0F 00 03 F0 B0 00 00 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_spgr_container", *data))

    assert_equal(target, result, caption)
  end

  def test_for_store_mso_sp_container
    caption = sprintf(" \t_store_mso_sp_container()")
    data    = [0x28]
    target  = %w(
    0F 00 04 F0 28 00 00 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_sp_container", *data))

    assert_equal(target, result, caption)
  end

  def test_for_store_mso_sp
    caption = sprintf(" \t_store_mso_sp()")
    data    = [0, 1024, 0x0005]
    target  = %w(
    02 00 0A F0 08 00 00 00 00 04 00 00 05 00 00 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_sp", *data))

    assert_equal(target, result, caption)

    data    = [202, 1025, 0x0A00]
    target  = %w(
    A2 0C 0A F0 08 00 00 00 01 04 00 00 00 0A 00 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_sp", *data))

    assert_equal(target, result, caption)
  end

  def test_for_store_mso_opt_comment
    caption = sprintf(" \t_store_mso_opt_comment()")
    comment = Writeexcel::Worksheet::Comment.new(@worksheet, 1, 1, ' ')
    data    = [0x80]
    target  = %w(
    93 00 0B F0 36 00 00 00
    80 00 00 00 00 00 BF 00 08 00 08 00
    58 01 00 00 00 00 81 01 50 00 00 08 83 01 50 00
    00 08 BF 01 10 00 11 00 01 02 00 00 00 00 3F 02
    03 00 03 00 BF 03 02 00 0A 00
    ).join(' ')

    result  = unpack_record(comment.store_mso_opt_comment(*data))

    assert_equal(target, result, caption)
  end

  def test_for_store_mso_client_data
    caption = sprintf(" \t_store_mso_client_data")
    target  = %w(
    00 00 11 F0 00 00 00 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_data"))

    assert_equal(target, result, caption)
  end

  def test_for_obj_comment_record
    caption = sprintf(" \t_obj_comment_record")
    comment = Writeexcel::Worksheet::Comment.new(@worksheet, 1, 1, ' ')
    data = [0x01]
    target  = %w(
    5D 00 34 00 15 00 12 00 19 00 01 00 11 40 00 00
    00 00 00 00 00 00 00 00 00 00 0D 00 16 00 00 00
    00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
    00 00 00 00 00 00 00 00
    ).join(' ')

    result  = unpack_record(comment.obj_comment_record(*data))

    assert_equal(target, result, caption)
  end

  def test_for_store_mso_client_text_box
    caption = sprintf(" \t_store_mso_client_text_box")
    comment = Writeexcel::Worksheet::Comment.new(@worksheet, 1, 1, ' ')
    target  = %w(
    00 00 0D F0 00 00 00 00
    ).join(' ')

    result  = unpack_record(comment.__send__("store_mso_client_text_box"))

    assert_equal(target, result, caption)
  end

  def test_for_store_mso_client_anchor

    # A1
    range   = 'A1'
    caption = sprintf(" \t_store_mso_client_anchor(%s)", range)
    row, col = @worksheet.__send__("substitute_cellref", range)
    vertices = Writeexcel::Worksheet::Comment.new(@worksheet, row, col, 'Test').vertices
    target  = %w(
    00 00 10 F0 12 00 00 00 03 00 01 00 F0 00 00 00
    1E 00 03 00 F0 00 04 00 78 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_anchor", 3, *vertices))

    assert_equal(target, result, caption)

    # A2
    range   = 'A2'
    caption = sprintf(" \t_store_mso_client_anchor(%s)", range)
    row, col = @worksheet.__send__("substitute_cellref", range)
    vertices = Writeexcel::Worksheet::Comment.new(@worksheet, row, col, 'Test').vertices
    target  = %w(
    00 00 10 F0 12 00 00 00 03 00 01 00 F0 00 00 00
    69 00 03 00 F0 00 04 00 C4 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_anchor", 3, *vertices))

    assert_equal(target, result, caption)


    # A3
    range   = 'A3'
    caption = sprintf(" \t_store_mso_client_anchor(%s)", range)
    row, col = @worksheet.__send__("substitute_cellref", range)
    vertices = Writeexcel::Worksheet::Comment.new(@worksheet, row, col, 'Test').vertices
    target  = %w(
    00 00 10 F0 12 00 00 00 03 00 01 00 F0 00 01 00
    69 00 03 00 F0 00 05 00 C4 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_anchor", 3, *vertices))

    assert_equal(target, result, caption)


    # A65534
    range   = 'A65534'
    caption = sprintf(" \t_store_mso_client_anchor(%s)", range)
    row, col = @worksheet.__send__("substitute_cellref", range)
    vertices = Writeexcel::Worksheet::Comment.new(@worksheet, row, col, 'Test').vertices
    target  = %w(
    00 00 10 F0 12 00 00 00 03 00 01 00 F0 00 F9 FF
    3C 00 03 00 F0 00 FD FF 97 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_anchor", 3, *vertices))

    assert_equal(target, result, caption)


    # A65536
    range   = 'A65536'
    caption = sprintf(" \t_store_mso_client_anchor(%s)", range)
    row, col = @worksheet.__send__("substitute_cellref", range)
    vertices = Writeexcel::Worksheet::Comment.new(@worksheet, row, col, 'Test').vertices
    target  = %w(
    00 00 10 F0 12 00 00 00 03 00 01 00 F0 00 FB FF
    1E 00 03 00 F0 00 FF FF 78 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_anchor", 3, *vertices))

    assert_equal(target, result, caption)


    # IT3
    range   = 'IT3'
    caption = sprintf(" \t_store_mso_client_anchor(%s)", range)
    row, col = @worksheet.__send__("substitute_cellref", range)
    vertices = Writeexcel::Worksheet::Comment.new(@worksheet, row, col, 'Test').vertices
    target  = %w(
    00 00 10 F0 12 00 00 00 03 00 FA 00 10 03 01 00
    69 00 FC 00 10 03 05 00 C4 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_anchor", 3, *vertices))

    assert_equal(target, result, caption)


    # IU3
    range   = 'IU3'
    caption = sprintf(" \t_store_mso_client_anchor(%s)", range)
    row, col = @worksheet.__send__("substitute_cellref", range)
    vertices = Writeexcel::Worksheet::Comment.new(@worksheet, row, col, 'Test').vertices
    target  = %w(
    00 00 10 F0 12 00 00 00 03 00 FB 00 10 03 01 00
    69 00 FD 00 10 03 05 00 C4 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_anchor", 3, *vertices))

    assert_equal(target, result, caption)


    #
    range   = 'IU3'
    caption = sprintf(" \t_store_mso_client_anchor(%s)", range)
    row, col = @worksheet.__send__("substitute_cellref", range)
    vertices = Writeexcel::Worksheet::Comment.new(@worksheet, row, col, 'Test').vertices
    target  = %w(
    00 00 10 F0 12 00 00 00 03 00 FB 00 10 03 01 00
    69 00 FD 00 10 03 05 00 C4 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_anchor", 3, *vertices))

    assert_equal(target, result, caption)


    # IV3
    range   = 'IV3'
    caption = sprintf(" \t_store_mso_client_anchor(%s)", range)
    row, col = @worksheet.__send__("substitute_cellref", range)
    vertices = Writeexcel::Worksheet::Comment.new(@worksheet, row, col, 'Test').vertices
    target  = %w(
    00 00 10 F0 12 00 00 00 03 00 FC 00 10 03 01 00
    69 00 FE 00 10 03 05 00 C4 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_anchor", 3, *vertices))

    assert_equal(target, result, caption)

  end

  def test_for_store_mso_client_anchor_where_comment_offsets_have_changed
    range    = 'A3'
    caption  = sprintf(" \t_store_mso_client_anchor(%s). Cell offsets changes.", range)
    row, col = @worksheet.__send__("substitute_cellref", range)
    vertices = Writeexcel::Worksheet::Comment.new(@worksheet, row, col, 'Test',
      :x_offset => 18, :y_offset => 9).vertices
    target  = %w(
    00 00 10 F0 12 00
    00 00 03 00 01 00 20 01 01 00 88 00 03 00 20 01
    05 00 E2 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_anchor", 3, *vertices))

    assert_equal(target, result, caption)
  end

  def test_for_store_mso_client_anchor_where_comment_dimensions_have_changed
    # x_scale, y_scale
    range   = 'A3'
    caption = sprintf(" \t_store_mso_client_anchor(%s). Dimensions changes.", range)
    row, col = @worksheet.__send__("substitute_cellref", range)
    vertices = Writeexcel::Worksheet::Comment.new(@worksheet, row, col, 'Test',
      :x_scale => 3, :y_scale => 2).vertices
    target  = %w(
    00 00 10 F0 12 00 00 00 03 00
    01 00 F0 00 01 00 69 00 07 00 F0 00 0A 00 1E 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_anchor", 3, *vertices))

    assert_equal(target, result, caption)


    # width, height
    row, col = @worksheet.__send__("substitute_cellref", range)
    vertices = Writeexcel::Worksheet::Comment.new(@worksheet, row, col, 'Test',
      :width => 384, :height => 148).vertices
    target  = %w(
    00 00 10 F0 12 00 00 00 03 00
    01 00 F0 00 01 00 69 00 07 00 F0 00 0A 00 1E 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_anchor", 3, *vertices))

    assert_equal(target, result, caption)

  end

  def test_for_store_mso_client_anchor_where_column_widths_have_changed
    # set_column G:G
    range = 'F3'
    @worksheet.set_column('G:G', 20)

    caption = sprintf(" \t_store_mso_client_anchor(%s). Col width changes.", range)
    row, col = @worksheet.__send__("substitute_cellref", range)
    vertices = Writeexcel::Worksheet::Comment.new(@worksheet, row, col, 'Test').vertices

    target  = %w(
    00 00 10 F0 12 00
    00 00 03 00 06 00 6A 00 01 00 69 00 06 00 F2 03
    05 00 C4 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_anchor", 3, *vertices))

    assert_equal(target, result, caption)


    # set_column L:O
    range = 'K3'
    @worksheet.set_column('L:O', 4)

    row, col = @worksheet.__send__("substitute_cellref", range)
    vertices = Writeexcel::Worksheet::Comment.new(@worksheet, row, col, 'Test').vertices

    target  = %w(
    00 00 10 F0 12 00
    00 00 03 00 0B 00 D1 01 01 00 69 00 0F 00 B0 00
    05 00 C4 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_anchor", 3, *vertices))

    assert_equal(target, result, caption)

  end

  def test_for_store_mso_client_anchor_where_row_height_have_changed
    # set_row 5 to 8
    range = 'A6'
    @worksheet.set_row(5, 6)
    @worksheet.set_row(6, 6)
    @worksheet.set_row(7, 6)
    @worksheet.set_row(8, 6)

    caption = sprintf(" \t_store_mso_client_anchor(%s). Row height changed.", range)
    row, col = @worksheet.__send__("substitute_cellref", range)
    vertices = Writeexcel::Worksheet::Comment.new(@worksheet, row, col, 'Test').vertices

    target  = %w(
    00 00 10 F0 12 00
    00 00 03 00 01 00 F0 00 04 00 69 00 03 00 F0 00
    0A 00 E2 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_anchor", 3, *vertices))

    assert_equal(target, result, caption)


    # set_row 14
    range = 'A15'
    @worksheet.set_row(14, 60)

    caption = sprintf(" \t_store_mso_client_anchor(%s). Row height changed.", range)
    row, col = @worksheet.__send__("substitute_cellref", range)
    vertices = Writeexcel::Worksheet::Comment.new(@worksheet, row, col, 'Test').vertices

    target  = %w(
    00 00 10 F0 12 00
    00 00 03 00 01 00 F0 00 0D 00 69 00 03 00 F0 00
    0E 00 CD 00
    ).join(' ')

    result  = unpack_record(@worksheet.__send__("store_mso_client_anchor", 3, *vertices))

    assert_equal(target, result, caption)

  end

=begin
  def test_for_the_generic_method
    data_for_test.each do |data|
      caption = data.shift
      target  = data.pop

      data[3].gsub!(/ /,'')
      data[3] = [data[3]].pack('H*')

      caption = sprintf(" \t_add_mso_generic(): (0x%04X) %s", data[0], caption)

      result = unpack_record(@worksheet.add_mso_generic(*data))

      assert_equal(target, result, caption)
    end
  end

  def test_for_store_mso_dgg_container
    caption = sprintf(" \t_store_mso_dgg_container()")
    target  = %w( 0F 00 00 F0 52 00 00 00 ).join(' ')

    @workbook.mso_size = 94
    result  = unpack_record(@workbook.store_mso_dgg_container)

    assert_equal(target, result, caption)
  end

  def test_for_store_mso_opt
    caption = sprintf(" \t_store_mso_opt()")
    target  = %w( 33 00 0B F0
    12 00 00 00 BF 00 08 00 08 00 81 01 09 00 00 08
    C0 01 40 00 00 08
    ).join(' ')

    result  = unpack_record(@workbook.store_mso_opt)

    assert_equal(target, result, caption)
  end

  def test_for_store_mso_split_menu_colors
    caption = sprintf(" \t_store_mso_split_menu_colors()")
    target  = %w( 40 00 1E F1 10 00 00 00 0D 00
    00 08 0C 00 00 08 17 00 00 08 F7 00 00 10
    ).join(' ')

    result  = unpack_record(@workbook.store_mso_split_menu_colors)

    assert_equal(target, result, caption)
  end

  def data_for_test
    return [
      [   'DggContainer',                 # Caption
        0xF000,                         # Type
        15,                             # Version
        0,                              # Instance
        '',                             # Data
        82,                             # Length
        '0F 00 00 F0 52 00 00 00',      # Target
      ],

      [   'DgContainer',                  # Caption
        0xF002,                         # Type
        15,                             # Version
        0,                              # Instance
        '',                             # Data
        328,                            # Length
        '0F 00 02 F0 48 01 00 00',      # Target
      ],

      [   'SpgrContainer',                # Caption
        0xF003,                         # Type
        15,                             # Version
        0,                              # Instance
        '',                             # Data
        304,                            # Length
        '0F 00 03 F0 30 01 00 00',      # Target
      ],

      [   'SpContainer',                  # Caption
        0xF004,                         # Type
        15,                             # Version
        0,                              # Instance
        '',                             # Data
        40,                             # Length
        '0F 00 04 F0 28 00 00 00',      # Target
      ],

      [   'Dgg',                          # Caption
        0xF006,                         # Type
        0,                              # Version
        0,                              # Instance
        '02 04 00 00 02 00 00 00 ' +    # Data
        '02 00 00 00 01 00 00 00 ' +
        '01 00 00 00 02 00 00 00',
        nil,                          # Length
        '00 00 06 F0 18 00 00 00 ' +    # Target
        '02 04 00 00 02 00 00 00 ' +
        '02 00 00 00 01 00 00 00 ' +
        '01 00 00 00 02 00 00 00',
      ],

      [   'Dg',                           # Caption
        0xF008,                         # Type
        0,                              # Version
        1,                              # Instance
        '03 00 00 00 02 04 00 00',      # Data
        nil,                          # Length
        '10 00 08 F0 08 00 00 00 ' +    # Target
        '03 00 00 00 02 04 00 00',
      ],

      [   'Spgr',                         # Caption
        0xF009,                         # Type
        1,                              # Version
        0,                              # Instance
        '00 0E 00 0E 40 41 00 00 ' +    # Data
        '00 0E 00 0E 40 41 00 00',
        nil,                          # Length
        '01 00 09 F0 10 00 00 00 ' +    # Target
        '00 0E 00 0E 40 41 00 00 ' +
        '00 0E 00 0E 40 41 00 00',
      ],

      [   'ClientTextbox',                # Caption
        0xF00D,                         # Type
        0,                              # Version
        0,                              # Instance
        '',                             # Data
        nil,                          # Length
        '00 00 0D F0 00 00 00 00',      # Target
      ],

      [   'ClientAnchor',                 # Caption
        0xF010,                         # Type
        0,                              # Version
        0,                              # Instance
        '03 00 01 00 F0 00 01 00 ' +    # Data
        '69 00 03 00 F0 00 05 00 ' +
        'C4 00',
        nil,                          # Length
        '00 00 10 F0 12 00 00 00 ' +    # Target
        '03 00 01 00 F0 00 01 00 ' +
        '69 00 03 00 F0 00 05 00 ' +
        'C4 00',
      ],

      [   'ClientData',                   # Caption
        0xF011,                         # Type
        0,                              # Version
        0,                              # Instance
        '',                             # Data
        nil,                          # Length
        '00 00 11 F0 00 00 00 00',      # Target
      ],

      [   'SplitMenuColors',              # Caption
        0xF11E,                         # Type
        0,                              # Version
        4,                              # Instance
        '0D 00 00 08 0C 00 00 08 ' +    # Data
        '17 00 00 08 F7 00 00 10',
        nil,                          # Length
        '40 00 1E F1 10 00 00 00 ' +    # Target
        '0D 00 00 08 0C 00 00 08 ' +
        '17 00 00 08 F7 00 00 10',
      ],

      [   'BstoreContainer',              # Caption
        0xF001,                         # Type
        15,                             # Version
        1,                              # Instance
        '',                             # Data
        163,                            # Length
        '1F 00 01 F0 A3 00 00 00',      # Target
      ],
    ]
  end
=end

end
