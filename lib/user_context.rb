# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# We need a special UserContext when authorizing in controller context
# because of Token authentication which has it's own permissions
# See: https://github.com/varvet/pundit#additional-context
# We use a Delegator here to have transparent / DuckType access
# to the underlying User instance in the Policy
class UserContext < Delegator

  # Allow a UserContext to be handed to a background job exactly like the User it wraps (e.g. a
  # GraphQL mutation enqueuing a job with `context.current_user`). ActiveJob serializes record
  # arguments via `case/when GlobalID::Identification`, a C-level ancestry check that ignores our
  # `is_a?` override — so the delegator must actually include the module. It then serializes through
  # the delegated `to_global_id` (the user's GID) and resolves back to the User on the other side.
  # Without this, `perform_later(…, context.current_user, …)` raises "Unsupported argument type: User".
  include GlobalID::Identification

  def initialize(user, token = nil) # rubocop:disable Lint/MissingSuper
    @user  = user
    @token = token
  end

  def __getobj__
    @user
  end

  # Ruby's Delegator does not delegate `class` or `is_a?`, so override them here
  # to make UserContext transparent for code that inspects the class or checks
  # type membership (e.g. AR association type checks via is_a?).
  def class
    @user.class
  end

  def is_a?(klass)
    super || @user.is_a?(klass)
  end
  alias kind_of? is_a?

  def permissions?(permissions)
    permissions!(permissions)
    true
  rescue Exceptions::Forbidden
    false
  end

  def permissions!(permissions)
    raise Exceptions::Forbidden, __('Authentication required') if !@user

    return @token.with_context(user: @user) { permissions!(permissions) } if @token

    @user.permissions!(permissions)
  end
end
