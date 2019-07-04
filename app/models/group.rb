# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Group < ApplicationModel
  include CanBeImported
  include HasActivityStreamLog
  include ChecksClientNotification
  include ChecksLatestChangeObserved
  include HasHistory
  include HasObjectManagerAttributesValidation

  belongs_to :email_address, optional: true
  belongs_to :signature, optional: true

  validates :name, presence: true

  activity_stream_permission 'admin.group'
end
