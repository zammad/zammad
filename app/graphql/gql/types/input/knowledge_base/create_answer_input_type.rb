# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::KnowledgeBase
  class CreateAnswerInputType < Gql::Types::BaseInputObject
    description 'Represents the knowledge base answer attributes to be used in create.'

    # Create-only, like Gql::Types::Input::Ticket::CreateInputType — not one type for create and
    #   update the way the category input is. An answer's update has to be able to leave the
    #   category, the title and the body alone, none of which this one does.
    #
    # An answer always belongs to a category — there is no top level for it, the way there is for a
    #   category — so the one thing a create cannot do without is required here rather than left to
    #   the service. Service::KnowledgeBase::Answer::Create still refuses a missing one: the schema
    #   speaks for this mutation, the guard for the service's own callers.
    #
    # Not gated with `loads_pundit_method:`: whether an answer may be filed in a category is
    #   KnowledgeBase::AnswerPolicy#create?, which the service asks of the built answer — the same
    #   split the category input makes for its parent.
    argument :category_id, GraphQL::Types::ID, loads: Gql::Types::KnowledgeBase::CategoryType, description: 'Category to file the answer in.'

    # An answer has no title or body column: it has one translation per knowledge base locale, and
    #   the mutation's `locale` says which one this is.
    #
    # Required, and this one has to be: its presence is validated on
    #   KnowledgeBase::Answer::Translation, and that error can only be reported on the answer's
    #   `translations.title` path — which ActiveModel cannot even render a message for, since it
    #   reads the attribute off the answer, which has no such method. Requiring it here keeps a
    #   blank title from ever reaching that validation. `NonEmptyStringType` also rules out a
    #   whitespace-only one, which would fail it just the same.
    argument :title, Gql::Types::NonEmptyStringType, description: 'Title of the answer in the locale of this mutation.'

    # Required, but as a plain String rather than a NonEmptyStringType like the title: what an empty
    #   body looks like is a question about markup ('<p></p>' is empty to a reader and not to a
    #   string), which the form's editor field answers, not the schema.
    #
    # Inline images travel inside it as data URLs and are pulled out into attachments of the
    #   translation content by HasRichText on save, so they are none of this argument's business.
    argument :body, String, description: 'Rich text body of the answer in the locale of this mutation.'

    # The counterpart of the form's file field, and only its id: the files themselves are already in
    #   the upload cache of that form, which is where a draft keeps them across sessions
    #   (Taskbar::HasAttachments). Flat like Gql::Types::Input::Ticket::SharedDraft::StartInputType,
    #   the other input that hands its files over this way, rather than an AttachmentInputType — the
    #   file field syncs its removals to the cache, so a list of what to pick out of it would only
    #   restate what the cache already holds.
    argument :form_id, Gql::Types::FormIdType, required: false, description: 'Form the answer is submitted from. Its upload cache holds the files to attach, minus the inline images of the body.'

    # Required, but an empty list is what "no tags" looks like: unlike an update, a create has no
    #   stored tags that an omitted argument could mean to leave alone, so there is nothing for the
    #   absent case to say.
    argument :tags, [String], description: 'Tags to assign to the answer, empty for none. A tag that does not exist yet is only created when the `tag_new` setting allows it.'

    # Required, `draft` included: which state an answer is created in is a decision the form makes
    #   (it starts out on `draft`), not something to be inferred from an absent argument. The state
    #   and its date travel together in one object, see
    #   Gql::Types::Input::KnowledgeBase::VisibilityInputType.
    argument :visibility, Gql::Types::Input::KnowledgeBase::VisibilityInputType, description: 'Publication state to create the answer in, and when it takes effect.'
  end
end
