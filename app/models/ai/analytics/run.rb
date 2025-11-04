# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Analytics::Run < ApplicationModel
  validates :identifier, presence: true
  validates :ai_service_name, presence: true

  belongs_to :locale, optional: true
  belongs_to :related_object, polymorphic: true, optional: true
  belongs_to :triggered_by, polymorphic: true, optional: true
  belongs_to :regeneration_of, class_name: 'AI::Analytics::Run', optional: true, inverse_of: :regenerations

  has_many :regenerations, class_name: 'AI::Analytics::Run', foreign_key: 'regeneration_of_id', dependent: :nullify, inverse_of: :regeneration_of
  has_many :usages, class_name: 'AI::Analytics::Usage', foreign_key: 'ai_analytics_run_id', dependent: :destroy, inverse_of: :ai_analytics_run
  has_many :stored_results, class_name: 'AI::StoredResult', foreign_key: 'ai_analytics_run_id', dependent: :nullify, inverse_of: :ai_analytics_run

  def usage_by(user)
    usage = usages.find_by(user:)

    return if !usage

    {
      user_has_provided_feedback: !usage.rating.nil?
    }
  end
end
