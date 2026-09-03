# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddEditedAtToKnowledgeBaseCategoryTranslations < ActiveRecord::Migration[8.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    add_edited_at
    migrate_existing_translations
    require_edited_at
    invalidate_asset_caches
  end

  private

  def add_edited_at
    add_column :knowledge_base_category_translations, :edited_at, :timestamp, limit: 3, null: true

    KnowledgeBase::Category::Translation.reset_column_information
  end

  # Nothing better to seed from: an existing installation has no record of when a category was last
  #   edited, and `updated_at` is exactly the approximation the sort used until now.
  def migrate_existing_translations
    KnowledgeBase::Category::Translation.update_all('edited_at = updated_at') # rubocop:disable Rails/SkipsModelValidations
  end

  def require_edited_at
    change_column_null :knowledge_base_category_translations, :edited_at, false
  end

  # The asset a client is served is cached until the record's `updated_at` moves
  #   (ApplicationModel::CanAssociations#attributes_with_association_ids), and the backfill above
  #   deliberately leaves that alone — so without dropping the entries here, the legacy interface
  #   keeps ordering its `last_update` category listings from assets that have no `edited_at` in
  #   them at all, until each translation happens to be saved again. There are as many rows as there
  #   are categories and locales, so this is a small loop, not a fan-out.
  def invalidate_asset_caches
    KnowledgeBase::Category::Translation.find_each(&:cache_delete)
  end
end
