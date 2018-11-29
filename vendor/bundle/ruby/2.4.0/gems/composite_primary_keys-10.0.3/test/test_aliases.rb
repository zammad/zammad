require File.expand_path('../abstract_unit', __FILE__)

class TestAliases < ActiveSupport::TestCase
  fixtures :reference_codes

  def test_primary_key_setter_alias_composite_key
    reference_code = ReferenceCodeUsingCompositeKeyAlias.find([1, 2])
    assert_equal 'MRS', reference_code.code_label
    assert_equal 'Mrs', reference_code.abbreviation
  end

  def test_primary_key_setter_alias_simple_key
    reference_code = ReferenceCodeUsingSimpleKeyAlias.find('MRS')
    assert_equal 1, reference_code.reference_type_id
    assert_equal 2, reference_code.reference_code
    assert_equal 'Mrs', reference_code.abbreviation
  end
end
