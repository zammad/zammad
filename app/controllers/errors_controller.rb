# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class ErrorsController < ApplicationController
  skip_before_action :verify_csrf_token
  def routing
    not_found(ActionController::RoutingError.new("No route matches [#{request.method}] #{request.path}"))
  end
end
