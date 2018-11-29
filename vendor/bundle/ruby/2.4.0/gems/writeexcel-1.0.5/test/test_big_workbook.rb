# -*- coding: utf-8 -*-
require 'helper'
require 'stringio'

class TC_BigWorkbook < Test::Unit::TestCase

  def test_big_workbook_saves
    workbook = Workbook.new(StringIO.new)
    4.times do
      worksheet = workbook.add_worksheet
      500.times {|i| worksheet.write_row(i, 0, [rand(10000).to_s])}
    end

    assert_nothing_raised { workbook.close }
  end

end
