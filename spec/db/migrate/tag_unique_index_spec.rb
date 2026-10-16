# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TagUniqueIndex, db_strategy: :reset, type: :db_migration do
  before do
    remove_index :tags, name: 'index_tags_on_tag_item_id_and_tag_object_id_and_o_id', if_exists: true
    remove_index :tag_items, name: 'index_tag_items_on_name', if_exists: true
    add_index :tags, [:tag_item_id], if_not_exists: true
  end

  it 'adds the unique indexes and drops the redundant single-column index' do
    expect { migrate }
      .to change { index_exists?(:tags, [:tag_item_id], name: 'index_tags_on_tag_item_id') }.to(false)
      .and change { index_exists?(:tags, %i[tag_item_id tag_object_id o_id], unique: true) }.to(true)
      .and change { index_exists?(:tag_items, :name, unique: true, name: 'index_tag_items_on_name') }.to(true)
  end

  context 'when the system was moved from MySQL with pgloader' do
    before do
      add_index :tags, [:tag_item_id], name: 'idx_16842_fk_rails_ee3ce5d7d4'
    end

    it 'drops the implicit foreign key index taken over from MySQL as well' do
      expect { migrate }
        .to change { index_exists?(:tags, [:tag_item_id]) }.to(false)
    end
  end

  context 'when a reverted earlier version of the migration ran on the system' do
    before do
      add_index :tags, %i[tag_item_id tag_object_id o_id], unique: true
      add_index :tag_items, 'LOWER(name)', unique: true, name: 'index_tag_items_on_lower_name'
      without_column(:tag_items, column: :name_downcase)
      Tag::Item.reset_column_information
    end

    it 'adds the missing index and drops the redundant single-column index' do
      expect { migrate }
        .to change { index_exists?(:tags, [:tag_item_id], name: 'index_tags_on_tag_item_id') }.to(false)
        .and change { index_exists?(:tag_items, :name, unique: true, name: 'index_tag_items_on_name') }.to(true)
    end

    def tag_schema
      {
        tag_items_indexes: ActiveRecord::Base.connection.indexes(:tag_items).map { [it.name, it.columns, it.unique] }.sort,
        name_downcase:     column_exists?(:tag_items, :name_downcase, :string, limit: 250, null: false),
        tags_unique_index: index_exists?(:tags, %i[tag_item_id tag_object_id o_id], unique: true),
      }
    end

    it 'ends in the base schema together with the clean-up migration' do
      migrate
      clean_up = CleanUpRevertedTagUniqueIndex.new
      clean_up.suppress_messages { clean_up.migrate(:up) }

      expect(tag_schema).to eq(
        tag_items_indexes: [['index_tag_items_on_name', %w[name], true], ['index_tag_items_on_name_downcase', %w[name_downcase], false]],
        name_downcase:     true,
        tags_unique_index: true,
      )
    end
  end

  context 'when both unique indexes already exist' do
    before do
      add_index :tags, %i[tag_item_id tag_object_id o_id], unique: true
      add_index :tag_items, :name, unique: true, name: 'index_tag_items_on_name'
    end

    it 'drops the redundant single-column index' do
      expect { migrate }
        .to change { index_exists?(:tags, [:tag_item_id], name: 'index_tags_on_tag_item_id') }.to(false)
    end
  end

  context 'when non-unique indexes of the same names exist' do
    before do
      add_index :tags, %i[tag_item_id tag_object_id o_id]
      add_index :tag_items, :name, name: 'index_tag_items_on_name'
    end

    it 'replaces them by the unique indexes' do
      expect { migrate }
        .to change { index_exists?(:tags, %i[tag_item_id tag_object_id o_id], unique: true) }.to(true)
        .and change { index_exists?(:tag_items, :name, unique: true, name: 'index_tag_items_on_name') }.to(true)
    end
  end

  context 'when multiple identical tag names exist' do
    let(:object)             { create(:ticket) }
    let(:other_object)       { create(:ticket) }
    let(:tag_name)           { 'sample' }
    let(:tag_item)           { create(:tag_item, name: tag_name) }
    let(:other_tag_item)     { build(:tag_item, name: tag_name).tap { it.save(validate: false) } }
    let(:unrelated_tag_item) { create(:tag_item) }

    before do
      create(:tag, tag_item_id: tag_item.id, o: object)
      create(:tag, tag_item_id: other_tag_item.id, o: other_object)
      create(:tag, tag: unrelated_tag_item.name, o: object)
    end

    it 'removes duplicate tag names' do
      expect { migrate }
        .to change(Tag::Item, :count).by(-1)
    end

    it 'keeps the link between both tags and their objects' do
      expect { migrate }
        .not_to change { [object.tag_list.uniq, other_object.tag_list.uniq] }
    end

    it 'keeps single link for objects linking to all identical tag names' do
      build(:tag, tag_item_id: other_tag_item.id, o: object).save(validate: false)

      expect { migrate }
        .not_to change { object.tag_list.uniq }
    end

    it 'does not queue transaction events for the moved links' do
      expect { migrate }
        .not_to change { EventBuffer.list('transaction').size }
    end
  end

  context 'when an object has multiple identical tags' do
    let(:object)         { create(:ticket) }
    let(:tag_item)       { create(:tag_item) }
    let(:other_tag_item) { create(:tag_item) }

    before do
      create(:tag, tag: tag_item.name, o: object)
      build(:tag, tag: tag_item.name, o: object).save(validate: false)
      create(:tag, tag: other_tag_item.name, o: object)
    end

    it 'removes duplicate tag names' do
      expect { migrate }
        .to change(Tag, :count).by(-1)
    end

    it 'keeps the link between both tags and their objects' do
      expect { migrate }
        .not_to change { object.tag_list.uniq }
    end

    it 'does not record the removed duplicate in the ticket history' do
      expect { migrate }
        .not_to change(History, :count)
    end
  end
end
