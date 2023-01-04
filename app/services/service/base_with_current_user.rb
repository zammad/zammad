# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::BaseWithCurrentUser < Service::Base
  attr_reader :current_user

  def initialize(current_user:)
    super()
    @current_user = current_user
  end
end
