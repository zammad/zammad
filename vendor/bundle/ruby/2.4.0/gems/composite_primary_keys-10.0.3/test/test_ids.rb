require File.expand_path('../abstract_unit', __FILE__)

class ChildCpkTest < ReferenceCode
end

class TestIds < ActiveSupport::TestCase
  fixtures :reference_types, :reference_codes, :pk_called_ids
  
  CLASSES = {
    :single => {
      :class => ReferenceType,
      :primary_keys => [:reference_type_id],
    },
    :dual   => {
      :class => ReferenceCode,
      :primary_keys => [:reference_type_id, :reference_code],
    },
    :dual_strs   => {
      :class => ReferenceCode,
      :primary_keys => ['reference_type_id', 'reference_code'],
    },
    :pk_called_id => {
      :class => PkCalledId,
      :primary_keys => ['id', 'reference_code'],
    },
  }

  def setup
    self.class.classes = CLASSES
  end

  def test_id
    testing_with do
      assert_equal @first.id, @first.ids if composite?
      assert_kind_of(CompositePrimaryKeys::CompositeKeys, @first.id) if composite?
    end
  end

  def test_to_param
    testing_with do
      assert_equal '1,1', @first.to_param if composite?
    end
  end

  def test_ids_to_s
    testing_with do
      order = @klass.primary_key.is_a?(String) ? @klass.primary_key : @klass.primary_key.join(',')
      to_test = @klass.order(order)[0..1].map(&:id)
      assert_equal '(1,1),(1,2)', @klass.ids_to_s(to_test) if @key_test == :dual
      assert_equal '1,1;1,2', @klass.ids_to_s(to_test, ',', ';', '', '') if @key_test == :dual
    end
  end

  def test_set_ids_string
    testing_with do
      array = @primary_keys.collect {|key| 5}
      expected = composite? ? array.to_composite_keys : array.first
      @first.id = expected.to_s
      assert_equal expected, @first.id
    end
  end

  def test_set_ids_array
    testing_with do
      array = @primary_keys.collect {|key| 5}
      expected = composite? ? array.to_composite_keys : array.first
      @first.id = expected
      assert_equal expected, @first.id
    end
  end

  def test_set_ids_comp
    testing_with do
      array = @primary_keys.collect {|key| 5}
      expected = composite? ? array.to_composite_keys : array.first
      @first.id = expected
      assert_equal expected, @first.id
    end
  end

  def test_primary_keys
    testing_with do
      if composite?
        assert_not_nil @klass.primary_keys
        assert_equal @primary_keys.map {|key| key.to_s}, @klass.primary_keys
        assert_equal @klass.primary_keys, @klass.primary_key
        assert_kind_of(CompositePrimaryKeys::CompositeKeys, @klass.primary_keys)
        assert_equal @primary_keys.map {|key| key.to_sym}.join(','), @klass.primary_key.to_s
      else
        assert_not_nil @klass.primary_key
        assert_equal @primary_keys.first, @klass.primary_key.to_sym
        assert_equal @primary_keys.first.to_s, @klass.primary_key.to_s
      end
    end
  end

  def test_inherited_primary_keys
    assert_equal(["reference_type_id", "reference_code"], ChildCpkTest.primary_keys)
  end

  def test_inherited_ids
    cpk_test = ChildCpkTest.new
    assert_equal([nil, nil], cpk_test.id)
  end

  def test_assign_ids
    ref_code = ReferenceCode.new
    assert_equal([nil, nil], ref_code.id)

    ref_code.id = [2,1]
    assert_equal([2,1], ref_code.id)
  end
end
