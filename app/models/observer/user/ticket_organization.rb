# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::User::TicketOrganization < ActiveRecord::Observer
  observe 'user'

  def after_create(record)
    check_organization(record)
  end

  def after_update(record)
    check_organization(record)
  end

  # check if organization need to be updated
  def check_organization(record)

    # check if organization has changed
    return true if !record.saved_change_to_attribute?('organization_id')

    # update last 100 tickets of user
    tickets = Ticket.where(customer_id: record.id).limit(100)
    tickets.each do |ticket|
      if ticket.organization_id != record.organization_id
        ticket.organization_id = record.organization_id
        ticket.save
      end
    end
  end

end
