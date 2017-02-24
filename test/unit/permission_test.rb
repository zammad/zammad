# encoding: utf-8
require 'test_helper'

class PermissionTest < ActiveSupport::TestCase

  test 'permission' do
    permissions = Permission.with_parents('some_key.sub_key')
    assert_equal('some_key', permissions[0])
    assert_equal('some_key.sub_key', permissions[1])
    assert_equal(2, permissions.count)
  end

  test 'user permission' do

    permission1 = Permission.create_or_update(
      name: 'admin.permission1',
      note: 'Admin Interface',
      preferences: {},
      active: true,
    )
    permission2 = Permission.create_or_update(
      name: 'admin.permission2',
      note: 'Admin Interface',
      preferences: {},
      active: true,
    )
    role_permission1 = Role.create_or_update(
      name: 'AdminPermission1',
      note: 'To configure your permission1.',
      preferences: {
        not: ['Customer'],
      },
      default_at_signup: false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    role_permission1.permission_revoke('admin')
    role_permission1.permission_grant('admin.permission1')
    user_with_permission1 = User.create_or_update(
      login: 'setting-permission1',
      firstname: 'Setting',
      lastname: 'Admin Permission1',
      email: 'setting-admin-permission1@example.com',
      password: 'some_pw',
      active: true,
      roles: [role_permission1],
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_equal(true, user_with_permission1.permissions?('admin.permission1'))
    assert_equal(true, user_with_permission1.permissions?('admin.*'))
    assert_equal(false, user_with_permission1.permissions?('admi.*'))
    assert_equal(false, user_with_permission1.permissions?('admin.permission2'))
    assert_equal(false, user_with_permission1.permissions?('admin'))

    permission1.active = false
    permission1.save!

    assert_equal(false, user_with_permission1.permissions?('admin.permission1'))
    assert_equal(false, user_with_permission1.permissions?('admin.*'))
    assert_equal(false, user_with_permission1.permissions?('admi.*'))
    assert_equal(false, user_with_permission1.permissions?('admin.permission2'))
    assert_equal(false, user_with_permission1.permissions?('admin'))

    role_permission1.permission_grant('admin')

    assert_equal(false, user_with_permission1.permissions?('admin.permission1'))
    assert_equal(true, user_with_permission1.permissions?('admin.*'))
    assert_equal(false, user_with_permission1.permissions?('admi.*'))
    assert_equal(true, user_with_permission1.permissions?('admin.permission2'))
    assert_equal(true, user_with_permission1.permissions?('admin'))

    role_permission1.permission_revoke('admin')

  end

  test 'user permission with invalid role' do

    permission3 = Permission.create_or_update(
      name: 'admin.permission3',
      note: 'Admin Interface',
      preferences: {},
      active: true,
    )
    role_permission3 = Role.create_or_update(
      name: 'AdminPermission2',
      note: 'To configure your permission3.',
      preferences: {
        not: ['Customer'],
      },
      default_at_signup: false,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    role_permission3.permission_grant('admin.permission3')
    user_with_permission3 = User.create_or_update(
      login: 'setting-permission3',
      firstname: 'Setting',
      lastname: 'Admin Permission2',
      email: 'setting-admin-permission3@example.com',
      password: 'some_pw',
      active: true,
      roles: [role_permission3],
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(true, user_with_permission3.permissions?('admin.permission3'))
    assert_equal(true, user_with_permission3.permissions?('admin.*'))
    assert_equal(false, user_with_permission3.permissions?('admi.*'))
    assert_equal(false, user_with_permission3.permissions?('admin.permission4'))
    assert_equal(false, user_with_permission3.permissions?('admin'))

    role_permission3.active = false
    role_permission3.save
    user_with_permission3.reload
    assert_equal(false, user_with_permission3.permissions?('admin.permission3'))
    assert_equal(false, user_with_permission3.permissions?('admin.*'))
    assert_equal(false, user_with_permission3.permissions?('admi.*'))
    assert_equal(false, user_with_permission3.permissions?('admin.permission4'))
    assert_equal(false, user_with_permission3.permissions?('admin'))

  end

  test 'user permission with childs' do

    permission1 = Permission.create_or_update(
      name: 'admin.permission_child1',
      note: 'Admin Interface',
      preferences: {},
      active: true,
    )
    permission2 = Permission.create_or_update(
      name: 'admin.permission_child2',
      note: 'Admin Interface',
      preferences: {},
      active: false,
    )
    role_permission1 = Role.create_or_update(
      name: 'AdminPermissionChild1',
      note: 'To configure your permission child1.',
      preferences: {
        not: ['Customer'],
      },
      default_at_signup: false,
      updated_by_id: 1,
      created_by_id: 1,
    )
    role_permission1.permission_grant('admin')
    user_with_permission1 = User.create_or_update(
      login: 'setting-permission-child1',
      firstname: 'Setting',
      lastname: 'Admin Permission Child1',
      email: 'setting-admin-permission-child1@example.com',
      password: 'some_pw',
      active: true,
      roles: [role_permission1],
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(user_with_permission1.permissions_with_child_ids.include?(permission1.id))
    assert_not(user_with_permission1.permissions_with_child_ids.include?(permission2.id))
    assert(user_with_permission1.permissions_with_child_ids.include?(Permission.find_by(name: 'admin').id))

    # cleanup
    user_with_permission1.destroy
    role_permission1.destroy
  end
end
