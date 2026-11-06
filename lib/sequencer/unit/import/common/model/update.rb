# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Model::Update < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_any_action

  uses :instance, :mapped
  provides :action

  def process
    # check if no instance is given - so we can't update it
    return if !instance

    # Locking reloads the instance, which is wasted on the common case of an
    #   unchanged record, so only lock if the mapped attributes change anything.
    if !assign_mapped
      state.provide(:action, :unchanged)
      return
    end

    # Locking refuses a record with unsaved changes.
    instance.restore_attributes

    # lock the current instance for write access
    instance.with_lock do
      action = assign_mapped ? :updated : :unchanged
      state.provide(:action, action)
    end
  rescue => e
    handle_failure(e)
  end

  private

  def assign_mapped
    # delete since we have an update and
    # the record is already created
    mapped.delete(:created_by_id)
    mapped.delete(:created_at)

    # assign regular attributes
    instance.assign_attributes(mapped)

    changed?
  end

  def changed?
    changes = attribute_changes
    logger.debug { "Changed instance attributes: #{changes.inspect}" }
    changes.present?
  end

  def attribute_changes
    if instance.has_changes_to_save?
      # dry run
      instance.changes_to_save
    else
      # live run
      instance.previous_changes
    end
  end
end
