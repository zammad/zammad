# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Form::UploadCache::Add < BaseMutation
    include Gql::Mutations::Form::UploadCache::Concerns::HandlesAuthorization

    description 'Upload files for a form'

    argument :form_id, Gql::Types::FormIdType, 'FormID for the uploads.'
    argument :files, [Gql::Types::Input::UploadFileInputType], 'Files to be uploaded.'

    field :uploaded_files, [Gql::Types::StoredFileType], null: false, description: 'Information about the uploaded files.'

    def resolve(form_id:, files:)

      cache  = UploadCache.new(form_id)
      result = files.map { |elem| add_single_file(cache, elem) }

      { uploaded_files: result }
    end

    private

    def add_single_file(cache, file)
      preferences = { 'Content-Type' => file.type }

      if file.inline
        preferences['Content-Disposition'] = 'inline'
      end

      cache.add(
        data:          file.content,
        filename:      file.name,
        preferences:   preferences,
        created_by_id: context.current_user.id
      )
    end
  end
end
