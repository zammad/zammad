# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Issue5191EnsureSingleMergedState < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    if !merged_named_and_type_state
      rename_oldest_merged_state
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
        .tap do |elem|
          elem.name = 'merged'
          elem.save! validate: false
        end
    end
  end
end
