# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::Article
  class SecurityStateType < Gql::Types::BaseObject
    description 'Ticket article security information, e.g. for S/MIME'

    field :type, String, description: 'Used security method (currently only S/MIME available)'
    field :signing_success, Boolean
    field :signing_message, String
    field :encryption_success, Boolean
    field :encryption_message, String

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
