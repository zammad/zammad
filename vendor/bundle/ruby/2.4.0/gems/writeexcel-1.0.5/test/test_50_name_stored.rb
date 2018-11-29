  # -*- coding: utf-8 -*-
##########################################################################
# test_50_name_stored.rb
#
# Tests for the Excel EXTERNSHEET and NAME records created by print_are()..
#
# reverse('ｩ'), September 2008, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
#########################################################################
require 'helper'
require 'stringio'

class TC_Name_Stored < Test::Unit::TestCase
  def setup
    @test_file = StringIO.new
    @workbook   = WriteExcel.new(@test_file)
    @worksheet  = @workbook.add_worksheet
  end

  def test_print_area_name_with_simple_range
    caption        = " \tNAME for worksheet1.print_area('A1:B12')"
    name           = [0x06].pack('C')
    encoding       = 0
    sheet_index    = 1
    formula        = ['3B000000000B0000000100'].pack('H*')

    result         = @workbook.__send__("store_name",
                                          name,
                                          encoding,
                                          sheet_index,
                                          formula
                                        )
    target = [%w(
               18 00 1B 00 20 00 00 01 0B 00 00 00 01 00 00 00
               00 00 00 06 3B 00 00 00 00 0B 00 00 00 01 00
             ).join('')].pack('H*')

#    result         = _unpack_name(result)
#    target         = _unpack_name(target)
    assert_equal(unpack_record(target), unpack_record(result))
  end

  def test_print_area_name_with_simple_range_in_sheet_3
    caption        = " \tNAME for worksheet3.print_area('G7:H8')"
    name           = [0x06].pack('C')
    encoding       = 0
    sheet_index    = 3
    formula        = ['3B02000600070006000700'].pack('H*')

    result         = @workbook.__send__("store_name",
                         name,
                         encoding,
                         sheet_index,
                         formula
                      )

    target         = [%w(
              18 00 1B 00 20 00 00 01 0B 00 00 00 03 00 00 00
              00 00 00 06 3B 02 00 06 00 07 00 06 00 07 00
      ).join('')].pack('H*')

#    result         = _unpack_name(result)
#    target         = _unpack_name(target)
    assert_equal(unpack_record(target), unpack_record(result))
  end

  def test_for_repeat_rows_name
    caption        = " \tNAME for worksheet1.repeat_rows(0, 9)"
    name           = [0x07].pack('C')
    encoding       = 0
    sheet_index    = 1
    formula        = ['3B0000000009000000FF00'].pack('H*')

    result         = @workbook.__send__("store_name",
                         name,
                         encoding,
                         sheet_index,
                         formula
                      )

    target         = [%w(
        18 00 1B 00 20 00 00 01 0B 00 00 00 01 00 00 00
        00 00 00 07 3B 00 00 00 00 09 00 00 00 FF 00
     ).join('')].pack('H*')

#    result         = _unpack_name(result)
#    target         = _unpack_name(target)
    assert_equal(unpack_record(target), unpack_record(result))
  end

  def test_for_repeat_rows_name_on_sheet_3
    caption        = " \tNAME for worksheet3.repeat_rows(6, 7)"
    name           = [0x07].pack('C')
    encoding       = 0
    sheet_index    = 1
    formula        = ['3B0000000009000000FF00'].pack('H*')

    result         = @workbook.__send__("store_name",
                         name,
                         encoding,
                         sheet_index,
                         formula
                      )

    target         = [%w(
        18 00 1B 00 20 00 00 01 0B 00 00 00 01 00 00 00
        00 00 00 07 3B 00 00 00 00 09 00 00 00 FF 00
     ).join('')].pack('H*')

#    result         = _unpack_name(result)
#    target         = _unpack_name(target)
    assert_equal(unpack_record(target), unpack_record(result))
  end

  def test_for_repeat_columns_name
    caption        = " \tNAME for worksheet1.repeat_columns('A:J')"
    name           = [0x07].pack('C')
    encoding       = 0
    sheet_index    = 1
    formula        = ['3B00000000FFFF00000900'].pack('H*')

    result         = @workbook.__send__("store_name",
                         name,
                         encoding,
                         sheet_index,
                         formula
                      )

    target         = [%w(
        18 00 1B 00 20 00 00 01 0B 00 00 00 01 00 00 00
        00 00 00 07 3B 00 00 00 00 FF FF 00 00 09 00
     ).join('')].pack('H*')

#    result         = _unpack_name(result)
#    target         = _unpack_name(target)
    assert_equal(unpack_record(target), unpack_record(result))
  end

  def test_for_repeat_rows_and_repeat_columns_together_name
    caption        = " \tNAME for repeat_rows(1, 2) repeat_columns(3, 4)"
    name           = [0x07].pack('C')
    encoding       = 0
    sheet_index    = 1
    formula        = ['2917003B00000000FFFF030004003B0000010002000000FF0010'].pack('H*')

    result         = @workbook.__send__("store_name",
                         name,
                         encoding,
                         sheet_index,
                         formula
                      )

    target         = [%w(
        18 00 2A 00 20 00 00 01 1A 00 00 00 01 00 00 00
        00 00 00 07 29 17 00 3B 00 00 00 00 FF FF 03 00
        04 00 3B 00 00 01 00 02 00 00 00 FF 00 10
     ).join('')].pack('H*')

