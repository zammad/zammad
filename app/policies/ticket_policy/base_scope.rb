# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    def resolve
      raise NoMethodError, <<~ERR.chomp if instance_of?(TicketPolicy::BaseScope)
        specify an access type using a subclass of TicketPolicy::BaseScope
      ERR

      sql  = []
      bind = []

      if user.permissions?('ticket.agent')
        sql.push('tickets.group_id IN (?)')
        bind.push(user.group_ids_access(self.class::ACCESS_TYPE))
      end

      customer_sql, customer_bind = customer_conditions
      sql.concat(customer_sql)
      bind.concat(customer_bind)

      sql.push '0 = 1' if sql.empty? # Forbid unlimited access for all other permissions.

      scope.where sql.join(' OR '), *bind
    end

    # The organizations whose tickets the user may see as a customer.
    def shared_organization_ids
      return [] if !user.permissions?('ticket.customer') || user.all_organization_ids.blank?

      @shared_organization_ids ||= Organization.where(id: user.all_organization_ids, shared: true).pluck(:id)
    end

    # #resolve is UNDEFINED BEHAVIOR for the abstract base class (but not its subclasses)
    def respond_to?(*args)
      return false if args.first.to_s == 'resolve' && instance_of?(TicketPolicy::BaseScope)

      super
    end

    private

    def customer_conditions
      return [[], []] if !user.permissions?('ticket.customer')

      sql  = ['tickets.customer_id = ?']
      bind = [user.id]

      shared_organization_ids.each do |organization_id|
        sql.push('tickets.organization_id = ?')
        bind.push(organization_id)
      end

      [sql, bind]
    end
  end
end
