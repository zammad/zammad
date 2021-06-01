# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ChecksLatestChangeObserved
  extend ActiveSupport::Concern

  included do
    after_commit :latest_change_set_from_observer
  end

  def latest_change_set_from_observer
    latest_change = destroyed? ? nil : updated_at
    self.class.latest_change_set(latest_change)
  end
end
