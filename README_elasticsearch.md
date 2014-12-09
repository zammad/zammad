# Setup a elastic search

* Install elastic search

* Install attachment plugin
  cd /usr/share/elasticsearch
  bin/plugin -install elasticsearch/elasticsearch-mapper-attachments/2.0.0

* Configure elasticsearch
  /etc/sysconfig/elasticsearch
  ES_HEAP_SIZE=2g

  /etc/elasticsearch/elasticsearch.yml
  http.max_content_length: 500mb

* Configure Zammad

  * rails r "Setting.set('es_url', 'http://172.0.0.1:9200')"
  * rails r "Setting.set('es_user', 'elasticsearch')" # optional
  * rails r "Setting.set('es_password', 'zammad')" # optional
  * rails r "Setting.set('es_index', Socket.gethostname + '_zammad')" # optional

* Create elastic search indexes
  * rake searchindex:rebuild # drop/create/reload

