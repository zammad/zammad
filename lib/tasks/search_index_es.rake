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

    # create indexes
    puts 'create indexes...'
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

  end

  task :reload, [:opts] => :environment do |_t, _args|

    puts 'reload data...'
    Models.searchable.each { |model_class|
      puts " reload #{model_class}"
      started_at = Time.zone.now
      puts "  - started at #{started_at}"
      model_class.search_index_reload
      took = Time.zone.now - started_at
      puts "  - took #{took.to_i} seconds"
    }

  end

  task :rebuild, [:opts] => :environment do |_t, _args|

    Rake::Task['searchindex:drop'].execute
    Rake::Task['searchindex:create'].execute
    Rake::Task['searchindex:reload'].execute

  end
end
