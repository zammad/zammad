$LOAD_PATH << './lib'
require 'rubygems'

namespace :searchindex do
  task :drop, [:opts] => :environment do |_t, _args|

    # drop indexes
    puts 'drop indexes...'
    SearchIndexBackend.index(
      action: 'delete',
    )

  end

  task :create, [:opts] => :environment do |_t, _args|
    puts 'create indexes...'

    # es with mapper-attachments plugin
    number = SearchIndexBackend.info['version']['number'].to_s
    if number =~ /^[2-4]\./ || number =~ /^5\.[0-5]\./

      # create indexes
      SearchIndexBackend.index(
        action: 'create',
        data: {
          mappings: {
            Ticket: {
              _source: { excludes: [ 'article.attachment' ] },
              properties: {
                article: {
                  type: 'nested',
                  include_in_parent: true,
                  properties: {
                    attachment: {
                      type: 'attachment',
                    }
                  }
                }
              }
            }
          }
        }
      )
      Setting.set('es_pipeline', '')

    # es with ingest-attachment plugin
    else

      # create indexes
      SearchIndexBackend.index(
        action: 'create',
        data: {
          mappings: {
            Ticket: {
              _source: { excludes: [ 'article.attachment' ] },
            }
          }
        }
      )

      # update processors
      pipeline = 'zammad-attachment'
      Setting.set('es_pipeline', pipeline)
      SearchIndexBackend.processors(
        "_ingest/pipeline/#{pipeline}": [
          {
            action: 'delete',
          },
          {
            action: 'create',
            description: 'Extract zammad-attachment information from arrays',
            processors: [
              {
                foreach: {
                  field: 'article',
                  ignore_failure: true,
                  processor: {
                    foreach: {
                      field: '_ingest._value.attachment',
                      ignore_failure: true,
                      processor: {
                        attachment: {
                          target_field: '_ingest._value',
                          field: '_ingest._value._content',
                          ignore_failure: true,
                        }
                      }
                    }
                  }
                }
              }
            ]
          }
        ]
      )
    end

  end

  task :reload, [:opts] => :environment do |_t, _args|

    puts 'reload data...'
    Models.searchable.each do |model_class|
      puts " reload #{model_class}"
      started_at = Time.zone.now
      puts "  - started at #{started_at}"
      model_class.search_index_reload
      took = Time.zone.now - started_at
      puts "  - took #{took.to_i} seconds"
    end

  end

  task :rebuild, [:opts] => :environment do |_t, _args|

    Rake::Task['searchindex:drop'].execute
    Rake::Task['searchindex:create'].execute
    Rake::Task['searchindex:reload'].execute

  end
end
