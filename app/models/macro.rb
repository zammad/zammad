# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Macro < ApplicationModel
  include ChecksClientNotification
  include ChecksHtmlSanitized
  include ChecksLatestChangeObserved
  include CanSeed
  include HasCollectionUpdate

  store     :perform
  validates :name, presence: true
  validates :ux_flow_next_up, inclusion: { in: %w[none next_task next_from_overview] }

  has_and_belongs_to_many :groups, after_add: :cache_update, after_remove: :cache_update, class_name: 'Group'

  sanitized_html :note

  collection_push_permission('ticket.agent')
end
