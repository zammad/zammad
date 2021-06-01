# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module CanBePublished
  class StateMachine
    include AASM

    delegate :current_state, to: :aasm

    def initialize(record)
      @record = record

      aasm.current_state = calculated_state
    end

    def calculated_state
      matching_time = Time.zone.now

      state = %i[archived published internal].find { |state_name| calculated_state_valid?(state_name, matching_time) }

      state || :draft
    end

    def calculated_state_valid?(state_name, time)
      date = @record.send "#{state_name}_at"

      date.present? && date < time
    end

    def set_timestamp
      override_unarchived_state if aasm.to_state == :unarchived
      @record.send "#{aasm.to_state}_at=", Time.zone.now.change(sec: 0)
    end

    def override_unarchived_state
      aasm.to_state = @record.published_at.present? ? :published : :internal
    end

    def update_using_current_user(user)
      %i[archived internal published].each { |state_name| update_state_using_current_user(user, state_name) }
    end

    def update_state_using_current_user(user, state_name)
      return if !@record.send("#{state_name}_at_changed?")

      new_value = @record.send("#{state_name}_at").present? ? user : nil
      @record.send("#{state_name}_by=", new_value)
    end

    def clear_archived
      @record.archived_at = nil
    end

    def save_record
      @record.save!
    end

    aasm do
      state :draft, initial: true
      state :internal
      state :published
      state :archived
      state :unarchived #magic

      event :internal do
        transitions from:  :draft,
                    to:    :internal,
                    guard: :guard_internal?,
                    after: :set_timestamp
      end

      event :publish do
        transitions from:  %i[draft internal],
                    to:    :published,
                    guard: :guard_publish?,
                    after: :set_timestamp
      end

      event :archive do
        transitions from:  %i[published internal],
                    to:    :archived,
                    guard: :guard_archive?,
                    after: :set_timestamp
      end

      event :unarchive do
        transitions from:  :archived,
                    to:    :unarchived,
                    guard: :guard_unarchive?,
                    after: %i[clear_archived set_timestamp]
      end

      after_all_events    %i[update_using_current_user save_record mark_as_idle]
      error_on_all_events :mark_as_idle
    end

    def mark_as_idle
      aasm.send(:current_event=, nil) # nullify current_event after transitioning
    end

    def guard_internal?
      draft?
    end

    def guard_publish?
      draft? || internal?
    end

    def guard_archive?
      internal? || published?
    end

    def guard_unarchive?
      archived?
    end
  end
end
