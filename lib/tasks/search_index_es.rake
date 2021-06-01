# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

$LOAD_PATH << './lib'
require 'rubygems'

namespace :searchindex do
  task :drop, [:opts] => %i[environment searchindex:configured searchindex:version_supported] do |_t, _args|
    print 'drop indexes...'

    # drop indexes
    SearchIndexBackend.drop_index

    puts 'done'

    Rake::Task['searchindex:drop_pipeline'].execute
  end

  task :create, [:opts] => %i[environment searchindex:configured searchindex:version_supported] do |_t, _args|
    print 'create indexes...'

    SearchIndexBackend.create_index

    puts 'done'

    Rake::Task['searchindex:create_pipeline'].execute
  end

  task :create_pipeline, [:opts] => %i[environment searchindex:configured searchindex:version_supported] do |_t, _args|
    print 'create pipeline (pipeline)... '

    SearchIndexBackend.create_pipeline

    puts 'done'
  end

  task :drop_pipeline, [:opts] => %i[environment searchindex:configured searchindex:version_supported] do |_t, _args|
    print 'delete pipeline (pipeline)... '

    SearchIndexBackend.drop_pipeline

    puts 'done'
  end

  task :reload, [:opts] => %i[environment searchindex:configured searchindex:version_supported] do |_t, _args|
    puts 'reload data...'
    Models.indexable.each do |model_class|
      puts " reload #{model_class}"
      started_at = Time.zone.now
      puts "  - started at #{started_at}"
      model_class.search_index_reload
      took = Time.zone.now - started_at
      puts "  - took #{took.to_i} seconds"
    end
  end

  task :refresh, [:opts] => %i[environment searchindex:configured searchindex:version_supported] do |_t, _args|
    print 'refresh all indexes...'

    SearchIndexBackend.refresh
  end

  task :rebuild, [:opts] => %i[environment searchindex:configured searchindex:version_supported] do |_t, _args|
    Rake::Task['searchindex:drop'].execute
    Rake::Task['searchindex:create'].execute
    Rake::Task['searchindex:reload'].execute
  end

  task :version_supported, [:opts] => :environment do |_t, _args|
    next if SearchIndexBackend.version_supported?

    abort "Your Elasticsearch version is not supported! Please update your version to a greater equal than 6.5.0 (Your current version: #{SearchIndexBackend.version})."
  end

  task :configured, [:opts] => :environment do |_t, _args|
    next if SearchIndexBackend.configured?

    abort "You have not configured Elasticsearch (Setting.get('es_url'))."
  end
end
