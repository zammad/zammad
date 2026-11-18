# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::ExternalReferences
  class IdoitUpObjectType < Gql::Types::BaseObject
    description 'i-doit up object item for an external reference for a ticket'

    field :idoit_up_object_id, String, null: false, method: :id, description: 'i-doit up object id'
    field :title, String, null: false
    field :link, Gql::Types::UriHttpStringType, description: 'Link to the object in the i-doit up GUI'
    field :type, String, null: false, method: :type_title
    field :status, String, null: false, method: :cmdb_status_title
  end
end
