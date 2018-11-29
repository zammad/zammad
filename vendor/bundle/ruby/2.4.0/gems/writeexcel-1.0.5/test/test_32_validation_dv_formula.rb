# -*- coding: utf-8 -*-
##########################################################################
# test_32_validation_dv_formula.rb
#
# Tests for the Excel DVAL structure used in data validation.
#
# reverse('©'), September 2005, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
#########################################################################
require 'helper'
require 'stringio'

class TC_validation_dv_formula < Test::Unit::TestCase

  def setup
    @workbook   = WriteExcel.new(StringIO.new)
    @worksheet  = @workbook.add_worksheet
    @worksheet2 = @workbook.add_worksheet
    @data_validation = Writeexcel::Worksheet::DataValidation.new(@worksheet.__send__("parser"), {})
  end

  def teardown
    if @workbook.instance_variable_get(:@filehandle)
      @workbook.instance_variable_get(:@filehandle).close(true)
    end
    if @worksheet.instance_variable_get(:@filehandle)
      @worksheet.instance_variable_get(:@filehandle).close(true)
    end
  end

  def test_integer_values
    formula      = '10'

    caption    = " \tData validation: _pack_dv_formula('#{formula}')"
    bytes      = %w(
                    03 00 00 E0 1E 0A 00
                 )

    # Zero out Excel's random unused word to allow comparison.
    bytes[2]   = '00'
    bytes[3]   = '00'
    target     = bytes.join(" ")

    result     = unpack_record(@data_validation.__send__("pack_dv_formula", formula))
    assert_equal(target, result, caption)
  end

  def test_decimal_values
    formula      = '1.2345'

    caption    = " \tData validation: _pack_dv_formula('#{formula}')"
    bytes      = %w(
                    09 00 E0 3F 1F 8D 97 6E 12 83 C0 F3 3F
                 )

    # Zero out Excel's random unused word to allow comparison.
    bytes[2]   = '00'
    bytes[3]   = '00'
    target     = bytes.join(" ")

    result     = unpack_record(@data_validation.__send__("pack_dv_formula", formula))
    assert_equal(target, result, caption)
  end

  def test_date_values
    formula      = @worksheet.__send__("convert_date_time", '2008-07-24T')

    caption    = " \tData validation: _pack_dv_formula('2008-07-24T')"
    bytes      = %w(
                    03 00 E0 3F 1E E5 9A
                 )

    # Zero out Excel's random unused word to allow comparison.
    bytes[2]   = '00'
    bytes[3]   = '00'
    target     = bytes.join(" ")

    result     = unpack_record(@data_validation.__send__("pack_dv_formula", formula))
    assert_equal(target, result, caption)
  end

  def test_time_values
    formula      = @worksheet.__send__("convert_date_time", 'T12:00')

    caption    = " \tData validation: _pack_dv_formula('T12:00')"
    bytes      = %w(
                    09 00 E0 3F 1F 00 00 00 00 00 00 E0 3F
                 )

    # Zero out Excel's random unused word to allow comparison.
    bytes[2]   = '00'
    bytes[3]   = '00'
    target     = bytes.join(" ")

    result     = unpack_record(@data_validation.__send__("pack_dv_formula", formula))
    assert_equal(target, result, caption)
  end

  def test_cell_reference_value_C9
    formula      = '=C9'

    caption    = " \tData validation: _pack_dv_formula('#{formula}')"
    bytes      = %w(
                    05 00 E0 3F 44 08 00 02 C0
                 )

    # Zero out Excel's random unused word to allow comparison.
    bytes[2]   = '00'
    bytes[3]   = '00'
    target     = bytes.join(" ")

    result     = unpack_record(@data_validation.__send__("pack_dv_formula", formula))
    assert_equal(target, result, caption)
  end

  def test_cell_reference_value_E3_E6
    formula      = '=E3:E6'

    caption    = " \tData validation: _pack_dv_formula('#{formula}')"
    bytes      = %w(
                    09 00 0C 00 25 02 00 05 00 04 C0 04 C0
                 )

    # Zero out Excel's random unused word to allow comparison.
    bytes[2]   = '00'
    bytes[3]   = '00'
    target     = bytes.join(" ")

    result     = unpack_record(@data_validation.__send__("pack_dv_formula", formula))
    assert_equal(target, result, caption)
  end

  def test_cell_reference_value_E3_E6_absolute
    formula      = '=$E$3:$E$6'

    caption    = " \tData validation: _pack_dv_formula('#{formula}')"
    bytes      = %w(
                    09 00 0C 00 25 02 00 05 00 04 00 04 00
                 )

    # Zero out Excel's random unused word to allow comparison.
    bytes[2]   = '00'
    bytes[3]   = '00'
    target     = bytes.join(" ")

    result     = unpack_record(@data_validation.__send__("pack_dv_formula", formula))
    assert_equal(target, result, caption)
  end

  def test_list_values
    formula      = ['a', 'bb', 'ccc']

    caption    = " \tData validation: _pack_dv_formula(['a', 'bb', 'ccc'])"
    bytes      = %w(
                    0B 00 0C 00 17 08 00 61 00 62 62 00 63 63 63
                 )

    # Zero out Excel's random unused word to allow comparison.
    bytes[2]   = '00'
    bytes[3]   = '00'
    target     = bytes.join(" ")

    result     = unpack_record(@data_validation.__send__("pack_dv_formula", formula))
    assert_equal(target, result, caption)
  end

  def test_empty_string
    formula      = ''

    caption    = " \tData validation: _pack_dv_formula('')"
    bytes      = %w(
                    00 00 00
                 )

    # Zero out Excel's random unused word to allow comparison.
    bytes[2]   = '00'
    bytes[3]   = '00'
    target     = bytes.join(" ")

    result     = unpack_record(@data_validation.__send__("pack_dv_formula", formula))
    assert_equal(target, result, caption)
  end

  def test_undefined_value
    formula      = nil

    caption    = " \tData validation: _pack_dv_formula(nil)"
    bytes      = %w(
                    00 00 00
                 )

    # Zero out Excel's random unused word to allow comparison.
    bytes[2]   = '00'
    bytes[3]   = '00'
    target     = bytes.join(" ")

    result     = unpack_record(@data_validation.__send__("pack_dv_formula", formula))
    assert_equal(target, result, caption)
  end

  def test_pack_dv_formula_should_not_change_formula_string
    formula = '=SUM(A1:D1)'
    @data_validation.__send__("pack_dv_formula", formula)

    assert_equal('=SUM(A1:D1)', formula)
  end
end
