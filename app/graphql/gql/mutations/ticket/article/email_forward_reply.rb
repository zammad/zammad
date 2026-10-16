# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Article::EmailForwardReply < BaseMutation
    include Gql::Mutations::Form::UploadCache::Concerns::HandlesAuthorization

    requires_permission 'ticket.agent'

    description 'Prepare for a new forward or reply email article'

    argument :article_id, GraphQL::Types::ID, loads: Gql::Types::Ticket::ArticleType, description: 'The article to be forwarded or replied to'
    argument :form_id, Gql::Types::FormIdType, description: 'Form identifier of the form for the new article to copy attachments to'

    field :quotable_from, String, description: "'From' information of the original email to be inserted in the quoted email block"
    field :quotable_to, String, description: "'To' information of the original email to be inserted in the quoted email block"
    field :quotable_cc, String, description: "'Cc' information of the original email to be inserted in the quoted email block"

    field :attachments, [Gql::Types::StoredFileType, { null: false }], null: false, description: 'Cloned attachments for the new article.'

    def resolve(article:, form_id:)
      # present? matches the blank? guard of the upload cache authorization -
      #   a blank form_id must not clone either.
      result = { attachments: form_id.present? ? clone_attachments(article:, form_id:) : [] }

      return result if !Setting.get('ui_ticket_zoom_article_email_full_quote_header')

      header = Service::Ticket::Article::QuotedHeader
        .with_current_user(context.current_user)
        .execute(article:)

      result.merge(quotable_from: header.from, quotable_to: header.to, quotable_cc: header.cc)
    end

    private

    def clone_attachments(article:, form_id:)
      article.clone_attachments('UploadCache', form_id, only_attached_attachments: true)
    end
  end
end
