# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Group < ApplicationModel
  include HasActivityStreamLog
  include ChecksClientNotification
  include ChecksLatestChangeObserved
  include HasHistory

  belongs_to :email_address
  belongs_to :signature

  validates :name, presence: true

  activity_stream_permission 'admin.group'
end
