# encoding: utf-8
require 'test_helper'

class ObjectTypeLookupTest < ActiveSupport::TestCase

  test 'object tests' do

    object_lookup_id = ObjectLookup.by_name( 'SomeObject' )
    assert( object_lookup_id, 'first by_name' )

    object_lookup_name = ObjectLookup.by_id( object_lookup_id )
    assert( object_lookup_name, 'first by_id' )
    assert_equal( object_lookup_name, 'SomeObject' )

    object_lookup_id2 = ObjectLookup.by_name( 'Some_Object' )
    assert( object_lookup_id2, 'by_name - Some_Object' )

    object_lookup_name2 = ObjectLookup.by_id( object_lookup_id2 )
    assert( object_lookup_name2, 'by_id - Some_Object' )
    assert_equal( object_lookup_name2, 'Some_Object' )

    object_lookup_id3 = ObjectLookup.by_name( 'SomeObject' )
    assert( object_lookup_id3, 'by_name 2 - SomeObject' )

    object_lookup_name3 = ObjectLookup.by_id( object_lookup_id3 )
    assert( object_lookup_name3, 'by_id 2 - SomeObject' )
    assert_equal( object_lookup_name3, 'SomeObject' )
    assert_equal( object_lookup_name3, object_lookup_name, 'SomeObject' )
    assert_equal( object_lookup_id3, object_lookup_id, 'SomeObject' )

  end

  test 'type tests' do

    type_lookup_id = TypeLookup.by_name( 'SomeType' )
    assert( type_lookup_id, 'first by_name' )

    type_lookup_name = TypeLookup.by_id( type_lookup_id )
    assert( type_lookup_name, 'first by_id' )
    assert_equal( type_lookup_name, 'SomeType' )

    type_lookup_id2 = TypeLookup.by_name( 'Some_Type' )
    assert( type_lookup_id2, 'by_name - Some_Type' )

    type_lookup_name2 = TypeLookup.by_id( type_lookup_id2 )
    assert( type_lookup_name2, 'by_id - Some_Type' )
    assert_equal( type_lookup_name2, 'Some_Type' )

    type_lookup_id3 = TypeLookup.by_name( 'SomeType' )
    assert( type_lookup_id3, 'by_name 2 - SomeType' )

    type_lookup_name3 = TypeLookup.by_id( type_lookup_id3 )
    assert( type_lookup_name3, 'by_id 2 - SomeType' )
    assert_equal( type_lookup_name3, 'SomeType' )
    assert_equal( type_lookup_name3, type_lookup_name, 'SomeType' )
    assert_equal( type_lookup_id3, type_lookup_id, 'SomeType' )

  end

  test 'type and object tests' do

    object_lookup_id = ObjectLookup.by_name( 'SomeObject' )
    assert( object_lookup_id, 'first by_name' )

    object_lookup_name = ObjectLookup.by_id( object_lookup_id )
    assert( object_lookup_name, 'first by_id' )
    assert_equal( object_lookup_name, 'SomeObject' )

    type_lookup_id = TypeLookup.by_name( 'SomeType' )
    assert( type_lookup_id, 'first by_name' )

    type_lookup_name = TypeLookup.by_id( type_lookup_id )
    assert( type_lookup_name, 'first by_id' )
    assert_equal( type_lookup_name, 'SomeType' )

    assert_not_equal( object_lookup_name, type_lookup_name, 'verify lookups' )

  end

end
