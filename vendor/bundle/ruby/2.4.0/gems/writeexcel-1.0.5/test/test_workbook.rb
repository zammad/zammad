# -*- coding: utf-8 -*-
require 'helper'
require "stringio"

class TC_Workbook < Test::Unit::TestCase

  def setup
    @test_file  = StringIO.new
    @workbook   = Workbook.new(@test_file)
  end

  def test_new
    assert_kind_of(Workbook, @workbook)
  end

  def test_add_worksheet
    sheetnames = ['sheet1', 'sheet2']
    (0 .. sheetnames.size-1).each do |i|
      sheets = @workbook.sheets
      assert_equal(i, sheets.size)
      @workbook.add_worksheet(sheetnames[i])
      sheets = @workbook.sheets
      assert_equal(i+1, sheets.size)
    end
  end

  def test_set_tempdir_after_sheet_added
    # after shees added, call set_tempdir raise RuntimeError
    @workbook.add_worksheet('name')
    assert_raise(RuntimeError, "already sheet exists, but set_tempdir() doesn't raise"){
      @workbook.set_tempdir
    }
  end

  def test_set_tempdir_with_invalid_dir
    # invalid dir raise RuntimeError
    while true do
      dir = Time.now.to_s
      break unless FileTest.directory?(dir)
      sleep 0.1
    end
    assert_raise(RuntimeError, "set_tempdir() doesn't raise invalid dir:#{dir}."){
      @workbook.set_tempdir(dir)
    }
  end

  def test_check_sheetname
    worksheet1 = @workbook.add_worksheet              # implicit name 'Sheet1'
    worksheet2 = @workbook.add_worksheet              # implicit name 'Sheet2'
    worksheet3 = @workbook.add_worksheet 'Sheet3'     # explicit name 'Sheet3'
    worksheet4 = @workbook.add_worksheet 'Sheetz'     # explicit name 'Sheetz'

    valid_sheetnames.each do |test|
      target    = test[0]
      sheetname = test[1]
      caption   = test[2]
      assert_nothing_raised { @workbook.add_worksheet(sheetname) }
    end

    invalid_sheetnames.each do |test|
      target    = test[0]
      sheetname = test[1]
      caption   = test[2]
      assert_raise(RuntimeError, "sheetname: #{sheetname}") {
          @workbook.add_worksheet(sheetname)
        }
    end
  end

  def test_check_sheetname_raise_if_same_utf16be_sheet_name
    smily = [0x263a].pack('n')
    @workbook.add_worksheet(smily, true)
    assert_raise(RuntimeError) { @workbook.add_worksheet(smily, true)}
  end

  def test_check_sheetname_utf8_only
    ['Лист 1', 'Лист 2', 'Лист 3'].each do |sheetname|
      assert_nothing_raised { @workbook.add_worksheet(sheetname) }
    end
  end

  def test_check_unicode_bytes_even
    assert_nothing_raised(RuntimeError){ @workbook.add_worksheet('ab', 1)}
    assert_raise(RuntimeError){ @workbook.add_worksheet('abc', 1)}
  end

  def test_raise_set_compatibility_after_sheet_creation
    @workbook.add_worksheet
    assert_raise(RuntimeError) { @workbook.compatibility_mode }
  end

  def valid_sheetnames
    [
      # Tests for valid names
      [ 'PASS', nil,        'No worksheet name'           ],
      [ 'PASS', '',         'Blank worksheet name'        ],
      [ 'PASS', 'Sheet10',  'Valid worksheet name'        ],
      [ 'PASS', 'a' * 31,   'Valid 31 char name'          ]
    ]
  end

  def invalid_sheetnames
    [
      # Tests for invalid names
      [ 'FAIL', 'Sheet1',   'Caught duplicate name'       ],
      [ 'FAIL', 'Sheet2',   'Caught duplicate name'       ],
      [ 'FAIL', 'Sheet3',   'Caught duplicate name'       ],
      [ 'FAIL', 'sheet1',   'Caught case-insensitive name'],
      [ 'FAIL', 'SHEET1',   'Caught case-insensitive name'],
      [ 'FAIL', 'sheetz',   'Caught case-insensitive name'],
      [ 'FAIL', 'SHEETZ',   'Caught case-insensitive name'],
      [ 'FAIL', 'a' * 32,   'Caught long name'            ],
      [ 'FAIL', '[',        'Caught invalid char'         ],
      [ 'FAIL', ']',        'Caught invalid char'         ],
      [ 'FAIL', ':',        'Caught invalid char'         ],
      [ 'FAIL', '*',        'Caught invalid char'         ],
      [ 'FAIL', '?',        'Caught invalid char'         ],
      [ 'FAIL', '/',        'Caught invalid char'         ],
      [ 'FAIL', '\\',       'Caught invalid char'         ]
    ]
  end

  def test_add_format_must_accept_one_or_more_hash_params
    font    = {
      :font   => 'ＭＳ 明朝',
      :size   => 12,
      :color  => 'blue',
      :bold   => 1
    }
    shading = {
      :bg_color => 'green',
      :pattern  => 1
    }
    properties = font.merge(shading)

    format1 = @workbook.add_format(properties)
    format2 = @workbook.add_format(font, shading)
    assert(format_equal?(format1, format2))
  end

  def format_equal?(f1, f2)
    require 'yaml'
    re = /xf_index: \d+\n/
    YAML.dump(f1).sub(re, '') == YAML.dump(f2).sub(re, '')
  end
end
