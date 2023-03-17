# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Answer::Suggestion::Content::Transform < BaseMutation
    description 'Transform the content of a knowledge base answer suggestion to be usable in the frontend'

    argument :translation_id, GraphQL::Types::ID, 'Answer translation ID to get the contents for'
    argument :form_id, Gql::Types::FormIdType, 'Form identifier of current form to copy attachments to'

    field :body, String, null: true, description: 'Answer translation content'
    field :attachments, [Gql::Types::StoredFileType], null: true, description: 'Attachments of the answer'

    def self.authorize(_obj, ctx)
      ctx[:current_user].permissions?('ticket.agent')
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

      Loofah.scrub_fragment(translation.content.body, inline_image_scrubber(translation.content.attachments)).to_s
    end

    def inline_image_scrubber(attachments)
      Loofah::Scrubber.new do |node|
        next if !contains_inline_images?(node)

        lookup_cids = inline_images_cids(node)

        attachment = attachments.find { |file| lookup_cids.include?(file.preferences&.dig('Content-ID')) }
        next if !attachment

        node['cid'] = nil
        node['src'] = base64_data_url(attachment)
      end
    end

    def contains_inline_images?(node)
      return false if node.name != 'img'
      return false if !node['src']&.start_with?('cid:')

      true
    end

    def inline_images_cids(node)
      cid = node['src'].sub(%r{^cid:}, '')
      [cid, "<#{cid}>"]
    end

    def base64_data_url(attachment)
      "data:#{attachment.preferences['Content-Type']};base64,#{Base64.strict_encode64(attachment.content)}"
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
