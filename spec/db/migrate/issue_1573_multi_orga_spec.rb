# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue1573MultiOrga, type: :db_migration do
  let(:ticket_organization_attribute) { ObjectManager::Attribute.find_by(name: 'organization_id', object_lookup_id: ObjectLookup.by_name('Ticket')) }

  def organization_field_shown_for_customer(name)
    ObjectManager::Attribute
      .find_by(name: name, object_lookup_id: ObjectLookup.by_name('Organization'))
      .screens[:view][:'ticket.customer'][:shown]
  end

  before do
    ObjectManager::Attribute.find_by(name: 'organization_ids', object_lookup_id: ObjectLookup.by_name('User')).delete

    ticket_organization_attribute.data_type = 'autocompletion_ajax'
    ticket_organization_attribute.save!(validate: false)

    { 'name' => false, 'note' => true }.each do |name, shown|
      attribute = ObjectManager::Attribute.find_by(name: name, object_lookup_id: ObjectLookup.by_name('Organization'))
      attribute.screens[:view] = { 'ticket.customer' => { shown: shown } }
      attribute.save!
    end
  end

  context 'when overview is given' do
    before do
      Overview.find_by(link: 'my_organization_tickets').update(view: {
                                                                 'd'                 => %w[title customer state created_at],
                                                                 's'                 => %w[number title customer state created_at],
                                                                 'm'                 => %w[number title customer state created_at],
                                                                 'view_mode_default' => 's'
                                                               })
    end

    it 'does add new field organization_ids' do
      expect { migrate }.to change { ObjectManager::Attribute.exists?(name: 'organization_ids') }.from(false).to(true)
    end

    it 'does update the ticket organization field' do
      expect { migrate }.to change { ticket_organization_attribute.reload.data_type }.to('autocompletion_ajax_customer_organization')
    end

    it 'does update ticket overview my_organization_tickets view d' do
      expect { migrate }.to change { Overview.find_by(link: 'my_organization_tickets').view[:d] }.to(%w[title customer organization state created_at])
    end

    it 'does update ticket overview my_organization_tickets view s' do
      expect { migrate }.to change { Overview.find_by(link: 'my_organization_tickets').view[:s] }.to(%w[number title customer organization state created_at])
    end

    it 'does update ticket overview my_organization_tickets view m' do
      expect { migrate }.to change { Overview.find_by(link: 'my_organization_tickets').view[:m] }.to(%w[number title customer organization state created_at])
    end

    it 'does update screens for organzation fields (name)' do
      expect { migrate }.to change { organization_field_shown_for_customer('name') }.from(false).to(true)
    end

    it 'does update screens for organzation fields (note)' do
      expect { migrate }.to change { organization_field_shown_for_customer('note') }.from(true).to(false)
    end
  end

  context 'when overview is missing' do
    before do
      Overview.find_by(link: 'my_organization_tickets').destroy
    end

    it 'does not crash if the overview does not exist' do
      expect { migrate }.to change { organization_field_shown_for_customer('name') }.from(false).to(true)
    end
  end
end
