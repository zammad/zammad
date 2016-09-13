# Setup a Elasticsearch

* Install Elasticsearch
  https://www.elastic.co/downloads/elasticsearch (2.4.x)

* Install attachment plugin
  cd /usr/share/elasticsearch
  bin/plugin install mapper-attachments

* Configure elasticsearch
  /etc/sysconfig/elasticsearch
  ES_HEAP_SIZE=2g

  /etc/elasticsearch/elasticsearch.yml
  http.max_content_length: 500mb

* Configure Zammad

  * rails r "Setting.set('es_url', 'http://127.0.0.1:9200')"

  # optional - es with http basic auth
  * rails r "Setting.set('es_user', 'elasticsearch')"
  * rails r "Setting.set('es_password', 'zammad')"

  # optional - extra es index name space
  * rails r "Setting.set('es_index', Socket.gethostname + '_zammad')"

  # optional - ignore certain file extentions
  * rails r "Setting.set('es_attachment_ignore', [ '.png', '.jpg', '.jpeg', '.mpeg', '.mpg', '.mov', '.bin', '.exe', '.box', '.mbox' ] )"

  # optional - max attachment size which is used by es, default is 50 mb
  * rails r "Setting.set('es_attachment_max_size_in_mb', 50)"

* Create elastic search indexes
  * rake searchindex:rebuild # drop/create/reload
