# Test cases devised by Santiago that broke the Composite Primary Keys
# code at one point in time. But no more!!!
require File.expand_path('../abstract_unit', __FILE__)

class TestSantiago < ActiveSupport::TestCase
  fixtures :suburbs, :streets, :users, :articles, :readings
  
  def test_normal_and_composite_associations
    assert_not_nil @suburb = Suburb.find([1, 1])
    assert_equal 1, @suburb.streets.length
    
    assert_not_nil @street = Street.find(1)
    assert_not_nil @street.suburb
  end
  
  def test_single_keys
    @santiago = User.find(1)
    assert_not_nil @santiago.articles
    assert_equal 2, @santiago.articles.length
    assert_not_nil @santiago.readings
    assert_equal 2, @santiago.readings.length
  end
end
