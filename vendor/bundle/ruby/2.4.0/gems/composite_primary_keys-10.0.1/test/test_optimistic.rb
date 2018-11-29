require File.expand_path('../abstract_unit', __FILE__)

class TestOptimisitic < ActiveSupport::TestCase
  fixtures :restaurants

  def test_update_with_stale_error
    restaurant_1 = Restaurant.find([1, 1])
    restaurant_1['name'] = "McDonalds renamed"

    restaurant_2 = Restaurant.find([1, 1])
    restaurant_2['name'] = "McDonalds renamed 2"

    assert(restaurant_1.save)
    assert_raise ActiveRecord::StaleObjectError do
      restaurant_2.save
    end
  end
end
