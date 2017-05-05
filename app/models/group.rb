# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Group < ApplicationModel
  include HasActivityStreamLog
  include ChecksClientNotification
  include ChecksLatestChangeObserved
  include HasHistory

  has_and_belongs_to_many  :users,         after_add: :cache_update, after_remove: :cache_update
  belongs_to               :email_address
  belongs_to               :signature
  validates                :name, presence: true

  activity_stream_permission 'admin.group'
end
