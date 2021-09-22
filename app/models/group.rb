# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Group < ApplicationModel
  include CanBeImported
  include HasActivityStreamLog
  include ChecksClientNotification
  include ChecksHtmlSanitized
  include ChecksLatestChangeObserved
  include HasHistory
  include HasObjectManagerAttributes
  include HasCollectionUpdate
  include HasTicketCreateScreenImpact
  include HasSearchIndexBackend

  include Group::Assets

  belongs_to :email_address, optional: true
  belongs_to :signature, optional: true

  # workflow checks should run after before_create and before_update callbacks
  include ChecksCoreWorkflow

  validates :name, presence: true

  sanitized_html :note

  activity_stream_permission 'admin.group'
end
