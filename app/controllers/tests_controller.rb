# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TestsController < ApplicationController

  prepend_before_action -> { authentication_check_only }

  # GET /test/wait
  def wait
    sleep params[:sec].to_i
    result = { success: true }
    render json: result
  end

  # GET /test/raised_exception
  def error_raised_exception
    exception = params.fetch(:exception, 'StandardError')
    message   = params.fetch(:message, 'no message provided')

    raise exception.safe_constantize, message
  end

end
