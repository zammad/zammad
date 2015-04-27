# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class TestsController < ApplicationController

  # GET /test/wait
  def wait
    sleep params[:sec].to_i
    result = { success: true }
    render json: result
  end

end
