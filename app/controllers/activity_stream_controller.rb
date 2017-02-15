# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class ActivityStreamController < ApplicationController
  prepend_before_action :authentication_check

  # GET /api/v1/activity_stream
  def show
    activity_stream = current_user.activity_stream(params[:limit], true)

    # return result
    render json: activity_stream
  end

end
