
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

    assert_raises(RuntimeError) do
      Role.create(
        name: 'Test1',
        note: 'Test1 Role.',
        permissions: [permission_test],
        updated_by_id: 1,
        created_by_id: 1
      )
    end
    assert_raises(RuntimeError) do
      Role.create(
        name: 'Test1',
        note: 'Test1 Role.',
        permissions: [permission_test_agent, permission_test_customer],
        updated_by_id: 1,
        created_by_id: 1
      )
    end
    assert_raises(RuntimeError) do
      Role.create(
        name: 'Test1',
        note: 'Test1 Role.',
        permissions: [permission_test_normal, permission_test_agent, permission_test_customer],
        updated_by_id: 1,
        created_by_id: 1
      )
    end
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
    assert(roles.blank?)

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

  test 'with permission' do
    permission_test1 = Permission.create_or_update(
      name: 'test-with-permission1',
      note: 'parent test permission 1',
    )
    permission_test2 = Permission.create_or_update(
      name: 'test-with-permission2',
      note: 'parent test permission 2',
    )
    name = rand(999_999_999)
    role = Role.create(
      name: "Test with Permission? #{name}",
      note: "Test with Permission? #{name} Role.",
      permissions: [permission_test2],
      updated_by_id: 1,
      created_by_id: 1
    )
    assert_not(role.with_permission?('test-with-permission1'))
    assert(role.with_permission?('test-with-permission2'))
    assert(role.with_permission?(['test-with-permission2', 'some_other_permission']))
  end

  test 'default_at_signup' do

    agent_role = Role.find_by(name: 'Agent')
    assert_raises(Exceptions::UnprocessableEntity) do
      agent_role.default_at_signup = true
      agent_role.save!
    end

    admin_role = Role.find_by(name: 'Admin')
    assert_raises(Exceptions::UnprocessableEntity) do
      admin_role.default_at_signup = true
      admin_role.save!
    end

    assert_raises(Exceptions::UnprocessableEntity) do
      Role.create!(
        name: 'Test1',
        note: 'Test1 Role.',
        default_at_signup: true,
        permissions: [Permission.find_by(name: 'admin')],
        updated_by_id: 1,
        created_by_id: 1
      )
    end

    role = Role.create!(
      name: 'Test1',
      note: 'Test1 Role.',
      default_at_signup: false,
      permissions: [Permission.find_by(name: 'admin')],
      updated_by_id: 1,
      created_by_id: 1
    )
    assert(role)

    permissions = Permission.where('name LIKE ? OR name = ?', 'admin%', 'ticket.agent').pluck(:name) # get all administrative permissions
    permissions.each do |type|

      assert_raises(Exceptions::UnprocessableEntity) do
        Role.create!(
          name: "Test1_#{type}",
          note: 'Test1 Role.',
          default_at_signup: true,
          permissions: [Permission.find_by(name: type)],
          updated_by_id: 1,
          created_by_id: 1
        )
      end

      role = Role.create!(
        name: "Test1_#{type}",
        note: 'Test1 Role.',
        default_at_signup: false,
        permissions: [Permission.find_by(name: type)],
        updated_by_id: 1,
        created_by_id: 1
      )
      assert(role)
    end

    assert_raises(Exceptions::UnprocessableEntity) do
      Role.create!(
        name: 'Test2',
        note: 'Test2 Role.',
        default_at_signup: true,
        permissions: [Permission.find_by(name: 'ticket.agent')],
        updated_by_id: 1,
        created_by_id: 1
      )
    end

    role = Role.create!(
      name: 'Test2',
      note: 'Test2 Role.',
      default_at_signup: false,
      permissions: [Permission.find_by(name: 'ticket.agent')],
      updated_by_id: 1,
      created_by_id: 1
    )
    assert(role)

  end

end
