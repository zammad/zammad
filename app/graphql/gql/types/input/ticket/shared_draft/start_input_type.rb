# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class Ticket::SharedDraft::StartInputType < Gql::Types::BaseInputObject
    description 'The ticket start draft fields'

    argument :form_id, String, description: 'Form ID to copy attachments from'
    argument :content, GraphQL::Types::JSON, description: 'Content of the draft'
    argument :group_id, GraphQL::Types::ID,
             loads:       Gql::Types::GroupType,
             description: 'Group to put shared draft into'

    transform :wrap_unknown_customer

    # Only the new UI arrives here, holding a customer who does not exist yet as the typed-in
    #   address or number - stored bare, it could not be told from an id the old UI wrote.
    def wrap_unknown_customer(payload)
      payload = payload.to_h
      content = payload[:content]
      return payload if !content.is_a?(Hash) || !content.key?('customer_id')

      payload.merge(content: content.merge('customer_id' => ::FormUpdater::StoreValue::UnknownCustomer.wrap(content['customer_id'])))
    end
  end
end
