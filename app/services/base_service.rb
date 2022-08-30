# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class BaseService
  include HandlesErrors
  include HandlesCoreWorkflow

  attr_reader :current_user

  @@require_current_user = true # rubocop:disable Style/ClassVars

  def self.omit_current_user!
    @@require_current_user = false # rubocop:disable Style/ClassVars
  end

  def initialize(current_user: nil)
    if current_user.nil? && @require_current_user
      raise __('Need a valid user to create a new service object!')
    end

    @current_user = current_user
  end

  def execute(args)
    raise NotImplementedError
  end

  # Easy build method to directly get a service object for a defined class.
  def use_service(klass)
    klass.new(current_user: @current_user)
  end

  # Easy build method to directly call the 'execute' method of a service.
  def execute_service(klass, ...)
    use_service(klass).execute(...)
  end
end
