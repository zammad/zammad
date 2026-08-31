# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::KnowledgeBase
  class CreateAnswerInputType < BaseAnswerInputType
    description 'Represents the knowledge base answer attributes to be used in create.'

    # A create has no stored answer to leave anything alone, so everything the answer is made of has
    #   to be submitted — see Gql::Types::Input::KnowledgeBase::BaseAnswerInputType, where each of
    #   them is declared and that requirement is reasoned per attribute.
    #
    # Service::KnowledgeBase::Answer::Create still guards the category itself: the schema speaks for
    #   this mutation, the guard for the service's own callers.
    answer_attributes required: true

    # Create-only. An existing answer is tagged straight away from its sidebar, with
    #   `tagAssignmentAdd`/`tagAssignmentRemove` on the record itself - the same as the ticket detail
    #   view does, and the reason the update input has no `tags` at all: an update that left it out
    #   could only ever mean "leave them alone", and one that sent it could silently clear them.
    #   A create has no record to tag yet, so its tags have to ride the mutation.
    #
    # An empty list is what "no tags" looks like, so there is nothing for an absent argument to say -
    #   which is why the argument is required rather than the list filled.
    argument :tags, [String], required: true, description: 'Tags to assign to the answer, empty for none. A tag that does not exist yet is only created when the `tag_new` setting allows it.'
  end
end
