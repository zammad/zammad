# -*- coding: utf-8 -*-
##########################################################################
# test_30_validation_dval.rb
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

class TC_validation_dval < Test::Unit::TestCase

  def setup
    @workbook   = WriteExcel.new(StringIO.new)
    @worksheet  = @workbook.add_worksheet
    @validations = Writeexcel::Worksheet::DataValidations.new
  end

  def teardown
    if @workbook.instance_variable_get(:@filehandle)
      @workbook.instance_variable_get(:@filehandle).close(true)
    end
    if @worksheet.instance_variable_get(:@filehandle)
      @worksheet.instance_variable_get(:@filehandle).close(true)
    end
  end

  def test_1
    obj_id     = 1
    dv_count   = 1

    caption    = " \tData validation: _store_dval(#{obj_id}, #{dv_count})"
    target     = %w(
                   B2 01 12 00 04 00 00 00 00 00 00 00 00 00 01 00
                   00 00 01 00 00 00
                 ).join(' ')

    result     = unpack_record(@validations.__send__("dval_record", obj_id, dv_count))
    assert_equal(target, result, caption)
  end

  def test_2
    obj_id     = -1
    dv_count   = 1

    caption    = " \tData validation: _store_dval(#{obj_id}, #{dv_count})"
    target     = %w(
                   B2 01 12 00 04 00 00 00 00 00 00 00 00 00 FF FF
                   FF FF 01 00 00 00
                 ).join(' ')

    result     = unpack_record(@validations.__send__("dval_record", obj_id, dv_count))
    assert_equal(target, result, caption)
  end

  def test_3
    obj_id     = 1
    dv_count   = 2

    caption    = " \tData validation: _store_dval(#{obj_id}, #{dv_count})"
    target     = %w(
                   B2 01 12 00 04 00 00 00 00 00 00 00 00 00 01 00
                   00 00 02 00 00 00
                 ).join(' ')

    result     = unpack_record(@validations.__send__("dval_record", obj_id, dv_count))
    assert_equal(target, result, caption)
  end
end
