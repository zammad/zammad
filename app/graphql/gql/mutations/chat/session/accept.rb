# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Chat::Session::Accept < BaseMutation
    description 'Take the longest waiting customer of the given topic, or of the topics the current agent handles'

    argument :topic_id, GraphQL::Types::ID, required: false, description: 'The topic to take a customer from'

    field :session, Gql::Types::Chat::SessionType, description: 'The accepted chat session'

    requires_permission 'chat.agent'
    requires_enabled_setting 'chat'

    def resolve(topic_id: nil)
      topic = Gql::ZammadSchema.verified_object_from_id(topic_id, type: ::Chat) if topic_id

      { session: Service::Chat::Session::Accept.with_current_user(context.current_user).execute(topic:) }
    rescue Exceptions::UnprocessableContent => e
      error_response({ message: e.message })
    end
  end
end
