# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'integration_test_helper'

class ZendeskImportTest < ActiveSupport::TestCase
  self.test_order = :sorted

  if !ENV['IMPORT_ZENDESK_ENDPOINT']
    raise "ERROR: Need IMPORT_ZENDESK_ENDPOINT - hint IMPORT_ZENDESK_ENDPOINT='https://example.zendesk.com/api/v2'"
  end
  if !ENV['IMPORT_ZENDESK_ENDPOINT_KEY']
    raise "ERROR: Need IMPORT_ZENDESK_ENDPOINT_KEY - hint IMPORT_ZENDESK_ENDPOINT_KEY='01234567899876543210'"
  end
  if !ENV['IMPORT_ZENDESK_ENDPOINT_USERNAME']
    raise "ERROR: Need IMPORT_ZENDESK_ENDPOINT_USERNAME - hint IMPORT_ZENDESK_ENDPOINT_USERNAME='bob.ross@happylittletrees.com'"
  end

  Setting.set('import_zendesk_endpoint', ENV['IMPORT_ZENDESK_ENDPOINT'])
  Setting.set('import_zendesk_endpoint_key', ENV['IMPORT_ZENDESK_ENDPOINT_KEY'])
  Setting.set('import_zendesk_endpoint_username', ENV['IMPORT_ZENDESK_ENDPOINT_USERNAME'])
  Setting.set('import_mode', true)
  Setting.set('system_init_done', false)

  job = ImportJob.create(name: 'Import::Zendesk')
  job.start

  # check statistic count
  test 'check statistic' do

    # retrive statistic
    compare_statistic = {
      Groups:        {
        skipped:     0,
        created:     2,
        updated:     0,
        unchanged:   0,
        failed:      0,
        deactivated: 0,
        sum:         2,
        total:       2
      },
      Users:         {
        skipped:     0,
        created:     141,
        updated:     1,
        unchanged:   0,
        failed:      0,
        deactivated: 0,
        sum:         142,
        total:       142
      },
      Organizations: {
        skipped:     0,
        created:     1,
        updated:     0,
        unchanged:   1,
        failed:      0,
        deactivated: 0,
        sum:         2,
        total:       2
      },
      Tickets:       {
        skipped:     1,
        created:     142,
        updated:     2,
        unchanged:   0,
        failed:      0,
        deactivated: 0,
        sum:         145,
        total:       145
      }
    }

    assert_equal(compare_statistic.with_indifferent_access, job.result, 'statistic')
  end

  # check count of imported items
  test 'check counts' do
    assert_equal(144, User.count, 'users')
    assert_equal(3, Group.count, 'groups')
    assert_equal(3, Role.count, 'roles')
    assert_equal(2, Organization.count, 'organizations')
    assert_equal(143, Ticket.count, 'tickets')
    assert_equal(153, Ticket::Article.count, 'ticket articles')
    assert_equal(3, Store.count, 'ticket article attachments')

    # TODO: Macros, Views, Automations...
  end

  # check imported users and permission
  test 'check users' do

    role_admin    = Role.find_by(name: 'Admin')
    role_agent    = Role.find_by(name: 'Agent')
    role_customer = Role.find_by(name: 'Customer')

    group_support          = Group.find_by(name: 'Support')
    group_additional_group = Group.find_by(name: 'Additional Group')

    checks = [
      {
        id:     144,
        data:   {
          firstname:     'Bob Smith',
          lastname:      'Smith',
          login:         'bob.smith@znuny.com',
          email:         'bob.smith@znuny.com',
          active:        true,
          phone:         '00114124',
          lieblingstier: 'Hundä',
        },
        roles:  [role_admin, role_agent],
        groups: [group_support],
      },
      {
        id:     142,
        data:   {
          firstname:     'Hansimerkur',
          lastname:      '',
          login:         'hansimerkur@znuny.com',
          email:         'hansimerkur@znuny.com',
          active:        true,
          lieblingstier: nil,
        },
        roles:  [role_admin, role_agent],
        groups: [group_additional_group, group_support],
      },
      {
        id:     6,
        data:   {
          firstname: 'Bernd',
          lastname:  'Hofbecker',
          login:     'bernd.hofbecker@znuny.com',
          email:     'bernd.hofbecker@znuny.com',
          active:    true,
        },
        roles:  [role_customer],
        groups: [],
      },
      {
        id:     143,
        data:   {
          firstname: 'Zendesk',
          lastname:  '',
          login:     'noreply@zendesk.com',
          email:     'noreply@zendesk.com',
          active:    true,
        },
        roles:  [role_customer],
        groups: [],
      },
      {
        id:     5,
        data:   {
          firstname: 'Hans',
          lastname:  'Peter Wurst',
          login:     'hansimerkur+zd-c1@znuny.com',
          email:     'hansimerkur+zd-c1@znuny.com',
          active:    true,
        },
        roles:  [role_customer],
        groups: [],
      },
    ]

    checks.each do |check|
      user = User.find(check[:id])
      check[:data].each do |key, value|
        user_value = user[key]
        text       = "user.#{key} for user_id #{check[:id]}"

        if value.nil?
          assert_nil(user_value, text)
        else
          assert_equal(value, user_value, text)
        end
      end
      assert_equal(check[:roles], user.roles.sort.to_a, "#{user.login} roles")
      assert_equal(check[:groups], user.groups_access('full').sort.to_a, "#{user.login} groups")
    end
  end

  # check user fields
  test 'check user fields' do
    local_fields = User.column_names
    copmare_fields = %w[
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
      out_of_office
      out_of_office_start_at
      out_of_office_end_at
      out_of_office_replacement_id
      preferences
      updated_by_id
      created_by_id
      created_at
      updated_at
      lieblingstier
      custom_dropdown
    ]

    assert_equal(copmare_fields, local_fields, 'user fields')
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

    checks.each do |check|
      group = Group.find(check[:id])
      check[:data].each do |key, value|
        assert_equal(value, group[key], "group.#{key} for group_id #{check[:id]}")
      end
    end
  end

  # check imported organizations
  test 'check organizations' do

    checks = [
      {
        id:   1,
        data: {
          name:            'Zammad Foundation',
          note:            '',
          api_key:         nil,
          custom_dropdown: nil,
        },
      },
      {
        id:   2,
        data: {
          name:            'Znuny',
          note:            nil,
          api_key:         'my api öäüß',
          custom_dropdown: 'b',
        },
      },
    ]

    checks.each do |check|
      organization = Organization.find(check[:id])
      check[:data].each do |key, value|
        organization_value = organization[key]
        text               = "organization.#{key} for organization_id #{check[:id]}"

        if value.nil?
          assert_nil(organization_value, text)
        else
          assert_equal(value, organization_value, text)
        end
      end
    end
  end

  # check organization fields
  test 'check organization fields' do
    local_fields = Organization.column_names
    copmare_fields = %w[
      id
      name
      shared
      domain
      domain_assignment
      active
      note
      updated_by_id
      created_by_id
      created_at
      updated_at
      api_key
      custom_dropdown
    ]

    assert_equal(copmare_fields, local_fields, 'organization fields')
  end

  # check imported tickets
  test 'check tickets' do

    checks = [
      {
        id:   2,
        data: {
          title:                    'test',
          note:                     nil,
          create_article_type_id:   1,
          create_article_sender_id: 2,
          article_count:            2,
          state_id:                 3,
          group_id:                 3,
          priority_id:              3,
          owner_id:                 User.find_by(login: 'bob.smith@znuny.com').id,
          customer_id:              User.find_by(login: 'bernd.hofbecker@znuny.com').id,
          organization_id:          2,
          test_checkbox:            true,
          custom_integer:           999,
          custom_dropdown:          'key2',
          custom_decimal:           '1.6',
          not_existing:             nil,
        },
      },
      {
        id:   3,
        data: {
          title:                    'Bob Smith, here is the test ticket you requested',
          note:                     nil,
          create_article_type_id:   10,
          create_article_sender_id: 2,
          article_count:            5,
          state_id:                 3,
          group_id:                 3,
          priority_id:              1,
          owner_id:                 User.find_by(login: 'bob.smith@znuny.com').id,
          customer_id:              User.find_by(login: 'noreply@zendesk.com').id,
          organization_id:          nil,
          test_checkbox:            false,
          custom_integer:           nil,
          custom_dropdown:          '',
          custom_decimal:           nil,
          not_existing:             nil,
        },
      },
      {
        id:   5,
        data: {
          title:                    'Twitter',
          note:                     nil,
          create_article_type_id:   6,
          create_article_sender_id: 2,
          article_count:            1,
          state_id:                 1,
          group_id:                 3,
          priority_id:              2,
          owner_id:                 User.find_by(login: '-').id,
          customer_id:              69,
          organization_id:          nil,
        },
      },
      {
        id:   143,
        data: {
          title:                    'Basti ist cool',
          note:                     nil,
          create_article_type_id:   8,
          create_article_sender_id: 2,
          article_count:            1,
          state_id:                 1,
          group_id:                 1,
          priority_id:              2,
          owner_id:                 User.find_by(login: '-').id,
          customer_id:              7,
          organization_id:          nil,
        },
      },
      {
        id:   145,
        data: {
          title:                    'closed ticket - should be archived and imported',
          note:                     nil,
          create_article_type_id:   11,
          create_article_sender_id: 1,
          article_count:            2,
          state_id:                 Ticket::State.find_by(name: 'closed').id,
          group_id:                 Group.find_by(name: 'Additional Group').id,
          priority_id:              Ticket::Priority.find_by(name: '2 normal').id,
          owner_id:                 User.find_by(login: 'hansimerkur@znuny.com').id,
          customer_id:              User.find_by(login: 'bob.smith@znuny.com').id,
          organization_id:          Organization.find_by(name: 'Znuny').id,
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

    checks.each do |check|
      ticket = Ticket.find(check[:id])
      check[:data].each do |key, value|
        ticket_value = ticket[key]
        text         = "ticket.#{key} for ticket_id #{check[:id]}"

        if value.nil?
          assert_nil(ticket_value, text)
        else
          assert_equal(value, ticket_value, text)
        end
      end
    end
  end

  test 'check article attachments' do

    checks = [
      {
        message_id: 39_984_258_725,
        data:       {
          count: 1,
          1 => {
            preferences: {
              'Content-Type'    => 'image/jpeg',
              'resizable'       => true,
              'content_preview' => true
            },
            filename:    '1a3496b9-53d9-494d-bbb0-e1d2e22074f8.jpeg',
          },
        },
      },
      {
        message_id: 32_817_827_921,
        data:       {
          count: 1,
          1 => {
            preferences: {
              'Content-Type'    => 'image/jpeg',
              'resizable'       => true,
              'content_preview' => true
            },
            filename:    'paris.jpg',
          },
        },
      },
      {
        message_id: 538_901_840_720,
        data:       {
          count: 1,
          1 => {
            preferences: {
              'Content-Type' => 'text/rtf'
            },
            filename:    'test.rtf',
          },
        },
      },
    ]

    checks.each do |check|
      article = Ticket::Article.find_by(message_id: check[:message_id])

      assert_equal(check[:data][:count], article.attachments.count, 'attachemnt count')

      (1..check[:data][:count]).each do |attachment_counter|

        attachment         = article.attachments[ attachment_counter - 1 ]
        compare_attachment = check[:data][ attachment_counter ]

        assert_equal(compare_attachment[:filename], attachment.filename, 'attachment file name')
        assert_equal(compare_attachment[:preferences], attachment[:preferences], 'attachment preferences')
      end
    end
  end

  # check ticket fields
  test 'check ticket fields' do
    local_fields = Ticket.column_names
    copmare_fields = %w[
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
      first_response_at
      first_response_escalation_at
      first_response_in_min
      first_response_diff_in_min
      close_at
      close_escalation_at
      close_in_min
      close_diff_in_min
      update_escalation_at
      update_in_min
      update_diff_in_min
      last_contact_at
      last_contact_agent_at
      last_contact_customer_at
      last_owner_update_at
      create_article_type_id
      create_article_sender_id
      article_count
      escalation_at
      pending_time
      type
      time_unit
      preferences
      updated_by_id
      created_by_id
      created_at
      updated_at
      custom_decimal
      test_checkbox
      custom_date
      custom_integer
      custom_regex
      custom_dropdown
    ]

    assert_equal(copmare_fields, local_fields, 'ticket fields')
  end

end
