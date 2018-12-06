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
    def access?(requester, access)
      # full admins can do whatever they want
      return true if requester.permissions?('admin')

      send("#{access}able_by?".to_sym, requester)
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

    private

    def readable_by?(requester)
      return true if own_account?(requester)
      return true if requester.permissions?('admin.*')
      return true if requester.permissions?('ticket.agent')
      # check same organization for customers
      return false if !requester.permissions?('ticket.customer')

      same_organization?(requester)
    end

    def changeable_by?(requester)
      return true if requester.permissions?('admin.user')
      # allow agents to change customers
      return false if !requester.permissions?('ticket.agent')

      permissions?('ticket.customer')
    end

    def deleteable_by?(requester)
      requester.permissions?('admin.user')
    end

    def own_account?(requester)
      id == requester.id
    end

    def same_organization?(requester)
      return false if organization_id.blank?
      return false if requester.organization_id.blank?

      organization_id == requester.organization_id
    end
  end
end
