# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4848FixOverviewBulkScreen, type: :db_migration do
  context 'when having pre-tenant setting' do
    before do
      ObjectManager::Attribute.for_object('Ticket').where(name: %w[state_id pending_time group_id owner_id priority_id]).each do |field|
        field.screens.delete(:overview_bulk)
        field.save!
      end
    end

    it 'checks changes for group_id' do
      migrate
      expect(ObjectManager::Attribute.for_object('Ticket').find_by(name: 'group_id').screens[:overview_bulk]['ticket.agent'][:direction]).to eq('up')
    end

    it 'checks changes for pending_time' do
      migrate
      expect(ObjectManager::Attribute.for_object('Ticket').find_by(name: 'pending_time').screens[:overview_bulk]['ticket.agent'][:orientation]).to eq('top')
    end

    it 'checks changes for state_id' do
      migrate
      expect(ObjectManager::Attribute.for_object('Ticket').find_by(name: 'state_id').screens[:overview_bulk]['ticket.agent'][:filter]).to eq(Ticket::State.by_category_ids(:viewable_agent_edit))
    end
  end
end
