# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket
  class ArticleType < Gql::Types::BaseObject
    include Gql::Concerns::IsModelObject
    include Gql::Concerns::HasInternalId

    def self.authorize(object, ctx)
      Pundit.authorize ctx.current_user, object, :show?
    end

    description 'Ticket articles'

    belongs_to :type, Gql::Types::Ticket::Article::TypeType, null: true
    belongs_to :sender, Gql::Types::Ticket::Article::TypeType, null: true

    field :subject, String
    field :from, Gql::Types::AddressesFieldType
    field :to, Gql::Types::AddressesFieldType
    field :cc, Gql::Types::AddressesFieldType
    field :reply_to, Gql::Types::AddressesFieldType
    field :message_id, String
    field :message_id_md5, String
    field :in_reply_to, String
    field :content_type, String, null: false
    field :references, String
    field :body, String, null: false
    field :internal, Boolean, null: false
    field :preferences, ::GraphQL::Types::JSON
    field :origin_by, Gql::Types::UserType, null: true

    field :attachments, [Gql::Types::StoredFileType, { null: false }], null: false
  end
end
