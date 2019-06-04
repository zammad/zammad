class ScheduledTouchJob < ApplicationJob
  def perform(klass_name, id)
    klass_name.constantize.find_by(id: id)&.touch # rubocop:disable Rails/SkipsModelValidations
  end

  def self.touch_at(object, date)
    set(wait_until: date).perform_later(object.class.to_s, object.id)
  end
end
