# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

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

    # touch old customer if changed
    cutomer_id_changed = record.changes['customer_id']
    if cutomer_id_changed && cutomer_id_changed[0] != cutomer_id_changed[1]
      if cutomer_id_changed[0]
        User.find(cutomer_id_changed[0]).touch
      end
    end

    # touch new/current customer
    if record.customer
      record.customer.touch
    end

    # touch old organization if changed
    organization_id_changed = record.changes['organization_id']
    if organization_id_changed && organization_id_changed[0] != organization_id_changed[1]
      if organization_id_changed[0]
        Organization.find(organization_id_changed[0]).touch
      end
    end

    # touch new/current organization
    return if !record.organization

    record.organization.touch
  end
end
