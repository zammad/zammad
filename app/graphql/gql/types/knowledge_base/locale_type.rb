# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class LocaleType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields

    description 'Knowledge Base Locale'

    field :primary, Boolean, null: false

    belongs_to :knowledge_base, Gql::Types::KnowledgeBaseType, null: false
    belongs_to :system_locale, Gql::Types::LocaleType, null: false
  end
end
