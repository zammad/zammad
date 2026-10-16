# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CleanUpRevertedTagUniqueIndex, db_strategy: :reset, type: :db_migration do
  let(:schema_migration) { ActiveRecord::Base.connection.pool.schema_migration }

  context 'when the reverted migration ran on the system' do
    let!(:tag_item) { create(:tag_item, name: 'Sample Tag') }

    before do
      remove_index :tag_items, :name_downcase
      remove_column :tag_items, :name_downcase
      add_index :tag_items, 'LOWER(name)', unique: true, name: 'index_tag_items_on_lower_name'
      schema_migration.create_version('20260520124322')
      Tag::Item.reset_column_information
    end

    it 'restores the name_downcase column with its index' do
      expect { migrate }
        .to change { column_exists?(:tag_items, :name_downcase, :string, limit: 250, null: false) }.to(true)
        .and change { index_exists?(:tag_items, :name_downcase) }.to(true)
    end

    it 'fills name_downcase of the existing tag items' do
      migrate

      expect(tag_item.reload.name_downcase).to eq('sample tag')
    end

    it 'drops the case-insensitive unique index' do
      expect { migrate }
        .to change { index_name_exists?(:tag_items, 'index_tag_items_on_lower_name') }.to(false)
    end

    it 'forgets the reverted migration' do
      expect { migrate }
        .to change { schema_migration.versions.include?('20260520124322') }.to(false)
    end

    it 'allows creating tag items again' do
      migrate

      expect { create(:tag_item, name: 'sample tag') }
        .to change(Tag::Item, :count).by(1)
    end
  end

  context 'when the reverted migration never ran on the system' do
    it 'leaves the tag items schema unchanged' do
      expect { migrate }
        .to not_change { ActiveRecord::Base.connection.indexes(:tag_items).map(&:name).sort }
        .and not_change { Tag::Item.column_names }
    end
  end

  context 'when the system was moved from MySQL with pgloader' do
    before do
      remove_index :tag_items, :name_downcase
      add_index :tag_items, :name_downcase, name: 'idx_16840_index_tag_items_on_name_downcase'
    end

    it 'keeps the index taken over from MySQL without adding a second one' do
      expect { migrate }
        .not_to change { ActiveRecord::Base.connection.indexes(:tag_items).map(&:name).sort }
    end
  end
end
