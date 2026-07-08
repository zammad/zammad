# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddEditedAtToKnowledgeBaseAnswerTranslations < ActiveRecord::Migration[8.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    add_edited_at
    migrate_existing_translations
    require_edited_at
  end

  private

  def add_edited_at
    add_column :knowledge_base_answer_translations, :edited_at, :timestamp, limit: 3, null: true

    KnowledgeBase::Answer::Translation.reset_column_information
  end

  def migrate_existing_translations
    KnowledgeBase::Answer::Translation.update_all('edited_at = updated_at') # rubocop:disable Rails/SkipsModelValidations
  end

  def require_edited_at
    change_column_null :knowledge_base_answer_translations, :edited_at, false
  end
end
