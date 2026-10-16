# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class TagUniqueIndex < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    migrate_duplicate_tag_names
    migrate_duplicate_tags

    # A reverted earlier version of this migration left the index on tags
    # behind on the nightly systems of May 2026 (#6451).
    ensure_unique_index :tag_items, %w[name]
    ensure_unique_index :tags, %w[tag_item_id tag_object_id o_id]

    # Covered by the leading column of the unique index above. Systems moved
    # from MySQL also carry its implicit foreign key index under a pgloader name.
    connection.indexes(:tags)
      .select { it.columns == %w[tag_item_id] }
      .each { remove_index :tags, name: it.name }
  end

  private

  # Matched by columns and uniqueness, as an index of the expected name may
  # still be a non-unique one.
  def ensure_unique_index(table, columns)
    return if index_exists?(table, columns, unique: true)

    connection.indexes(table)
      .select { it.columns == columns }
      .each { remove_index table, name: it.name }

    add_index table, columns, unique: true
  end

  def migrate_duplicate_tag_names
    Tag::Item
      .group(:name)
      .having('COUNT(*) > 1')
      .pluck(:name).each { migrate_single_duplicate_tag_name(it) }
  end

  def migrate_single_duplicate_tag_name(name)
    ids    = Tag::Item.where(name:).pluck(:id)
    keeper = ids.shift

    Tag.where(tag_item_id: ids).update_all(tag_item_id: keeper) # rubocop:disable Rails/SkipsModelValidations

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
    _keeper = ids.shift

    Tag.where(id: ids).delete_all
  end
end
