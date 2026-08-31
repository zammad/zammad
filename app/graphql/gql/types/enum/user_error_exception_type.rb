# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class UserErrorExceptionType < BaseEnum
    description 'All user error exception values'

    # The services whose validators may raise an exception the client is meant to recognise - and
    #   possibly resubmit with, in `skipValidators`.
    #
    # Listed explicitly rather than discovered from a shared error base: this enum is built when the
    #   schema loads, and `descendants` only ever sees classes that have already been autoloaded.
    #   Naming each service forces its validator subtree to load (Mixin::RequiredSubPaths), so the
    #   enum cannot silently come up short. A new caller is one line.
    VALIDATORS = [
      Service::KnowledgeBase::Answer::Update::Validator,
      Service::Ticket::Update::Validator,
    ].freeze

    build_class_list_enum VALIDATORS.flat_map(&:exceptions).sort_by(&:name)
  end
end
