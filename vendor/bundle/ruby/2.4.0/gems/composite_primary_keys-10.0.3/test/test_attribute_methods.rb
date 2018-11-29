require File.expand_path('../abstract_unit', __FILE__)

class TestAttributeMethods < ActiveSupport::TestCase
  fixtures :reference_types, :reference_codes

  def test_read_attribute_with_single_key
    rt = ReferenceType.find(1)
    assert_equal(1, rt.reference_type_id)
    assert_equal('NAME_PREFIX', rt.type_label)
    assert_equal('Name Prefix', rt.abbreviation)
  end

  def test_read_attribute_with_composite_keys
    ref_code = ReferenceCode.find([1, 1])
    assert_equal(1, ref_code.id.first)
    assert_equal(1, ref_code.id.last)
    assert_equal('Mr', ref_code.abbreviation)
  end

  # to_key returns array even for single key
  def test_to_key_with_single_key
    rt = ReferenceType.find(1)
    assert_equal([1], rt.to_key)
  end

  def test_to_key_with_composite_keys
    ref_code = ReferenceCode.find([1, 1])
    assert_equal(1, ref_code.to_key.first)
    assert_equal(1, ref_code.to_key.last)
  end

  def test_to_key_with_single_key_unsaved
    rt = ReferenceType.new
    assert_nil(rt.to_key)
  end

  def test_to_key_with_composite_keys_unsaved
    ref_code = ReferenceCode.new
    assert_nil(ref_code.to_key)
  end

  def test_to_key_with_single_key_destroyed
    rt = ReferenceType.find(1)
    rt.destroy
    assert_equal([1], rt.to_key)
  end

  def test_to_key_with_composite_key_destroyed
    ref_code = ReferenceCode.find([1, 1])
    ref_code.destroy
    assert_equal([1,1], ref_code.to_key)
  end

  def test_id_was
    rt = ReferenceType.find(1)
    rt.id = 2
    assert_equal 1, rt.id_was
    
    ref_code = ReferenceCode.find([1, 1])
    ref_code.id = [1,2]
    assert_equal [1,1], ref_code.id_was
  end
end
