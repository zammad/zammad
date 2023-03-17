# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class NewCacheClearJob < ActiveRecord::Migration[6.1]
  def change # rubocop:disable Metrics/AbcSize
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Scheduler.create_if_not_exists(
      name:          'Clean up cache.',
      method:        'CacheClearJob.perform_now',
      period:        1.day,
      prio:          2,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
      last_run:      Time.zone.now,
    )

    change_column :knowledge_bases, :created_at, :datetime, limit: 3, null: false
    change_column :knowledge_bases, :updated_at, :datetime, limit: 3, null: false
    change_column :knowledge_base_translations, :created_at, :datetime, limit: 3, null: false
    change_column :knowledge_base_translations, :updated_at, :datetime, limit: 3, null: false
    change_column :knowledge_base_categories, :created_at, :datetime, limit: 3, null: false
    change_column :knowledge_base_categories, :updated_at, :datetime, limit: 3, null: false
    change_column :knowledge_base_category_translations, :created_at, :datetime, limit: 3, null: false
    change_column :knowledge_base_category_translations, :updated_at, :datetime, limit: 3, null: false
    change_column :knowledge_base_answers, :created_at, :datetime, limit: 3, null: false
    change_column :knowledge_base_answers, :updated_at, :datetime, limit: 3, null: false
    change_column :knowledge_base_answer_translations, :created_at, :datetime, limit: 3, null: false
    change_column :knowledge_base_answer_translations, :updated_at, :datetime, limit: 3, null: false
    change_column :knowledge_base_menu_items, :created_at, :datetime, limit: 3, null: false
    change_column :knowledge_base_menu_items, :updated_at, :datetime, limit: 3, null: false

    KnowledgeBase.reset_column_information
    KnowledgeBase::Translation.reset_column_information
    KnowledgeBase::Category.reset_column_information
    KnowledgeBase::Category::Translation.reset_column_information
    KnowledgeBase::Answer.reset_column_information
    KnowledgeBase::Answer::Translation.reset_column_information
    KnowledgeBase::MenuItem.reset_column_information
  end
end
