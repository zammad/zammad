# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket
  class ArticleType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasScopedModelUserRelations
    include Gql::Types::Concerns::HasInternalIdField
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Ticket articles'

    belongs_to :type, Gql::Types::Ticket::Article::TypeType
    belongs_to :sender, Gql::Types::Ticket::Article::SenderType

    field :subject, String

    field :author, Gql::Types::UserType, null: false, is_dependent_field: true, description: 'The originator (originBy, if any) or the creator of an article.'

    field :from, Gql::Types::AddressesFieldType
    field :to, Gql::Types::AddressesFieldType
    field :cc, Gql::Types::AddressesFieldType
    field :reply_to, Gql::Types::AddressesFieldType
    field :message_id, String
    field :message_id_md5, String
    field :in_reply_to, String
    field :content_type, String, null: false
    field :references, String
    field :body, String, null: false, description: 'Raw body as saved in the database.'
    field :body_with_urls, String, null: false, description: 'Body with cid: URLs replaced for inline images in HTML articles.'
    field :internal, Boolean, null: false

    field :preferences, ::GraphQL::Types::JSON
    field :security_state, Gql::Types::Ticket::Article::SecurityStateType
    field :media_error_state, Gql::Types::Ticket::Article::MediaErrorStateType

    field :attachments, [Gql::Types::StoredFileType, { null: false }], null: false, description: 'All attached files as stored in the database.'
    field :attachments_without_inline, [Gql::Types::StoredFileType, { null: false }], null: false, description: 'Attachments for display, with inline images filtered out.'

    belongs_to :ticket, Gql::Types::TicketType, null: false
    # belongs_to :origin_by, Gql::Types::UserType # see :author instead

    def body_with_urls
      display_article['body']
    end

    def attachments_without_inline
      # TODO: This uses asset handling related code which does more than what we need here.
      #   On the long run it might be better to store the display flag directly with the attachments,
      #   rather than always calculating it on-the-fly.
      select_ids = display_article['attachments'].pluck('id')
      @object.attachments.select do |attachment|
        select_ids.include?(attachment.id)
      end
    end

    def security_state
      @object.preferences['security']
    end

    def media_error_state
      @object.preferences&.dig('whatsapp')
    end

    private

    def display_article
      # TODO: This uses asset handling related code which does more than what we need here.
      @display_article ||= @object.class.insert_urls(@object.attributes_with_association_ids)
    end
  end
end
