# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SettingAddInternalArticleCheck < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # this migration used to have a wrong timestmap
    # remove old timestmap from schema_migrations table
    # when re-running with the fixed timestamp
    # https://github.com/zammad/zammad/issues/3702
    return if ActiveRecord::SchemaMigration.where(version: '202104070000001').destroy_all.present?

    Setting.create_if_not_exists(
      title:       'Define postmaster filter.',
      name:        '5500_postmaster_internal_article_check',
      area:        'Postmaster::PreFilter',
      description: 'Defines the postmaster filter which set the article internal if a forwarded, replied or sent email also exists with the article internal received.',
      options:     {},
      state:       'Channel::Filter::InternalArticleCheck',
      frontend:    false
    )
  end
end
