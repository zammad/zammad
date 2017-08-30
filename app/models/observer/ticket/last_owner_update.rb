# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::LastOwnerUpdate < ActiveRecord::Observer
  observe 'ticket'

  def before_create(record)
    _check('create', record)
  end

  def before_update(record)
    _check('update', record)
  end

  private

  def _check(type, record)

    # return if we run import mode
    return true if Setting.get('import_mode')

    # check if owner has changed
    if type == 'update'
      return true if record.changes['owner_id'].blank?
    end

    # check if owner is nobody
    if record.owner_id.blank? || record.owner_id == 1
      record.last_owner_update_at = nil
      return true
    end

    record.last_owner_update_at = Time.zone.now
  end
end
