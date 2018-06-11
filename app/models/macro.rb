# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Macro < ApplicationModel
  include ChecksClientNotification
  include ChecksLatestChangeObserved
  include CanSeed

  store     :perform
  validates :name, presence: true
  validates :ux_flow_next_up, inclusion: { in: %w[none next_task next_from_overview] }
end
