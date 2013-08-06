# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class ActivityController < ApplicationController
  before_filter :authentication_check

  # GET /api/v1/activity_stream
  def activity_stream
    activity_stream = History.activity_stream_fulldata( current_user, params[:limit] )

    # return result
    render :json => activity_stream
  end

end
