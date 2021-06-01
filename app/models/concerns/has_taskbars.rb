# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasTaskbars
  extend ActiveSupport::Concern

  included do
    before_destroy :destroy_taskbars
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
