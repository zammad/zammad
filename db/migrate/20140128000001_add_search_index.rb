class AddSearchIndex < ActiveRecord::Migration
  def up
    Setting.create_or_update(
      title: 'Elasticsearch Endpoint URL',
      name: 'es_url',
      area: 'SearchIndex::Elasticsearch',
      description: 'Define endpoint of Elastic Search.',
      state: '',
      frontend: false
    )
    Setting.create_or_update(
      title: 'Elasticsearch Endpoint User',
      name: 'es_user',
      area: 'SearchIndex::Elasticsearch',
      description: 'Define http basic auth user of Elasticsearch.',
      state: '',
      frontend: false
    )
    Setting.create_or_update(
      title: 'Elastic Search Endpoint Password',
      name: 'es_password',
      area: 'SearchIndex::Elasticsearch',
      description: 'Define http basic auth password of Elasticsearch.',
      state: '',
      frontend: false
    )
    Setting.create_or_update(
      title: 'Elastic Search Endpoint Index',
      name: 'es_index',
      area: 'SearchIndex::Elasticsearch',
      description: 'Define Elasticsearch index name.',
      state: 'zammad',
      frontend: false
    )
    Setting.create_or_update(
      title: 'Elastic Search Attachment Extentions',
      name: 'es_attachment_ignore',
      area: 'SearchIndex::Elasticsearch',
      description: 'Define attachment extentions which are ignored for Elasticsearch.',
      state: [ '.png', '.jpg', '.jpeg', '.mpeg', '.mpg', '.mov', '.bin', '.exe', '.box', '.mbox' ],
      frontend: false
    )
    Setting.create_or_update(
      title: 'Elastic Search Attachment Size',
      name: 'es_attachment_max_size_in_mb',
      area: 'SearchIndex::Elasticsearch',
      description: 'Define max. attachment size for Elasticsearch.',
      state: 50,
      frontend: false
    )

    Ticket.search_index_reload
    User.search_index_reload
    Organization.search_index_reload
  end

  def down
  end
end
