# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::KnowledgeBase::AnswerScreenBehavior < BaseMutation
    description 'Update what happens for the current user after a knowledge base answer was saved'

    argument :screen, Gql::Types::Enum::KnowledgeBase::AnswerScreenType, description: 'Knowledge base answer screen to set the behavior for'
    argument :behavior, Gql::Types::Enum::KnowledgeBase::AnswerScreenBehaviorType, description: 'Knowledge base answer screen behavior to set'

    field :success, Boolean, null: false, description: 'Whether the setting was updated successfully'

    # Only the knowledge base editor has an answer edit tab to configure, and every other
    #   User::Current mutation states its permission too. It writes nothing but the caller's own
    #   preference, so this is about intent rather than about a hole.
    requires_permission 'knowledge_base.editor'

    # A key per screen, and neither of them the ticket one: `secondaryAction` belongs to the ticket
    #   detail view, and all three must be settable independently - somebody adding answers in a
    #   row wants to be left on the form, which is not what they want after correcting one.
    #   Preferences need no migration, so an absent key simply means the default (`stayOnTab`,
    #   applied client-side).
    PREFERENCES_KEYS = {
      'create' => 'knowledgeBaseAnswerCreateSecondaryAction',
      'edit'   => 'knowledgeBaseAnswerSecondaryAction',
    }.freeze

    # One mutation for both screens, unlike the ticket counterpart it sits next to: the two screens
    #   accept the very same behavior enum, so the screen can be a plain argument. (A shared
    #   `ScreenBehavior(entity:, behavior:)` across *entities* would not work that way - a GraphQL
    #   argument's type cannot depend on another argument's value, and ticket and answer take
    #   different enums.)
    def resolve(screen:, behavior:)
      user = context.current_user
      user.preferences[PREFERENCES_KEYS.fetch(screen)] = behavior
      user.save!

      { success: true }
    end
  end
end
