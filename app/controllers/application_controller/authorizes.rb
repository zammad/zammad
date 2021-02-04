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
  rescue Exceptions::Forbidden, Pundit::NotAuthorizedError
    false
  end

  def policy_record
    # check permissions in matching Pundit policy
    # Controllers namspace is used (See: https://github.com/varvet/pundit#policy-namespacing)
    # [:controllers, self] => Controllers::RolesControllerPolicy
    [:controllers, self]
  end

  def pundit_user
    @pundit_user ||= UserContext.new(current_user, @_token)
  end
end
