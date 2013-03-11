# encoding: utf-8
require 'test_helper'

class ObjectCacheTest < ActiveSupport::TestCase
  test 'object cache' do

    name = 'object cache test ' + rand(9999999).to_s
    group = Group.create(
      :name          => name,
      :updated_by_id => 1,
      :created_by_id => 1,
    )
    group_where = Group.where( :name => name ).first
    assert_equal( name, group_where[:name], 'verify by where' )

    group_lookup_name = Group.lookup( :name => name )
    assert_equal( name, group_lookup_name[:name], 'verify by lookup.name' )

    group_lookup_id = Group.lookup( :id => group.id )
    assert_equal( name, group_lookup_id[:name], 'verify by lookup.id' )

    name_new = name + ' next'
    group.name = name_new
    group.save

    group_where = Group.where( :name => name ).first
    assert_equal( nil, group_where, 'verify by where name_old' )

    group_where = Group.where( :name => name_new ).first
    assert_equal( name_new, group_where[:name], 'verify by where name_new' )

    group_lookup_name = Group.lookup( :name => name )
    assert_equal( nil, group_lookup_name, 'verify by lookup.name name_old' )

    group_lookup_name = Group.lookup( :name => name_new )
    assert_equal( name_new, group_lookup_name[:name], 'verify by lookup.name name_new' )

    group_lookup_id = Group.lookup( :id => group.id )
    assert_equal( name_new, group_lookup_id[:name], 'verify by lookup.id' )

    group.destroy

    group_where = Group.where( :name => name ).first
    assert_equal( nil, group_where, 'verify by where name_old' )

    group_where = Group.where( :name => name_new ).first
    assert_equal( nil, group_where, 'verify by where name_new' )

    group_lookup_name = Group.lookup( :name => name )
    assert_equal( nil, group_lookup_name, 'verify by lookup.name name_old' )

    group_lookup_name = Group.lookup( :name => name_new )
    assert_equal( nil, group_lookup_name, 'verify by lookup.name name_new' )

    group_lookup_id = Group.lookup( :id => group.id )
    assert_equal( nil, group_lookup_id, 'verify by lookup.id' )

  end
end
