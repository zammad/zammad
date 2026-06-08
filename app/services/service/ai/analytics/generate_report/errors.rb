# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Analytics::GenerateReport::Errors < Service::AI::Analytics::GenerateReport::Base
  def self.excel_sheet_class
    ExcelSheet::AI::Analytics::Errors
  end

  private

  def base_scope
    super.where("error IS NOT NULL and error <> '{}'::jsonb")
  end

  def build_struct_from_record(record)
    {
      **record.slice(*RUN_ATTRIBUTES).symbolize_keys,
      locale: record.locale&.locale,
    }
  end

  def enrich_batch(batch)
    batch.includes(:locale)
  end
end
