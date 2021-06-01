# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Taskbar < ApplicationModel
  include ChecksClientNotification

  store           :state
  store           :params
  store           :preferences

  belongs_to :user

  before_create   :update_last_contact, :set_user, :update_preferences_infos
  before_update   :update_last_contact, :set_user, :update_preferences_infos

  after_update    :notify_clients
  after_destroy   :update_preferences_infos, :notify_clients

  association_attributes_ignored :user

  client_notification_events_ignored :create, :update, :touch

  client_notification_send_to :user_id

  attr_accessor :local_update

  def state_changed?
    return false if state.blank?

    state.each_value do |value|
      if value.is_a? Hash
        value.each do |key1, value1|
          next if value1.blank?
          next if key1 == 'form_id'

          return true
        end
      else
        next if value.blank?

        return true
      end
    end
    false
  end

  def attributes_with_association_names
    add_attachments_to_attributes(super)
  end

  def attributes_with_association_ids
    add_attachments_to_attributes(super)
  end

  def as_json(options = {})
    add_attachments_to_attributes(super)
  end

  # form_id is saved directly in a new ticket, but inside of the article when updating an existing ticket
  def persisted_form_id
    state&.dig(:form_id) || state&.dig(:article, :form_id)
  end

  private

  def attachments
    return [] if persisted_form_id.blank?

    UploadCache.new(persisted_form_id).attachments
  end

  def add_attachments_to_attributes(attributes)
    attributes.tap do |result|
      result['attachments'] = attachments.map(&:attributes_for_display)
    end
  end

  def update_last_contact
    return true if local_update
    return true if changes.blank?

    if changes['notify']
      count = 0
      changes.each_key do |attribute|
        next if attribute == 'updated_at'
        next if attribute == 'created_at'

        count += 1
      end
      return true if count <= 1
    end
    self.last_contact = Time.zone.now
  end

  def set_user
    return true if local_update
    return true if !UserInfo.current_user_id

    self.user_id = UserInfo.current_user_id
  end

  def update_preferences_infos
    return true if key == 'Search'
    return true if local_update

    # find other same open tasks
    if !preferences
      self.preferences = {}
    end
    preferences[:tasks] = []
    Taskbar.where(key: key).order(:created_at, :id).each do |taskbar|
      if taskbar.id == id
        local_changed = state_changed?
        local_last_contact = last_contact
      else
        local_changed = taskbar.state_changed?
        local_last_contact = taskbar.last_contact
      end
      task = {
        id:           taskbar.id,
        user_id:      taskbar.user_id,
        last_contact: local_last_contact,
        changed:      local_changed,
      }
      preferences[:tasks].push task
    end
    if !id
      changed = state_changed?
      task = {
        user_id:      user_id,
        last_contact: last_contact,
        changed:      changed,
      }
      preferences[:tasks].push task
    end

    # update other taskbars
    Taskbar.where(key: key).order(:created_at, :id).each do |taskbar|
      next if taskbar.id == id

      taskbar.with_lock do
        taskbar.preferences = preferences
        taskbar.local_update = true
        taskbar.save!
      end
    end

    return true if destroyed?

    # remember preferences for current taskbar
    self.preferences = preferences

    true
  end

  def notify_clients
    return true if !saved_change_to_attribute?('preferences')

    data = {
      event: 'taskbar:preferences',
      data:  {
        id:          id,
        key:         key,
        preferences: preferences,
      },
    }
    PushMessages.send_to(
      user_id,
      data,
    )
  end

end
