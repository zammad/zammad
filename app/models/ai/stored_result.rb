# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::StoredResult < ApplicationModel
  self.table_name = 'ai_stored_results'

  belongs_to :related_object, polymorphic: true, optional: true
  belongs_to :locale, optional: true

  validates :identifier, presence: true, uniqueness: { scope: %i[locale_id related_object_type related_object_id] }

  belongs_to :ai_analytics_run, class_name: 'AI::Analytics::Run', optional: true

  # Delete all record matching given criterias
  #
  # @diff [Integer] number of seconds to look back for records to delete, also takes Rails helpers like 1.year.
  # @locale [Locale] to filter by
  # @object [ApplicationModel] to filter by
  # @identifier [String] to filter by
  def self.cleanup(diff: nil, locale: nil, object: nil, identifier: nil)
    scope = all

    if diff.present?
      scope = scope.where(created_at: ...diff.ago)
    end

    if locale.present?
      scope = scope.where(locale:)
    end

    if object.present?
      scope = scope.where(related_object: object)
    end

    if identifier.present?
      scope = scope.where(identifier:)
    end

    scope.delete_all
  end
end
