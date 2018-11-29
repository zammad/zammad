# -*- coding: utf-8 -*-
require 'helper'
require 'stringio'

class TC_OLE < Test::Unit::TestCase

  def setup
    @file  = StringIO.new
    @ole  = OLEWriter.new(@file)
  end

  def test_constructor
    assert_kind_of(OLEWriter, @ole)
  end

  def test_constants
    assert_equal(7087104, OLEWriter::MaxSize)
    assert_equal(4096, OLEWriter::BlockSize)
    assert_equal(512, OLEWriter::BlockDiv)
    assert_equal(127, OLEWriter::ListBlocks)
  end

  def test_calculate_sizes
    assert_respond_to(@ole, :calculate_sizes)
    assert_nothing_raised{ @ole.calculate_sizes }
    assert_equal(0, @ole.big_blocks)
    assert_equal(1, @ole.list_blocks)
    assert_equal(0, @ole.root_start)
  end

  def test_set_size_too_big
    assert(!@ole.set_size(999999999))
  end

  def test_book_size_large
    assert_nothing_raised{ @ole.set_size(8192) }
    assert_equal(8192, @ole.book_size)
  end

  def test_book_size_small
    assert_nothing_raised{ @ole.set_size(2048) }
    assert_equal(4096, @ole.book_size)
  end

  def test_biff_size
    assert_nothing_raised{ @ole.set_size(2048) }
    assert_equal(2048, @ole.biff_size)
  end

  def test_size_allowed
    assert_nothing_raised{ @ole.set_size }
    assert_equal(true, @ole.size_allowed)
  end

  def test_big_block_size_default
    assert_nothing_raised{ @ole.set_size }
    assert_nothing_raised{ @ole.calculate_sizes }
    assert_equal(8, @ole.big_blocks, "Bad big block size")
  end

  def test_big_block_size_rounded_up
    assert_nothing_raised{ @ole.set_size(4099) }
    assert_nothing_raised{ @ole.calculate_sizes }
    assert_equal(9, @ole.big_blocks, "Bad big block size")
  end

  def test_list_block_size
    assert_nothing_raised{ @ole.set_size }
    assert_nothing_raised{ @ole.calculate_sizes }
    assert_equal(1, @ole.list_blocks, "Bad list block size")
  end

  def test_root_start_size_default
    assert_nothing_raised{ @ole.set_size }
    assert_nothing_raised{ @ole.calculate_sizes }
    assert_equal(8, @ole.big_blocks, "Bad root start size")
  end

  def test_root_start_size_rounded_up
    assert_nothing_raised{ @ole.set_size(4099) }
    assert_nothing_raised{ @ole.calculate_sizes }
    assert_equal(9, @ole.big_blocks, "Bad root start size")
  end

  def test_write_header
    assert_nothing_raised{ @ole.write_header }
    #assert_nothing_raised{ @ole.close }
    #assert_equal(512, File.size(@file))
  end

  def test_write_big_block_depot
    assert_nothing_raised{ @ole.write_big_block_depot }
    #assert_nothing_raised{ @ole.close }
    #assert_equal(8, File.size(@file))
  end

  def test_write_property_storage_size
    assert_nothing_raised{ @ole.write_property_storage }
    #assert_nothing_raised{ @ole.close }
    #assert_equal(512, File.size(@file))
  end
end
