# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SetElasticSearchSSL < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Elasticsearch SSL verification',
      name:        'es_ssl_verify',
      area:        'SearchIndex::Elasticsearch',
      description: 'Defines Elasticsearch SSL verification.',
      state:       false,
      preferences: { online_service_disable: true },
      frontend:    false
    )
  end
end
