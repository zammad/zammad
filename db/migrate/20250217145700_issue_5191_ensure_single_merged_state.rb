# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue5191EnsureSingleMergedState < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    rename_non_merged_type_merged_named_state

    if !merged_named_and_type_state
      rename_oldest_merged_state
      create_merged_type_merged_named_state_if_needed
    end

    change_later_merged_to_closed
  end

  private

  def merged_type_states
    Ticket::State.joins(:state_type).where(state_type: { name: 'merged' })
  end

  def target_state_type
    Ticket::StateType.find_by name: 'closed'
  end

  def merged_named_and_type_state
    merged_type_states.find_by(name: 'merged')
  end

  def change_later_merged_to_closed
    merged_type_states
      .where.not(name: 'merged')
      .each do |record|
        record.update! state_type: target_state_type
      end
  end

  def rename_oldest_merged_state
    Ticket::State.without_callback(:update, :before, :prevent_merged_state_editing) do
      merged_type_states
        .where.not(name: 'merged')
        .reorder('id ASC')
        .first
        &.tap do |elem|
          elem.name = 'merged'
          elem.save! validate: false
        end
    end
  end

  def rename_non_merged_type_merged_named_state
    Ticket::State.without_callback(:update, :before, :prevent_merged_state_editing) do
      Ticket::State
        .joins(:state_type)
        .where(name: 'merged')
        .where.not(state_type: { name: 'merged' })
        .first
        &.tap do |elem|
          elem.name = "merged (#{elem.state_type.name})"
          elem.save! validate: false
        end
    end
  end

  def create_merged_type_merged_named_state_if_needed
    return if Ticket::State.exists?(name: 'merged')

    Ticket::State.without_callback(:update, :before, :prevent_merged_state_editing) do
      Ticket::State.create!(
        name:          'merged',
        state_type:    Ticket::StateType.lookup(name: 'merged'),
        created_by_id: 1,
        updated_by_id: 1
      )
    end
  end
end
