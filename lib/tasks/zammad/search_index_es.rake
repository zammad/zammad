# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

namespace :searchindex do
  %i[drop create drop_pipeline create_pipeline reload refresh rebuild].each do |name|
    redirect_name = :"zammad:searchindex:#{name}"
    desc "Forwards to #{redirect_name}"
    task name => redirect_name do
      warning = "The rake task 'searchindex:#{name}' is deprecated. Use '#{redirect_name}' instead."
      warn "DEPRECATION WARNING: #{warning}"
      ActiveSupport::Deprecation.warn(warning)
    end
  end
end

namespace :zammad do
  namespace :searchindex do
    desc 'Drop all search indexes'
    task drop: %i[zammad:searchindex:version_supported] do
      print 'Dropping indexes... '
      SearchIndexBackend.drop_index
      puts 'done.'

      Rake::Task['zammad:searchindex:drop_pipeline'].execute
    end

    desc 'Create all search indexes'
    task create: %i[zammad:searchindex:version_supported] do
      print 'Creating indexes... '
      SearchIndexBackend.create_index
      puts 'done.'
      Rake::Task['zammad:searchindex:create_pipeline'].execute
    end

    desc 'Create search pipeline'
    task create_pipeline: %i[zammad:searchindex:version_supported] do
      print 'Creating pipeline... '
      SearchIndexBackend.create_pipeline
      puts 'done.'
    end

    desc 'Delete search pipeline'
    task drop_pipeline: %i[zammad:searchindex:version_supported] do
      print 'Deleting pipeline... '
      SearchIndexBackend.drop_pipeline
      puts 'done.'
    end

    desc 'Reload all indexable data'
    task reload: %i[zammad:searchindex:version_supported] do
      puts 'Reloading data... '
      Models.indexable.each do |model_class|
        puts "  - #{model_class}... "
        time_spent = Benchmark.realtime do
          model_class.search_index_reload
        end
        # Add whitespace at the end to overwrite text from progress indicator line.
        puts "\r    done in #{time_spent.to_i} seconds.#{' ' * 20}"
      end
    end

    desc 'Refresh all search indexes'
    task refresh: %i[zammad:searchindex:version_supported] do
      print 'Refreshing all indexes... '
      SearchIndexBackend.refresh
      puts 'done.'
    end

    desc 'Full re-creation of all search indexes and re-indexing of all data'
    task rebuild: %i[zammad:searchindex:version_supported] do
      Rake::Task['zammad:searchindex:drop'].execute
      Rake::Task['zammad:searchindex:create'].execute
      Rake::Task['zammad:searchindex:reload'].execute
    end

    task version_supported: %i[zammad:searchindex:configured] do
      SearchIndexBackend.info # Raises for unsupported versions.
    end

    task configured: :environment do
      next if SearchIndexBackend.configured?

      abort 'Elasticsearch is not configured.'
    end
  end
end
