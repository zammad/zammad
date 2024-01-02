# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class User::AfterAuthController < ApplicationController
  prepend_before_action :authentication_check

  def show
    render json: Auth::AfterAuth.run(current_user, session)
  end
end
