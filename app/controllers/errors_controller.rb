class ErrorsController < ApplicationController
  def routing
    not_found(ActionController::RoutingError.new("No route matches [#{request.method}] #{request.path}"))
  end
end
