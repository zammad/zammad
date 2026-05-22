# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TagUniqueIndex, type: :db_migration do
  before do
    remove_index :tags, %i[tag_item_id tag_object_id o_id], if_exists: true
    remove_index :tag_items, name: 'index_tag_items_on_lower_name', if_exists: true
    add_column :tag_items, :name_downcase, :string if !column_exists?(:tag_items, :name_downcase)
  end

  context 'when multiple identical tag names exist' do
    let(:object)             { create(:ticket) }
    let(:other_object)       { create(:ticket) }
    let(:tag_name)           { 'sample' }
    let(:tag_item)           { create(:tag_item, name: tag_name) }
    let(:other_tag_item)     { build(:tag_item, name: other_tag_name).tap { it.save(validate: false) } }
    let(:unrelated_tag_item) { create(:tag_item) }

    before do
      create(:tag, tag_item_id: tag_item.id, o: object)
      create(:tag, tag_item_id: other_tag_item.id, o: other_object)
      create(:tag, tag: unrelated_tag_item.name, o: object)
    end

    shared_examples 'removing duplicate tag names' do
      it 'removes duplicate tag names' do
        expect { migrate }
          .to change(Tag::Item, :count).by(-1)
      end

      it 'keeps the link between both tags and their objects' do
        expect { migrate }
          .not_to change { [normalized_tag_names(object.tag_list), normalized_tag_names(other_object.tag_list)] }
      end

      it 'keeps single link for objects linking to all identical tag names' do
        build(:tag, tag_item_id: other_tag_item.id, o: object).save(validate: false)

        expect { migrate }
          .not_to change { normalized_tag_names(object.tag_list) }
      end
    end

    context 'when the tag names are identical' do
      let(:other_tag_name) { tag_name }

      it_behaves_like 'removing duplicate tag names'
    end

    context 'when the tag names are identical except for capitalization' do
      let(:other_tag_name) { tag_name.upcase }

      it_behaves_like 'removing duplicate tag names'
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
        .not_to change { normalized_tag_names(object.tag_list) }
    end
  end

  def normalized_tag_names(input)
    input.map(&:downcase).uniq
  end
end
