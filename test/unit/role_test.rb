# encoding: utf-8
require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  test 'permission' do

    permission_test = Permission.create_or_update(
      name: 'test',
      note: 'parent test permission',
      preferences: {
        disabled: true
      },
    )
    permission_test_agent = Permission.create_or_update(
      name: 'test.agent',
      note: 'agent test permission',
      preferences: {
        not: ['test.customer'],
      },
    )
    permission_test_customer = Permission.create_or_update(
      name: 'test.customer',
      note: 'customer test permission',
      preferences: {
        not: ['test.agent'],
      },
    )
    permission_test_normal = Permission.create_or_update(
      name: 'test.normal',
      note: 'normal test permission',
      preferences: {},
    )

    assert_raises(RuntimeError) {
      Role.create(
        name: 'Test1',
        note: 'Test1 Role.',
        permissions: [permission_test],
        updated_by_id: 1,
        created_by_id: 1
      )
    }
    assert_raises(RuntimeError) {
      Role.create(
        name: 'Test1',
        note: 'Test1 Role.',
        permissions: [permission_test_agent, permission_test_customer],
        updated_by_id: 1,
        created_by_id: 1
      )
    }
    assert_raises(RuntimeError) {
      Role.create(
        name: 'Test1',
        note: 'Test1 Role.',
        permissions: [permission_test_normal, permission_test_agent, permission_test_customer],
        updated_by_id: 1,
        created_by_id: 1
      )
    }
    role11 = Role.create(
      name: 'Test1.1',
      note: 'Test1.1 Role.',
      permissions: [permission_test_agent],
      updated_by_id: 1,
      created_by_id: 1
    )
    role12 = Role.create(
      name: 'Test1.2',
      note: 'Test1.2 Role.',
      permissions: [permission_test_customer],
      updated_by_id: 1,
      created_by_id: 1
    )
    role13 = Role.create(
      name: 'Test1.3',
      note: 'Test1.3 Role.',
      permissions: [permission_test_normal],
      updated_by_id: 1,
      created_by_id: 1
    )
    role14 = Role.create(
      name: 'Test1.4',
      note: 'Test1.4 Role.',
      permissions: [permission_test_normal, permission_test_customer],
      updated_by_id: 1,
      created_by_id: 1
    )

  end

  test 'permission default' do
    roles = Role.with_permissions('not_existing')
    assert(roles.empty?)

    roles = Role.with_permissions('admin')
    assert_equal('Admin', roles.first.name)

    roles = Role.with_permissions('admin.session')
    assert_equal('Admin', roles.first.name)

    roles = Role.with_permissions(['admin.session', 'not_existing'])
    assert_equal('Admin', roles.first.name)

    roles = Role.with_permissions('ticket.agent')
    assert_equal('Agent', roles.first.name)

    roles = Role.with_permissions(['ticket.agent', 'not_existing'])
    assert_equal('Agent', roles.first.name)

    roles = Role.with_permissions('ticket.customer')
    assert_equal('Customer', roles.first.name)

    roles = Role.with_permissions(['ticket.customer', 'not_existing'])
    assert_equal('Customer', roles.first.name)

  end

end
