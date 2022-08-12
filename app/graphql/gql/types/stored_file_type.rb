# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class StoredFileType < Gql::Types::BaseObject
    include Gql::Concerns::IsModelObject
    include Gql::Concerns::HasInternalId

    description 'Represents a stored file.'

    field :name, String, null: false, description: 'File name.', hash_key: 'filename'
    field :size, Integer, null: true, description: 'File size in bytes'
    field :type, String, null: true, description: "File's content-type."
    field :preferences, GraphQL::Types::JSON, null: true

    def self.authorize(object, ctx)
      Pundit.authorize ctx.current_user, object, :show?
    end

    def type
      object.preferences['Content-Type']
    end
  end
end
