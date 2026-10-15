# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Answer::Suggestion::Content::Transform < BaseMutation
    include Gql::Mutations::Form::UploadCache::Concerns::HandlesAuthorization

    description 'Transform the content of a knowledge base answer suggestion to be usable in the frontend'

    argument :translation_id, GraphQL::Types::ID, 'Answer translation ID to get the contents for'
    argument :form_id, Gql::Types::FormIdType, 'Form identifier of current form to copy attachments to'

    field :body, String, null: true, description: 'Answer translation content'
    field :attachments, [Gql::Types::StoredFileType], null: true, description: 'Attachments of the answer'

    requires_permission 'ticket.agent'

    def resolve(translation_id:, form_id:)
      translation = Gql::ZammadSchema.authorized_object_from_id(translation_id, type: ::KnowledgeBase::Answer::Translation, user: context.current_user)

      {
        body:        KnowledgeBaseRichText.link_video_widgets(convert_body(translation, form_id)),
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
      body = HasRichText.insert_urls(translation.content.body.dup, content_attachments)
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
