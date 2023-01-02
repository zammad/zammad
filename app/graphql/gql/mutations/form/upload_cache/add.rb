# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Form::UploadCache::Add < BaseMutation
    description 'Upload files for a form'

    argument :form_id, Gql::Types::FormIdType, 'FormID for the uploads.'
    argument :files, [Gql::Types::Input::UploadFileInputType], 'Files to be uploaded.'

    field :uploaded_files, [Gql::Types::StoredFileType], null: false, description: 'Information about the uploaded files.'

    def resolve(form_id:, files:)

      cache = UploadCache.new(form_id)

      result = files.map do |file|
        cache.add(
          data:          file.content,
          filename:      file.name,
          preferences:   { 'Content-Type' => file.type },
          created_by_id: context.current_user.id
        )
      end

      { uploaded_files: result }
    end

  end
end
