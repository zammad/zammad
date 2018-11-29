require File.expand_path('../abstract_unit', __FILE__)

# Testing the find action on composite ActiveRecords with two primary keys
class TestNestedAttributes < ActiveSupport::TestCase
  fixtures :reference_types, :reference_codes

  def test_nested_atttribute_create
    code_id = 1001

    reference_type = reference_types(:name_prefix)
    reference_type.update_attributes :reference_codes_attributes => [{
      :reference_code => code_id,
      :code_label => 'XX',
      :abbreviation => 'Xx'
    }]
    assert_not_nil ReferenceCode.find_by_reference_code(code_id)
  end

  def test_nested_atttribute_update
    code_id = 1002

    reference_type = reference_types(:name_prefix)
    reference_type.update_attributes :reference_codes_attributes => [{
      :reference_code => code_id,
      :code_label => 'XX',
      :abbreviation => 'Xx'
    }]

    reference_code = ReferenceCode.find_by_reference_code(code_id)
    cpk = CompositePrimaryKeys::CompositeKeys[reference_type.reference_type_id, code_id]
    reference_type.update_attributes :reference_codes_attributes => [{
      :id => cpk,
      :code_label => 'AAA',
      :abbreviation => 'Aaa'
    }]

    reference_code = ReferenceCode.find_by_reference_code(code_id)
    assert_kind_of(ReferenceCode, reference_code)
    assert_equal(reference_code.code_label, 'AAA')
  end

  def test_nested_atttribute_update_2
    reference_type = reference_types(:gender)
    reference_code = reference_codes(:gender_male)

    reference_type.update_attributes(:reference_codes_attributes => [{:id => reference_code.id,
                                                                      :code_label => 'XX',
                                                                      :abbreviation => 'Xx'}])

    reference_code.reload
    assert_equal(reference_code.code_label, 'XX')
    assert_equal(reference_code.abbreviation, 'Xx')
  end

  def test_nested_atttribute_update_3
    reference_type = reference_types(:gender)
    reference_code = reference_codes(:gender_male)

    reference_type.update_attributes(:reference_codes_attributes => [{:id => reference_code.id.to_s,
                                                                      :code_label => 'XX',
                                                                      :abbreviation => 'Xx'}])

    reference_code.reload
    assert_equal(reference_code.code_label, 'XX')
    assert_equal(reference_code.abbreviation, 'Xx')
  end

  fixtures :topics, :topic_sources

  def test_nested_attributes_create_with_string_in_primary_key
    platform = 'instagram'

    topic = topics(:music)
    topic.update_attributes :topic_sources_attributes => [{
      :platform => platform,
      :keywords => 'funk'
    }]
    assert_not_nil TopicSource.find_by_platform(platform)
  end

  def test_nested_attributes_update_with_string_in_primary_key
    platform = 'instagram'

    topic = topics(:music)
    topic.update_attributes :topic_sources_attributes => [{
      :platform => platform,
      :keywords => 'funk'
    }]
    assert_not_nil TopicSource.find_by_platform(platform)

    topic_source = TopicSource.find_by_platform(platform)
    cpk = CompositePrimaryKeys::CompositeKeys[topic.id, platform]
    topic.update_attributes :topic_sources_attributes => [{
      :id => cpk,
      :keywords => 'jazz'
    }]

    topic_source = TopicSource.find_by_platform(platform)
    assert_kind_of(TopicSource, topic_source)
    assert_equal(topic_source.keywords, 'jazz')
  end

  def test_nested_attributes_update_with_string_in_primary_key_2
    topic = topics(:music)
    topic_source = topic_sources(:music_source)

    topic.update_attributes(:topic_sources_attributes => [{:id => topic_source.id,
                                                           :keywords => 'classical, jazz'}])

    topic_source.reload
    assert_equal(topic_source.keywords, 'classical, jazz')
  end

  def test_nested_attributes_update_with_string_in_primary_key_3
    topic = topics(:music)
    topic_source = topic_sources(:music_source)

    topic.update_attributes(:topic_sources_attributes => [{:id => topic_source.id.to_s,
                                                           :keywords => 'classical, jazz'}])

    topic_source.reload
    assert_equal(topic_source.keywords, 'classical, jazz')
  end
end
