# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class ContentTranslationType < Gql::Types::BaseObject
    description 'The translation of the content of an object'

    field :content, String, description: 'The translated content, in the format of the original'
    field :backend, String, null: true, description: 'The service that produced the translation, e.g. "ai"'
    field :translated, Boolean, description: 'False if the content was returned as it is, because there was nothing to translate'
  end
end
