$LOAD_PATH << './lib'
require 'rubygems'

namespace :searchindex do
  task :drop, [:opts] => :environment do |t, args|

    # drop indexes
    puts "drop indexes..."
    SearchIndexBackend.index(
      :action => 'delete',
    )

  end

  task :create, [:opts] => :environment do |t, args|

    # create indexes
    puts "create indexes..."
    SearchIndexBackend.index(
      :action => 'create',
      :data   => {
        :mappings => {
          :Ticket => {
            :_source => { :excludes => [ 'articles_all.attachments', 'articles_external.attachments' ] },
            :properties => {
              :articles_all => {
                :type       => 'nested',
                :properties => {
                  :attachments => {
                    :type   => 'attachment',
                  }
                } 
              }
            } 
          }  
        }
      }
    )

  end

  task :reload, [:opts] => :environment do |t, args|

    puts "reload data..."
    User.search_index_reload
    Organization.search_index_reload
    Ticket.search_index_reload

  end

  task :rebuild, [:opts] => :environment do |t, args|

    Rake::Task["searchindex:drop"].execute
    Rake::Task["searchindex:create"].execute
    Rake::Task["searchindex:reload"].execute

  end
end
