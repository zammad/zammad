class AddSearchIndex < ActiveRecord::Migration
  def up
    Setting.create_or_update(
      :title       => 'Elastic Search Endpoint URL',
      :name        => 'es_url',
      :area        => 'SearchIndex::ElasticSearch',
      :description => 'Define endpoint of Elastic Search.',
      :state       => '',
      :frontend => false
    )
    Setting.create_or_update(
      :title       => 'Elastic Search Endpoint User',
      :name        => 'es_user',
      :area        => 'SearchIndex::ElasticSearch',
      :description => 'Define http basic auth user of Elastic Search.',
      :state       => '',
      :frontend => false
    )
    Setting.create_or_update(
      :title       => 'Elastic Search Endpoint Password',
      :name        => 'es_password',
      :area        => 'SearchIndex::ElasticSearch',
      :description => 'Define http basic auth password of Elastic Search.',
      :state       => '',
      :frontend => false
    )
    Setting.create_or_update(
      :title       => 'Elastic Search Endpoint Index',
      :name        => 'es_index',
      :area        => 'SearchIndex::ElasticSearch',
      :description => 'Define Elastic Search index name.',
      :state       => 'zammad',
      :frontend => false
    )

    Setting.set('es_url', 'http://217.111.80.181')
    Setting.set('es_user', 'elasticsearch')
    Setting.set('es_password', 'zammad')
    Setting.set('es_index', Socket.gethostname + '_zammad')

    Ticket.search_index_reload
    User.search_index_reload
    Organization.search_index_reload
  end
  def down
  end
end
