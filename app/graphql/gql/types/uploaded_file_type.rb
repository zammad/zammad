# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class UploadedFileType < Gql::Types::BaseObject

    description 'An uploaded file.'

    field :id, GraphQL::Types::ID, null: false, description: "ID of the file's store entry."
    field :name, String, null: false, description: 'File name.'
    field :type, String, null: true, description: "File's content-type."
  end
end
