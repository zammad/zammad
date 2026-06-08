# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Analytics::GenerateReport::WithUsages < Service::AI::Analytics::GenerateReport::Base
  def self.excel_sheet_class
    ExcelSheet::AI::Analytics::WithUsage
  end

  private

  def base_scope
    super.where("error IS NULL OR error = '{}'::jsonb")
  end

  def build_struct_from_record(record)
    likes_count    = record.usages.filter { it.rating == true }.size
    dislikes_count = record.usages.filter { it.rating == false }.size
    comments       = record.usages
      .filter { it.comment.present? }
      .map { |usage| usage.slice(:user_id, :comment, :created_at, :rating).merge(user_login: usage.user.login) }

    {
      **record.slice(*RUN_ATTRIBUTES).symbolize_keys,
      locale:         record.locale&.locale,
      usages_count:   record.usages.size,
      likes_count:,
      dislikes_count:,
      comments:
    }
  end

  def enrich_batch(batch)
    batch.includes(:locale, usages: :user)
  end
end
