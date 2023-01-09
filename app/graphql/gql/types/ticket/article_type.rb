# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket
  class ArticleType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalIdField
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Ticket articles'

    belongs_to :type, Gql::Types::Ticket::Article::TypeType
    belongs_to :sender, Gql::Types::Ticket::Article::SenderType

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
    field :origin_by, Gql::Types::UserType

    field :preferences, ::GraphQL::Types::JSON
    field :security_state, Gql::Types::Ticket::Article::SecurityStateType

    field :attachments, [Gql::Types::StoredFileType, { null: false }], null: false

    belongs_to :ticket, Gql::Types::TicketType, null: false

    def security_state
      @object.preferences['security']
    end
  end
end
