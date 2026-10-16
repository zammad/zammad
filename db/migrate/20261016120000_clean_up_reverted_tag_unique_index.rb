# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CleanUpRevertedTagUniqueIndex < ActiveRecord::Migration[8.1]
  # A reverted earlier version of TagUniqueIndex ran on the nightly systems of
  # May 2026 (#6451). It replaced name_downcase by a case-insensitive unique
  # index, which has left those systems unable to create tag items since.
  REVERTED_VERSION = '20260520124322'.freeze

  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    remove_index :tag_items, name: 'index_tag_items_on_lower_name', if_exists: true
    restore_name_downcase

    # Systems moved from MySQL carry the index under a pgloader name.
    add_index :tag_items, :name_downcase if !index_exists?(:tag_items, :name_downcase)

    connection.pool.schema_migration.delete_version(REVERTED_VERSION)
  end

  private

  def restore_name_downcase
    return if column_exists?(:tag_items, :name_downcase)

    add_column :tag_items, :name_downcase, :string, limit: 250
    Tag::Item.reset_column_information

    # Downcased in Ruby like Tag::Item#fill_namedowncase does it, as LOWER() in
    # PostgreSQL lowercases some non-ASCII letters differently.
    Tag::Item.find_each { it.update_column(:name_downcase, it.name.downcase) } # rubocop:disable Rails/SkipsModelValidations

    change_column_null :tag_items, :name_downcase, false
  end
end
