# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ScheduledTouchJob < ApplicationJob
  include HasActiveJobLock

  def lock_key
    # "ScheduledTouchJob/User/42"
    "#{self.class.name}/#{arguments[0]}/#{arguments[1]}"
  end

  def self.touch_at(object, date)
    set(wait_until: date).perform_later(object.class.to_s, object.id)
  end

  def perform(klass_name, id)
    klass_name.constantize.find_by(id: id)&.touch # rubocop:disable Rails/SkipsModelValidations
  end
end
