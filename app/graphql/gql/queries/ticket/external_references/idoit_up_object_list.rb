# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::ExternalReferences::IdoitUpObjectList < BaseQuery

    description 'Detailed i-doit up objects for the given i-doit up object ids or the given ticket'

    argument :input, Gql::Types::Input::Ticket::ExternalReferences::IdoitUpObjectListInputType, description: 'The input to fetch detailed i-doit up objects for the given i-doit up object ids or the given ticket'

    type [Gql::Types::Ticket::ExternalReferences::IdoitUpObjectType], null: false

    requires_permission 'ticket.agent'
    requires_enabled_setting 'idoit_up_integration', error_message: __('i-doit up integration is not enabled')

    def resolve(input:)
      idoit_up_object_ids = if input.ticket.present?
                              input.ticket.preferences.dig(:idoit_up, :object_ids) || []
                            else
                              input.idoit_up_object_ids
                            end

      return [] if idoit_up_object_ids.blank?

      # This code a) ignores ordering of the input ids array and uses the ordering from i-doit up,
      #   and b) will silently skip over not found items.
      #   That's how the legacy frontend also works and thus we'll keep it.
      IdoitUp.query('cmdb.objects', { ids: idoit_up_object_ids }, user: context.current_user)['result']
    end
  end
end
