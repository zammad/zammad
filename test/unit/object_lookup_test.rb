# encoding: utf-8
require 'test_helper'

class ObjectLookupTest < ActiveSupport::TestCase

  test 'simple tests' do

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
end
