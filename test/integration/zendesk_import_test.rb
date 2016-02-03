# encoding: utf-8
require 'integration_test_helper'

class ZendeskImportTest < ActiveSupport::TestCase

  if !ENV['IMPORT_ZENDESK_ENDPOINT']
    fail "ERROR: Need IMPORT_ZENDESK_ENDPOINT - hint IMPORT_ZENDESK_ENDPOINT='https://example.zendesk.com/api/v2'"
  end
  if !ENV['IMPORT_ZENDESK_ENDPOINT_KEY']
    fail "ERROR: Need IMPORT_ZENDESK_ENDPOINT_KEY - hint IMPORT_ZENDESK_ENDPOINT_KEY='01234567899876543210'"
  end
  if !ENV['IMPORT_ZENDESK_ENDPOINT_USERNAME']
    fail "ERROR: Need IMPORT_ZENDESK_ENDPOINT_USERNAME - hint IMPORT_ZENDESK_ENDPOINT_USERNAME='bob.ross@happylittletrees.com'"
  end

  Setting.set('import_zendesk_endpoint', ENV['IMPORT_ZENDESK_ENDPOINT'])
  Setting.set('import_zendesk_endpoint_key', ENV['IMPORT_ZENDESK_ENDPOINT_KEY'])
  Setting.set('import_zendesk_endpoint_username', ENV['IMPORT_ZENDESK_ENDPOINT_USERNAME'])
  Setting.set('import_mode', true)
  Import::Zendesk.start

  # check statistic count
  test 'check statistic' do

    remote_statistic = Import::Zendesk.statistic

    # retrive statistic
    compare_statistic = {
      'Tickets'            => 143,
      'TicketFields'       => 13,
      'UserFields'         => 1,
      'OrganizationFields' => 1,
      'Groups'             => 2,
      'Organizations'      => 1,
      'Users'              => 141,
      'GroupMemberships'   => 3,
      'Macros'             => 5,
      'Views'              => 11,
      'Automations'        => 5
    }

    assert_equal( compare_statistic, remote_statistic, 'statistic' )
  end

  # check count of imported items
  test 'check counts' do
    assert_equal( 143, User.count, 'users' )
    assert_equal( 3, Group.count, 'groups' )
    assert_equal( 5, Role.count, 'roles' )
    assert_equal( 2, Organization.count, 'organizations' )
    assert_equal( 143, Ticket.count, 'tickets' )
    assert_equal( 151, Ticket::Article.count, 'ticket articles' )
    assert_equal( 2, Store.count, 'ticket article attachments' )

    # TODO: Macros, Views, Automations...
  end

  # check imported users and permission
  test 'check users' do

    role_admin    = Role.find_by( name: 'Admin' )
    role_agent    = Role.find_by( name: 'Agent' )
    role_customer = Role.find_by( name: 'Customer' )

    group_users            = Group.find_by( name: 'Users' )
    group_support          = Group.find_by( name: 'Support' )
    group_additional_group = Group.find_by( name: 'Additional Group' )

    checks = [
      {
        id:   4,
        data: {
          firstname: 'Bob',
          lastname:  'Smith',
          login:     '1150734731',
          email:     'bob.smith@znuny.com',
          active:    true,
          phone:     '00114124',
        },
        roles:  [role_agent, role_admin],
        groups: [group_support],
      },
      {
        id:   5,
        data: {
          firstname: 'Hansimerkur',
          lastname:  '',
          login:     '1202726471',
          email:     'hansimerkur@znuny.com',
          active:    true,
        },
        roles:  [role_agent, role_admin],
        groups: [group_additional_group, group_support],
      },
      {
        id:   6,
        data: {
          firstname: 'Bernd',
          lastname:  'Hofbecker',
          login:     '1202726611',
          email:     'bernd.hofbecker@znuny.com',
          active:    true,
        },
        roles:  [role_customer],
        groups: [],
      },
      {
        id:   7,
        data: {
          firstname: 'Zendesk',
          lastname:  '',
          login:     '1202737821',
          email:     'noreply@zendesk.com',
          active:    true,
        },
        roles:  [role_customer],
        groups: [],
      },
      {
        id:   89,
        data: {
          firstname: 'Hans',
          lastname:  'Peter Wurst',
          login:     '1205512622',
          email:     'hansimerkur+zd-c1@znuny.com',
          active:    true,
        },
        roles:  [role_customer],
        groups: [],
      },
    ]

    checks.each { |check|
      user = User.find( check[:id] )

      assert_equal( check[:data][:firstname], user.firstname, 'firstname' )
      assert_equal( check[:data][:lastname], user.lastname, 'lastname' )
      assert_equal( check[:data][:login], user.login, 'login' )
      assert_equal( check[:data][:email], user.email, 'email' )
      assert_equal( check[:data][:phone], user.phone, 'phone' )
      assert_equal( check[:data][:active], user.active, 'active' )

      assert_equal( check[:roles], user.roles.to_a, "#{user.login} roles" )
      assert_equal( check[:groups], user.groups.to_a, "#{user.login} groups" )
    }
  end

  # check user fields
  test 'check user fields' do

    local_fields = User.column_names

    # TODO
    copmare_fields = %w(
      id
      organization_id
      login
      firstname
      lastname
      email
      image
      image_source
      web
      password
      phone
      fax
      mobile
      department
      street
      zip
      city
      country
      address
      vip
      verified
      active
      note
      last_login
      source
      login_failed
      preferences
      updated_by_id
      created_by_id
      created_at
      updated_at)

    assert_equal( copmare_fields, local_fields, 'user fields' )
  end

  # check groups/queues
  test 'check groups' do

    checks = [
      {
        id:   1,
        data: {
          name:   'Users',
          active: true,
        },
      },
      {
        id:   2,
        data: {
          name:   'Additional Group',
          active: true,
        },
      },
      {
        id:   3,
        data: {
          name:   'Support',
          active: true,
        },
      },
    ]

    checks.each { |check|
      group = Group.find( check[:id] )

      assert_equal( check[:data][:name], group.name, 'name' )
      assert_equal( check[:data][:active], group.active, 'active' )
    }
  end

  # check imported organizations
  test 'check organizations' do

    checks = [
      {
        id: 1,
        data: {
          name: 'Zammad Foundation',
          note: '',
        },
      },
      {
        id: 2,
        data: {
          name: 'Znuny',
          note: nil,
        },
      },
    ]

    checks.each { |check|
      organization = Organization.find( check[:id] )

      assert_equal( check[:data][:name], organization.name, 'name' )
      assert_equal( check[:data][:note], organization.note, 'note' )
    }
  end

  # check organization fields
  test 'check organization fields' do

    local_fields = Organization.column_names

    # TODO
    copmare_fields = %w(
      id
      name
      shared
      active
      note
      updated_by_id
      created_by_id
      created_at
      updated_at)

    assert_equal( copmare_fields, local_fields, 'organization fields' )
  end

  # check imported tickets
  test 'check tickets' do

    checks = [
      {
        id: 3,
        data: {
          title:                    'Bob Smith, here is the test ticket you requested',
          note:                     'test email',
          create_article_type_id:   10,
          create_article_sender_id: 2,
          article_count:            4,
          state_id:                 3,
          group_id:                 3,
          priority_id:              1,
          owner_id:                 1,
          customer_id:              7,
          organization_id:          nil,
        },
      },
      {
        id: 143,
        data: {
          title:                    'Basti ist cool',
          note:                     'Basti ist cool',
          create_article_type_id:   8,
          create_article_sender_id: 2,
          article_count:            1,
          state_id:                 1,
          group_id:                 1,
          priority_id:              2,
          owner_id:                 1,
          customer_id:              143,
          organization_id:          nil,
        },
      },
      {
        id: 5,
        data: {
          title:                    'Twitter',
          note:                     '@DesafioCaracol sh q acaso sto se vale ver el jueg...',
          create_article_type_id:   6,
          create_article_sender_id: 2,
          article_count:            1,
          state_id:                 1,
          group_id:                 3,
          priority_id:              2,
          owner_id:                 1,
          customer_id:              91,
          organization_id:          nil,
        },
      },
      {
        id: 2,
        data: {
          title:                    'This is a sample ticket requested and submitted by you',
          note:                     'This is the first comment. Feel free to delete this sample ticket.',
          create_article_type_id:   10,
          create_article_sender_id: 1,
          article_count:            4,
          state_id:                 3,
          group_id:                 3,
          priority_id:              3,
          owner_id:                 1,
          customer_id:              4,
          organization_id:          2,
        },
      },
      # {
      #   id: ,
      #   data: {
      #     title:                    ,
      #     note:                     ,
      #     create_article_type_id:   ,
      #     create_article_sender_id: ,
      #     article_count:            ,
      #     state_id:                 ,
      #     group_id:                 ,
      #     priority_id:              ,
      #     owner_id:                 ,
      #     customer_id:              ,
      #     organization_id:          ,
      #   },
      # },
    ]

    checks.each { |check|
      ticket = Ticket.find( check[:id] )

      assert_equal( check[:data][:title], ticket.title, 'title' )
      assert_equal( check[:data][:create_article_type_id], ticket.create_article_type_id, 'created_article_type_id' )
      assert_equal( check[:data][:create_article_sender_id], ticket.create_article_sender_id, 'created_article_sender_id' )
      assert_equal( check[:data][:article_count], ticket.article_count, 'article_count' )
      assert_equal( check[:data][:state_id], ticket.state.id, 'state_id' )
      assert_equal( check[:data][:group_id], ticket.group.id, 'group_id' )
      assert_equal( check[:data][:priority_id], ticket.priority.id, 'priority_id' )
      assert_equal( check[:data][:owner_id], ticket.owner.id, 'owner_id' )
      assert_equal( check[:data][:customer_id], ticket.customer.id, 'customer_id' )
      assert_equal( check[:data][:organization_id], ticket.organization.try(:id), 'organization_id' )
    }
  end

  test 'check article attachments' do

    checks = [
      {
        id: 5,
        data: {
          count: 1,
          1 => {
            preferences: {
              'Content-Type' => 'image/jpeg'
            },
            filename: '1a3496b9-53d9-494d-bbb0-e1d2e22074f8.jpeg',
          },
        },
      },
      {
        id: 7,
        data: {
          count: 1,
          1 => {
            preferences: {
              'Content-Type' => 'image/jpeg'
            },
            filename: 'paris.jpg',
          },
        },
      },
    ]

    checks.each { |check|
      article = Ticket::Article.find(check[:id])

      assert_equal( check[:data][:count], article.attachments.count, 'attachemnt count' )

      (1..check[:data][:count] ).each { |attachment_counter|

        attachment         = article.attachments[ attachment_counter - 1 ]
        compare_attachment = check[:data][ attachment_counter ]

        assert_equal( compare_attachment[:filename], attachment.filename, 'attachment file name' )

        assert_equal( compare_attachment[:preferences], attachment[:preferences], 'attachment preferences')

      }
    }
  end

  # check ticket fields
  test 'check ticket fields' do

    local_fields = Ticket.column_names

    # TODO
    copmare_fields = %w(
      id
      group_id
      priority_id
      state_id
      organization_id
      number
      title
      owner_id
      customer_id
      note
      first_response
      first_response_escal_date
      first_response_sla_time
      first_response_in_min
      first_response_diff_in_min
      close_time
      close_time_escal_date
      close_time_sla_time
      close_time_in_min
      close_time_diff_in_min
      update_time_escal_date
      updtate_time_sla_time
      update_time_in_min
      update_time_diff_in_min
      last_contact
      last_contact_agent
      last_contact_customer
      create_article_type_id
      create_article_sender_id
      article_count
      escalation_time
      pending_time
      type
      updated_by_id
      created_by_id
      created_at
      updated_at
      preferences)

    assert_equal( copmare_fields, local_fields, 'ticket fields' )
  end

end
