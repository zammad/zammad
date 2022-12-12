# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class MentionType < BaseObject
    include Gql::Types::Concerns::IsModelObject

    description 'Mention'

    belongs_to :user,        Gql::Types::UserType,   null: false
    belongs_to :mentionable, Gql::Types::TicketType, null: false
  end
end
