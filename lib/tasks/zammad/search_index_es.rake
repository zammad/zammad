# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'io/console'

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

      started_at = Time.current
      progress   = {}
      status     = ''
      # A progress line which is wider than the terminal cannot be overwritten.
      width      = $stdout.tty? ? IO.console&.winsize&.last : nil

      # The models are loaded in turns, see SearchIndexBackend::Reload.
      SearchIndexBackend::Reload.new(Models.indexable, worker: args[:worker].to_i).perform do |records|
        if records.finished?
          progress.delete(records.model)
          # Add whitespace at the end to overwrite text from progress indicator line.
          puts "\r#{"  - #{records.model}: #{records.count} done after #{(Time.current - started_at).to_i} seconds.".ljust(status.length)}"
        else
          progress[records.model] = "#{records.model} #{records.count}/#{records.total}"
        end

        previous_length = status.length
        status          = progress.any? ? "    #{progress.values.join(', ')}" : ''
        status          = status.truncate(width - 1, omission: '…') if width
        print "\r#{status.ljust(previous_length)}\r"
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

    desc 'Is the search index backend configured?'
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
