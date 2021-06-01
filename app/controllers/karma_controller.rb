# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KarmaController < ApplicationController
  prepend_before_action :authentication_check

  def index
    render json: {
      levels: Setting.get('karma_levels'),
      user:   Karma::User.by_user(current_user),
      logs:   Karma::ActivityLog.latest(current_user, 20),
    }
  end

end
