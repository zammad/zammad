class RssController < ApplicationController
  before_filter :authentication_check

  # GET /rss_fetch
  def fetch
    items = RSS.fetch(params[:url], params[:limit])
    if items == nil
      render :json => { :message => "failed to fetch #{ params[:url] }", :status => :unprocessable_entity }
    end
    render :json => { :items => items }
  end

end