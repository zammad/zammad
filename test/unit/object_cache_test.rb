# encoding: utf-8
require 'test_helper'

class ObjectCacheTest < ActiveSupport::TestCase
  test 'organization cache' do
    org = Organization.create_or_update(
      name: 'some org cache member',
      updated_by_id: 1,
      created_by_id: 1,
    )

    roles  = Role.where( name: %w(Agent Admin) )
    groups = Group.all
    user1 = User.create_or_update(
      login: 'object_cache1@example.org',
      firstname: 'object_cache1',
      lastname: 'object_cache1',
      email: 'object_cache1@example.org',
      password: 'some_pass',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
      organization_id: org.id,
      roles: roles,
      groups: groups,
    )
    assets = org.assets({})
    assert_equal( org.member_ids, assets[:Organization][org.id]['member_ids'] )

    user1.organization_id = nil
    user1.save

    assets = org.assets({})
    assert_equal( org.member_ids, assets[:Organization][org.id]['member_ids'] )
  end

  test 'user cache' do
    roles  = Role.where( name: %w(Agent Admin) )
    groups = Group.all
    user1 = User.create_or_update(
      login: 'object_cache1@example.org',
      firstname: 'object_cache1',
      lastname: 'object_cache1',
      email: 'object_cache1@example.org',
      password: 'some_pass',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
      roles: roles,
      groups: groups,
    )
    assets = user1.assets({})
    assert_equal( user1.group_ids, assets[:User][user1.id]['group_ids'] )

    # update group
    group1 = groups.first
    group1.note = "some note #{rand(9_999_999_999)}"
    group1.save

    assets = user1.assets({})
    assert_equal( group1.note, assets[:Group][group1.id]['note'] )

    # update group
    assert_equal( user1.group_ids, assets[:User][user1.id]['group_ids'] )
    user1.group_ids = []
    user1.save

    assets = user1.assets({})
    assert_equal( user1.group_ids, assets[:User][user1.id]['group_ids'] )

    # update role
    assert_equal( user1.role_ids, assets[:User][user1.id]['role_ids'] )
    user1.role_ids = []
    user1.save

    assets = user1.assets({})
    assert_equal( user1.role_ids, assets[:User][user1.id]['role_ids'] )

    # update groups
    assert_equal( user1.organization_ids, assets[:User][user1.id]['organization_ids'] )
    user1.organization_ids = [1]
    user1.save

    assets = user1.assets({})
    assert_equal( user1.organization_ids, assets[:User][user1.id]['organization_ids'] )

  end

  test 'group cache' do

    name = 'object cache test ' + rand(9_999_999).to_s
    group = Group.create(
      name: name,
      updated_by_id: 1,
      created_by_id: 1,
    )
    group_new = Group.where( name: name ).first
    assert_equal( name, group_new[:name], 'verify by where' )

    # lookup by name
    cache_key = group_new.name.to_s
    assert_nil( Group.cache_get(cache_key) )

    group_lookup_name = Group.lookup( name: group_new.name )
    assert_equal( group_new.name, group_lookup_name[:name], 'verify by lookup.name' )
    assert( Group.cache_get(cache_key) )

    # lookup by id
    cache_key = group_new.id.to_s
    assert_nil( Group.cache_get(cache_key) )

    group_lookup_id = Group.lookup( id: group.id )
    assert_equal( group_new.name, group_lookup_id[:name], 'verify by lookup.id' )
    assert( Group.cache_get(cache_key) )

    # update / check if old name caches are deleted
    name_new = name + ' next'
    group.name = name_new
    group.save

    # lookup by name
    cache_key = group.name.to_s
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
    cache_key = group_new.id.to_s
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
