# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# If a user is assigned to another organization, also assign their latest tickets to it.
module User::UpdatesTicketOrganization
  extend ActiveSupport::Concern

  included do
    after_create  :user_update_ticket_organization
    after_update  :user_update_ticket_organization
  end

  private

  def user_update_ticket_organization

    # check if organization has changed
    return true if !saved_change_to_attribute?('organization_id')

    # update last 100 tickets of user
    tickets = Ticket.where(customer_id: id).limit(100)
    tickets.each do |ticket|
      if ticket.organization_id != organization_id
        ticket.organization_id = organization_id
        ticket.save
      end
    end
  end
end
