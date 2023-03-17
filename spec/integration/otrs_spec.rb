# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Test a full OTRS import process against a system with known state and compare some expected results.

RSpec.describe 'OTRS import', integration: true, integration_standalone: true, required_envs: %w[IMPORT_OTRS_ENDPOINT IMPORT_OTRS_ENDPOINT_KEY] do # rubocop:disable RSpec/DescribeClass

  before :all do # rubocop:disable RSpec/BeforeAfterAll
    Setting.set('import_otrs_endpoint', ENV['IMPORT_OTRS_ENDPOINT'])
    Setting.set('import_otrs_endpoint_key', ENV['IMPORT_OTRS_ENDPOINT_KEY'])
    Setting.set('import_mode', true)
    Setting.set('system_init_done', false)

    WebMock.disable!
    Import::OTRS.start
    WebMock.enable!
  end

  context 'when importing setting' do
    let(:protocol) { ENV['IMPORT_OTRS_ENDPOINT'].start_with?('https') ? 'https' : 'http' }

    it 'imports correctly' do
      expect(Setting.get('system_id')).to be_truthy
      expect(Setting.get('http_type')).to eq(protocol)
      expect(Setting.get('organization')).to eq('Example Company')
    end
  end

  context 'when importing dynamic fields' do
    let(:local_objects) { ObjectManager::Attribute.list_full }
    let(:object_attribute_names) do
      local_objects.select do |local_object|
        local_object[:object] == 'Ticket'
      end.pluck('name')
    end
    let(:expected_object_attribute_names) { %w[vertriebsweg te_test number sugar_crm_remote_no sugar_crm_company_selected_no sugar_crm_company_selection combine title itsm_criticality customer_id itsm_impact itsm_review_required itsm_decision_result organization_id itsm_repair_start_time itsm_recovery_start_time itsm_decision_date itsm_due_date topic_no open_exchange_ticket_number hostname ticket_free_key11 type ticket_free_text11 open_exchange_tn topic zarafa_tn group_id scom_hostname checkbox_example scom_uuid scom_state scom_service location owner_id department customer_location textfeld state_id pending_time priority_id tags] }

    it 'imports correctly' do
      expect(object_attribute_names).to eq(expected_object_attribute_names)
    end
  end

  context 'when importing in general' do
    it 'imports the right number of objects' do
      expect(Ticket.count).to eq(603)
      expect(Ticket::Article.count).to eq(3182)
      expect(Store.count).to eq(274)
      expect(Ticket::State.count).to eq(10)
      expect(Group.count).to eq(24)
    end
  end

  context 'when importing users' do
    let(:role_admin)     { Role.where(name: 'Admin').first }
    let(:role_agent)     { Role.where(name: 'Agent').first }
    let(:role_customer)  { Role.where(name: 'Customer').first }
    let(:user1)          { User.find(2) }
    let(:user2)          { User.find(3) }
    let(:user3)          { User.find(7) }
    let(:user4)          { User.find(8) }
    let(:group_dasa)     { Group.where(name: 'dasa').first }
    let(:group_raw)      { Group.where(name: 'Raw').first }

    it 'imports correctly' do

      expect(user1).to have_attributes(
        {
          firstname: 'agent-1 firstname',
          lastname:  'agent-1 lastname',
          login:     'agent-1',
          email:     'agent-1@example.com',
          active:    true,
        }
      )

      expect(user1.roles).to include(role_agent).and(not_include(role_admin, role_customer))
      expect(user1.groups_access('full')).to include(group_raw).and(not_include(group_dasa))

      expect(user2).to have_attributes(
        {
          firstname: 'agent-2 firstname äöüß',
          lastname:  'agent-2 lastname äöüß',
          login:     'agent-2',
          email:     'agent-2@example.com',
          active:    true,
        }
      )

      expect(user2.roles).to include(role_agent, role_admin).and(not_include(role_customer))
      expect(user2.groups_access('full')).to include(group_raw, group_dasa)

      expect(user3).to have_attributes(
        {
          firstname: 'invalid',
          lastname:  'invalid',
          login:     'invalid',
          email:     'invalid@example.com',
          active:    false,
        }
      )

      expect(user3.roles).to include(role_agent).and(not_include(role_admin, role_customer))
      expect(user3.groups_access('full')).to not_include(group_raw, group_dasa)

      expect(user4).to have_attributes(
        {
          firstname: 'invalid-temp',
          lastname:  'invalid-temp',
          login:     'invalid-temp',
          active:    false,
        }
      )

      expect(user4.roles).to include(role_agent).and(not_include(role_admin, role_customer))
      expect(user4.groups_access('full')).to not_include(group_raw, group_dasa)
    end
  end

  context 'when importing groups' do
    let(:group1) { Group.find(1) }
    let(:group2) { Group.find(19) }

    it 'imports correctly' do
      expect(group1).to have_attributes(
        {
          name:   'Postmaster',
          active: true,
        }
      )
      expect(group2).to have_attributes(
        {
          name:   'UnitTestQueue20668',
          active: false,
        }
      )
    end
  end

  context 'when importing customers / organizations' do
    let(:user1) { User.where(login: 'jn').first }
    let(:user2) { User.where(login: 'test90133').first }

    it 'imports correctly' do
      expect(user1).to have_attributes(
        {
          firstname: 'Johannes',
          lastname:  'Nickel',
          login:     'jn',
          email:     'jn@example.com',
        }
      )
      expect(user1.organization).to have_attributes(
        {
          name: 'Znuny GmbH Berlin',
          note: 'äöüß',
        }
      )

      expect(user2).to have_attributes(
        {
          firstname: 'test90133',
          lastname:  'test90133',
          login:     'test90133',
          email:     'qa4711@t-online.de',
        }
      )
      expect(user2.organization).to have_attributes(
        {
          name: 'test554449',
          note: 'test554449',
        }
      )
    end
  end

  context 'when importing ticket states' do
    let(:new_state) { Ticket::State.find(1) }
    let(:closed_state)  { Ticket::State.find(2) }
    let(:pending_state) { Ticket::State.find(6) }

    it 'imports correctly' do
      expect(new_state.name).to eq('new')
      expect(new_state.state_type.name).to eq('new')
      expect(closed_state.name).to eq('closed successful')
      expect(closed_state.state_type.name).to eq('closed')
      expect(pending_state.name).to eq('pending reminder')
      expect(pending_state.state_type.name).to eq('pending reminder')
    end
  end

  context 'when importing tickets' do
    let(:ticket1) { Ticket.find(728) }
    let(:ticket2) { Ticket.find(729) }
    let(:ticket3) { Ticket.find(730) }
    let(:ticket4) { Ticket.find(591) }

    it 'imports correctly' do
      # ticket1 is open
      expect(ticket1.title).to eq('test #1')
      expect(ticket1.state.name).to eq('open')
      expect(ticket1.group.name).to eq('Misc')
      expect(ticket1.priority.name).to eq('4 high')
      expect(ticket1.owner.login).to eq('agent-2')
      expect(ticket1.customer.login).to eq('partner')
      expect(ticket1.organization.name).to eq('Partner der betreut')
      expect(ticket1.created_at.to_s).to eq(Time.zone.parse('2014-11-20 22:33:41 +0000').gmtime.to_s)
      expect(ticket1.close_at).to be_nil

      # ticket2 is created with state closed
      expect(ticket2.title).to eq('test #2')
      expect(ticket2.state.name).to eq('closed successful')
      expect(ticket2.group.name).to eq('Raw')
      expect(ticket2.priority.name).to eq('3 normal')
      expect(ticket2.owner.login).to eq('agent-2')
      expect(ticket2.customer.login).to eq('jn2')
      expect(ticket2.organization.name).to eq('Znuny GmbH')
      expect(ticket2.created_at.to_s).to eq(Time.zone.parse('2014-11-20 23:24:20 +0000').gmtime.to_s)
      expect(ticket2.close_at.to_s).to eq(Time.zone.parse('2014-11-20 23:24:20 +0000').gmtime.to_s)

      # ticket3 is created open and now closed
      expect(ticket3.title).to eq('test #3')
      expect(ticket3.state.name).to eq('closed successful')
      expect(ticket3.group.name).to eq('Postmaster')
      expect(ticket3.priority.name).to eq('3 normal')
      expect(ticket3.owner.login).to eq('agent-2')
      expect(ticket3.customer.login).to eq('betreuterkunde2')
      expect(ticket3.organization.name).to eq('Noch ein betreuter Kunde')
      expect(ticket3.created_at.to_s).to eq(Time.zone.parse('2014-11-21 00:17:40 +0000').gmtime.to_s)
      expect(ticket3.close_at.to_s).to eq(Time.zone.parse('2014-11-21 00:21:08 +0000').gmtime.to_s)

      # ticket dynamic fields
      expect(ticket4.title).to eq('Some other smart subject!')
      expect(ticket4.vertriebsweg).to eq('488')
      expect(ticket4.te_test).to eq(%w[193 194])
      expect(ticket4.sugar_crm_remote_no).to eq('358')
      expect(ticket4.sugar_crm_company_selected_no).to eq('69')
      expect(ticket4.sugar_crm_company_selection).to eq(['382'])
      expect(ticket4.topic_no).to eq('310')
      expect(ticket4.open_exchange_ticket_number).to eq('495')
      expect(ticket4.hostname).to eq('208')
    end
  end

  context 'when importing attachments' do
    let(:article1) { Ticket::Article.find(149) }
    let(:attachment1) { article1.attachments.first }
    let(:article2)    { Ticket::Article.find(156) }
    let(:attachment2) { article2.attachments.second }

    it 'imports correctly' do
      expect(article1.attachments.count).to eq(5)
      expect(attachment1.preferences['Mime-Type']).to eq('image/jpeg')
      expect(attachment1.filename).to eq('Cursor_und_Banners_and_Alerts_und_Paket-Verwaltung_-_Admin_-_otrs336_und_otrs336.jpg')

      expect(article2.attachments.count).to eq(2)
      expect(attachment2.preferences['Mime-Type']).to eq('application/pdf; name="=?UTF-8?B?5ZSQ6K+X5LiJ55m+6aaWLnBkZg==?="')
      expect(attachment2.filename).to eq('唐诗三百首.pdf')
    end
  end
end
