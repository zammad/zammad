require File.expand_path('../abstract_unit', __FILE__)

class TestAttributes < ActiveSupport::TestCase
  fixtures :reference_types, :reference_codes, :products, :tariffs, :product_tariffs
  
  CLASSES = {
    :single => {
      :class => ReferenceType,
      :primary_keys => :reference_type_id,
    },
    :dual   => { 
      :class => ReferenceCode,
      :primary_keys => [:reference_type_id, :reference_code],
    },
  }
  
  def setup
    self.class.classes = CLASSES
  end
  
  def test_brackets
    testing_with do
      @first.attributes.each_pair do |attr_name, value|
        assert_equal value, @first[attr_name]
      end
    end
  end

  def test_brackets_primary_key
    testing_with do
      assert_equal(@first.id, @first[@primary_keys])
      assert_equal(@first.id, @first[@first.class.primary_key])
    end
  end

  def test_brackets_assignment
    testing_with do
      @first.attributes.each_pair do |attr_name, value|
        next if attr_name == @first.class.primary_key
        @first[attr_name]= !value.nil? ? value * 2 : '1'
        assert_equal !value.nil? ? value * 2 : '1', @first[attr_name]
      end
    end
  end

  def test_brackets_foreign_key_assignment
    tarrif = tariffs(:flat)
    product_tariff = product_tariffs(:first_flat)
    compare_indexes(tarrif, tarrif.class.primary_key, product_tariff, [:tariff_id, :tariff_start_date])
  end

  private

  def compare_indexes(obj1, indexes1, obj2, indexes2)
    indexes1.length.times do |key_index|
      key1 = indexes1[key_index]
      key2 = indexes2[key_index]
      assert_equal(obj1[key1], obj2[key2])
    end
  end
end