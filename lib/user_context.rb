# We need a special UserContext when authorizing in controller context
# because of Token authentication which has it's own permissions
# See: https://github.com/varvet/pundit#additional-context
# We use a Delegator here to have transparent / DuckType access
# to the underlying User instance in the Policy
class UserContext < Delegator

  def initialize(user, token)
    @user  = user
    @token = token
  end

  def __getobj__
    @user
  end

  def permissions!(permissions)
    raise Exceptions::NotAuthorized, 'authentication failed' if !@user
    raise Exceptions::NotAuthorized, 'Not authorized (user)!' if !@user.permissions?(permissions)
    return if !@token
    return if @token.with_context(user: @user) { permissions?(permissions) }

    raise Exceptions::NotAuthorized, 'Not authorized (token)!'
  end

  def permissions?(permissions)
    permissions!(permissions)
    true
  rescue Exceptions::NotAuthorized
    false
  end
end
