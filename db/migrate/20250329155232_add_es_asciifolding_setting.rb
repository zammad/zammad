# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddEsAsciifoldingSetting < ActiveRecord::Migration[7.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Elasticsearch Asciifolding Configuration',
      name:        'es_asciifolding',
      area:        'SearchIndex::Elasticsearch',
      description: 'Define if asciifolding analyzer should be used in Elasticsearch.',
      state:       true,
      preferences: { online_service_disable: true },
      frontend:    false
    )
  end
end
