# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::RefObjectTouch < ActiveRecord::Observer
  observe 'ticket'

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
    if record.customer
      record.customer.touch
    end
    if record.organization
      record.organization.touch
    end
  end
end