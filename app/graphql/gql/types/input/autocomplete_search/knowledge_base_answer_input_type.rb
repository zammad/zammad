# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::AutocompleteSearch
  class KnowledgeBaseAnswerInputType < InputType

    description 'Input fields for knowledge base answer autocomplete searches.'

    argument :except_answer_ids, [GraphQL::Types::ID], required: false, description: 'Optional knowledge base answer translation IDs to be filtered out from results'
  end
end
