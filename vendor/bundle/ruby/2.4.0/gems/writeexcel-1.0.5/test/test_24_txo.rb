# -*- coding: utf-8 -*-
##########################################################################
# test_24_txo.rb
#
# Tests for some of the internal method used to write the NOTE record that
# is used in cell comments.
#
# reverse('©'), September 2005, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
#########################################################################
require 'helper'
require 'stringio'

class TC_txo < Test::Unit::TestCase

  def setup
    @workbook   = WriteExcel.new(StringIO.new)
    @worksheet  = @workbook.add_worksheet
  end

  def teardown
    if @workbook.instance_variable_get(:@filehandle)
      @workbook.instance_variable_get(:@filehandle).close(true)
    end
    if @worksheet.instance_variable_get(:@filehandle)
      @worksheet.instance_variable_get(:@filehandle).close(true)
    end
  end

  def test_txo
    string     = 'aaa'
    comment = Writeexcel::Worksheet::Comment.new(@worksheet, 1, 1, ' ')
    caption    = " \t_store_txo()"
    target     = %w(
                    B6 01 12 00 12 02 00 00 00 00 00 00 00 00 03 00
                    10 00 00 00 00 00
                   ).join(' ')

    result     = unpack_record(comment.__send__("store_txo", string.length))
    assert_equal(target, result, caption)
  end

  def test_first_continue_record_after_txo
    string     = 'aaa'
    comment = Writeexcel::Worksheet::Comment.new(@worksheet, 1, 1, ' ')
    caption    = " \t_store_txo_continue_1()"
    target     = %w(
                    3C 00 04 00 00 61 61 61
                   ).join(' ')

    result     = unpack_record(comment.__send__("store_txo_continue_1", string))
    assert_equal(target, result, caption)
  end

  def test_second_continue_record_after_txo
    string     = 'aaa'
    comment = Writeexcel::Worksheet::Comment.new(@worksheet, 1, 1, ' ')
    caption    = " \t_store_txo_continue_2()"
    target     = %w(
                    3C 00 10 00 00 00 00 00 00 00 00 00 03 00 00 00
                    00 00 00 00
                   ).join(' ')
    formats    = [
                    [0,             0],
                    [string.length, 0]
                 ]

    result     = unpack_record(comment.__send__("store_txo_continue_2", formats))
    assert_equal(target, result, caption)
  end
end
