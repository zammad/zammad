# -*- coding: utf-8 -*-
###############################################################################
#
# A test for WriteExcel.
#
# Check that max/min columns of the Excel ROW record are written correctly.
#
# reverse('©'), October 2007, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
############################################################################
require 'helper'
require 'stringio'

class TC_rows < Test::Unit::TestCase

  def setup
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
    file  = StringIO.new
    workbook = WriteExcel.new(file)
    workbook.compatibility_mode(1)
    @tests               = []

    # for test case 1
    row  = 1
    col1 = 0
    col2 = 0
    worksheet = workbook.add_worksheet
    worksheet.set_row(row, 15)
    @tests.push(
                 [
                    " \tset_row(): row = #{row}, col1 = #{col1}, col2 = #{col2}",
                    {
                      :col_min => 0,
                      :col_max => 0,
                    }
                 ]
              )

    # for test case 2
    row  = 2
    col1 = 0
    col2 = 0
    worksheet = workbook.add_worksheet
    worksheet.write(row, col1, 'Test')
    worksheet.write(row, col2, 'Test')
    @tests.push(
                 [
                    " \tset_row(): row = #{row}, col1 = #{col1}, col2 = #{col2}",
                    {
                      :col_min => 0,
                      :col_max => 1,
                    }
                 ]
              )


    # for test case 3
    row  = 3
    col1 = 0
    col2 = 1
    worksheet = workbook.add_worksheet
    worksheet.write(row, col1, 'Test')
    worksheet.write(row, col2, 'Test')
    @tests.push(
                [
                    " \twrite():   row = #{row}, col1 = #{col1}, col2 = #{col2}",
                    {
                        :col_min => 0,
                        :col_max => 2,
                    }
                ]
            )

    # for test case 4
    row  = 4
    col1 = 1
    col2 = 1
    worksheet = workbook.add_worksheet
    worksheet.write(row, col1, 'Test')
    worksheet.write(row, col2, 'Test')
    @tests.push(
                [
                    " \twrite():   row = #{row}, col1 = #{col1}, col2 = #{col2}",
                    {
                        :col_min => 1,
                        :col_max => 2,
                    }
                ]
            )

    # for test case 5
    row  = 5
    col1 = 1
    col2 = 255
    worksheet = workbook.add_worksheet
    worksheet.write(row, col1, 'Test')
    worksheet.write(row, col2, 'Test')
    @tests.push(
                [
                    " \twrite():   row = #{row}, col1 = #{col1}, col2 = #{col2}",
                    {
                        :col_min => 1,
                        :col_max => 256,
                    }
                ]
            )

    # for test case 6
    row  = 6
    col1 = 255
    col2 = 255
    worksheet = workbook.add_worksheet
    worksheet.write(row, col1, 'Test')
    worksheet.write(row, col2, 'Test')
    @tests.push(
                [
                    " \twrite():   row = #{row}, col1 = #{col1}, col2 = #{col2}",
                    {
                        :col_min => 255,
                        :col_max => 256,
                    }
                ]
            )

    # for test case 7
    row  = 7
    col1 = 2
    col2 = 9
    worksheet = workbook.add_worksheet
    worksheet.set_row(row, 15)
    worksheet.write(row, col1, 'Test')
    worksheet.write(row, col2, 'Test')
    @tests.push(
                [
                    " \tset_row + write():   row = #{row}, col1 = #{col1}, col2 = #{col2}",
                    {
                        :col_min => 2,
                        :col_max => 10,
                    }
                ]
            )

    workbook.biff_only  = 1
    workbook.close
    # Read in the row records
    rows = []

    xlsfile = StringIO.new(file.string)

    while header = xlsfile.read(4)
      record, length = header.unpack('vv')
      data = xlsfile.read(length)

      #read the row records only
      next unless record == 0x0208
      col_min, col_max = data.unpack('x2 vv')

      rows.push(
        {
          :col_min => col_min,
          :col_max => col_max
        }
      )
    end
    xlsfile.close
    (0 .. @tests.size - 1).each do |i|
      assert_equal(@tests[i][1], rows[i], @tests[i][0])
    end
  end
end
