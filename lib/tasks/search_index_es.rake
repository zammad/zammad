$LOAD_PATH << './lib'
require 'rubygems'

namespace :searchindex do
  task :drop, [:opts] => %i[environment searchindex:version_supported] do |_t, _args|
    print 'drop indexes...'

    # drop indexes
    if es_multi_index?
      Models.indexable.each do |local_object|
        SearchIndexBackend.index(
          action: 'delete',
          name:   local_object.name,
        )
      end
    else
      SearchIndexBackend.index(
        action: 'delete',
      )
    end
    puts 'done'

    Rake::Task['searchindex:drop_pipeline'].execute
  end

  task :create, [:opts] => %i[environment searchindex:version_supported] do |_t, _args|
    print 'create indexes...'

    if es_multi_index?
      Setting.set('es_multi_index', true)
    else
      Setting.set('es_multi_index', false)
    end

    settings = {
      'index.mapping.total_fields.limit': 2000,
    }

    # create indexes
    if es_multi_index?
      Models.indexable.each do |local_object|
        SearchIndexBackend.index(
          action: 'create',
          name:   local_object.name,
          data:   {
            mappings: get_mapping_properties_object(local_object),
            settings: settings,
          }
        )
      end
    else
      mapping = {}
      Models.indexable.each do |local_object|
        mapping.merge!(get_mapping_properties_object(local_object))
      end
      SearchIndexBackend.index(
        action: 'create',
        data:   {
          mappings: mapping,
          settings: settings,
        }
      )
    end

    puts 'done'

    Rake::Task['searchindex:create_pipeline'].execute
  end

  task :create_pipeline, [:opts] => %i[environment searchindex:version_supported] do |_t, _args|
    if !es_pipeline?
      Setting.set('es_pipeline', '')
      next
    end

    # update processors
    pipeline = Setting.get('es_pipeline')
    if pipeline.blank?
      pipeline = "zammad#{rand(999_999_999_999)}"
      Setting.set('es_pipeline', pipeline)
    end

    # define pipeline_field_attributes
    # ES 5.6 and nower has no ignore_missing support
    pipeline_field_attributes = {
      ignore_failure: true,
    }
    if es_multi_index?
      pipeline_field_attributes = {
        ignore_failure: true,
        ignore_missing: true,
      }
    end
    print 'create pipeline (pipeline)... '
    SearchIndexBackend.processors(
      "_ingest/pipeline/#{pipeline}": [
        {
          action: 'delete',
        },
        {
          action:      'create',
          description: 'Extract zammad-attachment information from arrays',
          processors:  [
            {
              foreach: {
                field:     'article',
                processor: {
                  foreach: {
                    field:     '_ingest._value.attachment',
                    processor: {
                      attachment: {
                        target_field: '_ingest._value',
                        field:        '_ingest._value._content',
                      }.merge(pipeline_field_attributes),
                    }
                  }.merge(pipeline_field_attributes),
                }
              }.merge(pipeline_field_attributes),
            },
            {
              foreach: {
                field:     'attachment',
                processor: {
                  attachment: {
                    target_field: '_ingest._value',
                    field:        '_ingest._value._content',
                  }.merge(pipeline_field_attributes),
                }
              }.merge(pipeline_field_attributes),
            }
          ]
        }
      ]
    )
    puts 'done'
  end

  task :drop_pipeline, [:opts] => %i[environment searchindex:version_supported] do |_t, _args|
    next if !es_pipeline?

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

  task :reload, [:opts] => %i[environment searchindex:version_supported] do |_t, _args|

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

  task :refresh, [:opts] => %i[environment searchindex:version_supported] do |_t, _args|
    print 'refresh all indexes...'

    SearchIndexBackend.refresh
  end

  task :rebuild, [:opts] => %i[environment searchindex:version_supported] do |_t, _args|
    Rake::Task['searchindex:drop'].execute
    Rake::Task['searchindex:create'].execute
    Rake::Task['searchindex:reload'].execute
  end

  task :version_supported, [:opts] => :environment do |_t, _args|
    next if es_version_supported?

    abort "Your elastic search version is not supported! Please update your version to a greater equal than 5.6.0 (Your current version: #{es_version})."
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

  name = object.name
  if es_multi_index?
    name = '_doc'
  end
  result = {
    name => {
      properties: {}
    }
  }

  store_columns = %w[preferences data]

  # for elasticsearch 6.x and later
  string_type = 'text'
  string_raw  = { 'type': 'keyword', 'ignore_above': 5012 }
  boolean_raw = { 'type': 'boolean' }

  # for elasticsearch 5.6 and lower
  if !es_multi_index?
    string_type = 'string'
    string_raw  = { 'type': 'string', 'index': 'not_analyzed' }
    boolean_raw = { 'type': 'boolean', 'index': 'not_analyzed' }
  end

  object.columns_hash.each do |key, value|
    if value.type == :string && value.limit && value.limit <= 5000 && store_columns.exclude?(key)
      result[name][:properties][key] = {
        type:   string_type,
        fields: {
          keyword: string_raw,
        }
      }
    elsif value.type == :integer
      result[name][:properties][key] = {
        type: 'integer',
      }
    elsif value.type == :datetime
      result[name][:properties][key] = {
        type: 'date',
      }
    elsif value.type == :boolean
      result[name][:properties][key] = {
        type:   'boolean',
        fields: {
          keyword: boolean_raw,
        }
      }
    elsif value.type == :binary
      result[name][:properties][key] = {
        type: 'binary',
      }
    elsif value.type == :bigint
      result[name][:properties][key] = {
        type: 'long',
      }
    elsif value.type == :decimal
      result[name][:properties][key] = {
        type: 'float',
      }
    elsif value.type == :date
      result[name][:properties][key] = {
        type: 'date',
      }
    end
  end

  # es with mapper-attachments plugin
  if object.name == 'Ticket'

    # do not server attachments if document is requested
    result[name][:_source] = {
      excludes: ['article.attachment']
    }

    # for elasticsearch 5.5 and lower
    if !es_pipeline?
      result[name][:_source] = {
        excludes: ['article.attachment']
      }
      result[name][:properties][:article] = {
        type:              'nested',
        include_in_parent: true,
        properties:        {
          attachment: {
            type: 'attachment',
          }
        }
      }
    end
  end

  if object.name == 'KnowledgeBase::Answer::Translation'
    # do not server attachments if document is requested
    result[name][:_source] = {
      excludes: ['attachment']
    }

    # for elasticsearch 5.5 and lower
    if !es_pipeline?
      result[name][:_source] = {
        excludes: ['attachment']
      }
      result[name][:properties][:attachment] = {
        type: 'attachment',
      }
    end
  end

  return result if es_type_in_mapping?

  result[name]
end

# get es version
def es_version
  @es_version ||= begin
    info = SearchIndexBackend.info
    number = nil
    if info.present?
      number = info['version']['number'].to_s
    end
    number
  end
end

def es_version_supported?
  version_split = es_version.split('.')
  version       = "#{version_split[0]}#{format('%<minor>03d', minor: version_split[1])}#{format('%<patch>03d', patch: version_split[2])}".to_i

  # only versions greater/equal than 5.6.0 are supported
  return if version < 5_006_000

  true
end

# no es_pipeline for elasticsearch 5.5 and lower
def es_pipeline?
  number = es_version
  return false if number.blank?
  return false if number.match?(/^[2-4]\./)
  return false if number.match?(/^5\.[0-5]\./)

  true
end

# no multi index for elasticsearch 5.6 and lower
def es_multi_index?
  number = es_version
  return false if number.blank?
  return false if number.match?(/^[2-5]\./)

  true
end

# no type in mapping
def es_type_in_mapping?
  number = es_version
  return true if number.blank?
  return true if number.match?(/^[2-6]\./)

  false
end
