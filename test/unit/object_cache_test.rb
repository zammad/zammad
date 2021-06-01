# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class ObjectCacheTest < ActiveSupport::TestCase
  test 'organization cache' do
    org = Organization.create_or_update(
      name:          'some org cache member',
      updated_by_id: 1,
      created_by_id: 1,
    )

    roles  = Role.where( name: %w[Agent Admin] )
    groups = Group.all
    user1 = User.create_or_update(
      login:           'object_cache1@example.org',
      firstname:       'object_cache1',
      lastname:        'object_cache1',
      email:           'object_cache1@example.org',
      password:        'some_pass',
      active:          true,
      updated_by_id:   1,
      created_by_id:   1,
      organization_id: org.id,
      roles:           roles,
      groups:          groups,
    )
    assets = org.assets({})
    assert_equal(org.member_ids.sort, assets[:Organization][org.id]['member_ids'].sort)

    user1.organization_id = nil
    user1.save
    org.reload

    assets = org.assets({})
    assert_equal(org.member_ids.sort, assets[:Organization][org.id]['member_ids'].sort)
  end

  test 'user cache' do
    roles  = Role.where(name: %w[Agent Admin])
    groups = Group.all.order(:id)

    # be sure that minimum one admin is available
    User.create_or_update(
      login:         'last_admin_check@example.org',
      firstname:     'last_admin_check',
      lastname:      'last_admin_check',
      email:         'last_admin_check@example.org',
      password:      'some_pass',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
      roles:         roles,
      groups:        groups,
    )

    user1 = User.create_or_update(
      login:         'object_cache1@example.org',
      firstname:     'object_cache1',
      lastname:      'object_cache1',
      email:         'object_cache1@example.org',
      password:      'some_pass',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
      roles:         roles,
      groups:        groups,
    )
    assets = user1.assets({})
    assert_equal(user1.group_ids_access_map.sort, assets[:User][user1.id]['group_ids'].sort)

    # update group
    group1 = groups.first
    group1.note = "some note #{rand(9_999_999_999)}"
    group1.save

    assets = user1.assets({})
    assert(assets[:Group][group1.id])
    assert_equal(group1.note, assets[:Group][group1.id]['note'])

    # update group
    assert_equal(user1.group_ids_access_map.sort, assets[:User][user1.id]['group_ids'].sort)
    user1.group_ids = []
    user1.save

    assets = user1.assets({})
    assert_equal(user1.group_ids_access_map.sort, assets[:User][user1.id]['group_ids'].sort)

    # update role
    assert_equal(user1.role_ids.sort, assets[:User][user1.id]['role_ids'].sort)
    user1.role_ids = []
    user1.save

    assets = user1.assets({})
    assert_equal(user1.role_ids.sort, assets[:User][user1.id]['role_ids'].sort)

    # update groups
    assert_equal(user1.organization_ids.sort, assets[:User][user1.id]['organization_ids'].sort)
    user1.organization_ids = [1]
    user1.save

    assets = user1.assets({})
    assert_equal(user1.organization_ids.sort, assets[:User][user1.id]['organization_ids'].sort)

  end
end
