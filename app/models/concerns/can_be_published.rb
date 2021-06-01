# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module CanBePublished
  extend ActiveSupport::Concern

  def can_be_published_aasm
    @can_be_published_aasm ||= StateMachine.new(self)
  end

  def visible?
    can_be_published_aasm.published?
  end

  def visible_internally?
    can_be_published_aasm.internal? || visible?
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
    after_save  :schedule_touch

    after_save    :update_active_publicly
    after_destroy :update_active_publicly
    after_touch   :update_active_publicly

    %i[archived published internal].each do |scope_name|
      local  = :"#{scope_name}_by"
      remote = inverse_relation_name(scope_name).to_sym

      belongs_to local, class_name: 'User', inverse_of: remote, optional: true

      User.has_many remote, class_name: model_name, inverse_of: local, foreign_key: "#{local}_id"
      User.association_attributes_ignored remote
    end

    scope :published, lambda {
      timestamp = Time.zone.now

      date_earlier(:published_at, timestamp).date_later_or_nil(:archived_at, timestamp)
    }

    scope :archived, lambda {
      timestamp = Time.zone.now

      date_earlier(:archived_at, timestamp)
    }

    scope :only_internal, lambda {
      timestamp = Time.zone.now

      date_earlier(:internal_at, timestamp)
        .date_later_or_nil(:archived_at,  timestamp)
        .date_later_or_nil(:published_at, timestamp)
    }

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

    scope :check_published_unless_editor, lambda { |user|
      return if user&.permissions? 'knowledge_base.editor'

      published
    }

    scope :check_internal_unless_editor, lambda { |user|
      return if user&.permissions? 'knowledge_base.editor'

      return internal if user&.permissions? 'knowledge_base.reader'

      published
    }
  end

  def update_user_references
    return if can_be_published_aasm.aasm.current_event.present? # state machine is handling it

    %i[archived internal published].each do |scope_name|
      update_user_reference_item(scope_name)
    end
  end

  def update_user_reference_item(scope_name)
    return if !send("#{scope_name}_at_changed?")

    send("#{scope_name}_by_id=", UserInfo.current_user_id)
  end

  def archived_after_internal
    return if internal_at.nil? || archived_at.nil? || archived_at >= internal_at

    errors.add(:archived_at, 'date must be no earlier than internal at date')
  end

  def archived_after_published
    return if published_at.nil? || archived_at.nil? || archived_at >= published_at

    errors.add(:archived_at, 'date must be no earlier than published at date')
  end

  def published_after_internal
    return if published_at.nil? || internal_at.nil? || published_at >= internal_at

    errors.add(:published_at, 'date must be no earlier than internal at date')
  end

  def schedule_touch_for(attr)
    date = saved_changes[attr]&.last

    return if date.nil? || date <= Time.zone.now

    ScheduledTouchJob.touch_at(self, date)
  end

  def schedule_touch
    %i[published_at archived_at].each { |attr| schedule_touch_for(attr) }
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
