# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Template < ApplicationModel
  include ChecksClientNotification
  include HasAuditLogs
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch
  include Template::Assets
  include Template::TriggersSubscriptions

  scope :active, -> { where(active: true) }
  scope :sorted, -> { order(:name) }

  store     :options
  validates :name,    presence: true
  validates :options, 'validations/verify_perform_rules': true

  association_attributes_ignored :user
end
