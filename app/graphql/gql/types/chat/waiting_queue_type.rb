# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Chat::WaitingQueueType < Gql::Types::BaseObject
    description 'The customers waiting in one chat topic, longest waiting first'

    field :topic, Gql::Types::Chat::TopicType, null: false
    field :sessions, [Gql::Types::Chat::SessionType, { null: false }], null: false
  end
end
