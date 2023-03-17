# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class AttachmentInputType < Gql::Types::BaseInputObject
    description 'Represents the attachment attributes to be used e.g. in ticket create/update.'

    argument :form_id, Gql::Types::FormIdType, description: 'FormID for the attached files.'
    argument :files, [Gql::Types::Input::UploadFileInputType], required: true, description: 'The attached files.'
  end
end
