# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Mention::Subscribe < Mention::Base
    description 'Subscribe to updates to an object.'

    argument :object_id, GraphQL::Types::ID, description: 'Object to subscribe to'

    field :success, Boolean, description: 'Was the mutation successful?'

    def resolve(object_id:)
      object = fetch_object(object_id)

      { success: ::Mention.subscribe!(object, context.current_user) }
    end
  end
end
