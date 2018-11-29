# -*- coding: utf-8 -*-
##########################################################################
# test_22_mso_drawing_group.rb
#
# Tests for the internal methods used to write the MSODRAWINGGROUP record.
#
# all test is commented out because related method was set to
# private method. Before that, all test passed.
#
#
#
#
# reverse('©'), September 2005, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
#########################################################################
require 'helper'
require 'stringio'

class TC_mso_drawing_group < Test::Unit::TestCase

  def test_dummy
    assert(true)
  end

  def setup
    @workbook   = WriteExcel.new(StringIO.new)
    @worksheet1 = @workbook.add_worksheet
    @worksheet2 = @workbook.add_worksheet
    @worksheet3 = @workbook.add_worksheet
  end

  def teardown
    if @workbook.instance_variable_get(:@filehandle)
      @workbook.instance_variable_get(:@filehandle).close(true)
    end
    if @worksheet.instance_variable_get(:@filehandle)
      @worksheet.instance_variable_get(:@filehandle).close(true)
    end
  end

=begin
  def test_1_time
    count = 1
    for i in 1 .. count
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    caption = sprintf(" \tSheet1: %4d comments.", count)
    target  = %w(
        EB 00 5A 00 0F 00 00 F0 52 00 00 00 00 00 06 F0
        18 00 00 00 02 04 00 00 02 00 00 00 02 00 00 00
        01 00 00 00 01 00 00 00 02 00 00 00 33 00 0B F0
        12 00 00 00 BF 00 08 00 08 00 81 01 09 00 00 08
        C0 01 40 00 00 08 40 00 1E F1 10 00 00 00 0D 00
        00 08 0C 00 00 08 17 00 00 08 F7 00 00 10
    ).join(' ')
    result = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 2, 1025,
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end

    assert_equal(target_ids, result_ids, caption)

  end

  def test_2_times
    count     = 2
    for i in 1 .. count
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    target  = %w(
        EB 00 5A 00 0F 00 00 F0 52 00 00 00 00 00 06 F0
        18 00 00 00 03 04 00 00 02 00 00 00 03 00 00 00
        01 00 00 00 01 00 00 00 03 00 00 00 33 00 0B F0
        12 00 00 00 BF 00 08 00 08 00 81 01 09 00 00 08
        C0 01 40 00 00 08 40 00 1E F1 10 00 00 00 0D 00
        00 08 0C 00 00 08 17 00 00 08 F7 00 00 10
    ).join(' ')
    caption    = sprintf( " \tSheet1: %4d comments.", count)
    result     = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 3, 1026,
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end
    assert_equal(target_ids, result_ids, caption)

  end

  def test_3_times
    count     = 3
    for i in 1 .. count
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    target  = %w(
        EB 00 5A 00 0F 00 00 F0 52 00 00 00 00 00 06 F0
        18 00 00 00 04 04 00 00 02 00 00 00 04 00 00 00
        01 00 00 00 01 00 00 00 04 00 00 00 33 00 0B F0
        12 00 00 00 BF 00 08 00 08 00 81 01 09 00 00 08
        C0 01 40 00 00 08 40 00 1E F1 10 00 00 00 0D 00
        00 08 0C 00 00 08 17 00 00 08 F7 00 00 10
    ).join(' ')
    caption    = sprintf( " \tSheet1: %4d comments.", count)
    result     = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 4, 1027
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end
    assert_equal(target_ids, result_ids, caption)

  end

  def test_1023_times
    count     = 1023
    for i in 1 .. count
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    target  = %w(
        EB 00 5A 00 0F 00 00 F0 52 00 00 00 00 00 06 F0
        18 00 00 00 00 08 00 00 02 00 00 00 00 04 00 00
        01 00 00 00 01 00 00 00 00 04 00 00 33 00 0B F0
        12 00 00 00 BF 00 08 00 08 00 81 01 09 00 00 08
        C0 01 40 00 00 08 40 00 1E F1 10 00 00 00 0D 00
        00 08 0C 00 00 08 17 00 00 08 F7 00 00 10
    ).join(' ')
    caption    = sprintf( " \tSheet1: %4d comments.", count)
    result     = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 1024, 2047
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end
    assert_equal(target_ids, result_ids, caption)

  end

  def test_1024_times
    count     = 1024
    for i in 1 .. count
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    target  = %w(
        EB 00 62 00 0F 00 00 F0 5A 00 00 00 00 00 06 F0
        20 00 00 00 01 08 00 00 03 00 00 00 01 04 00 00
        01 00 00 00 01 00 00 00 00 04 00 00 01 00 00 00
        01 00 00 00 33 00 0B F0 12 00 00 00 BF 00 08 00
        08 00 81 01 09 00 00 08 C0 01 40 00 00 08 40 00
        1E F1 10 00 00 00 0D 00 00 08 0C 00 00 08 17 00
        00 08 F7 00 00 10
    ).join(' ')
    caption    = sprintf( " \tSheet1: %4d comments.", count)
    result     = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 1025, 2048
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end
    assert_equal(target_ids, result_ids, caption)

  end

  def test_2048_times
    count     = 2048
    for i in 1 .. count
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    target  = %w(
        EB 00 6A 00 0F 00 00 F0 62 00 00 00 00 00 06 F0
        28 00 00 00 01 0C 00 00 04 00 00 00 01 08 00 00
        01 00 00 00 01 00 00 00 00 04 00 00 01 00 00 00
        00 04 00 00 01 00 00 00 01 00 00 00 33 00 0B F0
        12 00 00 00 BF 00 08 00 08 00 81 01 09 00 00 08
        C0 01 40 00 00 08 40 00 1E F1 10 00 00 00 0D 00
        00 08 0C 00 00 08 17 00 00 08 F7 00 00 10
    ).join(' ')
    caption    = sprintf( " \tSheet1: %4d comments.", count)
    result     = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 2049, 3072
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end
    assert_equal(target_ids, result_ids, caption)

  end

  def test_2_sheets_1_and_1_times
    count1     = 1
    count2     = 1
    for i in 1 .. count1
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count2
      @worksheet2.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    target  = %w(
        EB 00 62 00 0F 00 00 F0 5A 00 00 00 00 00 06 F0
        20 00 00 00 02 08 00 00 03 00 00 00 04 00 00 00
        02 00 00 00 01 00 00 00 02 00 00 00 02 00 00 00
        02 00 00 00 33 00 0B F0 12 00 00 00 BF 00 08 00
        08 00 81 01 09 00 00 08 C0 01 40 00 00 08 40 00
        1E F1 10 00 00 00 0D 00 00 08 0C 00 00 08 17 00
        00 08 F7 00 00 10
    ).join(' ')
    caption    = sprintf( " \tSheet1: %4d comments, Sheet2: %4d comments..",
                                 count1, count2)
    result     = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 2, 1025,
                2048, 2, 2, 2049
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end
    assert_equal(target_ids, result_ids, caption)

  end

  def test_2_sheets_2_and_2_times
    count1     = 2
    count2     = 2
    for i in 1 .. count1
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count2
      @worksheet2.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    target  = %w(
        EB 00 62 00 0F 00 00 F0 5A 00 00 00 00 00 06 F0
        20 00 00 00 03 08 00 00 03 00 00 00 06 00 00 00
        02 00 00 00 01 00 00 00 03 00 00 00 02 00 00 00
        03 00 00 00 33 00 0B F0 12 00 00 00 BF 00 08 00
        08 00 81 01 09 00 00 08 C0 01 40 00 00 08 40 00
        1E F1 10 00 00 00 0D 00 00 08 0C 00 00 08 17 00
        00 08 F7 00 00 10
    ).join(' ')
    caption    = sprintf( " \tSheet1: %4d comments, Sheet2: %4d comments..",
                                 count1, count2)
    result     = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 3, 1026,
                2048, 2, 3, 2050
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end
    assert_equal(target_ids, result_ids, caption)

  end

  def test_2_sheets_1023_and_1_times
    count1     = 1023
    count2     = 1
    for i in 1 .. count1
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count2
      @worksheet2.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    target  = %w(
        EB 00 62 00 0F 00 00 F0 5A 00 00 00 00 00 06 F0
        20 00 00 00 02 08 00 00 03 00 00 00 02 04 00 00
        02 00 00 00 01 00 00 00 00 04 00 00 02 00 00 00
        02 00 00 00 33 00 0B F0 12 00 00 00 BF 00 08 00
        08 00 81 01 09 00 00 08 C0 01 40 00 00 08 40 00
        1E F1 10 00 00 00 0D 00 00 08 0C 00 00 08 17 00
        00 08 F7 00 00 10
    ).join(' ')
    caption    = sprintf( " \tSheet1: %4d comments, Sheet2: %4d comments..",
                                 count1, count2)
    result     = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 1024, 2047,
                2048, 2,    2, 2049
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end
    assert_equal(target_ids, result_ids, caption)

  end

  def test_2_sheets_1023_and_1023_times
    count1     = 1023
    count2     = 1023
    for i in 1 .. count1
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count2
      @worksheet2.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    target  = %w(
        EB 00 62 00 0F 00 00 F0 5A 00 00 00 00 00 06 F0
        20 00 00 00 00 0C 00 00 03 00 00 00 00 08 00 00
        02 00 00 00 01 00 00 00 00 04 00 00 02 00 00 00
        00 04 00 00 33 00 0B F0 12 00 00 00 BF 00 08 00
        08 00 81 01 09 00 00 08 C0 01 40 00 00 08 40 00
        1E F1 10 00 00 00 0D 00 00 08 0C 00 00 08 17 00
        00 08 F7 00 00 10
    ).join(' ')
    caption    = sprintf( " \tSheet1: %4d comments, Sheet2: %4d comments..",
                                 count1, count2)
    result     = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 1024, 2047,
                2048, 2, 1024, 3071
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end
    assert_equal(target_ids, result_ids, caption)

  end

  def test_2_sheets_1024_and_1024_times
    count1     = 1024
    count2     = 1024
    for i in 1 .. count1
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count2
      @worksheet2.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    target  = %w(
        EB 00 72 00 0F 00 00 F0 6A 00 00 00 00 00 06 F0
        30 00 00 00 01 10 00 00 05 00 00 00 02 08 00 00
        02 00 00 00 01 00 00 00 00 04 00 00 01 00 00 00
        01 00 00 00 02 00 00 00 00 04 00 00 02 00 00 00
        01 00 00 00 33 00 0B F0 12 00 00 00 BF 00 08 00
        08 00 81 01 09 00 00 08 C0 01 40 00 00 08 40 00
        1E F1 10 00 00 00 0D 00 00 08 0C 00 00 08 17 00
        00 08 F7 00 00 10
    ).join(' ')
    caption    = sprintf( " \tSheet1: %4d comments, Sheet2: %4d comments..",
                                 count1, count2)
    result     = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 1025, 2048,
                3072, 2, 1025, 4096
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end
    assert_equal(target_ids, result_ids, caption)

  end

  def test_2_sheets_1024_and_1_times
    count1     = 1024
    count2     = 1
    for i in 1 .. count1
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count2
      @worksheet2.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    target  = %w(
        EB 00 6A 00 0F 00 00 F0 62 00 00 00 00 00 06 F0
        28 00 00 00 02 0C 00 00 04 00 00 00 03 04 00 00
        02 00 00 00 01 00 00 00 00 04 00 00 01 00 00 00
        01 00 00 00 02 00 00 00 02 00 00 00 33 00 0B F0
        12 00 00 00 BF 00 08 00 08 00 81 01 09 00 00 08
        C0 01 40 00 00 08 40 00 1E F1 10 00 00 00 0D 00
        00 08 0C 00 00 08 17 00 00 08 F7 00 00 10
    ).join(' ')
    caption    = sprintf( " \tSheet1: %4d comments, Sheet2: %4d comments..",
                                 count1, count2)
    result     = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 1025, 2048,
                3072, 2,    2, 3073
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end
    assert_equal(target_ids, result_ids, caption)

  end

  def test_3_sheets_1023_and_1_and_1023_times
    count1     = 1023
    count2     = 1
    count3     = 1023
    for i in 1 .. count1
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count2
      @worksheet2.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count3
      @worksheet3.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    target  = %w(
        EB 00 6A 00 0F 00 00 F0 62 00 00 00 00 00 06 F0
        28 00 00 00 00 10 00 00 04 00 00 00 02 08 00 00
        03 00 00 00 01 00 00 00 00 04 00 00 02 00 00 00
        02 00 00 00 03 00 00 00 00 04 00 00 33 00 0B F0
        12 00 00 00 BF 00 08 00 08 00 81 01 09 00 00 08
        C0 01 40 00 00 08 40 00 1E F1 10 00 00 00 0D 00
        00 08 0C 00 00 08 17 00 00 08 F7 00 00 10
    ).join(' ')
    caption    = sprintf( " \tSheet1: %4d comments, Sheet2: %4d comments,"+
                          "Sheet3: %4d comments.", count1, count2, count3)
    result     = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 1024, 2047,
                2048, 2,    2, 2049,
                3072, 3, 1024, 4095
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end
    assert_equal(target_ids, result_ids, caption)

  end

  def test_3_sheets_1023_and_1023_and_1_times
    count1     = 1023
    count2     = 1023
    count3     = 1
    for i in 1 .. count1
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count2
      @worksheet2.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count3
      @worksheet3.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    target  = %w(
        EB 00 6A 00 0F 00 00 F0 62 00 00 00 00 00 06 F0
        28 00 00 00 02 0C 00 00 04 00 00 00 02 08 00 00
        03 00 00 00 01 00 00 00 00 04 00 00 02 00 00 00
        00 04 00 00 03 00 00 00 02 00 00 00 33 00 0B F0
        12 00 00 00 BF 00 08 00 08 00 81 01 09 00 00 08
        C0 01 40 00 00 08 40 00 1E F1 10 00 00 00 0D 00
        00 08 0C 00 00 08 17 00 00 08 F7 00 00 10
    ).join(' ')
    caption    = sprintf( " \tSheet1: %4d comments, Sheet2: %4d comments,"+
                          "Sheet3: %4d comments.", count1, count2, count3)
    result     = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 1024, 2047,
                2048, 2, 1024, 3071,
                3072, 3,    2, 3073
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end
    assert_equal(target_ids, result_ids, caption)

  end

  def test_3_sheets_1024_and_1_and_1024_times
    count1     = 1024
    count2     = 1
    count3     = 1024
    for i in 1 .. count1
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count2
      @worksheet2.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count3
      @worksheet3.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    target  = %w(
        EB 00 7A 00 0F 00 00 F0 72 00 00 00 00 00 06 F0
        38 00 00 00 01 14 00 00 06 00 00 00 04 08 00 00
        03 00 00 00 01 00 00 00 00 04 00 00 01 00 00 00
        01 00 00 00 02 00 00 00 02 00 00 00 03 00 00 00
        00 04 00 00 03 00 00 00 01 00 00 00 33 00 0B F0
        12 00 00 00 BF 00 08 00 08 00 81 01 09 00 00 08
        C0 01 40 00 00 08 40 00 1E F1 10 00 00 00 0D 00
        00 08 0C 00 00 08 17 00 00 08 F7 00 00 10
    ).join(' ')
    caption    = sprintf( " \tSheet1: %4d comments, Sheet2: %4d comments,"+
                          "Sheet3: %4d comments.", count1, count2, count3)
    result     = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 1025, 2048,
                3072, 2,    2, 3073,
                4096, 3, 1025, 5120
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end
    assert_equal(target_ids, result_ids, caption)

  end

  def test_3_sheets_1024_and_1024_and_1_times
    count1     = 1024
    count2     = 1024
    count3     = 1
    for i in 1 .. count1
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count2
      @worksheet2.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count3
      @worksheet3.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    target  = %w(
        EB 00 7A 00 0F 00 00 F0 72 00 00 00 00 00 06 F0
        38 00 00 00 02 14 00 00 06 00 00 00 04 08 00 00
        03 00 00 00 01 00 00 00 00 04 00 00 01 00 00 00
        01 00 00 00 02 00 00 00 00 04 00 00 02 00 00 00
        01 00 00 00 03 00 00 00 02 00 00 00 33 00 0B F0
        12 00 00 00 BF 00 08 00 08 00 81 01 09 00 00 08
        C0 01 40 00 00 08 40 00 1E F1 10 00 00 00 0D 00
        00 08 0C 00 00 08 17 00 00 08 F7 00 00 10
    ).join(' ')
    caption    = sprintf( " \tSheet1: %4d comments, Sheet2: %4d comments,"+
                          "Sheet3: %4d comments.", count1, count2, count3)
    result     = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 1025, 2048,
                3072, 2, 1025, 4096,
                5120, 3,    2, 5121
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end
    assert_equal(target_ids, result_ids, caption)

  end

  def test_3_sheets_1024_and_1024_and_1_times_duplicate
    count1     = 1024
    count2     = 1024
    count3     = 1
    for i in 1 .. count1
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count2
      @worksheet2.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count3
      @worksheet3.write_comment(i -1, 0, 'aaa')
    end
    # dupulicate -- these are ignored.  result is same as prev.--
    for i in 1 .. count1
      @worksheet1.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count2
      @worksheet2.write_comment(i -1, 0, 'aaa')
    end
    for i in 1 .. count3
      @worksheet3.write_comment(i -1, 0, 'aaa')
    end
    @workbook.calc_mso_sizes

    target  = %w(
        EB 00 7A 00 0F 00 00 F0 72 00 00 00 00 00 06 F0
        38 00 00 00 02 14 00 00 06 00 00 00 04 08 00 00
        03 00 00 00 01 00 00 00 00 04 00 00 01 00 00 00
        01 00 00 00 02 00 00 00 00 04 00 00 02 00 00 00
        01 00 00 00 03 00 00 00 02 00 00 00 33 00 0B F0
        12 00 00 00 BF 00 08 00 08 00 81 01 09 00 00 08
        C0 01 40 00 00 08 40 00 1E F1 10 00 00 00 0D 00
        00 08 0C 00 00 08 17 00 00 08 F7 00 00 10
    ).join(' ')
    caption    = sprintf( " \tSheet1: %4d comments, Sheet2: %4d comments,"+
                          "Sheet3: %4d comments.", count1, count2, count3)
    result     = unpack_record(@workbook.add_mso_drawing_group)
    assert_equal(target, result, caption)


    # Test the parameters pass to the worksheets
    caption   += ' (params)'
    result_ids = []
    target_ids = [
                1024, 1, 1025, 2048,
                3072, 2, 1025, 4096,
                5120, 3,    2, 5121
                 ]

    @workbook.sheets.each do |sheet|
      sheet.object_ids.each {|id| result_ids.push(id) }
    end
    assert_equal(target_ids, result_ids, caption)

  end
=end
end
