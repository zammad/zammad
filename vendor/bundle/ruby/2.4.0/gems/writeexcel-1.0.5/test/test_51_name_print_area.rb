# -*- coding: utf-8 -*-
##########################################################################
# test_51_name_print_area.rb
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

class TC_Name_Print_Area < Test::Unit::TestCase
  def setup
    @test_file = StringIO.new
    @workbook   = WriteExcel.new(@test_file)
    @workbook.not_using_tmpfile
  end

  def test_print_area_name_for_a_simple_range
    worksheet1 = @workbook.add_worksheet
    area = 'A1:B12'

    worksheet1.print_area(area)

    # Test the EXTERNSHEET record.
    @workbook.__send__("calculate_extern_sizes")
    @workbook.__send__("store_externsheet")

    target         = [%w(
        17 00 08 00 01 00 00 00 00 00 00 00
     ).join('')].pack('H*')

    caption    = " \tExternsheet"
    result     = _unpack_externsheet(@workbook.data)
    target     = _unpack_externsheet(target)
    assert_equal(target, result)

    # Test the NAME record.
    @workbook.clear_data_for_test
    @workbook.__send__("store_names")

    target         = [%w(
        18 00 1B 00 20 00 00 01 0B 00 00 00 01 00 00 00
        00 00 00 06 3B 00 00 00 00 0B 00 00 00 01 00
     ).join('')].pack('H*')

    caption    = " \t+ Name      ( Sheet1!#{area} )";
    result     = _unpack_name(@workbook.data)
    target     = _unpack_name(target)
    assert_equal(target, result)
  end

  def test_print_area_name_for_a_simple_row
    worksheet1 = @workbook.add_worksheet
    area = 'A1:IV1'

    worksheet1.print_area(area)

    # Test the EXTERNSHEET record.
    @workbook.__send__("calculate_extern_sizes")
    @workbook.__send__("store_externsheet")

    target         = [%w(
        17 00 08 00 01 00 00 00 00 00 00 00
     ).join('')].pack('H*')

    caption    = " \tExternsheet"
    result     = _unpack_externsheet(@workbook.data)
    target     = _unpack_externsheet(target)
    assert_equal(target, result, caption)

    # Test the NAME record.
    @workbook.clear_data_for_test
    @workbook.__send__("store_names")

    target         = [%w(
        18 00 1B 00 20 00 00 01 0B 00 00 00 01 00 00 00
        00 00 00 06 3B 00 00 00 00 00 00 00 00 FF 00
     ).join('')].pack('H*')

    caption    = " \t+ Name      ( Sheet1!#{area} )";
    result     = _unpack_name(@workbook.data)
    target     = _unpack_name(target)
    assert_equal(target, result, caption)
  end

  def test_print_area_name_for_a_simple_column
    worksheet1 = @workbook.add_worksheet
    area = 'A1:A65536'

    worksheet1.print_area(area)

    # Test the EXTERNSHEET record.
    @workbook.__send__("calculate_extern_sizes")
    @workbook.__send__("store_externsheet")

    target         = [%w(
        17 00 08 00 01 00 00 00 00 00 00 00
     ).join('')].pack('H*')

    caption    = " \tExternsheet"
    result     = _unpack_externsheet(@workbook.data)
    target     = _unpack_externsheet(target)
    assert_equal(target, result)

    # Test the NAME record.
    @workbook.clear_data_for_test
    @workbook.__send__("store_names")

    target         = [%w(
        18 00 1B 00 20 00 00 01 0B 00 00 00 01 00 00 00
        00 00 00 06 3B 00 00 00 00 FF FF 00 00 00 00
     ).join('')].pack('H*')

    caption    = " \t+ Name      ( Sheet1!#{area} )";
    result     = _unpack_name(@workbook.data)
    target     = _unpack_name(target)
    assert_equal(target, result)
  end

  def test_print_area_name_for_a_multiple_column
    worksheet1 = @workbook.add_worksheet
    area = 'A:H'

    worksheet1.print_area(area)

    # Test the EXTERNSHEET record.
    @workbook.__send__("calculate_extern_sizes")
    @workbook.__send__("store_externsheet")

    target         = [%w(
        17 00 08 00 01 00 00 00 00 00 00 00
     ).join('')].pack('H*')

    caption    = " \tExternsheet"
    result     = _unpack_externsheet(@workbook.data)
    target     = _unpack_externsheet(target)
    assert_equal(target, result)

    # Test the NAME record.
    @workbook.clear_data_for_test
    @workbook.__send__("store_names")

    target         = [%w(
        18 00 1B 00 20 00 00 01 0B 00 00 00 01 00 00 00
        00 00 00 06 3B 00 00 00 00 FF FF 00 00 07 00
     ).join('')].pack('H*')

    caption    = " \t+ Name      ( Sheet1!#{area} )";
    result     = _unpack_name(@workbook.data)
    target     = _unpack_name(target)
    assert_equal(target, result)
  end

  def test_ranges_on_multiple_sheets
    worksheet1 = @workbook.add_worksheet
    worksheet2 = @workbook.add_worksheet
    worksheet3 = @workbook.add_worksheet

    worksheet1.print_area('A1:B2')
    worksheet2.print_area('D4:E5')
    worksheet3.print_area('G7:H8')

    # Test the EXTERNSHEET record.
    @workbook.__send__("calculate_extern_sizes")
    @workbook.__send__("store_externsheet")

    target         = [%w(
        17 00 14 00 03 00 00 00 00 00 00 00 00 00 01 00
        01 00 00 00 02 00 02 00
     ).join('')].pack('H*')

    caption    = " \tExternsheet"
    result     = _unpack_externsheet(@workbook.data)
    target     = _unpack_externsheet(target)
    assert_equal(target, result)

    # Test the NAME record.
    @workbook.clear_data_for_test
    @workbook.__send__("store_names")

    target         = [%w(
        18 00 1B 00 20 00 00 01 0B 00 00 00 01 00 00 00
        00 00 00 06 3B 00 00 00 00 01 00 00 00 01 00

        18 00 1B 00 20 00 00 01 0B 00 00 00 02 00 00 00
        00 00 00 06 3B 01 00 03 00 04 00 03 00 04 00

        18 00 1B 00 20 00 00 01 0B 00 00 00 03 00 00 00
        00 00 00 06 3B 02 00 06 00 07 00 06 00 07 00
     ).join('')].pack('H*')

    caption    = " \t+ Name      ( Sheet1!A1:B2, Sheet2!D4:E5, Sheet3!G7:H8 )";
    result     = _unpack_name(@workbook.data)
    target     = _unpack_name(target)
    assert_equal(target, result)
  end

  def test_ranges_on_multiple_sheets_with_sheets_spaced_out
    worksheet1 = @workbook.add_worksheet
    worksheet2 = @workbook.add_worksheet
    worksheet3 = @workbook.add_worksheet
    worksheet4 = @workbook.add_worksheet
    worksheet5 = @workbook.add_worksheet

    worksheet1.print_area('A1:B2')
    worksheet3.print_area('D4:E5')
    worksheet5.print_area('G7:H8')

    # Test the EXTERNSHEET record.
    @workbook.__send__("calculate_extern_sizes")
    @workbook.__send__("store_externsheet")

    target         = [%w(
        17 00 14 00 03 00 00 00 00 00 00 00 00 00 02 00
        02 00 00 00 04 00 04 00
     ).join('')].pack('H*')

    caption    = " \tExternsheet"
    result     = _unpack_externsheet(@workbook.data)
    target     = _unpack_externsheet(target)
    assert_equal(target, result)

    # Test the NAME record.
    @workbook.clear_data_for_test
    @workbook.__send__("store_names")

    target         = [%w(
        18 00 1B 00 20 00 00 01 0B 00 00 00 01 00 00 00
        00 00 00 06 3B 00 00 00 00 01 00 00 00 01 00

        18 00 1B 00 20 00 00 01 0B 00 00 00 03 00 00 00
        00 00 00 06 3B 01 00 03 00 04 00 03 00 04 00

        18 00 1B 00 20 00 00 01 0B 00 00 00 05 00 00 00
        00 00 00 06 3B 02 00 06 00 07 00 06 00 07 00
     ).join('')].pack('H*')

    caption    = " \t+ Name      ( Sheet1!A1:B2, Sheet3!D4:E5, Sheet5!G7:H8 )";
    result     = _unpack_name(@workbook.data)
    target     = _unpack_name(target)
    assert_equal(target, result)
  end

  ###############################################################################
  #
  # _unpack_externsheet()
  #
  # Unpack the EXTERNSHEET recordfor easier comparison.
  #
  def _unpack_externsheet(data)
      externsheet = Hash.new

      externsheet['record']       = data[0, 2].unpack('v')[0]
      data[0, 2] = ''
      externsheet['length']       = data[0, 2].unpack('v')[0]
      data[0, 2] = ''
      externsheet['count']        = data[0, 2].unpack('v')[0]
      data[0, 2] = ''
      externsheet['array']        = [];

      externsheet['count'].times do
          externsheet['array'] << data[0, 6].unpack('vvv')
          data[0, 6] = ''
      end
      externsheet
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
