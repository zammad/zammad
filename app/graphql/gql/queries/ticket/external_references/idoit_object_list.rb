# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::ExternalReferences::IdoitObjectList < BaseQuery

    description 'Detailed idoit objects for the given idoit object ids or the given ticket'

    argument :input, Gql::Types::Input::Ticket::ExternalReferences::IdoitObjectListInputType, description: 'The input to fetch detailed idoit objects for the given idoit object ids or the given ticket'

    type [Gql::Types::Ticket::ExternalReferences::IdoitObjectType], null: false

    def self.authorize(_obj, ctx)
      Setting.get('idoit_integration') && ctx.current_user.permissions?('ticket.agent')
    end

    def resolve(input:)
      idoit_object_ids = if input.ticket.present?
                           input.ticket.preferences.dig(:idoit, :object_ids) || []
                         else
                           input.idoit_object_ids
                         end

      return [] if idoit_object_ids.blank?

      # This code a) ignores ordering of the input ids array and uses the ordering from idoit,
      #   and b) will silently skip over not found items.
      #   That's how the legacy frontend also works and thus we'll keep it.
      Idoit.query('cmdb.objects', { ids: idoit_object_ids })['result']
    end
  end
end
