# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class KnowledgeBase::Answer::LiveUserUpdates < BaseSubscription
    include Gql::Subscriptions::Concerns::TransformsTaskbarLiveUsers

    description 'Updates to knowledge base answer live users (for editors).'

    field :live_users, [Gql::Types::KnowledgeBase::Answer::LiveUserType], description: 'Current live users from the knowledge base answer.'

    # Not 'ticket.agent' like its ticket counterpart: only an editor opens an answer in a tab, and
    #   an editor may hold no ticket permission at all. Who ends up *in* the list is decided per
    #   record by KnowledgeBase::AnswerPolicy#update? (see Taskbar#target_accessible_to_owner?).
    requires_permission 'knowledge_base.editor'
  end
end
