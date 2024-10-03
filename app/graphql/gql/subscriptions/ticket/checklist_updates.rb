# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class Ticket::ChecklistUpdates < BaseSubscription
    include Gql::Concerns::EnsuresChecklistFeatureActive

    description 'Subscription for ticket checklist changes.'

    argument :ticket_id, GraphQL::Types::ID, description: 'Ticket identifier'

    field :ticket_checklist, Gql::Types::ChecklistType, description: 'Ticket checklist'
    field :removed_ticket_checklist, Boolean, description: 'Ticket checklist was removed from ticket'

    def self.authorize(_obj, ctx)
      ensure_checklist_feature_active!
      super
    end

    def authorized?(ticket_id:)
      context.current_user.permissions?('ticket.agent') && Gql::ZammadSchema.authorized_object_from_id(ticket_id, type: ::Ticket, user: context.current_user)
    end

    def update(ticket_id:)
      return { removed_ticket_checklist: true } if object.nil?

      { ticket_checklist: object }
    end
  end
end
