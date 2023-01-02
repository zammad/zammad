# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue1573MultiOrga, type: :db_migration do
  context 'when overview is given' do
    before do
      Overview.find_by(link: 'my_organization_tickets').update(view: {
                                                                 'd'                 => %w[title customer state created_at],
                                                                 's'                 => %w[number title customer state created_at],
                                                                 'm'                 => %w[number title customer state created_at],
                                                                 'view_mode_default' => 's'
                                                               })
      migrate
    end

    it 'does add new field organization_ids' do
      expect(ObjectManager::Attribute.exists?(name: 'organization_ids')).to be true
    end

    it 'does update the ticket organization field' do
      attribute = ObjectManager::Attribute.find_by(name: 'organization_id', object_lookup_id: ObjectLookup.by_name('Ticket'))
      expect(attribute.data_type).to eq('autocompletion_ajax_customer_organization')
    end

    it 'does update ticket overview my_organization_tickets view d' do
      overview = Overview.find_by(link: 'my_organization_tickets')
      expect(overview.view[:d]).to include('organization')
    end

    it 'does update ticket overview my_organization_tickets view s' do
      overview = Overview.find_by(link: 'my_organization_tickets')
      expect(overview.view[:s]).to include('organization')
    end

    it 'does update ticket overview my_organization_tickets view m' do
      overview = Overview.find_by(link: 'my_organization_tickets')
      expect(overview.view[:m]).to include('organization')
    end

    it 'does update screens for organzation fields (name)' do
      field = ObjectManager::Attribute.find_by(name: 'name', object_lookup_id: ObjectLookup.by_name('Organization'))
      expect(field.screens[:view][:'ticket.customer'][:shown]).to be(true)
    end

    it 'does update screens for organzation fields (note)' do
      field = ObjectManager::Attribute.find_by(name: 'note', object_lookup_id: ObjectLookup.by_name('Organization'))
      expect(field.screens[:view][:'ticket.customer'][:shown]).to be(false)
    end
  end

  context 'when overview is missing' do
    before do
      Overview.find_by(link: 'my_organization_tickets').destroy
    end

    it 'does not crash if the overview does not exist' do
      migrate
    end
  end
end
