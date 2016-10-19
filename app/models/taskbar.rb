# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Taskbar < ApplicationModel
  store           :state
  store           :params
  before_create   :update_last_contact, :set_user
  before_update   :update_last_contact, :set_user

  private

  def update_last_contact
    self.last_contact = Time.zone.now
  end

  def set_user
    self.user_id = UserInfo.current_user_id
  end
end
