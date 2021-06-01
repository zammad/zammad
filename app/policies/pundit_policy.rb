# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

    raise Exceptions::Forbidden, 'Authentication required'
  end

  private

  def not_authorized(details = nil)
    if details
      details = "Not authorized (#{details})!"
    end
    @custom_exception = Exceptions::Forbidden.new(details)
    false
  end

end
