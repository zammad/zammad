# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module CanPriorization
  extend ActiveSupport::Concern

  included do
    before_create :fill_prio
    before_update :rearrangement
  end

  def rearrangement
    # rearrange only in case of changed prio
    return true if !changes['prio']

    rearranged_prio = 0
    rearrangement_previous_ordered_ids.each do |entry_id|

      # don't process currently updated entry
      next if id == entry_id

      rearranged_prio += 1

      # increase rearranged prio by one to avoid a collition
      # with the changed prio of current instance
      if rearranged_prio == prio
        rearranged_prio += 1
      end

      rearrange_entry(entry_id, rearranged_prio)
    end
  end

  def fill_prio
    return true if prio.present?

    self.prio = self.class.calculate_prio
    true
  end

  def rearrangement_previous_ordered_ids
    self.class.all.order(
      prio:       :asc,
      updated_at: :desc
    ).pluck(:id)
  end

  def rearrange_entry(id, prio)
    # don't start rearranging logic for entrys that have already been rearranged
    self.class.without_callback(:update, :before, :rearrangement) do
      # fetch and update entry only if prio needs to change
      entry = self.class.where(
        id: id
      ).where.not(
        prio: prio
      ).take

      next if entry.blank?

      entry.update!(prio: prio)
    end
  end

  # methods defined here are going to extend the class, not the instance of it
  class_methods do
    def calculate_prio
      existing_maximum = maximum(:prio)

      return 0 if !existing_maximum

      existing_maximum + 1
    end
  end
end
