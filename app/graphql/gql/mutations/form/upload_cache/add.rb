# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Form::UploadCache::Add < BaseMutation
    include Gql::Mutations::Form::UploadCache::Concerns::HandlesAuthorization

    description 'Upload files for a form'

    argument :form_id, Gql::Types::FormIdType, 'FormID for the uploads.'
    argument :files, [Gql::Types::Input::UploadCacheFileInputType], 'Files to be uploaded.'

    field :uploaded_files, [Gql::Types::StoredFileType], null: false, description: 'Information about the uploaded files, in the order of the given files.'

    def resolve(form_id:, files:)
      uploaded_files = Service::UploadCache::Add
        .with_current_user(context.current_user)
        .execute(form_id:, files: files.map(&:to_h))

      { uploaded_files: }
    end
  end
end
