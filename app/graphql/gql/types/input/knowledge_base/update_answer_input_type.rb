# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::KnowledgeBase
  class UpdateAnswerInputType < BaseAnswerInputType
    description 'Represents the knowledge base answer attributes to be used in update.'

    # Every attribute is optional, and an absent one leaves the stored value alone — see
    #   Gql::Types::Input::KnowledgeBase::BaseAnswerInputType, where they are declared.
    #
    # That is not just a convenience for partial saves: an editor may hold editor access to an answer
    #   whose category is reader-only for them (granular permissions apply per subtree), and the form
    #   sends the stored category back on every save. Only an actual move is authorized against the
    #   target, which the service decides — an unchanged category has to stay unauthorized, and
    #   therefore has to be recognizable as unchanged.
    answer_attributes required: false
  end
end
