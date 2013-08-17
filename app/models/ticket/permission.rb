# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

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
    if data[:current_user].is_role('Customer')

      # access ok if its own ticket
      return true if self.customer_id == data[:current_user].id

      # access ok if its organization ticket
      if data[:current_user].organization_id && self.organization_id
        return true if self.organization_id == data[:current_user].organization_id
      end

      # no access
      return false
    end

    # check agent

    # access if requestor is owner
    return true if self.owner_id == data[:current_user].id

    # access if requestor is in group
    data[:current_user].groups.each {|group|
      return true if self.group.id == group.id
    }
    return false
  end

end