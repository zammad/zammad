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
