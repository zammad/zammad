class LastOwnerUpdate < ActiveRecord::Migration
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    # reset assignment_timeout to prevent unwanted things happen
    Group.all.each { |group|
      group.assignment_timeout = nil
      group.save!
    }

    add_column :tickets, :last_owner_update_at, :timestamp, limit: 3, null: true
    add_index :tickets, [:last_owner_update_at]
    Ticket.reset_column_information

    Scheduler.create_if_not_exists(
      name: 'Process auto unassign tickets',
      method: 'Ticket.process_auto_unassign',
      period: 10.minutes,
      prio: 1,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    state_ids = Ticket::State.by_category(:work_on).pluck(:id)
    if state_ids.present?
      ticket_ids = Ticket.where('tickets.state_id IN (?) AND tickets.owner_id != 1', state_ids).order(created_at: :desc).limit(1000).pluck(:id)
      ticket_ids.each { |ticket_id|
        ticket = Ticket.find_by(id: ticket_id)
        next if !ticket
        ticket.last_owner_update_at = last_owner_update_at(ticket)
        ticket.save!
      }
    end
  end

  def last_owner_update_at(ticket)
    type = History::Type.lookup(name: 'updated')
    if type
      object = History::Object.lookup(name: 'Ticket')
      if object
        attribute = History::Attribute.lookup(name: 'owner')
        if attribute
          history = History.where(o_id: ticket.id, history_type_id: type.id, history_object_id: object.id, history_attribute_id: attribute.id).where.not(id_to: 1).order(created_at: :desc).limit(1)
          if history.present?
            return history.first.created_at
          end
        end
      end
    end
    return nil if ticket.owner_id == 1
    ticket.created_at
  end

end
