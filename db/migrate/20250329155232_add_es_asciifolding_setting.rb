class AddEsAsciifoldingSetting < ActiveRecord::Migration[7.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       __('Elasticsearch S Configuration'),
      name:        'es_asciifolding',
      area:        'SearchIndex::Elasticsearch',
      description: __('Define if asciifolding analyzer should be used in Elasticsearch.'),
      state:       false,
      preferences: { online_service_disable: true },
      frontend:    false
    )
  end
end
