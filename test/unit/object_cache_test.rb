# encoding: utf-8
require 'test_helper'

class ObjectCacheTest < ActiveSupport::TestCase
  test 'object cache' do

    name = 'object cache test ' + rand(9_999_999).to_s
    group = Group.create(
      name: name,
      updated_by_id: 1,
      created_by_id: 1,
    )
    group_new = Group.where( name: name ).first
    assert_equal( name, group_new[:name], 'verify by where' )

    # lookup by name
    cache_key = "#{group_new.name}"
    assert_nil( Group.cache_get(cache_key) )

    group_lookup_name = Group.lookup( name: group_new.name )
    assert_equal( group_new.name, group_lookup_name[:name], 'verify by lookup.name' )
    assert( Group.cache_get(cache_key) )

    # lookup by id
    cache_key = "#{group_new.id}"
    assert_nil( Group.cache_get(cache_key) )

    group_lookup_id = Group.lookup( id: group.id )
    assert_equal( group_new.name, group_lookup_id[:name], 'verify by lookup.id' )
    assert( Group.cache_get(cache_key) )

    # update / check if old name caches are deleted
    name_new = name + ' next'
    group.name = name_new
    group.save

    # lookup by name
    cache_key = "#{group.name}"
    assert_nil( Group.cache_get(cache_key) )

    group_lookup = Group.where( name: group_new.name ).first
    assert_nil( group_lookup, 'verify by where name_old' )
    assert_nil( Group.cache_get(cache_key) )

    group_lookup = Group.where( name: group.name ).first
    assert_equal( name_new, group_lookup[:name], 'verify by where name_new' )
    assert_nil( Group.cache_get(cache_key) )

    group_lookup_name = Group.lookup( name: group_new.name )
    assert_nil( group_lookup_name, 'verify by lookup.name name_old' )
    assert_nil( Group.cache_get(cache_key) )

    group_lookup_name = Group.lookup( name: group.name )
    assert_equal( name_new, group_lookup_name[:name], 'verify by lookup.name name_new' )
    assert( Group.cache_get(cache_key) )

    # lookup by id
    cache_key = "#{group_new.id}"
    assert_nil( Group.cache_get(cache_key) )

    group_lookup_id = Group.lookup( id: group.id )
    assert_equal( name_new, group_lookup_id[:name], 'verify by lookup.id' )
    assert( Group.cache_get(cache_key) )

    group.destroy

    # lookup by name
    group_lookup = Group.where( name: group_new.name ).first
    assert_nil( group_lookup, 'verify by where name_old' )

    group_lookup = Group.where( name: group.name ).first
    assert_nil( group_lookup, 'verify by where name_new' )

    group_lookup_name = Group.lookup( name: group_new.name )
    assert_nil( group_lookup_name, 'verify by lookup.name name_old' )

    group_lookup_name = Group.lookup( name: group.name )
    assert_nil( group_lookup_name, 'verify by lookup.name name_new' )

    # lookup by id
    group_lookup_id = Group.lookup( id: group.id )
    assert_nil( group_lookup_id, 'verify by lookup.id' )

  end
end
