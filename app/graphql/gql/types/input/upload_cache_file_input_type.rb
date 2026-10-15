# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class UploadCacheFileInputType < UploadFileInputType

    description 'A file to be added to the upload cache of a form, either from its content or copied from an existing attachment.'

    argument :name, String, required: false, description: 'File name, defaults to the name of the copied attachment.'
    argument :attachment_id, GraphQL::Types::ID, required: false, loads: Gql::Types::StoredFileType, description: 'Existing attachment to copy, instead of the content.'

    validates required: { one_of: %i[content attachment] }
  end
end
