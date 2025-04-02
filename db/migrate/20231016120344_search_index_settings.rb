# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SearchIndexSettings < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Elasticsearch Model Configuration',
      name:        'es_model_settings',
      area:        'SearchIndex::Elasticsearch',
      description: 'Define model configuration for Elasticsearch.',
      state:       {},
      preferences: { online_service_disable: true },
      frontend:    false
    )
  end
end
