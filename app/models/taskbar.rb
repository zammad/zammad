# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Taskbar < ApplicationModel
  include ChecksClientNotification
  include ::Taskbar::HasAttachments
  include Taskbar::Assets

  store           :state
  store           :params
  store           :preferences

  belongs_to :user

  validates :app, inclusion: { in: %w[desktop mobile] }

  before_create   :update_last_contact, :set_user, :update_preferences_infos
  before_update   :update_last_contact, :set_user, :update_preferences_infos

  after_update    :notify_clients
  after_destroy   :update_preferences_infos, :notify_clients

  association_attributes_ignored :user

  client_notification_events_ignored :create, :update, :touch

  client_notification_send_to :user_id

  attr_accessor :local_update

  scope :related_taskbars, lambda { |taskbar|
    where(key: taskbar.key)
      .where.not(id: taskbar.id)
      .order(:created_at, :id)
  }

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

  def attributes_with_association_names(empty_keys: false)
    add_attachments_to_attributes(super)
  end

  def attributes_with_association_ids
    add_attachments_to_attributes(super)
  end

  def as_json(options = {})
    add_attachments_to_attributes(super)
  end

  def preferences_task_info
    output = { user_id:, last_contact:, changed: state_changed?, apps: [app] }
    output[:id] = id if persisted?
    output
  end

  def related_taskbars
    self.class.related_taskbars(self)
  end

  private

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
    return if key == 'Search'
    return if local_update

    preferences = self.preferences || {}
    preferences[:tasks] = collect_related_tasks

    update_related_taskbars(preferences)

    # remember preferences for current taskbar
    self.preferences = preferences if !destroyed?
  end

  def collect_related_tasks
    related_taskbars
      .map(&:preferences_task_info)
      .push(preferences_task_info)
      .each_with_object({}) { |elem, memo| reduce_related_tasks(elem, memo) }
      .values
      .sort_by { |elem| elem[:id] || Float::MAX } # sort by IDs to pass old tests
  end

  def reduce_related_tasks(elem, memo)
    if memo[elem[:user_id]]
      memo[elem[:user_id]][:apps].concat elem[:apps]
      memo[elem[:user_id]][:changed] = true if elem[:changed]
      return
    end

    memo[elem[:user_id]] = elem
  end

  def update_related_taskbars(preferences)
    related_taskbars.each do |taskbar|
      taskbar.with_lock do
        taskbar.preferences = preferences
        taskbar.local_update = true
        taskbar.save!
      end
    end
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
