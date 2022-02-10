# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket
  class ArticleType < Gql::Types::BaseObject
    include Gql::Concern::IsModelObject

    def self.authorize(object, ctx)
      Pundit.authorize ctx.current_user, object, :show?
    end

    description 'Ticket articles'

    field :from, String
    field :to, String
    field :cc, String
    field :subject, String
    field :reply_to, String
    field :message_id, String
    field :message_id_md5, String
    field :in_reply_to, String
    field :content_type, String, null: false
    field :references, String
    field :body, String, null: false
    field :internal, Boolean, null: false
    field :origin_by, Gql::Types::UserType, null: true
  end
end
