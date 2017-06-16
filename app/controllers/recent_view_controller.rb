# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class RecentViewController < ApplicationController
  prepend_before_action :authentication_check

=begin

Resource:
GET /api/v1/recent_viewed

Response:
{
  ...
}

Test:
curl http://localhost/api/v1/recent_view -v -u #{login}:#{password} -H "Content-Type: application/json" -X GET

=end

  def index
    recent_viewed = RecentView.list_full(current_user, 10)

    # return result
    render json: recent_viewed
  end

=begin

Resource:
POST /api/v1/recent_viewed

Payload:
{
  "object": "Ticket",
  "o_id": 123,
}

Response:
{}

Test:
curl http://localhost/api/v1/recent_view -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"object": "Ticket","o_id": 123}'

=end

  def create

    RecentView.log(params[:object], params[:o_id], current_user)

    # return result
    render json: { message: 'ok' }
  end

end
