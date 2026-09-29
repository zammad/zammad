# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Analytics::GenerateReport::Base < Service::Base
  RESULT_SIZE = 10_000
  BATCH_SIZE  = 1_000

  RUN_ATTRIBUTES = %i[
    id identifier version ai_service_name locale
    related_object_type related_object_id triggered_by_type triggered_by_id regeneration_of_id
    error content payload context
    created_at
  ].freeze

  CONTENT_TYPES = {
    xlsx: ExcelSheet::CONTENT_TYPE,
    json: 'application/json',
  }.freeze

  attr_reader :scope, :format

  # @param scope [ActiveRecord::Relation<AI::Analytics::Run>]
  # @param format [Symbol, String] one of the keys of CONTENT_TYPES
  def initialize(scope: AI::Analytics::Run.all, format: :json)
    @scope  = scope
    @format = CONTENT_TYPES.keys.find { |key| key.to_s == format.to_s }

    raise Exceptions::UnprocessableContent, 'invalid format' if !@format
  end

  def content_type
    CONTENT_TYPES[format]
  end

  # Returns the report as a file with its path already deleted, the data vanishes once it is closed.
  def execute
    case format
    when :xlsx
      self.class.excel_sheet_class.new(
        entries:  each_parsed_record,
        timezone: Setting.get('timezone_default'),
        locale:   Locale.first
      ).file
    when :json
      # needs to take into account timezone too
      json_file
    end
  end

  def self.excel_sheet_class
    raise 'not implemented'
  end

  private

  def each_parsed_record
    return enum_for(__method__) if !block_given?

    query_records { |record| yield build_struct_from_record(record) }
  end

  def json_file
    file = Tempfile.new(['ai-analytics', '.json'])
    file.unlink

    separator = ''
    file.write('[')
    each_parsed_record do |record|
      file.write(separator, record.to_json)
      separator = ','
    end
    file.write(']')

    file.tap(&:rewind)
  rescue
    file&.close
    raise
  end

  def build_struct_from_record(_record)
    raise 'not implemented'
  end

  def query_records(&)
    base_scope
      .in_batches(of: BATCH_SIZE, order: :desc)
      .take(RESULT_SIZE / BATCH_SIZE)
      .each do |batch|
        enrich_batch(batch).reorder(id: :desc).each(&)
      end
  end

  def base_scope
    scope
  end

  def enrich_batch(_batch)
    raise 'not implemented'
  end
end
