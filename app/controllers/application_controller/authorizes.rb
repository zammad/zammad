module ApplicationController::Authorizes
  extend ActiveSupport::Concern
  include Pundit

  private

  def authorize!(record = policy_record, query = nil)
    authorize(record, query)
  end

  def authorized?(record = policy_record, query = nil)
    authorize!(record, query)
    true
  rescue Exceptions::NotAuthorized, Pundit::NotAuthorizedError
    false
  end

  def policy_record
    # check permissions in matching Pundit policy
    # Controllers namspace is used (See: https://github.com/varvet/pundit#policy-namespacing)
    # [:controllers, self] => Controllers::RolesControllerPolicy
    [:controllers, self]
  end

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
      return if @token.permissions?(permissions)

      raise Exceptions::NotAuthorized, 'Not authorized (token)!'
    end

    def permissions?(permissions)
      permissions!(permissions)
      true
    rescue Exceptions::NotAuthorized
      false
    end
  end

  def pundit_user
    @pundit_user ||= UserContext.new(current_user, @_token)
  end
end
