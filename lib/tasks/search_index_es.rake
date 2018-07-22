$LOAD_PATH << './lib'
require 'rubygems'

namespace :searchindex do
  task :drop, [:opts] => :environment do |_t, _args|

    # drop indexes
    print 'drop indexes...'
    SearchIndexBackend.index(
      action: 'delete',
    )
    puts 'done'

    Rake::Task['searchindex:drop_pipeline'].execute
  end

  task :create, [:opts] => :environment do |_t, _args|
    print 'create indexes...'

    # es with mapper-attachments plugin
    info = SearchIndexBackend.info
    number = nil
    if info.present?
      number = info['version']['number'].to_s
    end

    mapping = {}
    Models.searchable.each do |local_object|
      mapping.merge!(get_mapping_properties_object(local_object))
    end

    # create indexes
    SearchIndexBackend.index(
      action: 'create',
      data: {
        mappings: mapping
      }
    )

    if number.blank? || number =~ /^[2-4]\./ || number =~ /^5\.[0-5]\./
      Setting.set('es_pipeline', '')
    end

    puts 'done'

    Rake::Task['searchindex:create_pipeline'].execute
  end

  task :create_pipeline, [:opts] => :environment do |_t, _args|

    # es with mapper-attachments plugin
    info = SearchIndexBackend.info
    number = nil
    if info.present?
      number = info['version']['number'].to_s
    end
    next if number.blank? || number =~ /^[2-4]\./ || number =~ /^5\.[0-5]\./

    # update processors
    pipeline = Setting.get('es_pipeline')
    if pipeline.blank?
      pipeline = "zammad#{rand(999_999_999_999)}"
      Setting.set('es_pipeline', pipeline)
    end
    print 'create pipeline (pipeline)... '
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
    puts 'done'
  end

  task :drop_pipeline, [:opts] => :environment do |_t, _args|

    # es with mapper-attachments plugin
    info = SearchIndexBackend.info
    number = nil
    if info.present?
      number = info['version']['number'].to_s
    end
    next if number.blank? || number =~ /^[2-4]\./ || number =~ /^5\.[0-5]\./

    # update processors
    pipeline = Setting.get('es_pipeline')
    next if pipeline.blank?
    print 'delete pipeline (pipeline)... '
    SearchIndexBackend.processors(
      "_ingest/pipeline/#{pipeline}": [
        {
          action: 'delete',
        },
      ]
    )
    puts 'done'
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

=begin

This function will return a index mapping based on the
attributes of the database table of the existing object.

mapping = get_mapping_properties_object(Ticket)

Returns:

mapping = {
  User: {
    properties: {
      firstname: {
        type: 'keyword',
      },
    }
  }
}

=end

def get_mapping_properties_object(object)
  result = {
    object.name => {
      properties: {}
    }
  }

  store_columns = %w[preferences data]

  object.columns_hash.each do |key, value|
    if value.type == :string && value.limit && value.limit <= 5000 && store_columns.exclude?(key)
      result[object.name][:properties][key] = {
        type: 'string',
        fields: {
          raw: { 'type': 'string', 'index': 'not_analyzed' }
        }
      }
    elsif value.type == :integer
      result[object.name][:properties][key] = {
        type: 'integer',
      }
    elsif value.type == :datetime
      result[object.name][:properties][key] = {
        type: 'date',
      }
    elsif value.type == :boolean
      result[object.name][:properties][key] = {
        type: 'boolean',
        fields: {
          raw: { 'type': 'boolean', 'index': 'not_analyzed' }
        }
      }
    elsif value.type == :binary
      result[object.name][:properties][key] = {
        type: 'binary',
      }
    elsif value.type == :bigint
      result[object.name][:properties][key] = {
        type: 'long',
      }
    elsif value.type == :decimal
      result[object.name][:properties][key] = {
        type: 'float',
      }
    elsif value.type == :date
      result[object.name][:properties][key] = {
        type: 'date',
      }
    end
  end

  # es with mapper-attachments plugin
  info = SearchIndexBackend.info
  number = nil
  if info.present?
    number = info['version']['number'].to_s
  end

  if object.name == 'Ticket'

    result[object.name][:_source] = {
      excludes: ['article.attachment']
    }

    if number.blank? || number =~ /^[2-4]\./ || number =~ /^5\.[0-5]\./
      result[object.name][:_source] = {
        excludes: ['article.attachment']
      }
      result[object.name][:properties][:article] = {
        type: 'nested',
        include_in_parent: true,
        properties: {
          attachment: {
            type: 'attachment',
          }
        }
      }
    end
  end

  result
end
