# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class UserDeviceType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject

    description 'Users (session) device'

    field :user_id, ID, null: false
    field :name, String, null: false
    field :os, String
    field :browser, String
    field :location, String
    field :device_details, GraphQL::Types::JSON
    field :location_details, GraphQL::Types::JSON
    field :fingerprint, String
    field :user_agent, String
    field :ip, String

    def self.authorize(_object, ctx)
      ctx.current_user
    end

    def location
      return object.location if object.location_details['city_name'].blank?

      "#{object.location}, #{object.location_details['city_name']}"
    end
  end
end
