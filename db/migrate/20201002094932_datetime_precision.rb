# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class DatetimePrecision < ActiveRecord::Migration[5.2]

  # rubocop:disable Metrics/AbcSize
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_column :active_job_locks, :updated_at, :datetime, limit: 3
    change_column :active_job_locks, :created_at, :datetime, limit: 3
    change_column :taskbars, :last_contact, :datetime, limit: 3, null: false
    change_column :delayed_jobs, :run_at, :datetime, limit: 3
    change_column :delayed_jobs, :locked_at, :datetime, limit: 3
    change_column :delayed_jobs, :failed_at, :datetime, limit: 3
    change_column :import_jobs, :started_at, :datetime, limit: 3
    change_column :import_jobs, :finished_at, :datetime, limit: 3
    change_column :sessions, :updated_at, :datetime, limit: 3, null: false
    change_column :sessions, :created_at, :datetime, limit: 3, null: false
    change_column :smime_certificates, :not_before_at, :datetime, limit: 3
    change_column :smime_certificates, :not_after_at, :datetime, limit: 3
    change_column :knowledge_bases, :created_at, :datetime, limit: 3, null: false
    change_column :knowledge_bases, :updated_at, :datetime, limit: 3, null: false
    change_column :knowledge_base_locales, :created_at, :datetime, limit: 3, null: false
    change_column :knowledge_base_locales, :updated_at, :datetime, limit: 3, null: false
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
    change_column :oauth_access_grants, :created_at, :datetime, limit: 3, null: false
    change_column :oauth_access_grants, :revoked_at, :datetime, limit: 3
    change_column :oauth_access_tokens, :created_at, :datetime, limit: 3, null: false
    change_column :oauth_access_tokens, :revoked_at, :datetime, limit: 3
    change_column :oauth_applications, :created_at, :datetime, limit: 3, null: false
    change_column :oauth_applications, :updated_at, :datetime, limit: 3, null: false
  end
  # rubocop:enable Metrics/AbcSize
end
