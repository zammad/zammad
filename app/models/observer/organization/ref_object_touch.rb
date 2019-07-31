# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

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
    return true if Setting.get('import_mode')

    # feature used for different purpose; do not touch references
    return true if User.where(organization_id: record.id).count > 100

    # touch organizations tickets
    Ticket.select('id').where(organization_id: record.id).pluck(:id).each do |ticket_id|
      ticket = Ticket.find(ticket_id)
      ticket.with_lock do
        ticket.touch # rubocop:disable Rails/SkipsModelValidations
      end
    end

    # touch current members
    User.select('id').where(organization_id: record.id).pluck(:id).each do |user_id|
      user = User.find(user_id)
      user.with_lock do
        user.touch # rubocop:disable Rails/SkipsModelValidations
      end
    end
    true
  end
end
