# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
    @pundit_user ||= begin
      if current_user_on_behalf
        UserContext.new(current_user_on_behalf)
      else
        UserContext.new(current_user_real, @_token)
      end
    end
  end
end
