# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ChecklistTablesWrongColumnType, current_user_id: 1, type: :db_migration do
  describe 'with PostgreSQL backend', db_strategy: :reset do
    before do
      checklist && initial_sorted_items

      remove_column :checklists, :sorted_item_ids
      remove_column :checklist_templates, :sorted_item_ids

      add_column :checklists, :sorted_item_ids, :text, null: true, array: false
      add_column :checklist_templates, :sorted_item_ids, :text, null: true, array: false

      Checklist.reset_column_information
      ChecklistTemplate.reset_column_information
      checklist.reload

      checklist.sorted_item_ids = initial_sorted_items.to_json
      checklist.save!
    end

    let(:checklist)            { create(:checklist) }
    let(:initial_sorted_items) { checklist.sorted_item_ids }

    it 'migrates column array type' do
      expect { migrate }
        .to change { Checklist.columns.find { |c| c.name == 'sorted_item_ids' }.type }.from(:text).to(:string)
        .and change { ChecklistTemplate.columns.find { |c| c.name == 'sorted_item_ids' }.type }.from(:text).to(:string)
    end

    it 'keeps existing data' do
      checklist

      migrate

      expect(checklist.reload.sorted_item_ids).to eq(initial_sorted_items)
    end
  end
end
