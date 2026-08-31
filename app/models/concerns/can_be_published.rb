# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module CanBePublished
  extend ActiveSupport::Concern

  # Every publication state that can be scheduled, and the timestamp it is stored in — named after
  #   the schedulable states rather than after the columns, since that is what a caller names
  #   (Gql::Types::Enum::KnowledgeBase::SchedulableVisibilityType offers exactly these).
  #
  # In the order their timestamps have to run, which is also the order the current state is derived
  #   in: the last one whose timestamp has passed wins
  #   (CanBePublished::StateMachine#calculated_state asks in reverse).
  #
  # `draft` is not in here, which is what makes the set the schedulable one: it is what no timestamp
  #   at all means, so there is nothing to put in the future for it.
  #
  # Listed rather than interpolated from the state name: a state can arrive from outside, and the
  #   columns a caller may write are none of its choosing.
  SCHEDULABLE_VISIBILITIES = {
    internal:  :internal_at,
    published: :published_at,
    archived:  :archived_at,
  }.freeze

  def can_be_published_aasm
    @can_be_published_aasm ||= StateMachine.new(self)
  end

  def visible?
    can_be_published_aasm.published?
  end

  def visible_internally?
    can_be_published_aasm.internal? || visible?
  end

  def visibility
    can_be_published_aasm.current_state
  end

  # The transitions whose timestamp has not been reached yet, in the order they will take effect —
  #   which is their rank order, since the ordering validations below only let the timestamps run
  #   that way.
  #
  # Scheduled transitions, as opposed to the state the record is in: #visibility derives that from
  #   the timestamps that have already passed. Both are read off the very same columns, so this is
  #   the one place that says which of them is still ahead.
  def visibility_schedules
    SCHEDULABLE_VISIBILITIES.each_key.filter_map do |state|
      date = visibility_scheduled_at(state)

      { visibility: state, scheduled_at: date } if date
    end
  end

  # When the record is scheduled to reach the given state, or nil if it is not scheduled to at all.
  #   A timestamp that has already passed is how the record got where it is, not a schedule.
  #
  # @param state [Symbol] one of CanBePublished::SCHEDULABLE_VISIBILITIES' keys — `draft` has no
  #   timestamp of its own and is therefore not among them.
  def visibility_scheduled_at(state)
    date = self[SCHEDULABLE_VISIBILITIES.fetch(state)]

    date if date.present? && date.future?
  end

  class_methods do
    def inverse_relation_name(scope_name)
      "can_be_published_#{scope_name}_#{model_name.plural}"
    end
  end

  included do
    validate    :archived_after_internal
    validate    :archived_after_published
    validate    :published_after_internal
    before_save :update_user_references

    after_save_commit :schedule_touch

    after_save    :update_active_publicly
    after_destroy :update_active_publicly
    after_touch   :update_active_publicly

    %i[archived published internal].each do |scope_name|
      local  = :"#{scope_name}_by"
      remote = inverse_relation_name(scope_name).to_sym

      belongs_to local, class_name: 'User', inverse_of: remote, optional: true

      # Deletion of users is handled in User.destroy_move_dependency_ownership and resets fields to user_id: 1, so skip dependent: here.
      User.has_many remote, class_name: model_name, inverse_of: local, foreign_key: "#{local}_id" # rubocop:disable Rails/HasManyOrHasOneDependent
      User.association_attributes_ignored remote
    end

    # Returns answers according to given KnowledgeBase::AccessibleCategories::CategoriesStruct
    #
    # @param [KnowledgeBase::AccessibleCategories::CategoriesStruct] accessible_categories
    # @param [KnowledgeBase::Locale] kb_locale limits non-editor access to answers translated to the given locale
    scope :visible_by_categories, lambda { |accessible_categories, kb_locale: nil|
      reader_scope = all.internal.where(category: accessible_categories.reader)
      public_scope = all.published.where(category: accessible_categories.public_reader)

      if kb_locale
        reader_scope = reader_scope.translated_to(kb_locale)
        public_scope = public_scope.translated_to(kb_locale)
      end

      all.where(category: accessible_categories.editor)
        .or(reader_scope)
        .or(public_scope)
    }

    # Returns answers accessible to the given user
    # This method also evaluates if granular permissions are enabled
    #
    # @param [User] user
    # @param [KnowledgeBase::Locale] kb_locale limits non-editor access to answers translated
    #   to the given locale, mirroring the agent app (editors also see untranslated content)
    scope :visible_to_user, lambda { |user, kb_locale: nil|
      case KnowledgeBase.access_for_user(user)
      when :granular
        visible_by_categories(KnowledgeBase::AccessibleCategories.for_user(user), kb_locale:)
      when :editor
        all
      when :reader
        kb_locale ? internal.translated_to(kb_locale) : internal
      else
        kb_locale ? published.translated_to(kb_locale) : published
      end
    }

    # Returns all currently published answers
    scope :published, lambda {
      timestamp = Time.zone.now

      date_earlier(:published_at, timestamp).date_later_or_nil(:archived_at, timestamp)
    }

    # Returns all archived answers
    # Note: this method disregards granular permissions
    # @see .visible_to_user
    scope :archived, lambda {
      timestamp = Time.zone.now

      date_earlier(:archived_at, timestamp)
    }

    # Returns all internally published answers
    # Note: this method disregards granular permissions
    # @see .visible_to_user
    scope :only_internal, lambda {
      timestamp = Time.zone.now

      date_earlier(:internal_at, timestamp)
        .date_later_or_nil(:archived_at,  timestamp)
        .date_later_or_nil(:published_at, timestamp)
    }

    # Returns all answers visible internally, both internally and publicly published
    # Note: this method disregards granular permissions
    # @see .visible_to_user
    #
    # @see .only_internal
    scope :internal, lambda {
      timestamp = Time.zone.now

      internal = arel_table[:internal_at].lt(timestamp)
      published = arel_table[:published_at].lt(timestamp)

      where(internal.or(published))
        .date_later_or_nil(:archived_at, timestamp)
    }

    scope :date_earlier, lambda { |field, timestamp|
      where arel_table[field].lt(timestamp)
    }

    scope :date_later_or_nil, lambda { |field, timestamp|
      where arel_table[field].gt(timestamp).or(arel_table[field].eq(nil))
    }
  end

  def update_user_references
    return if can_be_published_aasm.aasm.current_event.present? # state machine is handling it

    %i[archived internal published].each do |scope_name|
      update_user_reference_item(scope_name)
    end
  end

  def update_user_reference_item(scope_name)
    return if !send(:"#{scope_name}_at_changed?")

    send(:"#{scope_name}_by_id=", UserInfo.current_user_id)
  end

  def archived_after_internal
    return if internal_at.nil? || archived_at.nil? || archived_at >= internal_at

    errors.add(:archived_at, __('date must be no earlier than internal date'))
  end

  def archived_after_published
    return if published_at.nil? || archived_at.nil? || archived_at >= published_at

    errors.add(:archived_at, __('date must be no earlier than published date'))
  end

  def published_after_internal
    return if published_at.nil? || internal_at.nil? || published_at >= internal_at

    errors.add(:published_at, __('date must be no earlier than internal date'))
  end

  # Scoped by the column, so each scheduled state keeps its own job: the touches of one record are
  #   otherwise one lock, and a second date - a state scheduled beside another, or the same one
  #   moved - would be dismissed and never fire.
  def schedule_touch_for(attr)
    date = saved_changes[attr]&.last

    return if date.nil? || date <= Time.zone.now

    ScheduledTouchJob.touch_at(self, date, scope: attr.to_s)
  end

  # `internal_at` as well, not only the two dates that decide public availability: a state reached
  #   in the future has to reach the open views at that point, whichever state it is (the schedule
  #   can be set for every state but `draft`, see
  #   Gql::Types::Enum::KnowledgeBase::SchedulableVisibilityType).
  def schedule_touch
    %i[published_at archived_at internal_at].each { |attr| schedule_touch_for(attr) }
  end

  def update_active_publicly
    CanBePublished.update_active_publicly!
  end

  def self.update_active_publicly!
    Setting.set('kb_active_publicly', active_publicly?)
  end

  def self.active_publicly?
    KnowledgeBase::Answer
      .published
      .joins(category: :knowledge_base)
      .exists?(knowledge_bases: { active: true })
  end
end
