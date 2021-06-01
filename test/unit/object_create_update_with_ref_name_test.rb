# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class ObjectCreateUpdateWithRefNameTest < ActiveSupport::TestCase
  test 'organization' do
    roles  = Role.where(name: %w[Agent Admin])
    groups = Group.all
    user1 = User.create_or_update(
      login:         'object_ref_name1@example.org',
      firstname:     'object_ref_name1',
      lastname:      'object_ref_name1',
      email:         'object_ref_name1@example.org',
      password:      'some_pass',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
      roles:         roles,
      groups:        groups,
    )
    user2 = User.create_or_update(
      login:         'object_ref_name2@example.org',
      firstname:     'object_ref_name2',
      lastname:      'object_ref_name2',
      email:         'object_ref_name2@example.org',
      password:      'some_pass',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
      roles:         roles,
      groups:        groups,
    )

    org1 = Organization.create_if_not_exists_with_ref(
      name:          'some org update_with_ref member',
      members:       ['object_ref_name1@example.org'],
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert(org1.member_ids.sort.include?(user1.id))
    assert_not(org1.member_ids.sort.include?(user2.id))

    org2 = Organization.create_or_update_with_ref(
      name:          'some org update_with_ref member',
      members:       ['object_ref_name2@example.org'],
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_not(org2.member_ids.sort.include?(user1.id))
    assert(org2.member_ids.sort.include?(user2.id))
    assert_equal(org1.id, org2.id)

    org3 = Organization.create_or_update_with_ref(
      name:          'some org update_with_ref member2',
      members:       ['object_ref_name2@example.org'],
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_not(org3.member_ids.sort.include?(user1.id))
    assert(org3.member_ids.sort.include?(user2.id))
    assert_not_equal(org2.id, org3.id)

    assert_raises( ActiveRecord::AssociationTypeMismatch ) do
      Organization.create_or_update_with_ref(
        name:          'some org update_with_ref member2',
        members:       ['object_ref_name2@example.org'],
        member_ids:    [2],
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

  end

  test 'user' do
    Organization.create_if_not_exists_with_ref(
      name:          'some org update_with_ref user',
      updated_by_id: 1,
      created_by_id: 1,
    )
    user1 = User.create_or_update_with_ref(
      login:         'object_ref_name1@example.org',
      firstname:     'object_ref_name1',
      lastname:      'object_ref_name1',
      email:         'object_ref_name1@example.org',
      password:      'some_pass',
      active:        true,
      organization:  'some org update_with_ref user',
      updated_by_id: 1,
      created_by_id: 1,
      roles:         %w[Agent Admin],
      groups:        ['Users'],
    )
    user2 = User.create_or_update_with_ref(
      login:           'object_ref_name2@example.org',
      firstname:       'object_ref_name2',
      lastname:        'object_ref_name2',
      email:           'object_ref_name2@example.org',
      password:        'some_pass',
      organization_id: nil,
      active:          true,
      updated_by_id:   1,
      created_by_id:   1,
      roles:           ['Customer'],
      groups:          [],
    )
    admin_role = Role.lookup(name: 'Admin')
    agent_role = Role.lookup(name: 'Agent')
    customer_role = Role.lookup(name: 'Customer')

    users_group = Group.lookup(name: 'Users')

    assert(user1.organization.name, 'some org update_with_ref user')
    assert(user1.group_ids.include?(users_group.id))
    assert(user1.role_ids.include?(admin_role.id))
    assert(user1.role_ids.include?(agent_role.id))
    assert_not(user1.role_ids.include?(customer_role.id))

    assert_nil(user2.organization_id)
    assert_not(user2.group_ids.include?(users_group.id))
    assert_not(user2.role_ids.include?(admin_role.id))
    assert_not(user2.role_ids.include?(agent_role.id))
    assert(user2.role_ids.include?(customer_role.id))

  end

  test 'group' do
    user1 = User.create_or_update_with_ref(
      login:           'object_ref_name1@example.org',
      firstname:       'object_ref_name1',
      lastname:        'object_ref_name1',
      email:           'object_ref_name1@example.org',
      password:        'some_pass',
      active:          true,
      organization_id: nil,
      updated_by_id:   1,
      created_by_id:   1,
      roles:           %w[Agent Admin],
      groups:          [],
    )
    user2 = User.create_or_update_with_ref(
      login:           'object_ref_name2@example.org',
      firstname:       'object_ref_name2',
      lastname:        'object_ref_name2',
      email:           'object_ref_name2@example.org',
      password:        'some_pass',
      organization_id: nil,
      active:          true,
      updated_by_id:   1,
      created_by_id:   1,
      roles:           ['Customer'],
      groups:          [],
    )

    group1 = Group.create_if_not_exists_with_ref(
      name:          'some group update_with_ref',
      users:         ['object_ref_name1@example.org'],
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert(group1.name, 'some group update_with_ref')
    assert(group1.user_ids.include?(user1.id))
    assert_not(group1.user_ids.include?(user2.id))

  end
end
