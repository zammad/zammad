# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::User::RefObjectTouch < ActiveRecord::Observer
  observe 'user'

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

    organization_id_changed = record.saved_changes['organization_id']
    return true if !organization_id_changed

    return true if organization_id_changed[0] == organization_id_changed[1]

    # touch old organization
    if organization_id_changed[0]
      organization = Organization.find(organization_id_changed[0])
      organization.touch # rubocop:disable Rails/SkipsModelValidations
    end

    # touch new/current organization
    if record&.organization
      record.organization.touch # rubocop:disable Rails/SkipsModelValidations
    end

    true
  end
end
