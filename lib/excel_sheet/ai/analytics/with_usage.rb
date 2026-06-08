# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ExcelSheet::AI::Analytics::WithUsage < ExcelSheet
  TITLE               = __('AI usage and feedback log').freeze
  PRETTY_JSON_COLUMNS = %i[content payload context].freeze

  attr_reader :entries

  def initialize(entries:, timezone:, locale:)
    @entries = entries

    super(
      title:    TITLE,
      header:   headers,
      records:  [],
      timezone:,
      locale:
    )
  end

  def headers
    [
      { display: 'ID', name: 'id', width: 18, data_type: 'string' },
      { display: __('Identifier'), name: 'identifier', width: 14, data_type: 'string' },
      { display: __('Version'), name: 'version', width: 14, data_type: 'string' },
      { display: __('AI Service Name'), name: 'ai_service_name', width: 14, data_type: 'string' },
      { display: __('Locale'), name: 'locale', width: 14, data_type: 'string' },

      { display: __('Related Object Type'), name: 'related_object_type', width: 14, data_type: 'string' },
      { display: __('Related Object ID'), name: 'related_object_id', width: 14, data_type: 'string' },
      { display: __('Triggered By Type'), name: 'triggered_by_type', width: 14, data_type: 'string' },
      { display: __('Triggered By ID'), name: 'triggered_by_id', width: 14, data_type: 'string' },

      { display: __('Regeneration Of ID'), name: 'regeneration_of_id', width: 14, data_type: 'string' },

      { display: __('Content'), name: 'content', width: 34, data_type: 'string' },
      { display: __('Payload'), name: 'payload', width: 34, data_type: 'string' },
      { display: __('Context'), name: 'context', width: 34, data_type: 'string' },

      { display: __('Created At'), name: 'created_at', width: 20, data_type: 'datetime' },

      { display: __('Usages count'), name: 'usages_count', width: 10, data_type: 'integer' },
      { display: __('Likes count'), name: 'likes_count', width: 10, data_type: 'integer' },
      { display: __('Dislikes count'), name: 'dislikes_count', width: 10, data_type: 'integer' },

      { display: __('Comments'), name: 'comments', width: 34, data_type: 'string' },
    ]
  end

  def gen_rows
    entries.each_with_index do |entry, _index|
      PRETTY_JSON_COLUMNS.each do |attr|
        entry[attr] = JSON.pretty_generate(entry[attr])
      end

      entry[:comments] = entry[:comments]
        .map do |comment|
          "- #{comment[:user_login]} (##{comment[:user_id]}) @ #{timestamp_in_localtime(comment[:created_at])}:\n#{comment[:comment]}"
        end
        .join("\n\n")

      gen_row_by_header(entry)
    end
  end

end
