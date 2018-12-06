# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class Ticket
  class Article
    module ChecksAccess
      extend ActiveSupport::Concern

      # Checks the given access of a given user for a ticket article.
      #
      # @param [User] The user that will be checked for given access.
      # @param [String] The access that should get checked.
      #
      # @example
      #  article.access?(user, 'read')
      #  #=> true
      #
      # @return [Boolean]
      def access?(user, access)
        if user.permissions?('ticket.customer')
          return false if internal == true
        end

        ticket = Ticket.lookup(id: ticket_id)
        ticket.access?(user, access)
      end

      # Checks the given access of a given user for a ticket article and fails with an exception.
      #
      # @param (see Ticket::Article#access?)
      #
      # @example
      #  article.access!(user, 'read')
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
end
