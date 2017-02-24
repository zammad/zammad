class ErrorsController < ApplicationController
  skip_before_action :verify_csrf_token
  def routing
    not_found(ActionController::RoutingError.new("No route matches [#{request.method}] #{request.path}"))
  end
end
