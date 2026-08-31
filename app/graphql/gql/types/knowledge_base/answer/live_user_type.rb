# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase::Answer
  class LiveUserType < Gql::Types::BaseObject
    description 'Knowledge base answer live user information'

    field :user, Gql::Types::UserType, null: false, is_dependent_field: true
    field :apps, [Gql::Types::KnowledgeBase::Answer::LiveUser::AppType], null: false, description: 'Different apps information from the user'
  end
end
