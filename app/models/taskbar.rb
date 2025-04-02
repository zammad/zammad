# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Taskbar < ApplicationModel
  include ChecksClientNotification
  include ::Taskbar::HasAttachments
  include Taskbar::Assets
  include Taskbar::TriggersSubscriptions
  include Taskbar::List

  TASKBAR_APPS = %w[desktop mobile].freeze
  TASKBAR_STATIC_ENTITIES = %w[
    Search
  ].freeze

  store           :state
  store           :params
  store           :preferences

  belongs_to :user

  validates :app, inclusion: { in: TASKBAR_APPS }
  validates :key, uniqueness: { scope: %i[user_id app] }

  before_validation :set_user

  before_create   :update_last_contact, :update_preferences_infos
  before_update   :update_last_contact, :update_preferences_infos
  after_update    :notify_clients
  after_destroy :update_preferences_infos, :notify_clients
  after_commit :update_related_taskbars

  association_attributes_ignored :user

  client_notification_events_ignored :create, :update, :touch

  client_notification_send_to :user_id

  attr_accessor :local_update

  default_scope { order(:id) }

  scope :related_taskbars, lambda { |taskbar|
    where(key: taskbar.key)
      .where.not(id: taskbar.id)
  }

  scope :app, ->(app) { where(app:) }

  # Returns IDs of objects referenced by the taskbars.
  # Works on scopes, relations etc.
  #
  # @return [Hash{Symbol=>Array<Integer>}] of arrays of object IDs
  #
  # @example
  #
  # user.taskbars.to_object_ids # => { user_ids: [1, 2, 3], organization_ids: [1, 2, 3], ticket_ids: [1, 2, 3] }
  #
  def self.to_object_ids
    all.each_with_object({ user_ids: [], organization_ids: [], ticket_ids: [] }) do |elem, memo|
      case elem.params
      in { user_id: }
        memo[:user_ids] << user_id.to_i
      in { organization_id: }
        memo[:organization_ids] << organization_id.to_i
      in { ticket_id: }
        memo[:ticket_ids] << ticket_id.to_i
      else
      end
    end
  end

  def self.taskbar_entities
    @taskbar_entities ||= begin
      ApplicationModel.descendants.select { |model| model.included_modules.include?(HasTaskbars) }.each_with_object([]) do |model, result|
        model.taskbar_entities&.each do |entity|
          result << entity
        end
      end | TASKBAR_STATIC_ENTITIES
    end
  end

  def self.taskbar_ignore_state_updates_entities
    @taskbar_ignore_state_updates_entities ||= begin
      ApplicationModel.descendants.select { |model| model.included_modules.include?(HasTaskbars) }.each_with_object([]) do |model, result|
        model.taskbar_ignore_state_updates_entities&.each do |entity|
          result << entity
        end
      end
    end
  end

  def state_changed?
    return false if state.blank?

    state.each do |key, value|
      if value.is_a? Hash
        value.each do |key1, value1|
          next if value1.blank?
          next if key1 == 'form_id'

          return true
        end
      else
        next if value.blank?
        next if key == 'form_id'

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
    output = { user_id:, apps: { app.to_sym => { last_contact: last_contact, changed: state_changed? } } }
    output[:id] = id if persisted?
    output
  end

  def related_taskbars
    self.class.related_taskbars(self)
  end

  def touch_last_contact!
    # Don't inform the current user (only!) about live user and item updates.
    self.skip_live_user_trigger = true
    self.skip_item_trigger      = true
    self.last_contact           = Time.zone.now
    save!
  end

  def saved_change_to_dirty?
    return false if !saved_change_to_preferences?

    !!preferences[:dirty] != !!preferences_previously_was[:dirty]
  end

  def collect_related_tasks
    related_taskbars.map(&:preferences_task_info)
      .tap { |arr| arr.push(preferences_task_info) if !destroyed? }
      .each_with_object({}) { |elem, memo| reduce_related_tasks(elem, memo) }
      .values
      .sort_by { |elem| elem[:id] || Float::MAX } # sort by IDs to pass old tests
  end

  private

  def update_last_contact
    return if local_update
    return if changes.blank?
    return if changed_only_prio?

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
    return if local_update
    return if !UserInfo.current_user_id

    self.user_id = UserInfo.current_user_id
  end

  def update_preferences_infos
    return if key == 'Search'
    return if local_update
    return if changed_only_prio?

    preferences = self.preferences || {}
    preferences[:tasks] = collect_related_tasks

    # remember preferences for current taskbar
    self.preferences = preferences if !destroyed?
  end

  def changed_only_prio?
    changed_attribute_names_to_save.to_set == Set.new(%w[updated_at prio])
  end

  def reduce_related_tasks(elem, memo)
    key = elem[:user_id]

    if memo[key]
      memo[key].deep_merge! elem
      return
    end

    memo[key] = elem
  end

  def update_related_taskbars
    return if key == 'Search'
    return if local_update
    return if changed_only_prio?

    TaskbarUpdateRelatedTasksJob.perform_later(related_taskbars.map(&:id))
  end

  def notify_clients
    return if !saved_change_to_attribute?('preferences')

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
