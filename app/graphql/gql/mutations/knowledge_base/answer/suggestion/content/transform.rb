# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Answer::Suggestion::Content::Transform < BaseMutation
    description 'Transform the content of a knowledge base answer suggestion to be usable in the frontend'

    argument :translation_id, GraphQL::Types::ID, 'Answer translation ID to get the contents for'
    argument :form_id, Gql::Types::FormIdType, 'Form identifier of current form to copy attachments to'

    field :body, String, null: true, description: 'Answer translation content'
    field :attachments, [Gql::Types::StoredFileType], null: true, description: 'Attachments of the answer'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('ticket.agent')
    end

    def resolve(translation_id:, form_id:)
      translation = Gql::ZammadSchema.verified_object_from_id(translation_id, type: ::KnowledgeBase::Answer::Translation)

      {
        body:        convert_body(translation),
        attachments: extract_and_copy_attachments(translation, form_id)
      }
    end

    private

    def convert_body(translation)
      return if translation.content.blank?

      scrubber = HtmlSanitizer::Scrubber::InsertInlineImages.new(translation.content.attachments)

      Loofah.scrub_fragment(translation.content.body, scrubber).to_s
    end

    def extract_and_copy_attachments(translation, form_id)
      return if translation.answer.attachments.none?

      translation.answer.clone_attachments(
        'UploadCache',
        form_id,
        only_attached_attachments: true
      ).each_with_object([]) do |attachment, result|
        result.push(attachment)
      end
    end
  end
end
