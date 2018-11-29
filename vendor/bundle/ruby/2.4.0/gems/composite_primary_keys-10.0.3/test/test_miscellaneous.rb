require File.expand_path('../abstract_unit', __FILE__)

class TestMiscellaneous < ActiveSupport::TestCase
  fixtures :reference_types, :reference_codes, :products
  
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

  def test_composite_class
    testing_with do
      assert_equal composite?, @klass.composite?
    end
  end

  def test_composite_instance
    testing_with do
      assert_equal composite?, @first.composite?
    end
  end
end
