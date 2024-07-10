# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class UploadFileInputType < Gql::Types::BaseInputObject

    description 'A file to be uploaded.'

    argument :name, String, description: 'File name.'
    argument :type, String, required: false, description: "File's content-type."
    argument :content, Gql::Types::BinaryStringType, required: false, description: 'File content'
    argument :inline, Boolean, required: false, description: 'Content-Disposition: inline flag'
  end
end
