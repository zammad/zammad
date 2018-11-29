# -*- coding: utf-8 -*-
###############################################################################
#
# A test for WriteExcel.
#
# all test is commented out because Workbook#calculate_extsst_size was set to
# private method. Before that, all test passed.
#
# Check that we calculate the correct bucket size and number for the EXTSST
# record. The data is taken from actual Excel files.
#
# reverse('©'), October 2007, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
############################################################################
require 'helper'
require 'stringio'

class TC_extsst < Test::Unit::TestCase

  def setup
    @tests = [
      # Unique     Number of   Bucket
      # strings    buckets       size
      [0,          0,               8],
      [1,          1,               8],
      [7,          1,               8],
      [8,          1,               8],
      [15,         2,               8],
      [16,         2,               8],
      [17,         3,               8],
      [32,         4,               8],
      [33,         5,               8],
      [64,         8,               8],
      [128,        16,              8],
      [256,        32,              8],
      [512,        64,              8],
      [1023,       128,             8],
      [1024,       114,             9],
      [1025,       114,             9],
      [2048,       121,            17],
      [4096,       125,            33],
      [4097,       125,            33],
      [8192,       127,            65],
      [8193,       127,            65],
      [9000,       127,            71],
      [10000,      127,            79],
      [16384,      128,           129],
      [262144,     128,          2049],
      [1048576,    128,          8193],
      [4194304,    128,         32769],
      [8257536,    128,         64513],
    ]
  end

  def teardown
    if @workbook.instance_variable_get(:@filehandle)
      @workbook.instance_variable_get(:@filehandle).close(true)
    end
    if @worksheet.instance_variable_get(:@filehandle)
      @worksheet.instance_variable_get(:@filehandle).close(true)
    end
  end

  def test_to_tests
    @tests.each do |test|
      io = StringIO.new
      workbook    = WriteExcel.new(io)
      workbook.not_using_tmpfile

      str_unique = test[0]

      workbook.__send__("calculate_extsst_size", str_unique)

      assert_equal(test[1], workbook.extsst_buckets,
        " \tBucket number for #{str_unique}  strings")
      assert_equal(test[2], workbook.extsst_bucket_size,
        " \tBucket size for #{str_unique}  strings")
    end
  end
end
