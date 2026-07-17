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
        sql.push('group_id IN (?)')
        bind.push(user.group_ids_access(self.class::ACCESS_TYPE))
      end

      if user.permissions?('ticket.customer')
        sql.push('tickets.customer_id = ?')
        bind.push(user.id)

        append_participant_scope!(sql, bind)

        if user.all_organization_ids.present?
          Organization.where(id: user.all_organization_ids).select(&:shared).each do |organization|
            sql.push('tickets.organization_id = ?')
            bind.push(organization.id)
          end
        end
      end

      sql.push '0 = 1' if sql.empty? # Forbid unlimited access for all other permissions.

      scope.where sql.join(' OR '), *bind
    end

    # #resolve is UNDEFINED BEHAVIOR for the abstract base class (but not its subclasses)
    def respond_to?(*args)
      return false if args.first.to_s == 'resolve' && instance_of?(TicketPolicy::BaseScope)

      super
    end

    private

    def append_participant_scope!(sql, bind)
      return if !Setting.get('ticket_participants_enabled')
      # Participant tickets are read-only and user-specific. Only ReadScope is safe:
      # - ChangeScope/FullScope: participants must not edit (already blocked by change_access?)
      # - OverviewScope: overview cache keys are not user-specific, so participant tickets
      #   would leak across customers with the same group permissions (privacy).
      # (Overview visibility for participants is a known limitation — see NEU-29.)
      return if self.class::ACCESS_TYPE != :read

      # Exclude agent users — agents get access through group access, not participant scope.
      # A mentioned agent who loses group access should not retain read access via mentions.
      agent_user_ids = User.with_permissions('ticket.agent').pluck(:id)

      participant_ticket_ids = Mention.joins(:user)
                                      .where(mentionable_type: 'Ticket', user_id: user.id, users: { active: true })
                                      .where.not(user_id: agent_user_ids)
                                      .pluck(:mentionable_id)
      return if participant_ticket_ids.blank?

      sql.push('tickets.id IN (?)')
      bind.push(participant_ticket_ids)
    end
  end
end
