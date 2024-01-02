# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
    task :reload, [:worker] => %i[zammad:searchindex:version_supported] do |_task, args|
      puts 'Reloading data... '
      Models.indexable.each do |model_class|
        puts "  - #{model_class}... "
        time_spent = Benchmark.realtime do
          model_class.search_index_reload(worker: args[:worker].to_i)
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
    task :rebuild, [:worker] => %i[zammad:searchindex:version_supported] do |_task, args|
      Rake::Task['zammad:searchindex:drop'].execute
      Rake::Task['zammad:searchindex:create'].execute
      Rake::Task['zammad:searchindex:reload'].execute(args)
    end

    task version_supported: %i[zammad:searchindex:configured] do
      SearchIndexBackend.info # Raises for unsupported versions.
    end

    task configured: :environment do
      next if SearchIndexBackend.configured?

      abort 'Elasticsearch is not configured.'
    end

    namespace :settings do
      desc 'Show model configuration'
      task show: %i[zammad:searchindex:version_supported] do
        SearchIndexBackend.all_settings.each do |model, settings|
          puts "#{model} => #{settings.inspect}"
        end
      end

      desc 'Set model configuration'
      task :set, %i[model key value] => %i[zammad:searchindex:version_supported] do |_task, args|
        SearchIndexBackend.set_setting(args[:model], args[:key], args[:value])
        puts "#{args[:model]} model settings for key '#{args[:key]}' updated to '#{args[:value]}'."
      end

      desc 'Unset model configuration'
      task :unset, %i[model key] => %i[zammad:searchindex:version_supported] do |_task, args|
        SearchIndexBackend.unset_setting(args[:model], args[:key])
        puts "#{args[:model]} model settings for key '#{args[:key]}' unset."
      end
    end
  end
end
