require File.expand_path('../abstract_unit', __FILE__)

class TestCalculations < ActiveSupport::TestCase
  fixtures :tariffs

  def test_update_counter
    tariff = tariffs(:flat)
    assert_equal(50, tariff.amount)
    Tariff.update_counters(tariff.id, :amount => 1)
    tariff.reload
    assert_equal(51, tariff.amount)
  end

  def test_increment_counter
    tariff = tariffs(:flat)
    assert_equal(50, tariff.amount)
    Tariff.increment_counter(:amount, tariff.id)

    tariff.reload
    assert_equal(51, tariff.amount)
  end

  def test_decrement_counter
    tariff = tariffs(:flat)
    assert_equal(50, tariff.amount)
    Tariff.decrement_counter(:amount, tariff.id)

    tariff.reload
    assert_equal(49, tariff.amount)
  end
end