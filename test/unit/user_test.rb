# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'user' do
    tests = [
      {
        name:          '#1 - simple create',
        create:        {
          firstname:     'Firstname',
          lastname:      'Lastname',
          email:         'some@example.com',
          login:         'some@example.com',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname:  'Lastname',
          image:     nil,
          fullname:  'Firstname Lastname',
          email:     'some@example.com',
          login:     'some@example.com',
        },
      },
      {
        name:          '#2 - simple create - no lastname',
        create:        {
          firstname:     'Firstname Lastname',
          lastname:      '',
          email:         'some@example.com',
          login:         'some@example.com',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname:  'Lastname',
          image:     nil,
          email:     'some@example.com',
          login:     'some@example.com',
        },
      },
      {
        name:          '#3 - simple create - no firstname',
        create:        {
          firstname:     '',
          lastname:      'Firstname Lastname',
          email:         'some@example.com',
          login:         'some@example.com',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname:  'Lastname',
          image:     nil,
          email:     'some@example.com',
          login:     'some@example.com',
        },
      },
      {
        name:          '#4 - simple create - nil as lastname',
        create:        {
          firstname:     'Firstname Lastname',
          lastname:      '',
          email:         'some@example.com',
          login:         'some@example.com',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname:  'Lastname',
          image:     nil,
          email:     'some@example.com',
          login:     'some@example.com',
        },
      },
      {
        name:          '#5 - simple create - no lastname, firstname with ","',
        create:        {
          firstname:     'Lastname, Firstname',
          lastname:      '',
          email:         'some@example.com',
          login:         'some@example.com',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname:  'Lastname',
          email:     'some@example.com',
          login:     'some@example.com',
        },
      },
      {
        name:          '#6 - simple create - no lastname/firstname',
        create:        {
          firstname:     '',
          lastname:      '',
          email:         'firstname.lastname@example.com',
          login:         'login-1',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname:  'Lastname',
          fullname:  'Firstname Lastname',
          email:     'firstname.lastname@example.com',
          login:     'login-1',
        },
      },
      {
        name:          '#7 - simple create - no lastname/firstnam',
        create:        {
          firstname:     '',
          lastname:      '',
          email:         'FIRSTNAME.lastname@example.com',
          login:         'login-2',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname:  'Lastname',
          email:     'firstname.lastname@example.com',
          login:     'login-2',
        },
      },
      {
        name:          '#8 - simple create - nill as fristname and lastname',
        create:        {
          firstname:     '',
          lastname:      '',
          email:         'FIRSTNAME.lastname@example.com',
          login:         'login-3',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname:  'Lastname',
          email:     'firstname.lastname@example.com',
          login:     'login-3',
        },
      },
      {
        name:          '#11 - update create with login/email check',
        create:        {
          firstname:     '',
          lastname:      '',
          email:         'caoyaoewfzfw@21222cn.com',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: '',
          lastname:  '',
          fullname:  'caoyaoewfzfw@21222cn.com',
          email:     'caoyaoewfzfw@21222cn.com',
          login:     'caoyaoewfzfw@21222cn.com',
        },
        update:        {
          email: 'caoyaoewfzfw@212224cn.com',
        },
        update_verify: {
          firstname: '',
          lastname:  '',
          email:     'caoyaoewfzfw@212224cn.com',
          fullname:  'caoyaoewfzfw@212224cn.com',
          login:     'caoyaoewfzfw@212224cn.com',
        }
      },
      {
        name:          '#12 - update create with login/email check',
        create:        {
          firstname:     'Firstname',
          lastname:      'Lastname',
          email:         'some_tEst11@example.com',
          updated_by_id: 1,
          created_by_id: 1,
        },
        create_verify: {
          firstname: 'Firstname',
          lastname:  'Lastname',
          fullname:  'Firstname Lastname',
          email:     'some_test11@example.com',
        },
        update:        {
          email: 'some_Test11-1@example.com',
        },
        update_verify: {
          firstname: 'Firstname',
          lastname:  'Lastname',
          email:     'some_test11-1@example.com',
          fullname:  'Firstname Lastname',
          login:     'some_test11-1@example.com',
        }
      },
    ]

    default_disable_in_test_env = Service::Image::Zammad.const_get(:DISABLE_IN_TEST_ENV)
    silence_warnings do
      Service::Image::Zammad.const_set(:DISABLE_IN_TEST_ENV, false)
    end

    tests.each do |test|

      # check if user exists
      user = User.find_by(login: test[:create][:login])
      user&.destroy!

      user = User.create!(test[:create])

      test[:create_verify].each do |key, value|
        next if key == :image_md5

        if user.respond_to?(key)
          result = user.send(key)
          if value.nil?
            assert_nil(result, "create check #{key} in (#{test[:name]})")
          else
            assert_equal(result, value, "create check #{key} in (#{test[:name]})")
          end
        else
          assert_equal(user[key], value, "create check #{key} in (#{test[:name]})")
        end
      end
      if test[:update]
        user.update!(test[:update])

        test[:update_verify].each do |key, value|
          next if key == :image_md5

          if user.respond_to?(key)
            assert_equal(user.send(key), value, "update check #{key} in (#{test[:name]})")
          else
            assert_equal(user[key], value, "update check #{key} in (#{test[:name]})")
          end
        end

      end

      user.destroy!
    end

    silence_warnings do
      Service::Image::Zammad.const_set(:DISABLE_IN_TEST_ENV, default_disable_in_test_env)
    end
  end

  test 'strange spaces' do
    name = "#{Time.zone.now.to_i}-#{SecureRandom.uuid}"
    email = "customer_email#{name}@example.com"
    customer = User.create!(
      firstname:     'Role',
      lastname:      "Customer#{name}",
      email:         " #{email} ",
      password:      'customerpw',
      active:        true,
      roles:         Role.where(name: %w[Customer]),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer)
    assert_equal(email, customer.email)
    customer.destroy!

    name = "#{Time.zone.now.to_i}-#{SecureRandom.uuid}"
    email = "customer_email#{name}@example.com"
    customer = User.create!(
      firstname:     "\u{00a0}\u{00a0}Role",
      lastname:      "Customer#{name} \u{00a0}",
      email:         "\u{00a0}#{email}\u{00a0}",
      password:      'customerpw',
      active:        true,
      roles:         Role.where(name: %w[Customer]),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer)
    assert_equal('Role', customer.firstname)
    assert_equal("Customer#{name}", customer.lastname)
    assert_equal(email, customer.email)
    customer.destroy!

    name = "#{Time.zone.now.to_i}-#{SecureRandom.uuid}"
    email = "customer_email#{name}@example.com"
    customer = User.create!(
      firstname:     "\u{200B}\u{200B}Role",
      lastname:      "Customer#{name} \u{200B}",
      email:         "\u{200B}#{email}\u{200B}",
      password:      'customerpw',
      active:        true,
      roles:         Role.where(name: %w[Customer]),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer)
    assert_equal('Role', customer.firstname)
    assert_equal("Customer#{name}", customer.lastname)
    assert_equal(email, customer.email)
    customer.destroy!

    name = "#{Time.zone.now.to_i}-#{SecureRandom.uuid}"
    email = "customer_email#{name}@example.com"
    customer = User.create!(
      firstname:     "\u{200B}\u{200B}Role\u{00a0}",
      lastname:      "\u{00a0}\u{00a0}Customer#{name} \u{200B}",
      email:         "\u{200B}#{email}\u{200B}",
      password:      'customerpw',
      active:        true,
      roles:         Role.where(name: %w[Customer]),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer)
    assert_equal('Role', customer.firstname)
    assert_equal("Customer#{name}", customer.lastname)
    assert_equal(email, customer.email)
    customer.destroy!

    name = "#{Time.zone.now.to_i}-#{SecureRandom.uuid}"
    email = "customer_email#{name}@example.com"
    customer = User.create!(
      firstname:     "\u{200a}\u{200b}\u{202F}\u{205F}Role\u{2007}\u{2008}",
      lastname:      "\u{00a0}\u{00a0}Customer#{name}\u{3000}\u{FEFF}\u{2000}",
      email:         "\u{200B}#{email}\u{200B}\u{2007}\u{2008}",
      password:      'customerpw',
      active:        true,
      roles:         Role.where(name: %w[Customer]),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(customer)
    assert_equal('Role', customer.firstname)
    assert_equal("Customer#{name}", customer.lastname)
    assert_equal(email, customer.email)
    customer.destroy!
  end

  test 'without email - but login eq email' do
    name = SecureRandom.uuid

    login = "admin-role_without_email#{name}@example.com"
    email = "admin-role_without_email#{name}@example.com"
    admin = User.create_or_update(
      login:         login,
      firstname:     'Role',
      lastname:      "Admin#{name}",
      # email: "",
      password:      'adminpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert(admin.id)
    assert_equal(admin.login, login)
    assert_equal(admin.email, '')

    admin.email = email
    admin.save!

    assert_equal(admin.login, login)
    assert_equal(admin.email, email)

    admin.email = ''
    admin.save!

    assert(admin.id)
    assert(admin.login)
    assert_not_equal(admin.login, login)
    assert_equal(admin.email, '')

    admin.destroy!
  end

  test 'without email - but login ne email' do
    name = SecureRandom.uuid

    login = "admin-role_without_email#{name}"
    email = "admin-role_without_email#{name}@example.com"
    admin = User.create_or_update(
      login:         login,
      firstname:     'Role',
      lastname:      "Admin#{name}",
      # email: "",
      password:      'adminpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert(admin.id)
    assert_equal(admin.login, login)
    assert_equal(admin.email, '')

    admin.email = email
    admin.save!

    assert_equal(admin.login, login)
    assert_equal(admin.email, email)

    admin.email = ''
    admin.save!

    assert(admin.id)
    assert_equal(admin.login, login)
    assert_equal(admin.email, '')

    admin.destroy!
  end

  test 'uniq email' do
    name = SecureRandom.uuid

    email1 = "admin1-role_without_email#{name}@example.com"
    admin1 = User.create!(
      login:         email1,
      firstname:     'Role',
      lastname:      "Admin1#{name}",
      email:         email1,
      password:      'adminpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert(admin1.id)
    assert_equal(admin1.email, email1)

    assert_raises(ActiveRecord::RecordInvalid) do
      User.create!(
        login:         "#{email1}-1",
        firstname:     'Role',
        lastname:      "Admin1#{name}",
        email:         email1,
        password:      'adminpw',
        active:        true,
        roles:         Role.where(name: %w[Admin Agent]),
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

    email2 = "admin2-role_without_email#{name}@example.com"
    admin2 = User.create!(
      firstname:     'Role',
      lastname:      "Admin2#{name}",
      email:         email2,
      password:      'adminpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert_raises(ActiveRecord::RecordInvalid) do
      admin2.email = email1
      admin2.save!
    end

    admin1.email = admin1.email
    admin1.save!

    admin2.destroy!
    admin1.destroy!
  end

  test 'uniq email - multiple use' do
    Setting.set('user_email_multiple_use', true)
    name = SecureRandom.uuid

    email1 = "admin1-role_without_email#{name}@example.com"
    admin1 = User.create!(
      login:         email1,
      firstname:     'Role',
      lastname:      "Admin1#{name}",
      email:         email1,
      password:      'adminpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )

    assert(admin1.id)
    assert_equal(admin1.email, email1)

    admin2 = User.create!(
      login:         "#{email1}-1",
      firstname:     'Role',
      lastname:      "Admin1#{name}",
      email:         email1,
      password:      'adminpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(admin2.email, email1)
    admin2.destroy!
    admin1.destroy!
    Setting.set('user_email_multiple_use', false)
  end

  test 'ensure roles' do
    name = SecureRandom.uuid
    admin = User.create_or_update(
      login:         "admin-role#{name}@example.com",
      firstname:     'Role',
      lastname:      "Admin#{name}",
      email:         "admin-role#{name}@example.com",
      password:      'adminpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )

    customer1 = User.create_or_update(
      login:         "user-ensure-role1-#{name}@example.com",
      firstname:     'Role',
      lastname:      "Customer#{name}",
      email:         "user-ensure-role1-#{name}@example.com",
      password:      'customerpw',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(customer1.role_ids.sort, Role.signup_role_ids)

    roles = Role.where(name: 'Agent')
    customer1.roles = roles

    customer1.save!

    assert_equal(customer1.role_ids.count, 1)
    assert_equal(customer1.role_ids.first, roles.first.id)
    assert_equal(customer1.roles.first.id, roles.first.id)

    customer1.roles = []
    customer1.save!

    assert_equal(customer1.role_ids.sort, Role.signup_role_ids)
    customer1.destroy!

    customer2 = User.create_or_update(
      login:         "user-ensure-role2-#{name}@example.com",
      firstname:     'Role',
      lastname:      "Customer#{name}",
      email:         "user-ensure-role2-#{name}@example.com",
      password:      'customerpw',
      roles:         roles,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(customer2.role_ids.count, 1)
    assert_equal(customer2.role_ids.first, roles.first.id)
    assert_equal(customer2.roles.first.id, roles.first.id)

    roles = Role.where(name: 'Admin')
    customer2.role_ids = [roles.first.id]
    customer2.save!

    assert_equal(customer2.role_ids.count, 1)
    assert_equal(customer2.role_ids.first, roles.first.id)
    assert_equal(customer2.roles.first.id, roles.first.id)

    customer2.roles = []
    customer2.save!

    assert_equal(customer2.role_ids.sort, Role.signup_role_ids)
    customer2.destroy!

    customer3 = User.create_or_update(
      login:         "user-ensure-role2-#{name}@example.com",
      firstname:     'Role',
      lastname:      "Customer#{name}",
      email:         "user-ensure-role2-#{name}@example.com",
      password:      'customerpw',
      roles:         roles,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    customer3.roles = Role.where(name: %w[Admin Agent])
    customer3.roles.each do |role|
      assert_not_equal(role.name, 'Customer')
    end
    customer3.roles = Role.where(name: 'Admin')
    customer3.roles.each do |role|
      assert_not_equal(role.name, 'Customer')
    end
    customer3.roles = Role.where(name: 'Agent')
    customer3.roles.each do |role|
      assert_not_equal(role.name, 'Customer')
    end
    customer3.destroy!

    admin.destroy!
  end

  test 'user default preferences' do
    name = SecureRandom.uuid
    groups = Group.where(name: 'Users')
    roles  = Role.where(name: 'Agent')
    agent1 = User.create_or_update(
      login:         "agent-default-preferences#{name}@example.com",
      firstname:     'Preferences',
      lastname:      "Agent#{name}",
      email:         "agent-default-preferences#{name}@example.com",
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        groups,
      preferences:   {
        locale: 'de-de',
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    agent1 = User.find(agent1.id)
    assert(agent1.preferences)
    assert(agent1.preferences['locale'])
    assert_equal(agent1.preferences['locale'], 'de-de')
    assert(agent1.preferences['notification_config'])
    assert(agent1.preferences['notification_config']['matrix'])
    assert(agent1.preferences['notification_config']['matrix']['create'])
    assert(agent1.preferences['notification_config']['matrix']['update'])

    roles = Role.where(name: 'Customer')
    customer1 = User.create_or_update(
      login:         "customer-default-preferences#{name}@example.com",
      firstname:     'Preferences',
      lastname:      "Customer#{name}",
      email:         "customer-default-preferences#{name}@example.com",
      password:      'customerpw',
      active:        true,
      roles:         roles,
      preferences:   {
        locale: 'de-de',
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    customer1 = User.find(customer1.id)
    assert(customer1.preferences)
    assert(customer1.preferences['locale'])
    assert_equal(customer1.preferences['locale'], 'de-de')
    assert_not(customer1.preferences['notification_config'])

    customer1 = User.find(customer1.id)
    customer1.roles = Role.where(name: 'Agent')
    customer1 = User.find(customer1.id)

    assert(customer1.preferences)
    assert(customer1.preferences['locale'])
    assert_equal(customer1.preferences['locale'], 'de-de')
    assert(customer1.preferences['notification_config'])
    assert(customer1.preferences['notification_config']['matrix']['create'])
    assert(customer1.preferences['notification_config']['matrix']['update'])
  end

  test 'permission' do
    test_role_1 = Role.create_or_update(
      name:          'Test1',
      note:          'To configure your system.',
      preferences:   {
        not: ['Test3'],
      },
      updated_by_id: 1,
      created_by_id: 1
    )
    test_role_2 = Role.create_or_update(
      name:          'Test2',
      note:          'To work on Tickets.',
      preferences:   {
        not: ['Test3'],
      },
      updated_by_id: 1,
      created_by_id: 1
    )
    test_role_3 = Role.create_or_update(
      name:          'Test3',
      note:          'People who create Tickets ask for help.',
      preferences:   {
        not: %w[Test1 Test2],
      },
      updated_by_id: 1,
      created_by_id: 1
    )
    test_role_4 = Role.create_or_update(
      name:          'Test4',
      note:          'Access the report area.',
      preferences:   {},
      created_by_id: 1,
      updated_by_id: 1,
    )
    name = SecureRandom.uuid
    assert_raises(RuntimeError) do
      User.create_or_update(
        login:         "customer-role#{name}@example.com",
        firstname:     'Role',
        lastname:      "Customer#{name}",
        email:         "customer-role#{name}@example.com",
        password:      'customerpw',
        active:        true,
        roles:         [test_role_1, test_role_3],
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    assert_raises(RuntimeError) do
      User.create_or_update(
        login:         "customer-role#{name}@example.com",
        firstname:     'Role',
        lastname:      "Customer#{name}",
        email:         "customer-role#{name}@example.com",
        password:      'customerpw',
        active:        true,
        roles:         [test_role_2, test_role_3],
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    user1 = User.create_or_update(
      login:         "customer-role#{name}@example.com",
      firstname:     'Role',
      lastname:      "Customer#{name}",
      email:         "customer-role#{name}@example.com",
      password:      'customerpw',
      active:        true,
      roles:         [test_role_1, test_role_2],
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(user1.role_ids.include?(test_role_1.id))
    assert(user1.role_ids.include?(test_role_2.id))
    assert_not(user1.role_ids.include?(test_role_3.id))
    assert_not(user1.role_ids.include?(test_role_4.id))
    user1 = User.create_or_update(
      login:         "customer-role#{name}@example.com",
      firstname:     'Role',
      lastname:      "Customer#{name}",
      email:         "customer-role#{name}@example.com",
      password:      'customerpw',
      active:        true,
      roles:         [test_role_1, test_role_4],
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(user1.role_ids.include?(test_role_1.id))
    assert_not(user1.role_ids.include?(test_role_2.id))
    assert_not(user1.role_ids.include?(test_role_3.id))
    assert(user1.role_ids.include?(test_role_4.id))
    assert_raises(RuntimeError) do
      User.create_or_update(
        login:         "customer-role#{name}@example.com",
        firstname:     'Role',
        lastname:      "Customer#{name}",
        email:         "customer-role#{name}@example.com",
        password:      'customerpw',
        active:        true,
        roles:         [test_role_1, test_role_3],
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    assert_raises(RuntimeError) do
      User.create_or_update(
        login:         "customer-role#{name}@example.com",
        firstname:     'Role',
        lastname:      "Customer#{name}",
        email:         "customer-role#{name}@example.com",
        password:      'customerpw',
        active:        true,
        roles:         [test_role_2, test_role_3],
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
    assert(user1.role_ids.include?(test_role_1.id))
    assert_not(user1.role_ids.include?(test_role_2.id))
    assert_not(user1.role_ids.include?(test_role_3.id))
    assert(user1.role_ids.include?(test_role_4.id))

  end

  test 'permission default' do
    name = SecureRandom.uuid
    admin_count = User.with_permissions('admin').count
    admin = User.create_or_update(
      login:         "admin-role#{name}@example.com",
      firstname:     'Role',
      lastname:      "Admin#{name}",
      email:         "admin-role#{name}@example.com",
      password:      'adminpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )
    agent_count = User.with_permissions('ticket.agent').count
    agent = User.create_or_update(
      login:         "agent-role#{name}@example.com",
      firstname:     'Role',
      lastname:      "Agent#{name}",
      email:         "agent-role#{name}@example.com",
      password:      'agentpw',
      active:        true,
      roles:         Role.where(name: 'Agent'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    customer_count = User.with_permissions('ticket.customer').count
    customer = User.create_or_update(
      login:         "customer-role#{name}@example.com",
      firstname:     'Role',
      lastname:      "Customer#{name}",
      email:         "customer-role#{name}@example.com",
      password:      'customerpw',
      active:        true,
      roles:         Role.where(name: 'Customer'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    users = User.with_permissions('not_existing')
    assert(users.blank?)

    users = User.with_permissions('admin')
    assert_equal(admin_count + 1, users.count)
    assert_equal(admin.login, users.last.login)

    users = User.with_permissions('admin.session')
    assert_equal(admin_count + 1, users.count)
    assert_equal(admin.login, users.last.login)

    users = User.with_permissions(['admin.session', 'not_existing'])
    assert_equal(admin_count + 1, users.count)
    assert_equal(admin.login, users.last.login)

    users = User.with_permissions('ticket.agent')
    assert_equal(agent_count + 1, users.count)
    assert_equal(agent.login, users.last.login)
    users = User.with_permissions(['ticket.agent', 'not_existing'])
    assert_equal(agent_count + 1, users.count)
    assert_equal(agent.login, users.last.login)

    users = User.with_permissions('ticket.customer')
    assert_equal(customer_count + 1, users.count)
    assert_equal(customer.login, users.last.login)
    users = User.with_permissions(['ticket.customer', 'not_existing'])
    assert_equal(customer_count + 1, users.count)
    assert_equal(customer.login, users.last.login)

  end

  test 'min admin permission check' do

    # delete inital admin
    User.find_by(login: 'admin@example.com').destroy

    # store current admin count
    admin_count_inital = User.with_permissions('admin').count
    assert_equal(0, admin_count_inital)

    # create two admin users
    random = SecureRandom.uuid
    admin1 = User.create_or_update(
      login:         "1admin-role#{random}@example.com",
      firstname:     'Role',
      lastname:      "Admin#{random}",
      email:         "admin-role#{random}@example.com",
      password:      'adminpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )

    random = SecureRandom.uuid
    admin2 = User.create_or_update(
      login:         "2admin-role#{random}@example.com",
      firstname:     'Role',
      lastname:      "Admin#{random}",
      email:         "admin-role#{random}@example.com",
      password:      'adminpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )

    random = SecureRandom.uuid
    admin3 = User.create_or_update(
      login:         "2admin-role#{random}@example.com",
      firstname:     'Role',
      lastname:      "Admin#{random}",
      email:         "admin-role#{random}@example.com",
      password:      'adminpw',
      active:        true,
      roles:         Role.where(name: %w[Admin Agent]),
      updated_by_id: 1,
      created_by_id: 1,
    )

    admin_count_inital = User.with_permissions('admin').count
    assert_equal(3, admin_count_inital)

    admin1.update!(roles: Role.where(name: %w[Agent]))

    admin_count_inital = User.with_permissions('admin').count
    assert_equal(2, admin_count_inital)

    admin2.update!(roles: Role.where(name: %w[Agent]))

    admin_count_inital = User.with_permissions('admin').count
    assert_equal(1, admin_count_inital)

    assert_raises(Exceptions::UnprocessableEntity) do
      admin3.update!(roles: Role.where(name: %w[Agent]))
    end

    admin_count_inital = User.with_permissions('admin').count
    assert_equal(1, admin_count_inital)

    assert_raises(Exceptions::UnprocessableEntity) do
      admin3.active = false
      admin3.save!
    end

    assert_equal(1, User.with_permissions('admin').count)
    admin_role = Role.find_by(name: 'Admin')
    assert_raises(Exceptions::UnprocessableEntity) do
      admin_role.active = false
      admin_role.save!
    end

    assert_raises(Exceptions::UnprocessableEntity) do
      admin_role.permission_revoke('admin')
    end

    assert_equal(1, User.with_permissions('admin').count)

  end

  test 'only valid agent in group permission check' do
    name = SecureRandom.uuid
    group = Group.create!(
      name:          "ValidAgentGroupPermission-#{name}",
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    roles = Role.where(name: 'Agent')
    User.create_or_update(
      login:         "valid_agent_permission-1#{name}@example.com",
      firstname:     'valid_agent_group_permission-1',
      lastname:      "Agent#{name}",
      email:         "valid_agent_permission-1#{name}@example.com",
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        [group],
      updated_by_id: 1,
      created_by_id: 1,
    )
    agent2 = User.create_or_update(
      login:         "valid_agent_permission-2#{name}@example.com",
      firstname:     'valid_agent_group_permission-2',
      lastname:      "Agent#{name}",
      email:         "valid_agent_permission-2#{name}@example.com",
      password:      'agentpw',
      active:        true,
      roles:         roles,
      groups:        [group],
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(2, User.group_access(group.id, 'full').count)
    agent2.active = false
    agent2.save!
    assert_equal(1, User.group_access(group.id, 'full').count)
    agent2.active = true
    agent2.save!
    assert_equal(2, User.group_access(group.id, 'full').count)
    roles = Role.where(name: 'Customer')
    agent2.roles = roles
    agent2.save!
    assert_equal(1, User.group_access(group.id, 'full').count)
  end

  test 'preferences[:notification_sound][:enabled] value check' do
    name  = SecureRandom.uuid
    roles = Role.where(name: 'Agent')

    agent1 = User.create!(
      login:         "agent-default-preferences-1#{name}@example.com",
      firstname:     'valid_agent_group_permission-1',
      lastname:      "Agent#{name}",
      email:         "agent-default-preferences-1#{name}@example.com",
      password:      'agentpw',
      active:        true,
      roles:         roles,
      preferences:   {
        notification_sound: {
          enabled: true,
        }
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(true, agent1.preferences[:notification_sound][:enabled])

    agent2 = User.create!(
      login:         "agent-default-preferences-2#{name}@example.com",
      firstname:     'valid_agent_group_permission-2',
      lastname:      "Agent#{name}",
      email:         "agent-default-preferences-2#{name}@example.com",
      password:      'agentpw',
      active:        true,
      roles:         roles,
      preferences:   {
        notification_sound: {
          enabled: false,
        }
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(false, agent2.preferences[:notification_sound][:enabled])

    agent3 = User.create!(
      login:         "agent-default-preferences-3#{name}@example.com",
      firstname:     'valid_agent_group_permission-3',
      lastname:      "Agent#{name}",
      email:         "agent-default-preferences-3#{name}@example.com",
      password:      'agentpw',
      active:        true,
      roles:         roles,
      preferences:   {
        notification_sound: {
          enabled: true,
        }
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(true, agent3.preferences[:notification_sound][:enabled])
    agent3.preferences[:notification_sound][:enabled] = 'false'
    agent3.save!
    agent3.reload
    assert_equal(false, agent3.preferences[:notification_sound][:enabled])

    agent4 = User.create!(
      login:         "agent-default-preferences-4#{name}@example.com",
      firstname:     'valid_agent_group_permission-4',
      lastname:      "Agent#{name}",
      email:         "agent-default-preferences-4#{name}@example.com",
      password:      'agentpw',
      active:        true,
      roles:         roles,
      preferences:   {
        notification_sound: {
          enabled: false,
        }
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(false, agent4.preferences[:notification_sound][:enabled])
    agent4.preferences[:notification_sound][:enabled] = 'true'
    agent4.save!
    agent4.reload
    assert_equal(true, agent4.preferences[:notification_sound][:enabled])

    agent4.preferences[:notification_sound][:enabled] = 'invalid'
    assert_raises(Exceptions::UnprocessableEntity) do
      agent4.save!
    end

    assert_raises(Exceptions::UnprocessableEntity) do
      User.create!(
        login:         "agent-default-preferences-5#{name}@example.com",
        firstname:     'valid_agent_group_permission-5',
        lastname:      "Agent#{name}",
        email:         "agent-default-preferences-5#{name}@example.com",
        password:      'agentpw',
        active:        true,
        roles:         roles,
        preferences:   {
          notification_sound: {
            enabled: 'invalid string',
          }
        },
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

  end

  test 'cleanup references on destroy' do
    agent1 = User.create!(
      login:         "agent-cleanup_check-1#{name}@example.com",
      firstname:     'valid_agent_group_permission-1',
      lastname:      "Agent#{name}",
      email:         "agent-cleanup_check-1#{name}@example.com",
      password:      'agentpw',
      active:        true,
      roles:         Role.where(name: 'Agent'),
      groups:        Group.all,
      updated_by_id: 1,
      created_by_id: 1,
    )
    agent1_id = agent1.id
    assert_equal(1, Avatar.list('User', agent1_id).count)

    UserDevice.add(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
      '91.115.248.231',
      agent1_id,
      'fingerprint1234',
      'session',
    )
    assert_equal(1, UserDevice.where(user_id: agent1_id).count)

    OnlineNotification.add(
      type:          'Assigned to you',
      object:        'Ticket',
      o_id:          1,
      seen:          false,
      user_id:       agent1_id,
      created_by_id: 1,
      updated_by_id: 1,
      created_at:    Time.zone.now,
      updated_at:    Time.zone.now,
    )
    assert_equal(1, OnlineNotification.where(user_id: agent1_id).count)

    Authorization.create!(
      user:     agent1,
      uid:      '123',
      username: '123',
      provider: 'some',
      token:    'token',
      secret:   'secret',
    )
    assert_equal(1, Authorization.where(user_id: agent1_id).count)

    Cti::CallerId.maybe_add(
      caller_id: '49123456789',
      comment:   'Hairdresser Bob Smith, San Francisco', # optional
      level:     'maybe', # known|maybe
      user_id:   agent1_id, # optional
      object:    'Ticket',
      o_id:      1,
    )
    assert_equal(1, Cti::CallerId.where(user_id: agent1_id).count)

    Taskbar.create!(
      client_id: 123,
      key:       'Ticket-1',
      callback:  'TicketZoom',
      params:    {
        id: 1,
      },
      state:     {},
      user_id:   agent1_id,
      prio:      1,
      notify:    false,
    )
    assert_equal(1, Taskbar.where(user_id: agent1_id).count)

    ticket1 = Ticket.create!(
      title:         'test 1234-1',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      owner_id:      2,
      updated_by_id: 1,
      created_by_id: 1,
    )

    RecentView.log(ticket1.class.to_s, ticket1.id, agent1)
    assert_equal(1, RecentView.where(created_by_id: agent1_id).count)

    Token.create!(action: 'api', user_id: agent1_id)

    StatsStore.create(
      stats_storable: agent1,
      key:            'some_key',
      data:           { A: 1, B: 2 },
      created_at:     Time.zone.now,
      created_by_id:  1,
    )
    item = StatsStore.find_by(
      stats_storable: agent1,
      key:            'some_key',
    )
    assert(item)

    agent1.destroy!

    assert_equal(0, UserDevice.where(user_id: agent1_id).count)
    assert_equal(0, Avatar.list('User', agent1_id, false).count)
    assert_equal(0, OnlineNotification.where(user_id: agent1_id).count)
    assert_equal(0, Authorization.where(user_id: agent1_id).count)
    assert_equal(0, Cti::CallerId.where(user_id: agent1_id).count)
    assert_equal(0, Taskbar.where(user_id: agent1_id).count)
    assert_equal(0, RecentView.where(created_by_id: agent1_id).count)
    assert_equal(0, Token.where(user_id: agent1_id).count)
    assert_equal(0, Token.where(user_id: agent1_id).count)
    item = StatsStore.find_by(
      stats_storable: agent1,
      key:            'some_key',
    )
    assert_nil(item)
  end

  test 'adding group drops cache' do
    agent1 = User.create!(
      login:         "agent-cleanup_check-1#{name}@example.com",
      firstname:     'valid_agent_group_permission-1',
      lastname:      "Agent#{name}",
      email:         "agent-cleanup_check-1#{name}@example.com",
      password:      'agentpw',
      active:        true,
      roles:         Role.where(name: 'Agent'),
      groups:        Group.all,
      updated_by_id: 1,
      created_by_id: 1,
    )

    group1 = Group.create_or_update(
      name:          "GroupWithoutPermission-#{SecureRandom.uuid}",
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    differences = %w[
      group1.attributes_with_association_ids['user_ids'].count
      agent1.attributes_with_association_ids['group_ids'].keys.count
    ]

    assert_difference differences, 1 do
      agent1.groups << group1
    end
  end
end
