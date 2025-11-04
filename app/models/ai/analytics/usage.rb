# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Analytics::Usage < ApplicationModel
  belongs_to :ai_analytics_run, class_name: 'AI::Analytics::Run', inverse_of: :usages
  belongs_to :user

  validates :ai_analytics_run_id, uniqueness: { scope: :user_id }
  validate :validate_rating_changing

  private

  def validate_rating_changing
    return if rating_was.nil?
    return if !rating_changed?

    errors.add(:base, __('Rating can only be set once'))
  end
end
