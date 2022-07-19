# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class UploadFileInputType < Gql::Types::BaseInputObject

    description 'A file to be uploaded.'

    argument :name, String, required: true, description: 'File name.'
    argument :type, String, required: false, description: "File's content-type."
    argument :content, Gql::Types::BinaryStringType, required: true, description: 'File content'
  end
end
