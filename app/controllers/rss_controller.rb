# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class RssController < ApplicationController
  before_action :authentication_check

=begin

Resource:
GET /api/v1/rss_fetch

Response:
{
  ...
}

Test:
curl http://localhost/api/v1/rss_fetch.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X GET

=end

  def fetch
    items = Rss.fetch(params[:url], params[:limit])
    raise Exceptions::UnprocessableEntity, "failed to fetch #{params[:url]}" if items.nil?
    render json: { items: items }
  end

end
