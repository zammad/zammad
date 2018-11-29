require File.expand_path('../abstract_unit', __FILE__)

class TestUpdate < ActiveSupport::TestCase
  fixtures :reference_types, :reference_codes

  CLASSES = {
    :single => {
      :class => ReferenceType,
      :primary_keys => :reference_type_id,
      :update => { :description => 'RT Desc' },
    },
    :dual   => {
      :class => ReferenceCode,
      :primary_keys => [:reference_type_id, :reference_code],
      :update => { :description => 'RT Desc' },
    },
  }

  def setup
    self.class.classes = CLASSES
  end

  def test_setup
    testing_with do
      assert_not_nil @klass_info[:update]
    end
  end

  def test_update_attributes
    testing_with do
      assert(@first.update_attributes(@klass_info[:update]))
      assert(@first.reload)
      @klass_info[:update].each_pair do |attr_name, new_value|
        assert_equal(new_value, @first[attr_name])
      end
    end
  end

  def test_update_primary_key
    obj = ReferenceCode.find([1,1])
    obj.reference_type_id = 2
    obj.reference_code = 3
    assert_equal({"reference_type_id" => 2, "reference_code" => 3}, obj.ids_hash)
    assert(obj.save)
    assert(obj.reload)
    assert_equal(2, obj.reference_type_id)
    assert_equal(3, obj.reference_code)
    assert_equal({"reference_type_id" => 2, "reference_code" => 3}, obj.ids_hash)
    assert_equal([2, 3], obj.id)
  end

  def test_update_attribute
    obj = ReferenceType.find(1)
    obj[:abbreviation] = 'a'
    obj['abbreviation'] = 'b'
    assert(obj.save)
    assert(obj.reload)
    assert_equal('b', obj.abbreviation)
  end

  def test_update_all
    ReferenceCode.update_all(description: 'random value')

    ReferenceCode.all.each do |reference_code|
      assert_equal('random value', reference_code.description)
    end
  end

  def test_update_all_join
    ReferenceCode.joins(:reference_type).update_all(description: 'random value')

    ReferenceCode.all.each do |reference_code|
      assert_equal('random value', reference_code.description)
    end
  end
end
