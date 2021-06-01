# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Adds a last_owner_update time on ticket changes.
module Ticket::SetsLastOwnerUpdateTime
  extend ActiveSupport::Concern

  included do
    before_create  :ticket_set_last_owner_update_time
    before_update  :ticket_set_last_owner_update_time
  end

  private

  def ticket_set_last_owner_update_time

    # return if we run import mode
    return true if Setting.get('import_mode')
    # check if owner, state or group has changed
    return true if changes_to_save['owner_id'].blank? && changes_to_save['state_id'].blank? && changes_to_save['group_id'].blank? && changes_to_save['last_contact_agent_at'].blank?

    # check if owner is nobody
    if changes_to_save['owner_id'].present? && changes_to_save['owner_id'][1] == 1
      self.last_owner_update_at = nil
      return true
    end

    # check if group is change
    if changes_to_save['group_id'].present?
      group = Group.lookup(id: changes_to_save['group_id'][1])
      return true if !group

      if group.assignment_timeout.blank? || group.assignment_timeout.zero?
        self.last_owner_update_at = nil
        return true
      end
    end

    # check if state is not new/open
    if changes_to_save['state_id'].present?
      state_ids = Ticket::State.by_category(:work_on).pluck(:id)
      if state_ids.exclude?(changes_to_save['state_id'][1])
        self.last_owner_update_at = nil
        return true
      end
    end

    self.last_owner_update_at = Time.zone.now
  end
end
