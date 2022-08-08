# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Group < ApplicationModel
  include CanBeImported
  include HasActivityStreamLog
  include ChecksClientNotification
  include ChecksHtmlSanitized
  include HasHistory
  include HasObjectManagerAttributes
  include HasCollectionUpdate
  include HasSearchIndexBackend

  include Group::Assets

  belongs_to :email_address, optional: true
  belongs_to :signature, optional: true

  # workflow checks should run after before_create and before_update callbacks
  include ChecksCoreWorkflow

  validates :name, presence: true

  validates :note, length: { maximum: 250 }
  sanitized_html :note, no_images: true

  activity_stream_permission 'admin.group'
end
