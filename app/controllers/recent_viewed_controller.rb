class RecentViewedController < ApplicationController
  before_filter :authentication_check

  # GET /recent_viewed
  def recent_viewed
    recent_viewed = History.recent_viewed_fulldata(current_user)

    # return result
    render :json => recent_viewed
  end
  
end