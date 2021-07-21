# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Abstract base class for various "types" of ticket access.
#
# Do NOT instantiate directly; instead,
# choose the appropriate subclass from below
# (see commit message for details).
class TicketPolicy < ApplicationPolicy
  class BaseScope < ApplicationPolicy::Scope

    # overwrite PunditPolicy#initialize to make `context` optional and use Ticket as default
    def initialize(user, context = Ticket)
      super
    end

    def resolve # rubocop:disable Metrics/AbcSize
      raise NoMethodError, <<~ERR.chomp if instance_of?(TicketPolicy::BaseScope)
        specify an access type using a subclass of TicketPolicy::BaseScope
      ERR

      sql  = []
      bind = []

      if user.permissions?('ticket.agent')
        sql.push('group_id IN (?)')
        bind.push(user.group_ids_access(self.class::ACCESS_TYPE))
      end

      if user.organization&.shared
        sql.push('(tickets.customer_id = ? OR tickets.organization_id = ?)')
        bind.push(user.id, user.organization.id)
      else
        sql.push('tickets.customer_id = ?')
        bind.push(user.id)
      end

      scope.where sql.join(' OR '), *bind
    end

    # #resolve is UNDEFINED BEHAVIOR for the abstract base class (but not its subclasses)
    def respond_to?(*args)
      return false if args.first.to_s == 'resolve' && instance_of?(TicketPolicy::BaseScope)

      super(*args)
    end
  end
end
