# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum::KnowledgeBase
  class AnswerScreenBehaviorType < Gql::Types::Enum::BaseEnum
    description 'Option to choose what happens after a knowledge base answer was saved'

    # Deliberately not Gql::Types::Enum::TicketScreenBehaviorType: `closeTabOnTicketClose` and
    #   `closeNextInOverview` are ticket concepts, and a GraphQL enum cannot be accepted in part -
    #   the mutation would have to reject half of its own values at runtime.
    #
    # Every "close" option closes the tab and differs only in where it leaves the editor, which is
    #   why they name their destination rather than the closing.
    #
    # Not every value applies to every screen (Gql::Types::Enum::KnowledgeBase::AnswerScreenType):
    #   `stayOnTab` needs a tab that outlives the save, which only the edit screen has, and
    #   `closeTabAndAddAnother` needs a form to reopen, which only the create screen has. Both are
    #   in one enum because a GraphQL argument's type cannot depend on another argument's value, and
    #   the alternative - a mutation and an enum per screen - would duplicate the whole thing to
    #   express one value each. What is offered per screen is decided where the options are built,
    #   so a screen can never store the value that does not apply to it; and a stored value that
    #   does not apply anyway means the screen's default rather than an error, the way the ticket
    #   enum already carries `closeNextInOverview` for a case its handler does not act on.
    value 'stayOnTab', 'Keep the tab open on the saved answer. Edit screen only.'
    value 'closeTabAndOpenAnswer', 'Close the tab and read the saved answer.'
    value 'closeTabAndOpenCategory', 'Close the tab and return to the answer\'s category.'
    value 'closeTabAndAddAnother', 'Close the tab and open a fresh form to add the next answer in the same category. Create screen only.'
  end
end
