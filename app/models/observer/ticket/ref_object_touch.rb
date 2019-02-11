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
    return true if Setting.get('import_mode')

    # touch old customer if changed
    cutomer_id_changed = record.saved_changes['customer_id']
    if cutomer_id_changed && cutomer_id_changed[0] != cutomer_id_changed[1]
      if cutomer_id_changed[0]
        User.find(cutomer_id_changed[0]).touch # rubocop:disable Rails/SkipsModelValidations
      end
    end

    # touch new/current customer
    record.customer&.touch # rubocop:disable Rails/SkipsModelValidations

    # touch old organization if changed
    organization_id_changed = record.saved_changes['organization_id']
    if organization_id_changed && organization_id_changed[0] != organization_id_changed[1]
      if organization_id_changed[0]
        Organization.find(organization_id_changed[0]).touch # rubocop:disable Rails/SkipsModelValidations
      end
    end

    # touch new/current organization
    return true if !record.organization

    record.organization.touch # rubocop:disable Rails/SkipsModelValidations
  end
end
