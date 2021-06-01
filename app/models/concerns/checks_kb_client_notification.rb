# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ChecksKbClientNotification
  extend ActiveSupport::Concern

  included do
    after_create  :notify_kb_clients_after_create
    after_update  :notify_kb_clients_after_update
    after_touch   :notify_kb_clients_after_touch
    after_destroy :notify_kb_clients_after_destroy

    class_attribute :notify_kb_clients_suspend, default: false
  end

  def self.disable_in_all_classes!
    all_classes.each { |klass| klass.notify_kb_clients_suspend = true }
  end

  def self.enable_in_all_classes!
    all_classes.each { |klass| klass.notify_kb_clients_suspend = false }
  end

  def self.all_classes
    ActiveRecord::Base
      .descendants
      .select { |c| c.included_modules.include?(ChecksKbClientNotification) }
  end

  private

  # generic call

  def notify_kb_clients(event)
    return if self.class.notify_kb_clients_suspend?

    ChecksKbClientNotificationJob.notify_later(self, event)
  end

  def notify_kb_clients_after_create
    notify_kb_clients(:create)
  end

  def notify_kb_clients_after_update
    notify_kb_clients(:update)
  end

  def notify_kb_clients_after_touch
    notify_kb_clients(:touch)
  end

  def notify_kb_clients_after_destroy
    notify_kb_clients(:destroy)
  end
end
