class RssController < ApplicationController
  before_filter :authentication_check

  # GET /rss_fetch
  def fetch
    url   = params[:url]
    limit = params[:limit] || 10
    response = Net::HTTP.get_response( URI.parse(url) )
    if response.code.to_s != '200'
      render :json => { :message => "failed to fetch #{url}, code: #{response.code}"}, :status => :unprocessable_entity
      return
    end
    rss     = SimpleRSS.parse response.body
    items   = []
    fetched = 0
    rss.items.each { |item|
      items.push item
      fetched += 1
      break item if fetched == limit.to_i
    }
    render :json => { :items => items }
  end

end