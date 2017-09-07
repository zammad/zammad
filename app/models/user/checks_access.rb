# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class User
  module ChecksAccess
    extend ActiveSupport::Concern

    # Checks the given access of a given user for another user.
    #
    # @param [User] The user that will be checked for given access.
    # @param [String] The access that should get checked.
    #
    # @example
    #  user.access?(user, 'read')
    #  #=> true
    #
    # @return [Boolean]
    def access?(user, _access)

      # check agent
      return true if user.permissions?('admin.user')
      return true if user.permissions?('ticket.agent')

      # check customer
      if user.permissions?('ticket.customer')
        # access ok if its own user
        return id == user.id
      end

      false
    end

    # Checks the given access of a given user for another user and fails with an exception.
    #
    # @param (see User#access?)
    #
    # @example
    #  user.access!(user, 'read')
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
