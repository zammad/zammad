# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
module Ticket::Permission

=begin

check if user has access to ticket

  ticket = Ticket.find(123)
  result = ticket.permission( :current_user => User.find(123) )

returns

  result = true|false

=end

  def permission (data)

    # check customer
    if data[:current_user].role?('Customer')

      # access ok if its own ticket
      return true if customer_id == data[:current_user].id

      # access ok if its organization ticket
      if data[:current_user].organization_id && organization_id
        return true if organization_id == data[:current_user].organization_id
      end

      # no access
      return false
    end

    # check agent

    # access if requestor is owner
    return true if owner_id == data[:current_user].id

    # access if requestor is in group
    data[:current_user].groups.each { |group|
      return true if self.group.id == group.id
    }
    false
  end
end
