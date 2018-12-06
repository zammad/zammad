# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::LastOwnerUpdate < ActiveRecord::Observer
  observe 'ticket'

  def before_create(record)
    _check(record)
  end

  def before_update(record)
    _check(record)
  end

  private

  def _check(record)

    # return if we run import mode
    return true if Setting.get('import_mode')

    # check if owner, state or group has changed
    return true if record.changes_to_save['owner_id'].blank? && record.changes_to_save['state_id'].blank? && record.changes_to_save['group_id'].blank? && record.changes_to_save['last_contact_agent_at'].blank?

    # check if owner is nobody
    if record.changes_to_save['owner_id'].present? && record.changes_to_save['owner_id'][1] == 1
      record.last_owner_update_at = nil
      return true
    end

    # check if group is change
    if record.changes_to_save['group_id'].present?
      group = Group.lookup(id: record.changes_to_save['group_id'][1])
      return true if !group

      if group.assignment_timeout.blank? || group.assignment_timeout.zero?
        record.last_owner_update_at = nil
        return true
      end
    end

    # check if state is not new/open
    if record.changes_to_save['state_id'].present?
      state_ids = Ticket::State.by_category(:work_on).pluck(:id)
      if !state_ids.include?(record.changes_to_save['state_id'][1])
        record.last_owner_update_at = nil
        return true
      end
    end

    record.last_owner_update_at = Time.zone.now
  end
end
