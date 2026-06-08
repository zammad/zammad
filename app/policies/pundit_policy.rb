# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module PunditPolicy
  USER_REQUIRED = true

  attr_reader :user, :custom_exception

  def initialize(user, context)
    @user = user
    user_required! if self.class::USER_REQUIRED

    initialize_context(context)
  end

  def user_required!
    return if user

    raise Exceptions::Forbidden, __('Authentication required')
  end

  private

  def not_authorized(details_or_exception)
    @custom_exception = case details_or_exception
                        when Exception
                          details_or_exception
                        else
                          message = "Not authorized (#{details_or_exception})!"
                          Exceptions::Forbidden.new(message)
                        end

    false
  end

end
