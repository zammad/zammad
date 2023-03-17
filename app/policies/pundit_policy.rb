# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module PunditPolicy

  attr_reader :user, :custom_exception

  def initialize(user, context)
    @user = user
    user_required! if user_required?

    initialize_context(context)
  end

  def user_required?
    true
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
