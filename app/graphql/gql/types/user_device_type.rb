# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    def location
      city_name = object.location_details['city_name']
      country   = object.location

      return country if city_name.blank?
      return city_name if country.blank? || country == 'unknown'

      "#{country}, #{city_name}"
    end
  end
end
