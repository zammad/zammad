# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class UpdateCtiLogsByCallerJob < ApplicationJob
  def perform(phone, limit: 60, offset: 0)
    variants = Cti::CallerId.stored_number_variants(phone)
    return if variants.blank?

    preferences = Cti::CallerId.get_comment_preferences(phone, 'from')&.last

    # The number is stored as the telephony backend sent it, while the caller id is normalized.
    #   The expression matches index_cti_logs_on_from_digits, so the lookup never scans the table.
    Cti::Log.where(direction: 'in')
            .where("regexp_replace(\"from\", '\\D', '', 'g') IN (?)", variants)
            .reorder(created_at: :desc)
            .limit(limit)
            .offset(offset)
            .each do |log|
              log.update(preferences: preferences)
            end
  end
end
