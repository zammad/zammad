# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingEsPipeline < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Elasticsearch Pipeline Name',
      name:        'es_pipeline',
      area:        'SearchIndex::Elasticsearch',
      description: 'Define pipeline name for Elasticsearch.',
      state:       '',
      preferences: { online_service_disable: true },
      frontend:    false
    )
  end
end
