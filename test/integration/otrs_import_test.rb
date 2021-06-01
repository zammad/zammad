# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'integration_test_helper'

class OtrsImportTest < ActiveSupport::TestCase

  if !ENV['IMPORT_OTRS_ENDPOINT']
    raise "ERROR: Need IMPORT_OTRS_ENDPOINT - hint IMPORT_OTRS_ENDPOINT='http://vz305.demo.znuny.com/otrs/public.pl?Action=ZammadMigrator'"
  end
  if !ENV['IMPORT_OTRS_ENDPOINT_KEY']
    raise "ERROR: Need IMPORT_OTRS_ENDPOINT_KEY - hint IMPORT_OTRS_ENDPOINT_KEY='01234567899876543210'"
  end

  Setting.set('import_otrs_endpoint', ENV['IMPORT_OTRS_ENDPOINT'])
  Setting.set('import_otrs_endpoint_key', ENV['IMPORT_OTRS_ENDPOINT_KEY'])
  Setting.set('import_mode', true)
  Setting.set('system_init_done', false)
  Import::OTRS.start

  # check settings items
  test 'check settings' do
    http      = nil
    system_id = nil
    if ENV['IMPORT_OTRS_ENDPOINT'] =~ %r{^(http|https)://((.+?)\..+?)/}
      http      = $1
      system_id = $3
      system_id.gsub!(%r{[A-z]}, '') # strip chars
    end
    assert_equal( system_id, Setting.get('system_id'), 'system_id' )
    assert_equal( http, Setting.get('http_type'), 'http_type' )
    assert_equal( 'Example Company', Setting.get('organization'), 'organization' )
  end

  test 'check dynamic fields' do
    local_objects = ObjectManager::Attribute.list_full

    object_attribute_names = local_objects.select do |local_object|
      local_object[:object] == 'Ticket'
    end.collect do |local_object|
      local_object['name']
    end
    expected_object_attribute_names = %w[vertriebsweg te_test sugar_crm_remote_no sugar_crm_company_selected_no sugar_crm_company_selection combine itsm_criticality customer_id itsm_impact itsm_review_required itsm_decision_result itsm_repair_start_time itsm_recovery_start_time itsm_decision_date title itsm_due_date topic_no open_exchange_ticket_number hostname ticket_free_key11 type ticket_free_text11 open_exchange_tn topic zarafa_tn group_id scom_hostname checkbox_example scom_uuid scom_state scom_service location owner_id department customer_location state_id pending_time priority_id tags]

    assert_equal(expected_object_attribute_names, object_attribute_names, 'dynamic field names')
  end

  # check count of imported items
  test 'check counts' do
    assert_equal( 603, Ticket.count, 'tickets' )
    assert_equal( 3182, Ticket::Article.count, 'ticket articles' )
    assert_equal( 274, Store.count, 'ticket article attachments' )
    assert_equal( 10, Ticket::State.count, 'ticket states' )
    assert_equal( 24, Group.count, 'groups' )
  end

  # check imported users and permission
  test 'check users' do
    role_admin    = Role.where( name: 'Admin' ).first
    role_agent    = Role.where( name: 'Agent' ).first
    role_customer = Role.where( name: 'Customer' ).first
    #role_report   = Role.where( :name => 'Report' ).first

    user1 = User.find(2)
    assert_equal( 'agent-1 firstname', user1.firstname )
    assert_equal( 'agent-1 lastname', user1.lastname )
    assert_equal( 'agent-1', user1.login )
    assert_equal( 'agent-1@example.com', user1.email )
    assert_equal( true, user1.active )

    assert( user1.roles.include?( role_agent ) )
    assert_not( user1.roles.include?( role_admin ) )
    assert_not( user1.roles.include?( role_customer ) )
    #assert_not( user1.roles.include?( role_report ) )

    group_dasa = Group.where( name: 'dasa' ).first
    group_raw  = Group.where( name: 'Raw' ).first

    assert_not( user1.groups_access('full').include?( group_dasa ) )
    assert( user1.groups_access('full').include?( group_raw ) )

    user2 = User.find(3)
    assert_equal( 'agent-2 firstname äöüß', user2.firstname )
    assert_equal( 'agent-2 lastname äöüß', user2.lastname )
    assert_equal( 'agent-2', user2.login )
    assert_equal( 'agent-2@example.com', user2.email )
    assert_equal( true, user2.active )

    assert( user2.roles.include?( role_agent ) )
    assert( user2.roles.include?( role_admin ) )
    assert_not( user2.roles.include?( role_customer ) )
    #assert( user2.roles.include?( role_report ) )

    assert( user2.groups_access('full').include?( group_dasa ) )
    assert( user2.groups_access('full').include?( group_raw ) )

    user3 = User.find(7)
    assert_equal( 'invalid', user3.firstname )
    assert_equal( 'invalid', user3.lastname )
    assert_equal( 'invalid', user3.login )
    assert_equal( 'invalid@example.com', user3.email )
    assert_equal( false, user3.active )

    assert( user3.roles.include?( role_agent ) )
    assert_not( user3.roles.include?( role_admin ) )
    assert_not( user3.roles.include?( role_customer ) )
    #assert( user3.roles.include?( role_report ) )

    assert_not( user3.groups_access('full').include?( group_dasa ) )
    assert_not( user3.groups_access('full').include?( group_raw ) )

    user4 = User.find(8)
    assert_equal( 'invalid-temp', user4.firstname )
    assert_equal( 'invalid-temp', user4.lastname )
    assert_equal( 'invalid-temp', user4.login )
    assert_equal( 'invalid-temp@example.com', user4.email )
    assert_equal( false, user4.active )

    assert( user4.roles.include?( role_agent ) )
    assert_not( user4.roles.include?( role_admin ) )
    assert_not( user4.roles.include?( role_customer ) )
    #assert( user4.roles.include?( role_report ) )

    assert_not( user4.groups_access('full').include?( group_dasa ) )
    assert_not( user4.groups_access('full').include?( group_raw ) )

  end

  # check all synced states and state types
  test 'check ticket stats' do
    state = Ticket::State.find(1)
    assert_equal( 'new', state.name )
    assert_equal( 'new', state.state_type.name )

    state = Ticket::State.find(2)
    assert_equal( 'closed successful', state.name )
    assert_equal( 'closed', state.state_type.name )

    state = Ticket::State.find(6)
    assert_equal( 'pending reminder', state.name )
    assert_equal( 'pending reminder', state.state_type.name )
  end

  # check groups/queues
  test 'check groups' do
    group1 = Group.find(1)
    assert_equal( 'Postmaster', group1.name )
    assert_equal( true, group1.active )

    group2 = Group.find(19)
    assert_equal( 'UnitTestQueue20668', group2.name )
    assert_equal( false, group2.active )
  end

  # check imported customers and organization relation
  test 'check customers / organizations' do
    user1 = User.where( login: 'jn' ).first
    assert_equal( 'Johannes', user1.firstname )
    assert_equal( 'Nickel', user1.lastname )
    assert_equal( 'jn', user1.login )
    assert_equal( 'jn@example.com', user1.email )
    organization1 = user1.organization
    assert_equal( 'Znuny GmbH Berlin', organization1.name )
    assert_equal( 'äöüß', organization1.note )

    user2 = User.where( login: 'test90133' ).first
    assert_equal( 'test90133', user2.firstname )
    assert_equal( 'test90133', user2.lastname )
    assert_equal( 'test90133', user2.login )
    assert_equal( 'qa4711@t-online.de', user2.email )
    organization2 = user2.organization
    assert( organization2, nil )
  end

  # check imported tickets
  test 'check tickets' do

    # ticket is open
    ticket = Ticket.find(728)
    assert_equal( 'test #1', ticket.title )
    assert_equal( 'open', ticket.state.name )
    assert_equal( 'Misc', ticket.group.name )
    assert_equal( '4 high', ticket.priority.name )
    assert_equal( 'agent-2', ticket.owner.login )
    assert_equal( 'partner', ticket.customer.login )
    assert_equal( 'Partner der betreut', ticket.organization.name )
    assert_equal( Time.zone.parse('2014-11-20 22:33:41 +0000').gmtime.to_s, ticket.created_at.to_s )
    assert_nil( ticket.close_at )

    # check history
    #  - create entry

    # ticket is created with state closed
    ticket = Ticket.find(729)
    assert_equal( 'test #2', ticket.title )
    assert_equal( 'closed successful', ticket.state.name )
    assert_equal( 'Raw', ticket.group.name )
    assert_equal( '3 normal', ticket.priority.name )
    assert_equal( 'agent-2', ticket.owner.login )
    assert_equal( 'jn2', ticket.customer.login )
    assert_equal( 'Znuny GmbH', ticket.organization.name )
    assert_equal( Time.zone.parse('2014-11-20 23:24:20 +0000').gmtime.to_s, ticket.created_at.to_s )
    assert_equal( Time.zone.parse('2014-11-20 23:24:20 +0000').gmtime.to_s, ticket.close_at.to_s )

    # check history
    #  - create entry

    # ticket is created open and now closed
    ticket = Ticket.find(730)
    assert_equal( 'test #3', ticket.title )
    assert_equal( 'closed successful', ticket.state.name )
    assert_equal( 'Postmaster', ticket.group.name )
    assert_equal( '3 normal', ticket.priority.name )
    assert_equal( 'agent-2', ticket.owner.login )
    assert_equal( 'betreuterkunde2', ticket.customer.login )
    assert_equal( 'Noch ein betreuter Kunde', ticket.organization.name )
    assert_equal( Time.zone.parse('2014-11-21 00:17:40 +0000').gmtime.to_s, ticket.created_at.to_s )
    assert_equal( Time.zone.parse('2014-11-21 00:21:08 +0000').gmtime.to_s, ticket.close_at.to_s )

    # ticket dynamic fields
    ticket = Ticket.find(591)
    assert_equal( 'Some other smart subject!', ticket.title )
    assert_equal( '488', ticket.vertriebsweg )
    assert_equal( '["193"]', ticket.te_test ) # TODO: multiselect
    assert_equal( '358', ticket.sugar_crm_remote_no )
    assert_equal( '69', ticket.sugar_crm_company_selected_no )
    assert_equal( '["382"]', ticket.sugar_crm_company_selection ) # TODO: multiselect
    assert_equal( '310', ticket.topic_no )
    assert_equal( '495', ticket.open_exchange_ticket_number )
    assert_equal( '208', ticket.hostname )

    # check history
    #  - create entry
    #  - state change entry
  end

  test 'check article attachments' do

    article = Ticket::Article.find(149)
    assert_equal( 5, article.attachments.count )

    attachment = article.attachments.first
    assert_equal( 'image/jpeg', attachment[:preferences]['Mime-Type'] )
    assert_equal( 'Cursor_und_Banners_and_Alerts_und_Paket-Verwaltung_-_Admin_-_otrs336_und_otrs336.jpg', attachment.filename )

    article = Ticket::Article.find(156)
    assert_equal( 2, article.attachments.count )

    attachment = article.attachments.second
    assert_equal( 'application/pdf; name="=?UTF-8?B?5ZSQ6K+X5LiJ55m+6aaWLnBkZg==?="', attachment[:preferences]['Mime-Type'] )
    assert_equal( '唐诗三百首.pdf', attachment.filename )
  end

end
