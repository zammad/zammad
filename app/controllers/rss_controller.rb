class RssController < ApplicationController
  before_filter :authentication_check

=begin

Resource:
GET /api/rss_fetch

Response:
{
  ...
}

Test:
curl http://localhost/api/rss_fetch.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X GET

=end

  def fetch
    items = RSS.fetch(params[:url], params[:limit])
    if items == nil
      render :json => { :message => "failed to fetch #{ params[:url] }", :status => :unprocessable_entity }
    end
    render :json => { :items => items }
  end

end