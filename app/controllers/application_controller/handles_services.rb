# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module ApplicationController::HandlesServices
  extend ActiveSupport::Concern

  included do
    # Easy build method to directly get a service object for a defined class.
    def use_service(klass)
      klass.new(current_user: current_user)
    end

    # Easy build method to directly call the 'execute' method of a service.
    def execute_service(klass, ...)
      use_service(klass).execute(...)
    end
  end
end
