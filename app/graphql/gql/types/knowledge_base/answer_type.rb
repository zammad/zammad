# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class AnswerType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Knowledge Base Answer'

    internal_fields do
      field :promoted, Boolean
      field :internal_note, String
    end

    field :position, Integer, null: false
    field :archived_at, GraphQL::Types::ISO8601DateTime
    field :internal_at, GraphQL::Types::ISO8601DateTime
    field :published_at, GraphQL::Types::ISO8601DateTime

    belongs_to :category, Gql::Types::KnowledgeBase::CategoryType, null: false
    belongs_to :archived_by, Gql::Types::UserType, null: true
    belongs_to :internal_by, Gql::Types::UserType, null: true
    belongs_to :published_by, Gql::Types::UserType, null: true
  end
end
