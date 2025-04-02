# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User::TaskbarItemEntity
  class TicketCreateType < Gql::Types::BaseObject
    description 'Entity representing taskbar item ticket create'

    field :uid, String, null: false
    field :title, String, null: false
    field :create_article_type_key, String

    def title
      @object['title'] || ''
    end

    def create_article_type_key
      @object['formSenderType']
    end
  end
end