#    result         = _unpack_name(result)
#    target         = _unpack_name(target)
    assert_equal(unpack_record(target), unpack_record(result))
  end

  def test_for_print_area_name_with_simple_range
    caption        = " \tNAME for worksheet1.autofilter('A1:C5')"
    name           = [0x0D].pack('C')
    encoding       = 0
    sheet_index    = 1
    formula        = ['3B00000000040000000200'].pack('H*')

    result         = @workbook.__send__("store_name",
                         name,
                         encoding,
                         sheet_index,
                         formula
                      )

    target         = [%w(
        18 00 1B 00 21 00 00 01 0B 00 00 00 01 00 00 00
        00 00 00 0D 3B 00 00 00 00 04 00 00 00 02 00
     ).join('')].pack('H*')

#    result         = _unpack_name(result)
#    target         = _unpack_name(target)
    assert_equal(unpack_record(target), unpack_record(result))
  end

  def test_for_define_name_global_name
    caption        = " \tNAME for worksheet1.define_name('Foo', ...)"
    name           = 'Foo'
    encoding       = 0
    sheet_index    = 0
    formula        = ['3A000007000100'].pack('H*')

    result         = @workbook.__send__("store_name",
                         name,
                         encoding,
                         sheet_index,
                         formula
                      )

    target         = [%w(
        18 00 19 00 00 00 00 03 07 00 00 00 00 00 00 00
        00 00 00 46 6F 6F 3A 00 00 07 00 01 00
     ).join('')].pack('H*')

#    result         = _unpack_name(result)
#    target         = _unpack_name(target)
    assert_equal(unpack_record(target), unpack_record(result))
  end

  ###############################################################################
  #
  # _unpack_name()
  #
  # Unpack 1 or more NAME structures into a AoH for easier comparison.
  #
  def _unpack_name(data)
    names = Array.new
    while data.length > 0
      name = Hash.new

      name['record']       = data[0, 2].unpack('v')[0]
      data[0, 2] = ''
      name['length']       = data[0, 2].unpack('v')[0]
      data[0, 2] = ''
      name['flags']        = data[0, 2].unpack('v')[0]
      data[0, 2] = ''
      name['shortcut']     = data[0, 1].unpack('C')[0]
      data[0, 1] = ''
      name['str_len']      = data[0, 1].unpack('C')[0]
      data[0, 1] = ''
      name['formula_len']  = data[0, 2].unpack('v')[0]
      data[0, 2] = ''
      name['itals']        = data[0, 2].unpack('v')[0]
      data[0, 2] = ''
      name['sheet_index']  = data[0, 2].unpack('v')[0]
      data[0, 2] = ''
      name['menu_len']     = data[0, 1].unpack('C')[0]
      data[0, 1] = ''
      name['desc_len']     = data[0, 1].unpack('C')[0]
      data[0, 1] = ''
      name['help_len']     = data[0, 1].unpack('C')[0]
      data[0, 1] = ''
      name['status_len']   = data[0, 1].unpack('C')[0]
      data[0, 1] = ''
      name['encoding']     = data[0, 1].unpack('C')[0]
      data[0, 1] = ''

      # Decode the individual flag fields.
      flag = Hash.new
      flag['hidden']       = name['flags'] & 0x0001
      flag['function']     = name['flags'] & 0x0002
      flag['vb']           = name['flags'] & 0x0004
      flag['macro']        = name['flags'] & 0x0008
      flag['complex']      = name['flags'] & 0x0010
      flag['builtin']      = name['flags'] & 0x0020
      flag['group']        = name['flags'] & 0x0FC0
      flag['binary']       = name['flags'] & 0x1000
      name['flags'] = flag

      # Decode the string part of the NAME structure.
      if name['encoding'] == 1
        # UTF-16 name. Leave in hex.
        name['string'] = data[0, 2 * name['str_len']].unpack('H*')[0].upcase
        data[0, 2 * name['str_len']] = ''
      elsif flag['builtin'] != 0
        # 1 digit builtin name. Leave in hex.
        name['string'] = data[0, name['str_len']].unpack('H*')[0].upcase
        data[0, name['str_len']] = ''
      else
        # ASCII name.
        name['string'] = data[0, name['str_len']].unpack('C*').pack('C*')
        data[0, name['str_len']] = ''
      end

      # Keep the formula as a hex string.
      name['formula'] = data[0, name['formula_len']].unpack('H*')[0].upcase
      data[0, name['formula_len']] = ''

      names << name
    end
    names
  end

  def assert_hash_equal?(result, target)
    assert_equal(result.keys.sort, target.keys.sort)
    result.each_key do |key|
      assert_equal(result[key], target[key])
    end
  end
end
