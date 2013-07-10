# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class TestsController < ApplicationController

  # GET /tests/core
  def core
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /tests/from
  def form
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
