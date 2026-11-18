# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Answer::Suggestion::Content::Transform < BaseMutation
    include Gql::Mutations::Form::UploadCache::Concerns::HandlesAuthorization

    description 'Transform the content of a knowledge base answer suggestion to be usable in the frontend'

    argument :translation_id, GraphQL::Types::ID, 'Answer translation ID to get the contents for'
    argument :form_id, Gql::Types::FormIdType, required: false, description: 'Form identifier of current form to copy attachments to; without one, the images are embedded as data and no attachments are returned'

    field :body, String, null: true, description: 'Answer translation content'
    field :attachments, [Gql::Types::StoredFileType], null: true, description: 'Attachments of the answer'

    # Also for chat agents without ticket access, who insert answers into a chat message.
    requires_permission 'ticket.agent', 'chat.agent'

    def resolve(translation_id:, form_id: nil)
      translation = Gql::ZammadSchema.authorized_object_from_id(translation_id, type: ::KnowledgeBase::Answer::Translation, user: context.current_user)

      {
        body:        convert_body(translation, form_id),
        attachments: form_id.present? ? clone_attachments(translation, form_id) : nil
      }
    end

    private

    def convert_body(translation, form_id)
      # Before the images: an embedded image can be longer than the parser of the links takes.
      body = resolve_answer_links(translation.content.body.dup)
      body = form_id.present? ? body_with_copied_images(body, translation, form_id) : body_with_embedded_images(body, translation)

      KnowledgeBaseRichText.link_video_widgets(body)
    end

    def body_with_copied_images(body, translation, form_id)
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
      HasRichText.insert_urls(body, content_attachments)
    end

    # For a message without a form, like a chat message, whose reader cannot load an attachment URL.
    def body_with_embedded_images(body, translation)
      scrubber = HtmlSanitizer::Scrubber::InsertInlineImages.new(translation.content.attachments)

      ScrubHtml.new(body, scrubber).scrub!.to_s
    end

    def resolve_answer_links(body)
      KnowledgeBaseRichText.resolve_answer_links(body, detach: true) { |target| publicly_visible?(target) ? target.public_url : agent_url(target) }
    end

    # The public help site serves active knowledge bases only.
    def publicly_visible?(translation)
      translation.answer.visible? && translation.kb_locale.knowledge_base.visible?
    end

    # Absolute, as the article is also read outside the app, e.g. in the agent notification email.
    def agent_url(translation)
      "#{Setting.get('http_type')}://#{Setting.get('fqdn')}#{translation.desktop_url}"
    end

    def clone_attachments(translation, form_id)
      translation.answer.clone_attachments('UploadCache', form_id, only_attached_attachments: true)
    end
  end
end
