# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::ExternalReferences
  class IdoitObjectType < Gql::Types::BaseObject
    description 'Idoit object item for an external reference for a ticket'

    field :idoit_object_id, Integer, null: false, method: :id, description: 'Idoit object id'
    field :title, String, null: false
    field :link, Gql::Types::UriHttpStringType, description: 'Link to the object in the idoit GUI'
    field :type, String, null: false, method: :type_title
    field :status, String, null: false, method: :cmdb_status_title
  end
end
