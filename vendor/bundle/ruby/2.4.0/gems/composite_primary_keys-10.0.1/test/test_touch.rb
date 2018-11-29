# Test cases devised by Santiago that broke the Composite Primary Keys
# code at one point in time. But no more!!!
require File.expand_path('../abstract_unit', __FILE__)

class TestTouch < ActiveSupport::TestCase
  fixtures :products, :tariffs

  def test_touching_a_record_updates_its_timestamp
    tariff                = tariffs(:flat)
    previous_amount       = tariff.amount
    previously_updated_at = tariff.updated_at

    tariff.amount         = previous_amount + 1
    sleep 1.0 # we need to sleep for 1 second because the times updated (on mysql, at least) are only precise to 1 second.
    tariff.touch
    assert_not_equal previously_updated_at, tariff.updated_at
    assert_equal previous_amount + 1, tariff.amount
    assert tariff.amount_changed?, 'tarif amount should have changed'
    assert tariff.changed?, 'tarif should be marked as changed'
    tariff.reload
    assert_not_equal previously_updated_at, tariff.updated_at
  end
end
