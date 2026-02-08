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

  attr_reader :scope, :format

  # @param scope [ActiveRecord::Relation<AI::Analytics::Run>]
  # @param format [Symbol] :json or :xlsx
  def initialize(scope: AI::Analytics::Run.all, format: :json)
    super()

    @scope  = scope
    @format = format.to_sym
  end

  def execute
    case format
    when :xlsx
      self.class.excel_sheet_class.new(
        entries:  parsed_records,
        timezone: Setting.get('timezone_default'),
        locale:   Locale.first
      ).content
    when :json
      # needs to take into account timezone too
      parsed_records
        .to_json
    end
  end

  def self.excel_sheet_class
    raise 'not implemented'
  end

  private

  def parsed_records
    parsed = []
    query_records { |record| parsed << build_struct_from_record(record) }
    parsed
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
