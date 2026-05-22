# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class TagUniqueIndex < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    migrate_duplicate_tag_names
    migrate_duplicate_tags

    add_index :tag_items, 'LOWER(name)', unique: true, name: 'index_tag_items_on_lower_name'
    add_index :tags, %i[tag_item_id tag_object_id o_id], unique: true

    remove_column :tag_items, :name_downcase

    Tag::Item.reset_column_information
  end

  private

  def migrate_duplicate_tag_names
    Tag::Item
      .group('LOWER(name)')
      .having('COUNT(*) > 1')
      .pluck('LOWER(name)').each { migrate_single_duplicate_tag_name(it) }
  end

  def migrate_single_duplicate_tag_name(name)
    ids    = Tag::Item.where('LOWER(NAME) = LOWER(?)', name).pluck(:id)
    keeper = ids.shift

    Tag.where(tag_item_id: ids).each do
      it.tag_item_id = keeper
      it.save!(validate: false)
    end

    Tag::Item.where(id: ids).destroy_all
  end

  def migrate_duplicate_tags
    Tag
      .group(:tag_item_id, :tag_object_id, :o_id)
      .having('COUNT(*) > 1')
      .pluck(:tag_item_id, :tag_object_id, :o_id)
      .each do |tag_item_id, tag_object_id, o_id|
        migrate_single_duplicate_tag(tag_item_id, tag_object_id, o_id)
      end
  end

  def migrate_single_duplicate_tag(tag_item_id, tag_object_id, o_id)
    ids = Tag.where(tag_item_id:, tag_object_id:, o_id:).pluck(:id)
    ids.shift

    Tag.where(id: ids).destroy_all
  end
end
