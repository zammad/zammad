# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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

end
