# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::KnowledgeBase::Answer
  class UpdateMetaInputType < Gql::Types::BaseInputObject
    description 'How to carry out a knowledge base answer update, as opposed to what to store.'

    # The attachments the form was opened with, so the service can tell a foreign change from this
    #   editor's own: saving replays the upload cache and deletes what is not in it, so a cache
    #   seeded before somebody else added a file would delete their file (see
    #   Service::KnowledgeBase::Answer::Update::Validator::ConcurrentAttachmentChange).
    #
    # Meta rather than part of the answer data: it describes the form's starting point, not a value
    #   to store.
    argument :known_attachments, [Gql::Types::Input::KnowledgeBase::Answer::KnownAttachmentInputType], required: false, description: 'The attachments the form was opened with, to detect a concurrent change. Omit to skip that check.'

    # Resubmitting with the exception the previous attempt reported is the deliberate overwrite.
    argument :skip_validators, [Gql::Types::Enum::UserErrorExceptionType], required: false, description: 'Validator exceptions the caller was warned about and chooses to override.'
  end
end
