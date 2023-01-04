# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4306ExcludesSetting < ActiveRecord::Migration[6.1]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Elasticsearch Excludes',
      name:        'es_excludes',
      area:        'SearchIndex::Elasticsearch',
      description: 'Defines if the search index is using excluded attributes.',
      state:       true,
      preferences: { online_service_disable: true },
      frontend:    false
    )
  end
end
