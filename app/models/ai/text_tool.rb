# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::TextTool < ApplicationModel
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
end
