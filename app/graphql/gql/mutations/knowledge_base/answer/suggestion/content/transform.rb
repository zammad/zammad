# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Answer::Suggestion::Content::Transform < BaseMutation
    description 'Transform the content of a knowledge base answer suggestion to be usable in the frontend'

    argument :translation_id, GraphQL::Types::ID, 'Answer translation ID to get the contents for'
    argument :form_id, Gql::Types::FormIdType, 'Form identifier of current form to copy attachments to'

    field :body, String, null: true, description: 'Answer translation content'
    field :attachments, [Gql::Types::StoredFileType], null: true, description: 'Attachments of the answer'

    requires_permission 'ticket.agent'

    def resolve(translation_id:, form_id:)
      translation = Gql::ZammadSchema.verified_object_from_id(translation_id, type: ::KnowledgeBase::Answer::Translation)

      {
        body:        convert_body(translation, form_id),
        attachments: clone_attachments(translation, form_id)
      }
    end

    private

    def convert_body(translation, form_id)
      # Consider moving this to the CanCloneAttachments concern in future.
      content_attachments = translation.content.attachments.map do |elem|
        Store.create!(
          object:      'UploadCache',
          o_id:        form_id,
          data:        elem.content,
          filename:    elem.filename,
          preferences: elem.preferences,
        )
      end
      HasRichText.insert_urls(translation.content.body.dup, content_attachments)
    end

    def clone_attachments(translation, form_id)
      translation.answer.clone_attachments('UploadCache', form_id, only_attached_attachments: true)
    end
  end
end
