# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
    field :body, String, null: false, description: 'Raw body as saved in the database.'
    field :body_with_urls, String, null: false, description: 'Body with cid: URLs replaced for inline images in HTML articles.'
    field :internal, Boolean, null: false
    field :detected_language, String

    field :preferences, ::GraphQL::Types::JSON
    field :security_state, Gql::Types::Ticket::Article::SecurityStateType
    field :media_error_state, Gql::Types::Ticket::Article::MediaErrorStateType

    field :attachments, [Gql::Types::StoredFileType, { null: false }], null: false, description: 'All attached files as stored in the database.'
    field :attachments_without_inline, [Gql::Types::StoredFileType, { null: false }], null: false, description: 'Attachments for display, with inline images filtered out.'

    internal_fields do
      field :highlighted_texts, [Gql::Types::Ticket::Article::HighlightedTextType]
    end

    belongs_to :ticket, Gql::Types::TicketType, null: false
    # belongs_to :origin_by, Gql::Types::UserType # see :author instead

    def body_with_urls
      display_article[:body]
    end

    def attachments_without_inline
      display_article[:attachments]
    end

    def security_state
      @object.preferences['security']
    end

    def media_error_state
      @object.preferences&.dig('whatsapp')
    end

    def highlighted_texts
      @object.preferences&.dig('highlight')&.split('|')&.drop(1) || []
    end

    private

    def display_article
      @display_article ||= begin
        body, attachments = @object.class.insert_urls(@object)

        { body:, attachments: }
      end
    end
  end
end
