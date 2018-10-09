# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class Organization
  module ChecksAccess
    extend ActiveSupport::Concern

    # Checks the given access of a given user for an organization.
    #
    # @param [User] The user that will be checked for given access.
    # @param [String] The access that should get checked.
    #
    # @example
    #  organization.access?(user, 'read')
    #  #=> true
    #
    # @return [Boolean]
    def access?(user, access)

      # check customer
      if user.permissions?('ticket.customer')

        # access ok if its own organization
        return false if access != 'read'
        return false if !user.organization_id

        return id == user.organization_id
      end

      # check agent
      return true if user.permissions?('admin')
      return true if user.permissions?('ticket.agent')

      false
    end

    # Checks the given access of a given user for an organization and fails with an exception.
    #
    # @param (see Organization#access?)
    #
    # @example
    #  organization.access!(user, 'read')
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
