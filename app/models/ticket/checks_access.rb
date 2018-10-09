# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class Ticket
  module ChecksAccess
    extend ActiveSupport::Concern

    # Checks the given access of a given user for a ticket.
    #
    # @param [User] The user that will be checked for given access.
    # @param [String] The access that should get checked.
    #
    # @example
    #  ticket.access?(user, 'read')
    #  #=> true
    #
    # @return [Boolean]
    def access?(user, access)

      # check customer
      if user.permissions?('ticket.customer')

        # access ok if its own ticket
        return true if customer_id == user.id

        # check organization ticket access
        return false if organization_id.blank?
        return false if user.organization_id.blank?
        return false if organization_id != user.organization_id

        return organization.shared?
      end

      # check agent

      # access if requestor is owner
      return true if owner_id == user.id

      # access if requestor is in group
      user.group_access?(group.id, access)
    end

    # Checks the given access of a given user for a ticket and fails with an exception.
    #
    # @param (see Ticket#access?)
    #
    # @example
    #  ticket.access!(user, 'read')
    #
    # @raise [NotAuthorized] Gets raised if given user doesn't have the given access.
    #
    # @return [nil]
    def access!(user, access)
      return if access?(user, access)

      raise Exceptions::NotAuthorized
    end
  end
end
