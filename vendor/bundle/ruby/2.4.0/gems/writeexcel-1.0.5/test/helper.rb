# -*- coding: utf-8 -*-
require 'simplecov'
require 'test/unit'

SimpleCov.start

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'writeexcel'

class Test::Unit::TestCase
  ###############################################################################
  #
  # Unpack the binary data into a format suitable for printing in tests.
  #
  def unpack_record(data)
    data.unpack('C*').map! {|c| sprintf("%02X", c) }.join(' ')
  end

  # expected : existing file path
  # target   : io (ex) string io object where stored data.
  def compare_file(expected, target)
    # target is StringIO object.
    result =
      ruby_18 { target.string } ||
      ruby_19 { target.string.force_encoding('BINARY') }
    assert_equal(
      File.binread(expected),
      result,
      "#{File.basename(expected)} doesn't match."
    )
  end
end
