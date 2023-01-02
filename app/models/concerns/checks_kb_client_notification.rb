# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module ChecksKbClientNotification
  extend ActiveSupport::Concern

  included do
    after_commit :notify_kb_clients_after

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

  def notify_kb_clients_after
    return if self.class.notify_kb_clients_suspend?

    # do not leak details about deleted items. See ChecksKbClientVisibilityJob
    # after_commit does not allow on: :touch
    return if destroyed?

    ChecksKbClientNotificationJob.perform_later(self.class.name, id)
  end
end
