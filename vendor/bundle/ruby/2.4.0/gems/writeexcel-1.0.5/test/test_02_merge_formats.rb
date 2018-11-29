# -*- coding: utf-8 -*-
require 'helper'
require 'stringio'

class TC_merge_formats < Test::Unit::TestCase

  def setup
    @workbook            = WriteExcel.new(StringIO.new)
    @worksheet           = @workbook.add_worksheet
    @merged_format       = @workbook.add_format(:bold => 1)
    @non_merged_format   = @workbook.add_format(:bold => 1)

    @worksheet.set_row(    5,    nil, @merged_format)
    @worksheet.set_column('G:G', nil, @merged_format)
  end

  def test_some
    # Test 1   Normal usage.
    assert_nothing_raised { @worksheet.write('A1',    'Test', @non_merged_format) }
    assert_nothing_raised { @worksheet.write('A3:B4', 'Test', @merged_format) }

    # Test 2   Non merge format in merged cells.
    assert_nothing_raised {
      @worksheet.merge_range('D3:E4', 'Test', @non_merged_format)
    }

    # Test 3   Merge format in column.
    assert_nothing_raised { @worksheet.write('G1', 'Test') }

    # Test 4   Merge format in row.
    assert_nothing_raised { @worksheet.write('A6', 'Test') }

    # Test 5   Merge format in column and row.
    assert_nothing_raised { @worksheet.write('G6', 'Test') }

    # Test 6   No merge format in column and row.
    assert_nothing_raised { @worksheet.write('H7', 'Test') }

    # Test 7   Normal usage again.
    assert_nothing_raised {
      @worksheet.write('A1',    'Test', @non_merged_format)
    }
    assert_nothing_raised {
      @worksheet.merge_range('A3:B4', 'Test', @merged_format)
    }
  end


end
