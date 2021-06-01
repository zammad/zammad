# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# We need a special UserContext when authorizing in controller context
# because of Token authentication which has it's own permissions
# See: https://github.com/varvet/pundit#additional-context
# We use a Delegator here to have transparent / DuckType access
# to the underlying User instance in the Policy
class UserContext < Delegator

  def initialize(user, token = nil) # rubocop:disable Lint/MissingSuper
    @user  = user
    @token = token
  end

  def __getobj__
    @user
  end

  def permissions!(permissions)
    raise Exceptions::Forbidden, 'Authentication required' if !@user
    raise Exceptions::Forbidden, 'Not authorized (user)!' if !@user.permissions?(permissions)
    return if !@token
    return if @token.with_context(user: @user) { permissions?(permissions) }

    raise Exceptions::Forbidden, 'Not authorized (token)!'
  end

  def permissions?(permissions)
    permissions!(permissions)
    true
  rescue Exceptions::Forbidden
    false
  end
end
