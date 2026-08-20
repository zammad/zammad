# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Policy::KnowledgeBaseType < Gql::Types::BaseObject
    include Gql::Types::Policy::Concerns::HasPunditQueries

    description 'Access knowledge base specific Pundit policy queries for the current object and user.'

    # Editor access to the knowledge base itself, which is what gates both editing it and adding a
    #   top level category (KnowledgeBase::CategoryPolicy#create? asks the parent, and for a top
    #   level category the parent is the knowledge base).
    #
    # No `destroy`, hence no Policy::DefaultType: KnowledgeBasePolicy has no `destroy?` at all, and
    #   deleting a knowledge base is not something the desktop view offers.
    field :update, Boolean, null: false, description: 'Is the user allowed to update this knowledge base?'

    def update
      pundit(:update?)
    end
  end
end
