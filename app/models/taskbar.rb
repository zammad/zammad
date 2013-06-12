# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Taskbar < ApplicationModel
  store           :state
  store           :params
  before_create   :update_last_contact
  before_update   :update_last_contact

  private
  def update_last_contact
    self.last_contact = Time.now
  end
end
