class TestsController < ApplicationController

  # GET /test
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /test/wait
  def wait
    sleep params[:sec].to_i
    result = { :success => true }
    render :json => result
  end

end
