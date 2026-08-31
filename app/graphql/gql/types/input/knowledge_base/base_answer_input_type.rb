# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::KnowledgeBase
  # What an answer is made of, for the create and the update mutation alike — the shared base of
  #   Gql::Types::Input::KnowledgeBase::CreateAnswerInputType and ::UpdateAnswerInputType, like
  #   Gql::Types::Input::Ticket::BaseInputType is for the ticket pair.
  #
  # Not one type for both the way the category input is: the two disagree about whether the answer's
  #   own attributes have to be there. A create cannot do without them, while an update has to be
  #   able to leave every single one alone — so `required` is declared by the subclass (see
  #   .answer_attributes) and everything else lives here once.
  #
  # They also disagree about `tags`, which only a create submits at all — declared there rather than
  #   here, for the reason given on Gql::Types::Input::KnowledgeBase::CreateAnswerInputType.
  #
  # Abstract, and therefore not part of the schema: nothing takes it as an argument.
  class BaseAnswerInputType < Gql::Types::BaseInputObject
    # Declares the answer's attributes on the calling type. Which locale the title and the body
    #   belong to is not among them: that is the mutation's own flat `locale` argument, which
    #   describes the call rather than the answer.
    #
    # @param required [Boolean] whether the answer's attributes have to be submitted
    def self.answer_attributes(required:)
      # An answer always belongs to a category — there is no top level for it, the way there is for
      #   a category — so a create requires one. An update leaves the stored one alone unless a
      #   different one is submitted, and only an actual move is authorized against the target.
      #
      # Not gated with `loads_pundit_method:`: whether an answer may be filed in a category is
      #   KnowledgeBase::AnswerPolicy#create?, which the service asks of the answer — the same split
      #   the category input makes for its parent.
      argument :category_id, GraphQL::Types::ID, required: required, loads: Gql::Types::KnowledgeBase::CategoryType, description: 'Category to file the answer in.'

      # An answer has no title or body column: it has one translation per knowledge base locale, and
      #   the mutation's `locale` says which one this is.
      #
      # Required for a create, and that one has to be: presence is validated on
      #   KnowledgeBase::Answer::Translation, and that error can only be reported on the answer's
      #   `translations.title` path — which ActiveModel cannot even render a message for, since it
      #   reads the attribute off the answer, which has no such method. `NonEmptyStringType` also
      #   rules out a whitespace-only one, which would fail the very same validation.
      argument :title, Gql::Types::NonEmptyStringType, required: required, description: 'Title of the answer in the locale of this mutation.'

      # A plain String rather than a NonEmptyStringType like the title: what an empty body looks like
      #   is a question about markup ('<p></p>' is empty to a reader and not to a string), which the
      #   form's editor field answers, not the schema.
      #
      # Inline images travel inside it as data URLs and are pulled out into attachments of the
      #   translation content by HasRichText on save, so they are none of this argument's business.
      argument :body, String, required: required, description: 'Rich text body of the answer in the locale of this mutation.'

      # The one attribute `required` does not apply to: an answer can be submitted from a form that
      #   has no files at all, in a create as much as in an update.
      #
      # The counterpart of the form's file field, and only its id: the files themselves are already in
      #   the upload cache of that form, which is where a draft keeps them across sessions
      #   (Taskbar::HasAttachments). Flat like Gql::Types::Input::Ticket::SharedDraft::StartInputType,
      #   the other input that hands its files over this way, rather than an AttachmentInputType — the
      #   file field syncs its removals to the cache, so a list of what to pick out of it would only
      #   restate what the cache already holds.
      argument :form_id, Gql::Types::FormIdType, required: false, description: 'Form the answer is submitted from. Its upload cache holds the files to attach, minus the inline images of the body.'

      # Which state an answer is created in is a decision the form makes (it starts out on `draft`),
      #   not something to be inferred from an absent argument — `draft` included, hence required for
      #   a create.
      #
      # The state alone, with no date to go with it: both forms say what the answer's state is
      #   *now*, and a transition scheduled for later is managed apart from the answer's data. The
      #   service keeps a schedule the old interface wrote rather than cancelling it
      #   (Service::KnowledgeBase::Answer::Base#scheduled_publication?).
      argument :visibility, Gql::Types::Enum::KnowledgeBase::VisibilityType, required: required, description: 'Publication state to put the answer in, effective immediately.'
    end
  end
end
