# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The plumbing behind the `policy` field of an object type: answer Pundit questions about the
#   object the field was resolved on, for the current user.
#
# Extracted from Gql::Types::Policy::DefaultType so a policy type can also be built from scratch.
#   Subclassing DefaultType is only an option when the policy actually answers both `update?` and
#   `destroy?` — KnowledgeBasePolicy has no `destroy?`, and the resulting NoMethodError is
#   re-raised by Gql::ZammadSchema rather than turned into a user error.
module Gql::Types::Policy::Concerns::HasPunditQueries
  extend ActiveSupport::Concern

  private

  # A policy question the user is not allowed to ask is not an error here, it is a `false` — the
  #   whole point of the field is to let the client hide an action instead of running into it.
  def pundit(query)
    Pundit.authorize(user, record, query)
  rescue Pundit::NotAuthorizedError
    false
  end

  def record
    @object
  end

  def user
    context.current_user
  end
end
