# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

  store :state
  store :params
  store :preferences

  belongs_to :user

  validates :app, inclusion: { in: TASKBAR_APPS }
  validates :key, uniqueness: { scope: %i[user_id app] }

  before_validation :set_user

  before_create   :update_last_contact, :update_preferences_infos
  before_update   :update_last_contact, :update_preferences_infos
  after_update    :notify_clients
  after_destroy :update_preferences_infos, :notify_clients
  after_commit :update_related_taskbars
  after_destroy_commit :log_recent_close

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

  def to_object_class
    case params
    in { user_id: }
      User
    in { organization_id: }
      Organization
    in { ticket_id: }
      Ticket
    else
    end
  end

  def to_object_id
    case params
    in { user_id: }
      user_id.to_i
    in { organization_id: }
      organization_id.to_i
    in { ticket_id: }
      ticket_id.to_i
    else
    end
  end

  def to_object
    to_object_class&.find_by(id: to_object_id)
  end

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
      object_id = elem.to_object_id
      next if object_id.blank?

      key = "#{elem.to_object_class.name.downcase}_ids"

      memo[key.to_sym] << elem.to_object_id
    end
  end

  # Models with taskbar support, i.e. the classes a taskbar entry can point to.
  def self.entity_classes
    @entity_classes ||= begin
      classes = ApplicationModel.descendants.select { |model| model.include?(HasTaskbars) }

      # Entries of one model would resolve to the other one, so a collision must
      #   not pass silently - an addon can add taskbar models at any time.
      colliding = classes
        .group_by { |model| entity_key_prefix(model) }
        .find { |_prefix, models| models.size > 1 }

      if colliding
        raise "Taskbar key prefix '#{colliding.first}' is used by #{colliding.last.map(&:name).sort.join(' and ')}."
      end

      classes
    end
  end

  # The model part is a key prefix as built by .entity_key_prefix, which may
  #   contain digits and the encoded namespace separator ('Sso2__Session-1').
  #
  # The optional qualifier behind the id is what makes more than one tab per
  #   record possible (see .entity_key); it has to start with a letter, so that
  #   a create screen's UUID is not read as an id plus a qualifier.
  KEY_REGEXP = %r{^(?<model>\p{Lu}[\p{L}\p{N}_]+)-(?<id>\d+)(?:-(?<qualifier>\p{L}[\p{L}\p{N}_-]*))?$}

  # Key prefix used for taskbar entries of a model, e.g. 'Ticket' for
  #   'Ticket-123' and 'ProjectBaller__Project' for a namespaced one (see
  #   IdentifierName).
  def self.entity_key_prefix(klass)
    IdentifierName.encode(klass.name)
  end

  # Key of the taskbar entries for a record, e.g. 'Ticket-123'. Both stacks
  #   build their keys this way, so an object opened in one of them shows up as
  #   the same tab in the other.
  #
  # A qualifier narrows a tab down to a part of the record, so that one record
  #   can have more than one tab: an answer is edited per locale, and its edit
  #   tab is keyed 'KnowledgeBase__Answer-42-de-de'. The record stays the tab's
  #   entity, which is what keeps its authorization (see
  #   Gql::Types::User::TaskbarItemType#object_entity!) and its cleanup (see
  #   HasTaskbars#destroy_taskbars) working.
  def self.entity_key(record, qualifier = nil)
    [entity_key_prefix(record.class), record.id, qualifier].compact.join('-')
  end

  # Record id in a taskbar key, or nil for a key that names none - a create
  #   screen's UUID, a static entity like 'Search', or a legacy key format.
  #
  # Parsed rather than split off at the first '-', so that a qualifier behind
  #   the id cannot reach a record lookup, where it would survive as nothing
  #   but an integer type cast.
  def self.entity_key_id(key)
    match = key.match(KEY_REGEXP)

    match[:id] if match
  end

  # Model for a taskbar key prefix, or nil for an unknown one. Resolved via the
  #   known taskbar classes, never by constantizing the (client-provided) key.
  def self.entity_class_for_key_prefix(prefix)
    entity_classes.find { |model| entity_key_prefix(model) == prefix }
  end

  def self.taskbar_entities
    @taskbar_entities ||= begin
      entity_classes.each_with_object([]) do |model, result|
        model.taskbar_entities&.each do |entity|
          result << entity
        end
      end | TASKBAR_STATIC_ENTITIES
    end
  end

  def self.taskbar_ignore_state_updates_entities
    @taskbar_ignore_state_updates_entities ||= begin
      entity_classes.each_with_object([]) do |model, result|
        model.taskbar_ignore_state_updates_entities&.each do |entity|
          result << entity
        end
      end
    end
  end

  # Pundit queries the entities of the taskbar entries are authorized with,
  #   per entity. Collected from the models the way .taskbar_entities is, so an
  #   addon can bring a tab of its own along with the query it needs.
  def self.taskbar_entity_pundit_methods
    @taskbar_entity_pundit_methods ||= entity_classes.each_with_object({}) do |model, result|
      result.merge!(model.taskbar_entity_pundit_methods)
    end
  end

  # Key prefixes of the models whose taskbar entries relate to each other -
  #   their owners appear in one another's live user list - mapped to the Pundit
  #   query that decides who belongs in it (see
  #   HasTaskbars.taskbar_live_user_pundit_method).
  def self.taskbar_live_user_pundit_methods
    @taskbar_live_user_pundit_methods ||= entity_classes.each_with_object({}) do |model, result|
      method = model.taskbar_live_user_pundit_method
      next if method.blank?

      result[entity_key_prefix(model)] = method
    end
  end

  # Pundit query for one entity, :show? for every entity that names none.
  #
  # An *edit* tab needs more than that: a reader of a knowledge base category
  #   passes KnowledgeBase::AnswerPolicy#show?, so the tab list would report the
  #   entity of an edit tab as accessible while the view refuses it.
  def self.entity_pundit_method(entity)
    taskbar_entity_pundit_methods.fetch(entity, :show?)
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

    # When we touch the taskbar for the last contact, we should also reset the notify flag.
    self.notify = false

    save!
  end

  def saved_change_to_dirty?
    return false if !saved_change_to_preferences?

    !!preferences[:dirty] != !!preferences_previously_was[:dirty]
  end

  def collect_related_tasks
    return [] if !target_accessible_to_owner?

    related_taskbars
      .filter(&:target_accessible_to_owner?)
      .map(&:preferences_task_info)
      .tap { |arr| arr.push(preferences_task_info) if !destroyed? }
      .each_with_object({}) { |elem, memo| reduce_related_tasks(elem, memo) }
      .values
      .sort_by { |elem| elem[:id] || Float::MAX } # sort by IDs to pass old tests
  end

  # Checks if taskbar's owner has access to the target object (Ticket, KnowledgeBase::Answer...)
  #   with the Pundit query that model's live user list is gated by.
  # @return [Boolean, nil] true if the target is accessible, false if not accessible and nil for non-relatable items
  # rubocop:disable Style/ReturnNilInPredicateMethodDefinition -- nil and false mean different
  #   things here, as the doc above says: nil is "no live user list at all", false is "this owner
  #   may not see it". Callers treat both as falsy, the specs tell them apart.
  def target_accessible_to_owner?
    return if !relatable?

    record = live_user_entity
    return if !record

    query = self.class.taskbar_live_user_pundit_methods.fetch(key_match[:model])

    # Bang: a model that opted into live users without having a policy is a bug, not a state.
    Pundit.policy!(user, record).public_send(query)
  end
  # rubocop:enable Style/ReturnNilInPredicateMethodDefinition

  # Checks if taskbar should update related taskbars
  # to make sure each taskbar includes siblings
  # for displaying active users in frontend
  def relatable?
    return false if !key_match

    self.class.taskbar_live_user_pundit_methods.key?(key_match[:model])
  end

  # The record the live user list of this taskbar belongs to, or nil for a key that names none -
  #   a deleted record, a create screen's UUID, a legacy key format.
  #
  # The class comes from the known taskbar models rather than from constantizing the
  #   (client-provided) key, and so does the id: KEY_REGEXP keeps a qualifier behind it out of the
  #   lookup, where it would survive as nothing but an integer type cast.
  def live_user_entity
    return if !relatable?

    self.class.entity_class_for_key_prefix(key_match[:model])&.find_by(id: key_match[:id])
  end

  private

  # Not memoized: a taskbar is saved with the key it was built with, and a stale match would be a
  #   silent one. The regexp runs a handful of times per save.
  def key_match
    key.match(KEY_REGEXP)
  end

  def update_last_contact
    return if local_update
    return if changes.blank?
    return if changed_only_prio?
    return if changed_only_notify?

    self.last_contact = Time.zone.now
  end

  def set_user
    return if local_update
    return if !UserInfo.current_user_id

    self.user_id = UserInfo.current_user_id
  end

  def update_preferences_infos
    return if !relatable?
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

  def changed_only_notify?
    changed_attribute_names_to_save.to_set == Set.new(%w[updated_at notify])
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
    return if !relatable?
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

  def log_recent_close
    return if !ActiveRecord::Base.connection.data_source_exists?('recent_closes')

    object = to_object

    return if !object
    return if !User.exists?(user.id)

    RecentClose.upsert_closing_time!(user, to_object)
  end
end
