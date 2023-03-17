# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class StoredFileType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalIdField
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Represents a stored file.'

    field :name, String, null: false, description: 'File name.', hash_key: 'filename'
    field :size, Integer, description: 'File size in bytes'
    field :type, String, description: "File's content-type."
    field :preferences, GraphQL::Types::JSON

    def type
      object.preferences['Content-Type']
    end
  end
end
