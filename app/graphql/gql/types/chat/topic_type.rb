# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Chat::TopicType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasInternalIdField

    description 'Chat topic, the queue the customers of a website chat wait in'

    field :name, String, null: false
    field :active, Boolean, null: false
  end
end
