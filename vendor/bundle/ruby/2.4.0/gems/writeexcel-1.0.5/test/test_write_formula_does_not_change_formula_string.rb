# -*- coding: utf-8 -*-
require 'helper'
require 'writeexcel'
require 'stringio'

class TestWriteFormula < Test::Unit::TestCase
  def setup
    @workbook = WriteExcel.new(StringIO.new)
    @worksheet = @workbook.add_worksheet('')
  end

  def teardown
    if @workbook.instance_variable_get(:@filehandle)
      @workbook.instance_variable_get(:@filehandle).close(true)
    end
    if @worksheet.instance_variable_get(:@filehandle)
      @worksheet.instance_variable_get(:@filehandle).close(true)
    end
  end

  def test_write_formula_does_not_change_formula_string
    formula = '=PI()'
    @worksheet.write('A1', formula)

    assert_equal('=PI()', formula)
  end
end
