# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Organization::RefObjectTouch < ActiveRecord::Observer
  observe 'organization'

  def after_create(record)
    ref_object_touch(record)
  end

  def after_update(record)
    ref_object_touch(record)
  end

  def after_destroy(record)
    ref_object_touch(record)
  end

  def ref_object_touch(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # touch organizations tickets
    Ticket.select('id').where( organization_id: record.id ).each(&:touch)

    # touch current members
    record.member_ids.uniq.each { |user_id|
      User.find(user_id).touch
    }
  end
end
