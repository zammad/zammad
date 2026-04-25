# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class OnlineNotification::MetaType < Gql::Types::BaseObject
    description 'Meta information for an online notification'

    field :created_by_ai, Boolean, null: false

    def created_by_ai
      object['created_by_ai'] || false
    end
  end
end
