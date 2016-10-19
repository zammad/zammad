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
    return if Setting.get('import_mode')

    # touch old organization if changed
    member_ids = []
    organization_id_changed = record.changes['organization_id']
    if organization_id_changed && organization_id_changed[0] != organization_id_changed[1]
      if organization_id_changed[0]
        organization = Organization.find(organization_id_changed[0])
        organization.touch
        member_ids = organization.member_ids
      end
    end

    # touch new/current organization
    if record.organization
      record.organization.touch
      member_ids += record.organization.member_ids
    end

    # touch old/current customer
    member_ids.uniq.each { |user_id|
      if user_id != record.id
        User.find(user_id).touch
      end
    }
  end
end
