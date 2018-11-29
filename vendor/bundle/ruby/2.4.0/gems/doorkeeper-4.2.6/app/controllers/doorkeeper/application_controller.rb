module Doorkeeper
  class ApplicationController <
    Doorkeeper.configuration.base_controller.constantize

    include Helpers::Controller

    if ::Rails.version.to_i < 4
      protect_from_forgery
    else
      protect_from_forgery with: :exception
    end

    helper 'doorkeeper/dashboard'
  end
end
