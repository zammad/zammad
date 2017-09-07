# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module ChecksLatestChangeObserved
  extend ActiveSupport::Concern

  included do
    after_create  :latest_change_set_from_observer
    after_update  :latest_change_set_from_observer
    after_touch   :latest_change_set_from_observer
    after_destroy :latest_change_set_from_observer_destroy
  end

  def latest_change_set_from_observer
    self.class.latest_change_set(updated_at)
    true
  end

  def latest_change_set_from_observer_destroy
    self.class.latest_change_set(nil)
    true
  end
end
