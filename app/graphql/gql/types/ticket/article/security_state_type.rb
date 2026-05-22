# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::Article
  class SecurityStateType < Gql::Types::BaseObject
    description 'Ticket article security information, e.g. for S/MIME'

    field :type, Gql::Types::Enum::SecurityStateTypeType, description: 'The used email security method'
    field :signing_success, Boolean
    field :signing_message, String
    field :encryption_success, Boolean # rubocop:disable Zammad/GraphqlForbidSensitiveFields -- Boolean status of S/MIME encryption, not key material.
    field :encryption_message, String # rubocop:disable Zammad/GraphqlForbidSensitiveFields -- Human-readable status message about S/MIME encryption, not encrypted content.

    # Map the security preference date to the flattened SecurityStateType.
    def signing_success
      @object.dig('sign', 'success')
    end

    def signing_message
      @object.dig('sign', 'comment')
    end

    def encryption_success
      @object.dig('encryption', 'success')
    end

    def encryption_message
      @object.dig('encryption', 'comment')
    end
  end
end
