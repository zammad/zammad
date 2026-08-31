# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User::TaskbarItemEntity
  class KnowledgeBaseAnswerCreateType < Gql::Types::BaseObject
    description 'Entity representing taskbar item knowledge base answer create'

    VISIBILITIES = Gql::Types::Enum::KnowledgeBase::VisibilityType.values.values.map(&:value).freeze

    field :uid, String, null: false
    field :title, String, null: false

    # The locale of the draft, from the taskbar params. Nullable on purpose: a tab whose params
    #   never got one must still render, rather than failing the whole entity on a non-null.
    field :locale, String

    # The publication state the draft would be created in, so the tab can show the same status icon a
    #   stored answer has. Out of the draft state.
    #
    # Non-null, like the `visibility` of Gql::Types::KnowledgeBase::AnswerType, which an *edit* tab
    #   selects from the same union: one response name has to have one response shape across a
    #   document. `draft` stands in for a tab that has not been through a form updater round trip
    #   yet, which is the state a new answer starts in and what the client rendered for a null
    #   before.
    field :visibility, Gql::Types::Enum::KnowledgeBase::VisibilityType, null: false

    # The draft state of a tab that was opened but never typed into has no title yet, while the
    #   field is non-null for the client - which renders its own fallback label for a blank one.
    def title
      @object['title'] || ''
    end

    # The state holds what the form submitted, i.e. the enum's *name*; the field wants the value it
    #   was declared with. Anything else falls back to `draft` rather than being raised on: a single
    #   unexpected value in a stored draft would otherwise take the whole entity down with it, and
    #   with it the tab's title.
    def visibility
      value = @object['visibility'].presence&.to_sym

      VISIBILITIES.include?(value) ? value : :draft
    end
  end
end
