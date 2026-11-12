# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Chat::SessionType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasInternalIdField

    description 'Chat session of one customer, from the queue of a topic to its end'

    belongs_to :user, Gql::Types::UserType, null: true, description: 'The agent who accepted the session'

    field :name, String, null: true, description: 'Name an agent gave the conversation'
    field :tags, [String, { null: false }], null: false, method: :tag_list, description: 'Tags an agent gave the conversation'
    field :state, Gql::Types::Enum::Chat::SessionStateType, null: false
    field :topic, Gql::Types::Chat::TopicType, null: false, description: 'The topic whose queue the customer entered'
    field :url, String, null: true, description: 'Page the customer started the chat on'
    field :remote_ip, String, null: true
    field :geo_ip, Gql::Types::Chat::Session::GeoIpType, null: true, description: 'Location looked up for the remote IP, when a GeoIP backend is configured'
    field :dns_name, String, null: true, description: 'Reverse DNS name of the remote IP'
    field :messages, [Gql::Types::Chat::MessageType, { null: false }], null: false, description: 'The conversation so far, oldest first; empty unless the current user may read it'

    # The model names the topic after its table; the batch loader stands in for the
    #   belongs_to macro, which resolves by the association name.
    def topic
      Gql::RecordLoader.for(::Chat).load(object.chat_id)
    end

    def url
      object.preferences[:url].presence
    end

    def remote_ip
      object.preferences[:remote_ip].presence
    end

    def geo_ip
      object.preferences[:geo_ip].presence
    end

    def dns_name
      object.preferences[:dns_name].presence
    end

    # Lists show the sessions of the topics to anyone who sees the topics; the conversation is for chat agents.
    def messages
      return [] if !Pundit.policy(context.current_user, object).read_conversation?

      Gql::Loaders::Chat::SessionMessagesLoader.load(object.id)
    end
  end
end
