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
  #
  # Asked of one instance per object rather than through `Pundit.authorize`, which builds a fresh
  #   policy per question: whatever a policy memoizes is then shared by every field of the same
  #   `policy` selection. KnowledgeBase::CategoryPolicy resolves the effective permission of a
  #   category once per instance, so its five fields used to resolve it five times - per category
  #   in a browse grid.
  def pundit(query)
    pundit_policy.public_send(query)
  rescue Pundit::NotAuthorizedError
    false
  end

  def pundit_policy
    @pundit_policy ||= Pundit.policy!(user, record)
  end

  def record
    @object
  end

  def user
    context.current_user
  end
end
