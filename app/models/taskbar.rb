# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Taskbar < ApplicationModel
  store           :state
  store           :params
  store           :preferences
  before_create   :update_last_contact, :set_user, :update_preferences_infos
  before_update   :update_last_contact, :set_user, :update_preferences_infos

  after_update    :notify_clients
  after_destroy   :update_preferences_infos, :notify_clients

  attr_accessor :local_update

  def state_changed?
    return false if !state
    return false if state.empty?
    state.each { |_key, value|
      if value.class == Hash || value.class == ActiveSupport::HashWithIndifferentAccess
        value.each { |_key1, value1|
          next if value1 && value1.empty?
          return true
        }
      else
        next if value && value.empty?
        return true
      end
    }
    false
  end

  private

  def update_last_contact
    return true if local_update
    return true if changes.empty?
    if changes['notify']
      count = 0
      changes.each { |attribute, _value|
        next if attribute == 'updated_at'
        next if attribute == 'created_at'
        count += 1
      }
      return true if count <= 1
    end
    self.last_contact = Time.zone.now
  end

  def set_user
    return true if local_update
    self.user_id = UserInfo.current_user_id
  end

  def update_preferences_infos
    return true if local_update

    # find other same open tasks
    if !preferences
      self.preferences = {}
    end
    preferences[:tasks] = []
    Taskbar.where(key: key).order(:created_at, :id).each { |taskbar|
      if taskbar.id == id
        local_changed = state_changed?
        local_last_contact = last_contact
      else
        local_changed = taskbar.state_changed?
        local_last_contact = taskbar.last_contact
      end
      task = {
        id: taskbar.id,
        user_id: taskbar.user_id,
        last_contact: local_last_contact,
        changed: local_changed,
      }
      preferences[:tasks].push task
    }
    if !id
      changed = state_changed?
      task = {
        user_id: user_id,
        last_contact: last_contact,
        changed: changed,
      }
      preferences[:tasks].push task
    end

    # update other taskbars
    Taskbar.where(key: key).order(:created_at, :id).each { |taskbar|
      next if taskbar.id == id
      taskbar.with_lock do
        taskbar.preferences = preferences
        taskbar.local_update = true
        taskbar.save!
      end
    }

    return true if destroyed?

    # remember preferences for current taskbar
    self.preferences = preferences

    true
  end

  def notify_clients
    return true if !changes['preferences']
    data = {
      event: 'taskbar:preferences',
      data: {
        id: id,
        key: key,
        preferences: preferences,
      },
    }
    PushMessages.send_to(
      user_id,
      data,
    )
  end

end
