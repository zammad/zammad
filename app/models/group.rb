# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Group < ApplicationModel
  include CanBeImported
  include HasActivityStreamLog
  include ChecksClientNotification
  include ChecksHtmlSanitized
  include ChecksLatestChangeObserved
  include HasHistory
  include HasObjectManagerAttributesValidation
  include HasCollectionUpdate
  include HasTicketCreateScreenImpact
  include HasSearchIndexBackend

  belongs_to :email_address, optional: true
  belongs_to :signature, optional: true

  validates :name, presence: true

  sanitized_html :note

  activity_stream_permission 'admin.group'
end
