require File.expand_path('../abstract_unit', __FILE__)

class TestEqual < ActiveSupport::TestCase
  fixtures :capitols

  def test_new
    assert_equal(Capitol.new, Capitol.new)
  end

  def test_same_new
    it = Capitol.new
    assert_equal(it, it)
  end

  def test_same
    first = Capitol.find(['Canada', 'Ottawa'])
    second = Capitol.find(['Canada', 'Ottawa'])
    assert_equal(first, second)
  end

  def test_different
    first = Capitol.find(['Mexico', 'Mexico City'])
    second = Capitol.find(['Canada', 'Ottawa'])
    assert_not_equal(first, second)
  end
end
