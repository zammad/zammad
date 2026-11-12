# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  # The lookup result stored with the session, a plain hash from Service::GeoIp.
  class Chat::Session::GeoIpType < Gql::Types::BaseObject
    description 'Location looked up for the remote IP of a chat session'

    field :country_name, String, null: true
    field :country_code, String, null: true
    field :city_name, String, null: true
  end
end
