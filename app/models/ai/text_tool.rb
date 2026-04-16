# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::TextTool < ApplicationModel
  ASSETS_ANALYTICS_STATS_KEY = 'analytics_stats'.freeze

  include ChecksClientNotification
  include ChecksHtmlSanitized
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch
  include AI::TextTool::TriggersSubscriptions
  include HasOptionalGroups

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :note, length: { maximum: 250 }

  sanitized_html :note

  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'

  def reset_analytics_timestamp!
    self.analytics_stats_reset_at = Time.zone.now

    save!
  end

  def satisfaction_ratio
    Service::AI::Analytics::AggregateSatisfactionRatio
      .new(triggered_by: self)
      .execute
  end

  def attributes_with_association_ids
    attributes = super

    if UserInfo.assets&.user&.permissions?('admin.ai_assistance_text_tools')
      attributes[ASSETS_ANALYTICS_STATS_KEY] = satisfaction_ratio
    end

    attributes
  end
end
