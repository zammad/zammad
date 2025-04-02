# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ErrorsController < ApplicationController
  skip_before_action :verify_csrf_token
  def routing
    not_found(ActionController::RoutingError.new("This page doesn't exist.")) # rubocop:disable Zammad/DetectTranslatableString
  end
end
