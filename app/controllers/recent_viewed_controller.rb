# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class RecentViewedController < ApplicationController
  before_filter :authentication_check

=begin

Resource:
GET /api/v1/recent_viewed

Response:
{
  ...
}

Test:
curl http://localhost/api/v1/recent_viewed.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X GET

=end

  def recent_viewed
    recent_viewed = RecentView.list_fulldata( current_user, 10 )

    # return result
    render :json => recent_viewed
  end

end
