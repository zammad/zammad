# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class AppVersion < BaseSubscription

    description 'Application update/change messages'

    field :message, Gql::Types::Enum::AppVersionMessageType, null: true, description: 'App version message'

    def update
      { message: object }
    end

    def self.register_in_schema(schema)
      schema.field :app_version, resolver: self, broadcastable: true
    end
  end
end
