# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Mention::Unsubscribe < Mention::Base
    description 'Unsubscribe from updates to an object.'

    argument :object_id, GraphQL::Types::ID, description: 'Object to unsubscribe from'

    field :success, Boolean, description: 'Was the mutation successful?'

    def resolve(object_id:)
      object = fetch_object(object_id)

      { success: ::Mention.unsubscribe!(object, context.current_user) }
    end
  end
end
