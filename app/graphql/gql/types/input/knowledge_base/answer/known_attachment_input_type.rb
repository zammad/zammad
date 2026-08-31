# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::KnowledgeBase::Answer
  class KnownAttachmentInputType < Gql::Types::BaseInputObject
    description 'One attachment the form was opened with, identified the only way it can be: the upload cache holds copies whose ids are not the answer\'s.'

    argument :name, String, description: 'File name.'
    # Integer, matching Gql::Types::StoredFileType#size, which is where the client reads it.
    argument :size, Integer, description: 'File size in bytes.'
  end
end
