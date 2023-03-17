# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Mention::Base < BaseMutation # rubocop:disable GraphQL/ObjectDescription
    protected

    def fetch_object(object_id)
      Gql::ZammadSchema
        .authorized_object_from_id(
          object_id,
          user:  context.current_user,
          query: :agent_read_access?,
          type:  ::Ticket
        )
    end
  end
end
