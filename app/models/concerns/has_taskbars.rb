# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module HasTaskbars
  extend ActiveSupport::Concern

  included do
    before_destroy :destroy_taskbars
  end

  class_methods do
    # Defines the entities which are available for the taskbar.
    def taskbar_entities(*entities)
      @taskbar_entities ||= entities
    end

    def taskbar_ignore_state_updates_entities(*entities)
      @taskbar_ignore_state_updates_entities ||= entities
    end
  end

=begin

destroy all taskbars for the class object id

  model = Model.find(123)
  model.destroy

=end

  def destroy_taskbars
    Taskbar.where(key: "#{self.class}-#{id}").destroy_all
  end

  # Closes all taskbar tabs for this object (ticket).
  # Called by the new scheduler/trigger/macro action "Taskbar → Close Tab".
  # Automatically triggers the WebSocket broadcast (after_destroy in Taskbar), so that tabs
  # disappear immediately for ALL users (agents + customers) – just like with manual closure.  # Schließt alle Taskbar-Tabs für dieses Objekt (Ticket).
  def close_taskbars!
    destroy_taskbars
  end
end
